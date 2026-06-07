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

node <<'EOF'
const fs = require('fs');
const path = require('path');

const configPath = '/app/engine/data/config/world.json';
const configDir = path.dirname(configPath);

let config = {};
if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
}

config.easyStartup = process.env.EASY_STARTUP === 'true';
config.build = {
    ...config.build,
    srcDir: process.env.BUILD_SRC_DIR
};
config.db = {
    ...config.db,
    backend: process.env.DB_BACKEND
};
config.node = {
    ...config.node,
    port: Number(process.env.NODE_PORT)
};
config.web = {
    ...config.web,
    managementPort: Number(process.env.WEB_MANAGEMENT_PORT),
    port: Number(process.env.WEB_PORT)
};

fs.mkdirSync(configDir, { recursive: true });
fs.writeFileSync(configPath, JSON.stringify(config, null, 4) + '\n');
EOF

if [[ "${DB_BACKEND}" == "sqlite" && ! -s /config/db.sqlite ]]; then
    npm run sqlite:migrate
fi

exec ./node_modules/.bin/tsx src/app.ts "$@"
