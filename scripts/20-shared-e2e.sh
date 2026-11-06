#!/usr/bin/env bash
# Live test of the plugin through Herdr itself, on the Runzivo shared test
# environment. It installs the plugin from GitHub into a pinned Herdr 0.9.5
# with its own config, then drives the plugin's actions and panes:
# create, a pane in the sandbox, status, sleep, wake, a pane after wake,
# a refused delete and a confirmed delete.
#
#   RZV_PROFILE=<shared profile> E2E_WORK=<dir> [E2E_REF=<git ref>] scripts/20-shared-e2e.sh
#
# E2E_WORK holds the local Herdr and the evidence; keep its path short, since
# Herdr's socket path must fit in a Unix socket address. The sandbox is
# deleted on exit, also after a failure. No credential is written anywhere.
set -euo pipefail

herdr_version=0.9.5
sha_macos_aarch64=fb77c2232a05a8035421382c894392f4174e4e38a18e48af3dd0290157c3a7e2
sha_macos_x86_64=5fb0a908ec7f6745e3e245738b06bfad56c46391c391ab3c0955fbead01f1369
sha_linux_x86_64=14d9e8bc8b4a9e0118d77c32266f76d461f09b40342eb23752960bd89f59929d
sha_linux_aarch64=17d7536f2da50859523680ef279dffcac8e4a235f4e46fe8da6c2ec44141897c
ref="${E2E_REF:-main}"
work="${E2E_WORK:?set E2E_WORK to a short, empty directory}"
lock="${E2E_LOCK:-$HOME/runzivo/tmp/shared-sandbox.lock}"
rzv="${RZV_BIN:-$(command -v rzv)}"
plugin=runzivo.sandboxes
slug="e2e$(date +%H%M%S)"
name="herdr-$slug"
sandbox="" locked=""
mkdir -p "$work/c" "$work/s"
export XDG_CONFIG_HOME="$work/c" XDG_STATE_HOME="$work/s"
H="$work/herdr"
log() { printf '%s %s\n' "$(date -u +%H:%M:%S)" "$*" | tee -a "$work/log.txt" >&2; }
fail() { log "FAIL: $*"; exit 1; }
sha256() { if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }

cleanup() {
  local status=$?
  if [ -z "$sandbox" ]; then
    sandbox=$("$rzv" sandboxes list --json 2>/dev/null | grep -o "{\"id\":\"sbx_[a-z0-9]*\",\"name\":\"$name\"" | cut -d'"' -f4 | head -1 || true)
  fi
  if [ -n "$sandbox" ] && ! "$rzv" sandboxes get "$sandbox" --json 2>/dev/null | grep -qE '"status":"(deleting|deleted)"'; then
    log "cleanup: deleting $sandbox"
    "$rzv" sandboxes delete "$sandbox" --json >/dev/null || { log "could not delete $sandbox: rzv sandboxes delete $sandbox"; status=1; }
    rm -f "$HOME/.ssh/rzv/$sandbox.conf"
  fi
  [ ! -x "$H" ] || "$H" server stop >/dev/null 2>&1 || true
  [ -z "$locked" ] || rmdir "$lock"
  if [ "$status" -eq 0 ]; then log PASS; else log "exit $status"; fi
}
trap cleanup EXIT

"$rzv" whoami | grep -q '^Environment: shared ' || fail "the rzv profile is not signed in to shared"
until mkdir "$lock" 2>/dev/null; do log "waiting for $lock"; sleep 20; done
locked=1

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) asset=macos-aarch64 sum=$sha_macos_aarch64 ;;
  Darwin-x86_64) asset=macos-x86_64 sum=$sha_macos_x86_64 ;;
  Linux-x86_64) asset=linux-x86_64 sum=$sha_linux_x86_64 ;;
  Linux-aarch64) asset=linux-aarch64 sum=$sha_linux_aarch64 ;;
  *) fail "no Herdr build for $(uname -sm)" ;;
esac
curl -fsSL -o "$H" "https://github.com/herdrdev/herdr/releases/download/v$herdr_version/herdr-$asset"
[ "$(sha256 "$H")" = "$sum" ] || fail "Herdr checksum mismatch"
chmod +x "$H"
log "herdr: $("$H" --version); rzv: $("$rzv" --version | cut -d' ' -f1-2)"

