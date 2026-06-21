#!/usr/bin/env bash
set -euo pipefail

# traversal_server takes no config: it binds UDP 6262 (and alt 6226) and logs to stdout.
exec traversal_server "$@"
