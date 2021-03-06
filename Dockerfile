FROM thevlang/vlang:alpine-dev AS builder

# update packages, to reduce risk of vulnerabilities
RUN apk update && apk upgrade
RUN apk --no-cache add upx
# RUN apk cache clean

# copy and build application sources
WORKDIR /src
COPY . .
RUN make build-optimized && make dist


# use standard alpine image 
FROM alpine AS runtime

LABEL version="1.0.0"
LABEL description="Example vweb (V) webapp Docker Image"
LABEL maintainer="Sandro Martini <sandro.martini@gmail.com>"

# update packages, to reduce risk of vulnerabilities
RUN apk update && apk upgrade \
    && apk add --no-cache openssl

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
