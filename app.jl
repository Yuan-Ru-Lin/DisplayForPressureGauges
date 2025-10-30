using WiringPi
using LibPQ, DBInterface

ads1115Setup(100, 0x48)
digitalWrite(100, ADS1115_GAIN_6)
digitalWrite(101, ADS1115_DR_64)

conn_string = get(ENV, "DATABASE_URL", "postgresql://myuser:mypassword@localhost:5432/mydatabase")
conn = DBInterface.connect(LibPQ.Connection, conn_string)
DBInterface.execute(conn, "CREATE TABLE IF NOT EXISTS mytable (channel TEXT, timestamp BIGINT DEFAULT FLOOR(EXTRACT(EPOCH FROM now())), value REAL)")
stmt = DBInterface.prepare(conn, "INSERT INTO mytable (channel, value) VALUES (\$1, \$2)")

t = Threads.@spawn try
    while true
        ch0 = analogRead(100) / 32768 * 6.144 * 3
        ch1 = analogRead(101) / 32768 * 6.144 * 3
        ch2 = analogRead(102) / 32768 * 6.144 * 6

        pressure_pcg550_mbar = 5e-5 * exp10((ch0 - 0.61)/1.286)  # Inficon PCG550 (0--10V output)
        pressure_pkg261_mbar = exp10(1.667 * ch1 - 5.3333)       # Pfeiffer PKR 261 (0--10V output)
        pressure_aa07b_psia  = ch2 / 5 * 250                     # MKS AA07B (0--5V output)

        DBInterface.execute(stmt, ("ch0", pressure_pcg550_mbar))
        DBInterface.execute(stmt, ("ch1", pressure_pkg261_mbar))
        DBInterface.execute(stmt, ("ch2", pressure_aa07b_psia))

        @debug "ch0 = $val1, ch1 = $val2, ch3 = $val3"
        sleep(1)
    end
catch e
    e isa InterruptException ? (@info "Cancelled by the user" exception = e) : rethrow(e)
end
