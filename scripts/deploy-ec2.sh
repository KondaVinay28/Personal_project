#!/usr/bin/env bash
set -eu

IMAGE_TAG="${1:?Image tag is required}"
RELEASE_DIR="${2:?Release directory is required}"
IMAGE="personal-project:${IMAGE_TAG}"
CONTAINER="personal-project-app"
PREVIOUS_CONTAINER="personal-project-app-previous"

docker load --input "${RELEASE_DIR}/image.tar"

if docker inspect "${PREVIOUS_CONTAINER}" >/dev/null 2>&1; then
    docker rm -f "${PREVIOUS_CONTAINER}"
fi

if docker inspect "${CONTAINER}" >/dev/null 2>&1; then
    docker stop "${CONTAINER}"
    docker rename "${CONTAINER}" "${PREVIOUS_CONTAINER}"
fi

restore_previous() {
    if docker inspect "${CONTAINER}" >/dev/null 2>&1; then
        docker rm -f "${CONTAINER}"
    fi

    if docker inspect "${PREVIOUS_CONTAINER}" >/dev/null 2>&1; then
        docker rename "${PREVIOUS_CONTAINER}" "${CONTAINER}"
        docker start "${CONTAINER}"
    fi
}

if ! docker run --detach \
    --name "${CONTAINER}" \
    --restart unless-stopped \
    --publish 80:8000 \
    --env "APP_VERSION=${IMAGE_TAG}" \
    "${IMAGE}"; then
    restore_previous
    exit 1
fi

healthy=false
for attempt in $(seq 1 15); do
    if docker exec "${CONTAINER}" python -c \
        "from urllib.request import urlopen; urlopen('http://127.0.0.1:8000/health', timeout=2)"; then
        healthy=true
        break
    fi
    sleep 2
done

if [ "${healthy}" != true ]; then
    docker logs "${CONTAINER}"
    restore_previous
    exit 1
fi

if docker inspect "${PREVIOUS_CONTAINER}" >/dev/null 2>&1; then
    docker rm -f "${PREVIOUS_CONTAINER}"
fi
