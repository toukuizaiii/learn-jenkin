FROM golang:1.26 AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -o /out/server .

FROM alpine:3.23
WORKDIR /app
COPY --from=builder /out/server /app/server
ENV PORT=8080
EXPOSE 8080
USER 65532:65532
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null "http://127.0.0.1:${PORT}/" || exit 1
ENTRYPOINT ["/app/server"]
