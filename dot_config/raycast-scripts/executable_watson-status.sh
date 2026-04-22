#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Watson Status
# @raycast.mode menu-bar
# @raycast.packageName Watson
#
# Optional parameters:
# @raycast.icon ⏱
# @raycast.refreshTime 30s
# @raycast.description Show the currently-tracked Watson project in the menu bar. Empty when not tracking.

set -euo pipefail

# Raycast launches script commands with a minimal PATH, so resolve watson
# from the usual Homebrew / user-local locations.
WATSON=""
for candidate in /opt/homebrew/bin/watson /usr/local/bin/watson "$HOME/.local/bin/watson"; do
  if [[ -x "$candidate" ]]; then
    WATSON="$candidate"
    break
  fi
done
: "${WATSON:=$(command -v watson 2>/dev/null || true)}"

# No watson binary — stay silent rather than surfacing an error.
[[ -z "$WATSON" ]] && exit 0

# `watson status` prints "No project started." when idle and a line beginning
# with "Project " when tracking. Bail silently when not tracking so the menu
# bar item is empty.
status_line=$("$WATSON" status 2>/dev/null || true)
[[ "$status_line" == Project\ * ]] || exit 0

project=$("$WATSON" status -p 2>/dev/null || true)
[[ -z "$project" ]] && exit 0

tags=$("$WATSON" status -t 2>/dev/null || true)

if [[ -n "$tags" ]]; then
  printf '⏱ %s [%s]\n' "$project" "$tags"
else
  printf '⏱ %s\n' "$project"
fi
