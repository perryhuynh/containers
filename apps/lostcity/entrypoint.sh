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

if [[ "${DB_BACKEND}" == "sqlite" && ! -s /config/db.sqlite ]]; then
    npm run sqlite:migrate
fi

exec ./node_modules/.bin/tsx src/app.ts "$@"
