# Pressure Gauge Monitoring System

A Julia application for monitoring multiple vacuum pressure gauges, storing time-series data in PostgreSQL, and visualizing it via SlowDash.

This guide walks you through the system step by step, starting with visualization and building up to hardware integration.

## Quick Start: See the Dashboard First

Let's start by getting the visualization running so you have something to interact with immediately.

### Step 1: Start the Database and Dashboard

```bash
docker compose up -d
```

This starts two services:
- **PostgreSQL** (port 5432) - stores your pressure readings
- **SlowDash** (port 18881) - web dashboard for visualization

Open your browser to http://localhost:18881 to see the dashboard interface.

### Step 2: Add Some Test Data

Let's manually insert data so you can see how the system works:

```bash
# Connect to the database
docker compose exec db psql -U myuser -d mydatabase

# Create the table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS mytable (
    channel TEXT,
    timestamp BIGINT DEFAULT FLOOR(EXTRACT(EPOCH FROM now())),
    value REAL
);

# Insert some test readings
INSERT INTO mytable (channel, value) VALUES ('ch0', 1.5);
INSERT INTO mytable (channel, value) VALUES ('ch1', 0.002);
INSERT INTO mytable (channel, value) VALUES ('ch2', 15.3);

# See your data
SELECT * FROM mytable ORDER BY timestamp DESC LIMIT 10;

# Exit
\q
```

Refresh your SlowDash dashboard - you should see your test data plotted.

### Step 3: Generate Continuous Test Data

Instead of manual insertion, let's create a simple script to generate data continuously.

Create a file `test_data_generator.jl`:

```julia
using LibPQ, DBInterface

# Connect to database
conn_string = get(ENV, "DATABASE_URL", "postgresql://myuser:mypassword@localhost:5432/mydatabase")
conn = DBInterface.connect(LibPQ.Connection, conn_string)

# Create table
DBInterface.execute(conn, """
    CREATE TABLE IF NOT EXISTS mytable (
        channel TEXT,
        timestamp BIGINT DEFAULT FLOOR(EXTRACT(EPOCH FROM now())),
        value REAL
    )
""")

# Prepare insert statement
stmt = DBInterface.prepare(conn, "INSERT INTO mytable (channel, value) VALUES (\$1, \$2)")

println("Generating test data... Press Ctrl+C to stop")

try
    while true
        # Generate random pressure-like values
        ch0 = rand() * 10.0      # Random 0-10 mbar
        ch1 = rand() * 0.01      # Random 0-0.01 mbar
        ch2 = rand() * 250.0     # Random 0-250 psia

        # Insert into database
        DBInterface.execute(stmt, ("ch0", ch0))
        DBInterface.execute(stmt, ("ch1", ch1))
        DBInterface.execute(stmt, ("ch2", ch2))

        println("Inserted: ch0=$ch0, ch1=$ch1, ch2=$ch2")
        sleep(1)
    end
catch e
    e isa InterruptException ? println("\nStopped by user") : rethrow(e)
end
```

Run it:

```bash
# Install Julia dependencies first
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Run the test data generator
julia --project=. test_data_generator.jl
```

Click one of the channels and watch the SlowDash dashboard update in real-time as data flows in!

## Understanding the Data Flow

Now that you've seen the system working, here's what's happening:

```
Data Source → PostgreSQL → SlowDash → Your Browser
```

1. **Data Source**: Pressure readings (from test script or real hardware)
2. **PostgreSQL**: Stores timestamped readings in `mytable`
3. **SlowDash**: Queries the database and renders plots
4. **Your Browser**: Displays interactive dashboard at http://localhost:18881

### Database Schema

```sql
CREATE TABLE mytable (
    channel TEXT,              -- Which gauge: 'ch0', 'ch1', or 'ch2'
    timestamp BIGINT,          -- Unix epoch (seconds since 1970)
    value REAL                 -- Pressure reading
);
```

### SlowDash Configuration

Check `SlowdashProject.yaml` to see how SlowDash connects to PostgreSQL:

```yaml
data_source:
  url: postgresql://myuser:mypassword@db:5432/mydatabase
  time_series:
    schema: mytable [channel] @timestamp(unix) = value
```

This tells SlowDash:
- Where the database is
- Which table to read from
- How to interpret the columns (channel name, timestamp, value)

