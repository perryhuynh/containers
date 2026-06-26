#!/bin/sh
set -eu

exec caddy run --adapter caddyfile --config /etc/caddy/Caddyfile "$@"
