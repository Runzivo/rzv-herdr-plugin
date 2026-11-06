#!/usr/bin/env bash
# Herdr pane: run one rzv-herdr command, then wait so you can read the result.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
"$here/rzv-herdr" "${RZV_HERDR_CMD:-help}"
status=$?
[ "$status" -eq 0 ] || printf '\nrzv-herdr exited with status %s.\n' "$status"
read -r -p "Press Enter to close. " _ || true
exit "$status"