log "1. install the plugin from GitHub ($ref)"
"$H" plugin install "Runzivo/rzv-herdr-plugin" --ref "$ref" --yes > "$work/install.txt" 2>&1 || fail "plugin install failed (see install.txt)"
"$H" plugin action list --plugin "$plugin" > "$work/actions.txt" 2>&1 || true
("$H" server </dev/null >"$work/server.log" 2>&1 &)
sleep 3
"$H" workspace create --cwd "$work" --label e2e --no-focus >/dev/null

# Run one plugin action; its pane id goes to $pane.
act() {
  "$H" plugin action invoke "$plugin.$1" > "$work/invoke-$1.json" || fail "invoke $1"
  sleep 3
  pane=$("$H" pane list | grep -o '"label":"Runzivo","pane_id":"[^"]*"' | tail -1 | cut -d'"' -f8)
  [ -n "$pane" ] || fail "no plugin pane for $1"
}
wait_for() { "$H" pane wait-output "$pane" --match "$1" --timeout "$2" >/dev/null || { "$H" pane read "$pane" --source recent --lines 30 >&2 || true; fail "pane did not show: $1"; }; }
answer() { "$H" pane send-text "$pane" "$1"; "$H" pane send-keys "$pane" enter; }
finish() { # finish <step>: save the pane's text, check it succeeded, close it
  wait_for 'Press Enter to close' "$2"
  "$H" pane read "$pane" --source recent --lines 40 > "$work/pane-$1.txt"
  answer ""
  if [ "${3:-ok}" = ok ] && grep -q 'exited with status' "$work/pane-$1.txt"; then fail "$1 failed (see pane-$1.txt)"; fi
}

log "2. create through the plugin pane"
act create
wait_for 'Name (herdr- is added)' 30000; answer "$slug"
wait_for 'Size' 10000; answer ""
wait_for 'Lifetime' 10000; answer ""
wait_for 'Install the' 900000; answer y
finish create 600000
sandbox=$(grep -o 'sbx_[a-z0-9]*' "$work/pane-create.txt" | head -1)
[ -n "$sandbox" ] || fail "no sandbox id in the create pane"
grep -q "^Ready: $name" "$work/pane-create.txt" || fail "create did not finish"
"$H" machine status "$name" --json | grep -q '"status": "reachable"' || fail "machine not reachable"

rpane() { # rpane <marker>: run a pane in the sandbox through the saved machine
  local p
  p=$("$H" --machine "$name" workspace create --cwd /workspace --label "$1" --no-focus | grep -o '"pane_id":"[^"]*"' | head -1 | cut -d'"' -f4)
  "$H" --machine "$name" pane run "$p" "uname -n; ls /workspace; echo $1""_OK"
  "$H" --machine "$name" pane wait-output "$p" --match "$1_OK" --timeout 30000 >/dev/null || fail "remote pane $1"
  "$H" --machine "$name" pane read "$p" --source recent --lines 10 > "$work/remote-$1.txt"
}
log "3. run a pane in the sandbox"
rpane first
ssh -o BatchMode=yes "$sandbox.rzv" 'echo kept > /workspace/e2e-mark.txt'

log "4. status and cost"
act status; finish status 60000
grep -q 'Credits used:' "$work/pane-status.txt" || fail "status shows no credits"
grep -q 'machine reachable' "$work/pane-status.txt" || fail "status shows no reachable machine"

log "5. sleep and wake"
act sleep; finish sleep 600000
"$rzv" sandboxes get "$sandbox" --json | grep -q '"status":"stopped"' || fail "not stopped"
act wake; finish wake 900000
rpane after
grep -q e2e-mark.txt "$work/remote-after.txt" || fail "/workspace lost across sleep"
"$rzv" sandboxes get "$sandbox" --json | grep -o '"runtime_seconds":[0-9]*,"credits_used":[0-9.]*' > "$work/usage.txt"

log "6. delete: a wrong name is refused, the right one deletes"
act delete; wait_for 'to confirm' 60000; answer wrong; finish delete-refused 60000 fail
grep -q 'Not deleted' "$work/pane-delete-refused.txt" || fail "wrong name was not refused"
act delete; wait_for 'to confirm' 60000; answer "$name"; finish delete 300000
"$H" machine list --json | grep -q "$sandbox" && fail "machine still saved"
"$rzv" sandboxes get "$sandbox" --json | grep -qE '"status":"(deleting|deleted)"' || fail "sandbox not deleted"
log "usage: $(cat "$work/usage.txt")"
