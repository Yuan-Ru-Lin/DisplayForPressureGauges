# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Julia-based real-time pressure gauge display system that creates a web interface for visualizing sensor data. The application uses WGLMakie for plotting, Bonito for web components, and PostgreSQL for data persistence.

## Development Commands

### Environment Setup
- `julia --project=.` - Start Julia with the project environment
- `julia --project=. -e 'using Pkg; Pkg.instantiate()'` - Install dependencies

### Running the Application
- `julia --project=. script.jl` - Start the web server (serves on port 9384)
- `julia --project=. -i script.jl` - Start with interactive mode

### Docker
- `docker build -t display-system .` - Build Docker image
- `docker run -p 8080:8080 display-system` - Run containerized version

## Architecture

### Core Components

**Main Application (`script.jl`)**:
- Creates a web-based dashboard with real-time data visualization
- Uses CircularBuffer for efficient data storage (100-point sliding window)
- Implements threaded data generation and database insertion
- Serves on `0.0.0.0:9384` by default

**Display System Module (`src/DisplaySystem.jl`)**:
- Currently a minimal module structure
- Imports required dependencies but implementation is in main script

### Key Dependencies
- **WGLMakie**: Web-based plotting and visualization
- **Bonito**: Web application framework for Julia
- **LibPQ**: PostgreSQL database interface
- **DataStructures**: Provides CircularBuffer for efficient data storage

### Database Integration
- PostgreSQL connection with hardcoded credentials (needs refactoring)
- Creates `mytable` with columns: channel (TEXT), timestamp (BIGINT), value (REAL)
- Real-time data insertion for three channels (ch0, ch1, ch2)

### Data Flow
1. Background thread generates random Int16 values for 3 channels
2. Values are inserted into PostgreSQL database
3. Values are pushed to observable CircularBuffers
4. UI automatically updates with new data (trend plots and histograms)
5. Start/Stop functionality via web button interface

## Development Notes

- The database connection string is hardcoded and marked for refactoring (line 20 in script.jl)
- Application generates fake data (random Int16 values) - ready for real sensor integration
- No formal test suite currently exists
- The `notes/` directory contains extensive research materials but is not part of the main application