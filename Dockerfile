FROM julia:1.12.1-bookworm

WORKDIR /app
COPY Project.toml Manifest.toml .
ENV JULIA_CPU_TARGET=generic
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'
ENTRYPOINT ["julia", "--project=.", "app.jl"]
