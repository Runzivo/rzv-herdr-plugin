#!/usr/bin/env bash
# Herdr action: open the plugin's terminal pane running one rzv-herdr command,
# so prompts and confirmations work.
set -euo pipefail
case "${1:-}" in
  create | attach | status | list | sleep | wake | delete) ;;
  *) echo "rzv-herdr: unknown command ${1:-}" >&2; exit 2 ;;
esac
exec "${HERDR_BIN_PATH:-herdr}" plugin pane open \
  --plugin "${HERDR_PLUGIN_ID:-runzivo.sandboxes}" \
  --entrypoint console \
  --env "RZV_HERDR_CMD=$1" \
  --focus
