using DataStructures
using LibPQ, DBInterface
using WiringPi

## Initilizaition

# Setup ADS1115
ads1115Setup(100, 0x48)
digitalWrite(100, ADS1115_GAIN_6)
digitalWrite(101, ADS1115_DR_64)

conn_string = get(ENV, "DATABASE_URL", "postgresql://myuser:mypassword@localhost:5432/mydatabase")
conn = DBInterface.connect(LibPQ.Connection, conn_string)
DBInterface.execute(conn, "CREATE TABLE IF NOT EXISTS mytable (channel TEXT, timestamp BIGINT DEFAULT FLOOR(EXTRACT(EPOCH FROM now())), value REAL)")
stmt = DBInterface.prepare(conn, "INSERT INTO mytable (channel, value) VALUES (\$1, \$2)")

t = Threads.@spawn try
    while true
        if is_running[]

            val1 = analogRead(100)
            val2 = analogRead(101)
            val3 = analogRead(102)

            DBInterface.execute(stmt, ("ch0", val1))
            DBInterface.execute(stmt, ("ch1", val2))
            DBInterface.execute(stmt, ("ch2", val3))

            @info "Inserted values: ch0 = $val1, ch1 = $val2, ch3 = $val3"
        end
        sleep(1)
    end
catch e
    e isa InterruptionException ? (@info "Stopped" exception = e) : rethrow(e)
end
