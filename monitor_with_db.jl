# monitor_with_db.jl
using WiringPi
using StyledStrings
using Dates
using LibPQ, DBInterface

# Initialize ADC
ads1115Setup(100, 0x48)
digitalWrite(100, ADS1115_GAIN_6)
digitalWrite(101, ADS1115_DR_64)

# Global flag for database writing
db_writing = Ref(false)

# Clear screen
function clear_screen()
    print("\033[2J\033[H")
end

# Make a simple bar
function make_bar(value::Float64, max_val::Float64)
    percent = (value / max_val) * 100
    bar_length = Int(round(percent / 2))  # 50 char max width
    bar = repeat("█", bar_length) * repeat("░", 50 - bar_length)
    return bar, percent
end

# Get color based on voltage
function get_color(voltage::Float64)
    if voltage < 1.5
        return :green
    elseif voltage < 3.5
        return :yellow
    else
        return :red
    end
end

# Setup database
function setup_database()
    conn_string = get(ENV, "DATABASE_URL", "postgresql://myuser:mypassword@localhost:5432/mydatabase")
    try
        conn = DBInterface.connect(LibPQ.Connection, conn_string)
        
        # Create table if not exists
        DBInterface.execute(conn, """
            CREATE TABLE IF NOT EXISTS adc_readings (
                id SERIAL PRIMARY KEY,
                channel TEXT,
                timestamp TIMESTAMP DEFAULT NOW(),
                value REAL,
                voltage REAL
            )
        """)
        
        # Prepare insert statement
        stmt = DBInterface.prepare(conn, 
            "INSERT INTO adc_readings (channel, value, voltage) VALUES (\$1, \$2, \$3)")
        
        return conn, stmt
    catch e
        println(styled"{bold,red:Database connection failed: $e}")
        return nothing, nothing
    end
end

# Check for keyboard input (non-blocking)
function check_keyboard()
    # Set terminal to non-blocking mode
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, 1)
    
    if bytesavailable(stdin) > 0
        key = read(stdin, Char)
        # Reset terminal mode
        ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, 0)
        return key
    end
    
    # Reset terminal mode
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, 0)
    return nothing
end

# Main monitoring function
function run_monitor()
    # Setup database
    conn, stmt = setup_database()
    db_available = (conn !== nothing && stmt !== nothing)
    
    sample_count = 0
    db_write_count = 0
    
    # Spawn keyboard listener
    @async begin
        while true
            key = check_keyboard()
            if key == 's' || key == 'S'
                if db_available
                    db_writing[] = !db_writing[]
                end
            end
            sleep(0.1)  # Check every 100ms
        end
    end
    
    try
        while true
            # Read ADC values
            val0 = analogRead(100)
            val1 = analogRead(101)
            val2 = analogRead(102)
            
            # Convert to voltages
            v0 = val0 * 5.0 / 32767.0
            v1 = val1 * 5.0 / 32767.0
            v2 = val2 * 5.0 / 32767.0
            
            sample_count += 1
            
            # Write to database if enabled
            if db_writing[] && db_available
                try
                    DBInterface.execute(stmt, ("ch0", val0, v0))
                    DBInterface.execute(stmt, ("ch1", val1, v1))
                    DBInterface.execute(stmt, ("ch2", val2, v2))
                    db_write_count += 3
                catch e
                    println(styled"{bold,red:DB write error: $e}")
                end
            end
            
            # Clear and display
            clear_screen()
            
            # Header
            println(styled"{bold,cyan:╔════════════════════════════════╗}")
            println(styled"{bold,cyan:║      ADC MONITOR               ║}")
            println(styled"{bold,cyan:╚════════════════════════════════╝}")
            println()
            
            # Status line
            time_str = Dates.format(now(), "HH:MM:SS")
            db_status = if !db_available
                styled"{dim,red:DB: Not Connected}"
            elseif db_writing[]
                styled"{bold,green:DB: Writing ✓}"
            else
                styled"{yellow:DB: Paused}"
            end
            
            println(styled"{white:Time: $time_str   Sample: #$sample_count}")
            println(db_status)
            
            if db_writing[] && db_available
                println(styled"{dim,white:Records written: $db_write_count}")
            end
            println()
            
            # Display each channel
            for (ch, voltage, raw) in [("CH0", v0, val0), ("CH1", v1, val1), ("CH2", v2, val2)]
                color = get_color(voltage)
                bar, percent = make_bar(voltage, 5.0)
                
                println(styled"{bold,white:$ch:} {bold,$color:$(round(voltage, digits=2))V} " * 
                              styled"{dim,white:(raw: $raw)}")
                println(styled"    {$color:$bar} {dim,white:$(round(percent, digits=1))%}")
                println()
            end
            
            # Footer instructions
            println(styled"{dim,cyan:━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━}")
            if db_available
                action = db_writing[] ? "pause" : "start"
                println(styled"{dim,white:Press 's' to $action database writing}")
            else
                println(styled"{dim,red:Database not available}")
            end
            println(styled"{dim,white:Press Ctrl+C to stop}")
            
            # Wait before next reading
            sleep(1)
        end
    catch e
        if e isa InterruptException
            clear_screen()
            println(styled"{bold,green:✓ Stopped}")
            println(styled"{white:Total samples: $sample_count}")
            if db_available
                println(styled"{white:Total DB records: $db_write_count}")
            end
        else
            rethrow(e)
        end
    finally
        # Cleanup database connection
        if conn !== nothing
            DBInterface.close!(conn)
        end
    end
end

# Run it
run_monitor()
