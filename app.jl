using Bonito
using WGLMakie
using DataStructures
using LibPQ, DBInterface
using WiringPi

## Initilizaition

# Setup ADS1115
ads1115Setup(100, 0x48)
digitalWrite(100, ADS1115_GAIN_6)
digitalWrite(101, ADS1115_DR_64)

# Initialize buffers with some initial data
initial_buf1 = CircularBuffer{Int16}(100)
initial_buf2 = CircularBuffer{Int16}(100)
initial_buf3 = CircularBuffer{Int16}(100)

for i in 1:10
    push!(initial_buf1, rand(Int16))
    push!(initial_buf2, rand(Int16))
    push!(initial_buf3, rand(Int16))
end

conn_string = get(ENV, "DATABASE_URL", "postgresql://myuser:mypassword@localhost:5432/mydatabase")
conn = DBInterface.connect(LibPQ.Connection, conn_string)
DBInterface.execute(conn, "CREATE TABLE IF NOT EXISTS mytable (channel TEXT, timestamp BIGINT DEFAULT FLOOR(EXTRACT(EPOCH FROM now())), value REAL)")
stmt = DBInterface.prepare(conn, "INSERT INTO mytable (channel, value) VALUES (\$1, \$2)")

buf1 = Observable(initial_buf1)
buf2 = Observable(initial_buf2)
buf3 = Observable(initial_buf3)

is_running = Observable(false)

fig = Figure();
ax1 = Axis(fig[1,1],
    xgridvisible=false,
    ygridvisible=false,
    leftspinevisible=false,
    rightspinevisible=false,
    bottomspinevisible=false,
    topspinevisible=false,
    xticksvisible=false,
    yticksvisible=false,
    xticklabelsvisible=false,
    yticklabelsvisible=false,
)
text!(ax1, 0.5, 0.5, space=:relative, align=(:center, :center),
    text=rich("Will display values here later", font=:bold, fontsize=30)
)
ax2 = Axis(fig[2,1], title="Trend of Lastest 100 points")
lines!(ax2, buf1)
lines!(ax2, buf2)
lines!(ax2, buf3)
ax3 = Axis(fig[3,1], title="Histogram of Lastest 100 points")
stephist!.(ax3, [buf1, buf2, buf3], bins=(typemin(Int16):1000:typemax(Int16)))

t = Threads.@spawn try while true
        if is_running[]

            val1 = analogRead(100)
            val2 = analogRead(101)
            val3 = analogRead(102)

            DBInterface.execute(stmt, ("ch0", val1))
            DBInterface.execute(stmt, ("ch1", val2))
            DBInterface.execute(stmt, ("ch2", val3))

            push!(buf1.val, val1)
            push!(buf2.val, val2)
            push!(buf3.val, val3)
            notify(buf1)
            notify(buf2)
            notify(buf3)
            Makie.reset_limits!.([ax1, ax2, ax3])

        end
        sleep(1)
    end
catch e
    e isa InterruptionException ? (@info "Stopped" exception = e) : rethrow(e)
end

toggle_button = Button("Start Display")

on(toggle_button.value) do _
    is_running[] = !is_running[]
    toggle_button.content[] = is_running[] ? "Stop Display" : "Start Display"
end

app = App(
    DOM.div(
        DOM.h1("Values from Pressure Gauges (fake for now)"),
        DOM.p("Styles can be adjusted later :)"),
        toggle_button,
        fig
    )
)
s = Server(app, "0.0.0.0", 9384)
