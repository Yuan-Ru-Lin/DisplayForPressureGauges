using StyledStrings
using REPL

function clear_screen()
    REPL.Terminals.clear(REPL.TerminalMenus.terminal)
end

function display_colorful_values(data::Dict)
    clear_screen()
    
    # Header
    println(styled"{bold,underline,blue:━━━━━━━━━━━━━━━━━━━━━━━━━━}")
    println(styled"{bold,magenta:     SYSTEM MONITOR}")
    println(styled"{bold,underline,blue:━━━━━━━━━━━━━━━━━━━━━━━━━━}")
    println()
    
    for (name, value) in data
        # Since we can't dynamically interpolate symbols, we need to handle each case
        if value > 80
            println(styled"{bold:$(rpad(name, 15))}: {bold,red:$(lpad(round(value, digits=1), 8))}")
            bar = repeat("▰", Int(round(value / 2)))
            empty = repeat("▱", max(50 - Int(round(value / 2)), 0))
            println(styled"  {red:$bar}{dim:$empty}")
        elseif value > 50
            println(styled"{bold:$(rpad(name, 15))}: {bold,yellow:$(lpad(round(value, digits=1), 8))}")
            bar = repeat("▰", Int(round(value / 2)))
            empty = repeat("▱", max(50 - Int(round(value / 2)), 0))
            println(styled"  {yellow:$bar}{dim:$empty}")
        else
            println(styled"{bold:$(rpad(name, 15))}: {bold,green:$(lpad(round(value, digits=1), 8))}")
            bar = repeat("▰", Int(round(value / 2)))
            empty = repeat("▱", max(50 - Int(round(value / 2)), 0))
            println(styled"  {green:$bar}{dim:$empty}")
        end
        println()
    end
end

function run_monitor()
    while true
        # Generate random values for demonstration
        data = Dict(
            "CPU Usage %" => rand() * 100,
            "Memory %" => rand() * 100,
            "Disk Usage %" => rand() * 100,
            "Temperature °C" => 30 + rand() * 40,
            "Network Mbps" => rand() * 1000
        )
        
        display_colorful_values(data)
        sleep(1)  # Update every second
    end
end

# Run it (press Ctrl+C to stop)
run_monitor()
