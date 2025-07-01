FROM julia:1.11.5-bookworm

WORKDIR /env
COPY . . 
ENV JULIA_CPU_TARGET=generic
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'
EXPOSE 8080
ENTRYPOINT ["julia", "--project=.", "-i", "script.jl"]
