#!/usr/bin/env bash
set -euo pipefail

mkdir -p /config/players

PACK_SOURCE_DIR="${PACK_SOURCE_DIR:-/usr/share/lostcity/bootstrap-pack}"
PACK_TARGET_DIR=/app/content/pack
PACK_HASH="$(cat "${PACK_SOURCE_DIR}/.lostcity-pack-hash")"

if [[ ! -f "${PACK_TARGET_DIR}/.lostcity-pack-hash" ]] || [[ "$(cat "${PACK_TARGET_DIR}/.lostcity-pack-hash")" != "${PACK_HASH}" ]]; then
    find "${PACK_TARGET_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -R "${PACK_SOURCE_DIR}/." "${PACK_TARGET_DIR}/"
    printf '%s\n' "${PACK_HASH}" > "${PACK_TARGET_DIR}/.lostcity-pack-hash"
fi

export BUILD_SRC_DIR="${BUILD_SRC_DIR:-/app/content}"
export DB_BACKEND="${DB_BACKEND:-sqlite}"
export EASY_STARTUP="${EASY_STARTUP:-true}"
export NODE_PORT="${NODE_PORT:-43594}"
export WEB_MANAGEMENT_PORT="${WEB_MANAGEMENT_PORT:-8898}"
export WEB_PORT="${WEB_PORT:-8888}"

if [[ "${DB_BACKEND}" == "sqlite" && ! -s /config/db.sqlite ]]; then
    bun run sqlite:migrate
fi

exec bun run src/app.ts "$@"
