FROM julia:1.11.6-bookworm

WORKDIR /env
COPY . . 
ENV JULIA_CPU_TARGET=generic
RUN julia --project=. -e 'using Pkg; Pkg.instantiate()'
ENTRYPOINT ["julia", "--project=."]
