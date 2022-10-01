FROM crystallang/crystal:1-alpine AS builder

COPY . /flatorte
WORKDIR /flatorte
RUN shards build --release --no-debug
RUN chown nobody:nogroup bin/flatorte

FROM alpine:3

COPY --from=builder /flatorte/bin/flatorte /flatorte
RUN apk add --update --no-cache --force-overwrite libgcc pcre-dev

USER nobody
WORKDIR /
EXPOSE 7453
ENTRYPOINT ["/flatorte"]
