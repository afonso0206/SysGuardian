#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_FILE="${PROJECT_ROOT}/modules/printers.sh"
TEMP_CONFIG_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TEMP_CONFIG_DIR"
}

trap cleanup EXIT

bash -n "$MODULE_FILE"

CONFIG_DIR="$TEMP_CONFIG_DIR"
source "$MODULE_FILE"

touch "$CONFIG_DIR/printers.conf"

collect_printers

[[ "$PRINTER_COUNT" -eq 0 ]]
[[ "$PRINTER_ONLINE_COUNT" -eq 0 ]]
[[ "$PRINTER_OFFLINE_COUNT" -eq 0 ]]

printf 'PR-006 printers module: OK\n'
