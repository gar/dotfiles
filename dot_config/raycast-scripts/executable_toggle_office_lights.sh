#!/usr/bin/env bash

# @raycast.schemaVersion 1
# @raycast.title Toggle Office Lights
# @raycast.mode silent
# @raycast.packageName Philips Hue
# @raycast.icon 💡
# @raycast.description Toggle the office light group. Activates "Read" (08:00-18:00) or "Rest" (otherwise) when turning on.

# Thin wrapper around ~/bin/toggle_office_lights so the same logic is reachable
# from Raycast, the shell, and Neovim.

exec "$HOME/bin/toggle_office_lights" "$@"
