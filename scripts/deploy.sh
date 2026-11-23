#!/bin/sh
set -eu

: "${APP_IMAGE:?APP_IMAGE is required}"
: "${APP_PORT:?APP_PORT is required}"
: "${CONTAINER_NAME:?CONTAINER_NAME is required}"

# Keep the previous container until the replacement passes its health check.
backup="${CONTAINER_NAME}-previous"
if docker container inspect "$backup" >/dev/null 2>&1; then
    echo "Backup container $backup already exists; inspect it before deploying." >&2
    exit 1
fi

had_previous=false
if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    docker stop "$CONTAINER_NAME"
    if ! docker rename "$CONTAINER_NAME" "$backup"; then
        docker start "$CONTAINER_NAME"
        exit 1
    fi
    had_previous=true
fi

rollback() {
    result=$?
    if [ "$result" -ne 0 ]; then
        docker logs "$CONTAINER_NAME" || true
        docker rm -f "$CONTAINER_NAME" || true
        if [ "$had_previous" = true ]; then
            docker rename "$backup" "$CONTAINER_NAME" && docker start "$CONTAINER_NAME" || true
        fi
    fi
}
trap rollback EXIT

docker run -d --name "$CONTAINER_NAME" --restart unless-stopped \
    -p "${APP_PORT}:8080" "$APP_IMAGE"

attempt=0
while [ "$attempt" -lt 30 ]; do
    health=$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_NAME")
    if [ "$health" = healthy ]; then
        echo "Deployment healthy; service published on Docker host port $APP_PORT."
        if [ "$had_previous" = true ]; then
            docker rm "$backup"
        fi
        trap - EXIT
        exit 0
    fi
    if [ "$health" = unhealthy ]; then
        break
    fi
    attempt=$((attempt + 1))
    sleep 2
done

echo 'Deployment failed its health check; restoring the previous container if present.' >&2
exit 1
