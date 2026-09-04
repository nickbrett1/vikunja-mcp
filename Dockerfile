# vikunja-mcp — MCP server for Vikunja (acidvegas/vikunja-mcp)
#
# Thin wrapper image: builds the upstream Go binary (single static binary with
# stdio + Streamable HTTP transports — ideal for Open WebUI) and serves it.
#
# Published by CircleCI to ghcr.io/nickbrett1/vikunja-mcp. To rebuild against
# the latest upstream, just re-run the `publish` workflow in CircleCI: each run
# uses a clean builder (no layer cache), so `go install ...@latest` always
# fetches the newest upstream code. Pin a specific version with:
#   docker build --build-arg VERSION=<git-ref-or-tag> .

FROM golang:1.25-alpine AS builder
ARG VERSION=latest
RUN apk add --no-cache ca-certificates \
 && go install github.com/acidvegas/vikunja-mcp@${VERSION}

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata \
 && addgroup -g 1000 mcp \
 && adduser -D -u 1000 -G mcp mcp
# Link the GHCR package to this repo so it inherits public visibility.
LABEL org.opencontainers.image.source=https://github.com/nickbrett1/vikunja-mcp
COPY --from=builder /go/bin/vikunja-mcp /usr/local/bin/vikunja-mcp
USER mcp
EXPOSE 8000
ENTRYPOINT ["/usr/local/bin/vikunja-mcp"]
