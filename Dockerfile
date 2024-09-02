FROM ghcr.io/gleam-lang/gleam:v1.3.2-erlang-alpine

# Add project code
COPY . /build/

# Compile the Gleam application, not using the group and user for now
RUN apk add gcc build-base \
  && cd /build \
  && gleam export erlang-shipment \
  && mv build/erlang-shipment /app \
  && rm -r /build \
  && apk del gcc build-base \
  && addgroup -S gleamx \
  && adduser -S gleamx -G gleamx \
  && chown -R gleamx /app

COPY --from=flyio/litefs:0.5 /usr/local/bin/litefs /usr/local/bin/litefs

COPY ./litefs.yml /etc/litefs.yml

RUN apk add fuse3 sqlite ca-certificates

# We should run this as root otherwise it wont have perms to do file ops
ENTRYPOINT litefs mount
