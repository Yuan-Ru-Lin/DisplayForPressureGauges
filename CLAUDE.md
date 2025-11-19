# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Julia-based real-time pressure gauge monitoring system that reads sensor data from I2C devices, stores it in PostgreSQL, and visualizes it through SlowDash. The application runs as a containerized service in a Docker Compose stack.

## Development Commands

### Environment Setup
- `julia --project=.` - Start Julia with the project environment
- `julia --project=. -e 'using Pkg; Pkg.instantiate()'` - Install dependencies

### Running the Application

**Production (Docker Compose)**:
- `docker compose up -d` - Start all services (PostgreSQL, SlowDash, Julia app)
- `docker compose down` - Stop all services
- `docker compose logs juliaapp` - View Julia application logs
- `docker compose logs -f juliaapp` - Follow Julia application logs in real-time

**Development (Local)**:
- `julia --project=. app.jl` - Run the data collection script locally
- Requires PostgreSQL to be running and DATABASE_URL environment variable set

## Architecture

### System Services (Docker Compose)

The system consists of three containerized services:

1. **PostgreSQL (`db`)**:
   - Stores time-series pressure gauge data
   - Port 5432 (accessible from other containers)
   - Persistent storage via Docker volume `db_data`

2. **SlowDash (`slowdash`)**:
   - Web-based visualization dashboard
   - Port 18881 (http://localhost:18881)
   - Connects to PostgreSQL for data retrieval
   - Configuration: `SlowdashProject.yaml`

3. **Julia Application (`juliaapp`)**:
   - Reads pressure values from I2C devices (ADS1115 ADC)
   - Inserts data into PostgreSQL
   - Runs continuously with 1-second sampling interval
   - Image: `yuanruleonlin/ar-pressure-gauges-display:0.3`

### Core Components

**Main Application (`app.jl`)**:
- Reads analog values from three channels (100, 101, 102) via WiringPi
- Converts ADC readings to voltage (6.144V reference, 3x gain)
- Inserts timestamped readings into PostgreSQL `mytable`
- Runs as main process (synchronous loop, not threaded)

### Key Dependencies
- **LibPQ**: PostgreSQL database interface
- **WiringPi**: Raspberry Pi I2C/GPIO interface for sensor reading
- **DBInterface**: Generic database interface

### Database Schema
- **Table**: `mytable`
- **Columns**:
  - `channel` (TEXT): Channel identifier (ch0, ch1, ch2)
  - `timestamp` (BIGINT): Unix timestamp (auto-generated)
  - `value` (REAL): Pressure reading in appropriate units

### Data Flow
1. Julia app reads analog values from I2C ADC (WiringPi.analogRead)
2. Values are converted from ADC counts to voltage
3. Timestamped values inserted into PostgreSQL for each channel
4. SlowDash queries PostgreSQL and displays time-series plots
5. Process repeats every 1 second

### Hardware Integration
- **ADC**: ADS1115 (16-bit, I2C interface at `/dev/i2c-1`)
- **Channels**: Three pressure gauges on channels 100, 101, 102
- **Conversion**: `voltage = (adc_value / 32768) * 6.144 * 3`

## Development Notes

- Database credentials configured via `DATABASE_URL` environment variable
- Currently runs on Raspberry Pi hardware (requires I2C device access)
- The `notes/` directory contains extensive research materials but is not part of the main application
- Julia version: 1.12.1