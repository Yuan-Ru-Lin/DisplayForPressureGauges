using WiringPi
using StyledStrings
using Dates

ads1115Setup(100, 0x48)
digitalWrite(100, ADS1115_GAIN_6)
digitalWrite(101, ADS1115_DR_64)

clear_screen() = print("\033[2J\033[H")

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

# Main display loop
function run_monitor()
    sample_count = 0
    
    try
        while true
            # Read ADC values
            val0 = analogRead(100)
            val1 = analogRead(101)
            val2 = analogRead(102)
            
            # Convert to voltages (assuming 16-bit ADC, 5V reference)
            v0 = val0 * 5.0 / 32767.0
            v1 = val1 * 5.0 / 32767.0
            v2 = val2 * 5.0 / 32767.0
            
            sample_count += 1
            
            # Clear and display
            clear_screen()
            
            # Header
            println(styled"{bold,cyan:╔════════════════════════════════╗}")
            println(styled"{bold,cyan:║      ADC MONITOR               ║}")
            println(styled"{bold,cyan:╚════════════════════════════════╝}")
            println()
            
            # Time and sample count
            time_str = Dates.format(now(), "HH:MM:SS")
            println(styled"{white:Time: $time_str   Sample: #$sample_count}")
            println()
            
            # Display each channel
            for (ch, voltage, raw) in [("CH0", v0, val0), ("CH1", v1, val1), ("CH2", v2, val2)]
                color = get_color(voltage)
                bar, percent = make_bar(voltage, 5.0)
                
                # Channel info
                println(styled"{bold,white:$ch:} {bold,$color:$(round(voltage, digits=2))V} " * 
                              styled"{dim,white:(raw: $raw)}")
                println(styled"    {$color:$bar} {dim,white:$(round(percent, digits=1))%}")
                println()
            end
            
            # Footer
            println(styled"{dim,yellow:Press Ctrl+C to stop}")
            
            # Wait before next reading
            sleep(1)
        end
    catch e
        if e isa InterruptException
            clear_screen()
            println(styled"{bold,green:✓ Stopped}")
            println(styled"{white:Total samples: $sample_count}")
        else
            rethrow(e)
        end
    end
end

# Run it
run_monitor()