## Real Hardware Integration

Once you're comfortable with the data flow, you can connect to real pressure gauges.

### Hardware Requirements

- **Raspberry Pi** with WiringPi support
- **ADS1115 ADC** (I2C address 0x48) - converts analog voltages to digital
- **Three pressure gauges:**
    - Inficon PCG550 (0-10V output)
    - Pfeiffer PKR 261 (0-10V output)
    - MKS AA07B (0-5V output, 250 psia range)

### Running Real Data Collection

The `app.jl` script reads from actual hardware:

```bash
julia --project=. app.jl
```

**What it does:**

1. Configures the ADS1115 ADC
2. Reads voltage from each gauge every second
3. Converts voltages to pressure using gauge-specific calibration formulas (see `app.jl` for details)
4. Inserts readings into PostgreSQL (same schema as test data!)
5. SlowDash automatically picks up the real data

### Hardware Connections

```
Raspberry Pi GPIO
    ↓ (I2C: SDA, SCL)
ADS1115 ADC (channels 0, 1, 2)
    ↓ (analog voltage)
Pressure Gauges (PCG550, PKR 261, AA07B)
```

The ADS1115 converts the analog voltage outputs from the gauges into digital values that Julia can read.

## Configuration

### Database Connection

The default database credentials are:
- Username: `myuser`
- Password: `mypassword`
- Database: `mydatabase`

These are configured in `docker-compose.yaml`. To use different credentials, either:
1. Edit `docker-compose.yaml` and restart: `docker compose down && docker compose up -d`
2. Set the `DATABASE_URL` environment variable before running Julia scripts:
```bash
export DATABASE_URL="postgresql://youruser:yourpassword@localhost:5432/yourdatabase"
```

### Change SlowDash Settings

Edit `SlowdashProject.yaml` to customize:
- Project name and title
- Database connection
- Plot configurations

Restart SlowDash: `docker compose restart slowdash`

## Troubleshooting

### Can't access SlowDash

- Verify it's running: `docker compose ps`
- Check logs: `docker compose logs slowdash`
- Try http://localhost:18881 in a different browser

### Database connection errors

- Ensure Docker Compose is running: `docker compose ps`
- Check database logs: `docker compose logs db`
- Verify connection string matches `docker-compose.yaml` credentials

### No data appearing in SlowDash

- Check if data exists: `docker compose exec db psql -U myuser -d mydatabase -c "SELECT COUNT(*) FROM mytable;"`
- Verify SlowDash is reading the right table (check `SlowdashProject.yaml`)
- Look at SlowDash logs for errors: `docker compose logs slowdash`

### Hardware issues (Raspberry Pi only)

**Cannot connect to I2C device:**
- Verify ADS1115 is connected at address 0x48: `i2cdetect -y 1`
- Enable I2C if disabled: `sudo raspi-config` → Interface Options → I2C

**WiringPi errors:**
- This requires a Raspberry Pi with WiringPi library installed
- Won't work on regular computers (use test data generator instead)

## Stopping Services

```bash
# Stop data collection
Ctrl+C in the Julia terminal

# Stop Docker services
docker compose down

# Stop and remove all data; don't do this unless you know what you're doing
docker compose down -v
```

## Project Structure

```
.
├── app.jl                  # Real hardware data collection
├── Project.toml            # Julia dependencies
├── docker-compose.yaml     # Docker services (PostgreSQL + SlowDash)
├── SlowdashProject.yaml    # SlowDash configuration
├── db_data/                # PostgreSQL data directory (persists data)
└── README.md               # This file
```

## Further Learning

- **SlowDash Documentation**: https://slowproj.github.io/slowdash/
- **PostgreSQL Tutorial**: https://www.postgresql.org/docs/current/tutorial.html
- **ADS1115 Datasheet**: https://www.ti.com/lit/ds/symlink/ads1115.pdf
- **Vacuum Gauge Basics**:
    - [Inficon PCG550](docs/PCG55x-Pirani-Capacitance-Diaphragm-Gauge.pdf)
    - [Pfeiffer PKR 261](docs/PKR261-Manual.pdf)
    - [MKS AA07B](docs/AA07B-AA08B-20054398-001-MAN.pdf)
- [**Schematic**](docs/Schematic.pdf)
