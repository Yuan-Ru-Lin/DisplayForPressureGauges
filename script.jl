using Bonito
using WGLMakie
using DataStructures

buf1 = Observable(CircularBuffer{Int16}(100))
buf2 = Observable(CircularBuffer{Int16}(100))
buf3 = Observable(CircularBuffer{Int16}(100))

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
        push!(buf1.val, rand(Int16))
        push!(buf2.val, rand(Int16))
        push!(buf3.val, rand(Int16))
        notify(buf1)
        notify(buf2)
        notify(buf3)
        Makie.reset_limits!.([ax1, ax2, ax3])
        sleep(1)
    end
catch e
    e isa InterruptionException ? (@info "Stopped" exception = e) : rethrow(e)
end

app = App(
    DOM.div(
        DOM.h1("Values from Pressure Gauges (fake for now)"),
        DOM.p("Styles can be adjusted later :)"),
        fig
    )
)
s = Server(app, "0.0.0.0", 9384)
