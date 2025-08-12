# Real-Time Pressure Gauge Display

A Julia web application for visualizing sensor data with interactive plots and database storage.

## Setup

Requires Julia 1.6+ and PostgreSQL. Install dependencies and run:

```bash
julia --project=.
julia> using Pkg; Pkg.instantiate()
julia> exit()
julia --project=. script.jl
```

Access the dashboard at http://localhost:9384

## Requirements

- Julia 1.6 or higher
- PostgreSQL database server
- Web browser

## Troubleshooting

**Database connection issues**
Set the `DATABASE_URL` environment variable with your PostgreSQL credentials:
```bash
export DATABASE_URL="postgresql://username:password@localhost:5432/database"
```
If not set, it defaults to `postgresql://myuser:mypassword@localhost:5432/mydatabase`.

**Port conflicts**
If port 9384 is in use, modify the port setting in the script or stop the conflicting service.

**Package installation problems**
Run `julia --project=. -e 'using Pkg; Pkg.update()'` to resolve dependency issues.

**Julia help**
Use `?function_name` in the Julia REPL for documentation on any function.

## Package Documentation

- [WGLMakie.jl](https://docs.makie.org/stable/explanations/backends/wglmakie/) - Interactive web plotting
- [Bonito.jl](https://bonito.bonito.dev/dev/) - Julia web application framework
- [LibPQ.jl](https://invenia.github.io/LibPQ.jl/stable/) - PostgreSQL database interface
- [DataStructures.jl](https://juliacollections.github.io/DataStructures.jl/stable/) - Provides CircularBuffer for data storage
- [DBInterface.jl](https://juliadatabases.org/DBInterface.jl/stable/) - Database abstraction layer

For Julia beginners, see the [official documentation](https://docs.julialang.org/en/v1/).

## Docker Deployment

```bash
docker build -t display-system .
docker run -p 8080:8080 display-system
```

## Notes

The application currently generates simulated data. Modify the data generation section to connect real sensors.