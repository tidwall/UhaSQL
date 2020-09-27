# build stage
# Build using Ubuntu/Musl/Go
FROM ubuntu:groovy AS build

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y build-essential wget git \
    && wget -q https://golang.org/dl/go1.15.2.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.15.2.linux-amd64.tar.gz \
    && ln -s /usr/local/go/bin/go /usr/local/bin/go \
    && mkdir -p /repo/sqlite

ADD cmd/ /repo/cmd/
ADD sqlite/sqlite.c /repo/sqlite/sqlite.c
ADD sqlite/sqlite.h /repo/sqlite/sqlite.h
ADD go.mod /repo/go.mod
ADD go.sum /repo/go.sum
ADD Makefile /repo/Makefile
ADD scripts/env.sh /repo/scripts/env.sh
ADD scripts/build.sh /repo/scripts/build.sh

ARG GITVERS
ARG GITSHA

RUN apt-get install -y musl-tools

RUN cd /repo && GITVERS=$GITVERS GITSHA=$GITSHA CC=musl-gcc make

# run stage
# Run using Alpine
FROM alpine:3.12.0 AS run

RUN apk add --no-cache ca-certificates 

COPY --from=build /repo/uhasql-server /usr/local/bin/uhasql-server
COPY --from=build /repo/uhasql-cli /usr/local/bin/uhasql-cli

RUN chmod +x /usr/local/bin/uhasql-server && \
    chmod +x /usr/local/bin/uhasql-cli

RUN addgroup -S uhasql && \
    adduser -S -G uhasql uhasql && \
    mkdir /data && chown uhasql:uhasql /data

VOLUME /data

EXPOSE 11001
CMD ["uhasql-server", "-d", "/data", "-a", "0.0.0.0:11001"]
