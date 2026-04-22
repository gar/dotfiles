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
# @raycast.refreshTime 10s
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

# A single `watson status` call is ~3x cheaper than invoking it for the
# project name and tags separately. Output shapes we care about:
#   Project <name> [<tag1>, <tag2>] started <rel> ago (<timestamp>)
#   Project <name> started <rel> ago (<timestamp>)
#   No project started.
status_line=$("$WATSON" status 2>/dev/null || true)

if [[ "$status_line" =~ ^Project\ (.+)\ \[(.+)\]\ started\  ]]; then
  printf '⏱ %s [%s]\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
elif [[ "$status_line" =~ ^Project\ (.+)\ started\  ]]; then
  printf '⏱ %s\n' "${BASH_REMATCH[1]}"
fi
