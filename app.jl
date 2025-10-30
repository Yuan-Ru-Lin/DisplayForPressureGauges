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
        # MKS AA07B (0--5V output)
        val1 = analogRead(100) / 32768 * 6.144 * 6
        # Pfeiffer PKR 261 (0--10V output)
        val2 = analogRead(101) / 32768 * 6.144 * 3
        # Inficon PCG550 (0--10V output)
        val3 = analogRead(102) / 32768 * 6.144 * 3

        pressure1_psia = val1 / 5 * 250                     # MKS AA07B
        pressure2_mbar = exp10(1.667 * val2 - 5.3333)       # Pfeiffer PKR 261
        pressure3_mbar = 5e-5 * exp10((val3 - 0.61)/1.286)  # Inficon PCG550

        DBInterface.execute(stmt, ("ch0", pressure1_psia))
        DBInterface.execute(stmt, ("ch1", pressure2_mbar))
        DBInterface.execute(stmt, ("ch2", pressure3_mbar))

        @debug "ch0 = $val1, ch1 = $val2, ch3 = $val3"
        sleep(1)
    end
catch e
    e isa InterruptException ? (@info "Cancelled by the user" exception = e) : rethrow(e)
end
