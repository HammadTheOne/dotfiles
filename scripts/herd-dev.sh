#!/usr/bin/env bash
#
# Spin up the numbox dev stack in a herdr workspace across 3 named tabs.
#
#   Tab "Flask Server"  task start            -> http://localhost:8000
#   Tab "Celery"        worker (task start-celery, top) + beat (task start-beat, bottom)
#   Tab "Services"      redis (top-left) + ngrok (top-right), postgres (full-width bottom)
#
# redis    : shuts down any existing instance, then starts fresh
# ngrok    : run `task configure-ngrok` once first
# postgres : reminder only — you start it yourself
#
# Prereqs: a running herdr instance, plus `herdr` and `jq` on PATH.
# Targets the numbox checkout at $NUMBOX_DIR (default ~/Documents/numbox).
# Run from anywhere (aliased as `numboxup`).

set -euo pipefail

REPO_DIR="${NUMBOX_DIR:-$HOME/Documents/numbox}"
PG_DATA="$HOME/numbox_pgdata"
LABEL="numbox-dev"

for tool in herdr jq; do
	if ! command -v "$tool" >/dev/null 2>&1; then
		echo "❌ '$tool' not found on PATH." >&2
		exit 1
	fi
done

if [ ! -d "$REPO_DIR" ]; then
	echo "❌ numbox repo not found at $REPO_DIR — set NUMBOX_DIR to override." >&2
	exit 1
fi

# Kill strays from previous runs — closing a herdr workspace/pane does NOT
# reliably kill the full process tree, so old instances hold port 8000, the
# ngrok endpoints, and duplicate celery consumers. Patterns are scoped to
# numbox so unrelated watchmedo/celery processes survive.
echo "▶ Cleaning up stray processes from previous runs"
pkill -f 'watchmedo auto-restart.*numbox' 2>/dev/null || true
sleep 1
pkill -f 'celery -A numbox' 2>/dev/null || true
lsof -ti :8000 2>/dev/null | xargs kill 2>/dev/null || true
pkill -x ngrok 2>/dev/null || true

# Close leftover numbox-dev workspaces (just dead shells after the cleanup).
for old_ws in $(herdr workspace list | jq -r --arg label "$LABEL" \
	'.result.workspaces[] | select(.label == $label) | .workspace_id'); do
	herdr workspace close "$old_ws" >/dev/null 2>&1 || true
done

echo "▶ Creating herdr workspace '$LABEL' in $REPO_DIR"
herdr workspace create --cwd "$REPO_DIR" --label "$LABEL" --focus >/dev/null

# herdr IDs: panes are "<workspace_id>-<n>", tabs are "<workspace_id>:<n>", both
# numbered sequentially as created. Resolve the workspace we just made by label.
WS_ID="$(herdr workspace list \
	| jq -r --arg label "$LABEL" \
		'.result.workspaces | map(select(.label == $label)) | last | .workspace_id')"

if [ -z "$WS_ID" ] || [ "$WS_ID" = "null" ]; then
	echo "❌ Could not resolve workspace id for '$LABEL'." >&2
	exit 1
fi

pid() { echo "${WS_ID}-$1"; }   # pane id
tid() { echo "${WS_ID}:$1"; }   # tab id

# Tab 1 "Flask Server": task start (-1).
herdr tab rename "$(tid 1)" "Flask Server" >/dev/null

# Tab 2 "Celery": worker (-2, top) + beat (-3, bottom).
herdr tab create --workspace "$WS_ID" --cwd "$REPO_DIR" --label "Celery" >/dev/null   # -> -2
herdr pane split "$(pid 2)" --direction down >/dev/null   # -> -3

# Tab 3 "Services": redis (-4, top-left) + ngrok (-6, top-right), postgres (-5, bottom).
herdr tab create --workspace "$WS_ID" --cwd "$REPO_DIR" --label "Services" >/dev/null        # -> -4
herdr pane split "$(pid 4)" --direction down  >/dev/null   # -> -5 (full-width bottom)
herdr pane split "$(pid 4)" --direction right >/dev/null   # -> -6 (top-right)

# Sanity check: confirm we ended up with 6 panes before sending commands.
pane_count="$(herdr pane list --workspace "$WS_ID" | jq '.result.panes | length')"
panes_ok=1
if [ "$pane_count" -ne 6 ]; then
	panes_ok=0
	echo "⚠️  Expected 6 panes, found $pane_count. Pane/tab IDs may differ on your" >&2
	echo "    herdr version — check 'herdr pane list' / 'herdr tab list' and adjust." >&2
fi

# Redis first so celery/beat/flask can connect. Shut down any redis already on
# the port so this pane owns a fresh instance, then let it settle before the
# clients start (avoids celery's "connection refused" retry loop).
herdr pane run "$(pid 4)" "redis-cli shutdown nosave 2>/dev/null; sleep 1; redis-server"
sleep 4

# Flask tab
herdr pane run "$(pid 1)" "task start"
# Celery tab
herdr pane run "$(pid 2)" "task start-celery"
herdr pane run "$(pid 3)" "task start-beat"
# Services tab
herdr pane run "$(pid 6)" "ngrok start --all"

# Postgres pane: not auto-started. Echo a reminder so the prompt is ready for
# your usual command, or swap in the readonly prod connection when you want.
herdr pane run "$(pid 5)" \
	"echo 'Postgres (run manually): pg_ctl -D $PG_DATA -l logfile start   |   or point at readonly prod'"

herdr pane focus "$(pid 1)"   # land on Flask Server
if [ "$panes_ok" -eq 1 ]; then
	echo "✅ '$LABEL' ready — tabs: Flask Server · Celery · Services ($pane_count panes)"
else
	echo "⚠️  '$LABEL' started with $pane_count panes (expected 6) — some commands may not have landed." >&2
fi
