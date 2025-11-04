# Pressure Gauge Monitoring System

A Julia application for monitoring multiple vacuum pressure gauges, storing time-series data in PostgreSQL, and visualizing it via SlowDash.

## Hardware Requirements

- **Raspberry Pi** with WiringPi support
- **ADS1115 ADC** (I2C address 0x48)
- **Three pressure gauges:**
  - Inficon PCG550 (0-10V output)
  - Pfeiffer PKR 261 (0-10V output)
  - MKS AA07B (0-5V output, 250 psia range)

## Software Requirements

- Julia 1.6 or higher
- Docker Compose
- PostgreSQL (provided via Docker Compose)

## Setup

### 1. Install Julia Dependencies

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### 2. Start the Database and Dashboard

```bash
docker compose up -d
```

This starts:
- PostgreSQL on port 5432
- SlowDash visualization on http://localhost:18881

### 3. Run Data Collection

```bash
julia --project=. app.jl
```

The application reads from the three pressure gauges every second and stores readings in the database.

## Architecture

**Data Collection (`app.jl`)**
- Configures ADS1115 ADC with appropriate gain and data rate
- Reads analog values from three channels
- Converts voltages to pressure readings using gauge-specific formulas:
  - PCG550: `5e-5 * 10^((V - 0.61)/1.286)` mbar
  - PKR 261: `10^(1.667V - 11.3333)` mbar
  - AA07B: `V / 5 * 250` psia
- Inserts timestamped readings into PostgreSQL

**Database Schema**
- Table: `mytable`
- Columns: `channel` (TEXT), `timestamp` (BIGINT, unix epoch), `value` (REAL)

**Visualization**
- SlowDash reads from PostgreSQL and provides web-based plotting
- Configuration in `SlowdashProject.yaml`
- Access dashboard at http://localhost:18881

## Configuration

Set the database connection via environment variable:

```bash
export DATABASE_URL="postgresql://myuser:mypassword@localhost:5432/mydatabase"
```

Default credentials are in `docker-compose.yaml`.

## Troubleshooting

**Cannot connect to I2C device**
- Verify ADS1115 is connected at address 0x48
- Check I2C is enabled: `sudo raspi-config`

**Database connection refused**
- Ensure Docker Compose is running: `docker compose ps`
- Check database logs: `docker compose logs db`

**WiringPi errors**
- This requires a Raspberry Pi with WiringPi library installed
- Won't work on non-Pi systems

## Stopping Services

```bash
# Stop data collection
Ctrl+C in the Julia terminal

# Stop Docker services
docker compose down
```

## Notes

- The MKS AA07B reading is divided by 2 (see app.jl:22) for calibration reasons
- Data persists in `./db_data/` directory
- Debug logging available with `julia --project=. app.jl` (see `@debug` statements in code)
