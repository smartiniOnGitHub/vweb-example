FROM thevlang/vlang:ubuntu-build AS builder

# update packages, to reduce risk of vulnerabilities
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get upgrade -y \
    && apt-get install --quiet -y openssl upx \
    # && apt-get install --quiet -y --no-install-recommends libssl-dev libsqlite3-dev && \
    && apt-get autoclean && apt-get autoremove

# build V
WORKDIR /opt/vlang
RUN git clone https://github.com/vlang/v /opt/vlang \ 
    && make CC=clang && v -version && v symlink

# copy and build application sources
WORKDIR /src
COPY . .
RUN make build-optimized && make dist


# use a standard ubuntu image, 
FROM ubuntu AS runtime

LABEL version="1.0.0"
LABEL description="Example vweb (V) webapp Docker Image"
LABEL maintainer="Sandro Martini <sandro.martini@gmail.com>"

# update packages, to reduce risk of vulnerabilities
RUN DEBIAN_FRONTEND=noninteractive \
    && apt-get update && apt-get upgrade -y \
    && apt-get install --quiet -y openssl \
    && apt-get autoclean && apt-get autoremove

WORKDIR /app
COPY --from=builder /src/dist/ .
# RUN ls -la /app

# describe port/s opened in the container
EXPOSE 8000

# add an healthcheck by calling the additional script/application
HEALTHCHECK --interval=60s --timeout=10s --start-period=15s CMD ["./healthcheck"]

# ENTRYPOINT [ "/app/vweb-example" ]
CMD [ "./vweb-example" ]

# end.
