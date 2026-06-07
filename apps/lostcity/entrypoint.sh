#!/usr/bin/env bash
set -euo pipefail

mkdir -p /config/players

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
