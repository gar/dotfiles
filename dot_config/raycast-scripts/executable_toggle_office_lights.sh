#!/usr/bin/env zsh

# @raycast.schemaVersion 1
# @raycast.title Toggle Office Lights
# @raycast.mode silent
# @raycast.packageName Philips Hue
# @raycast.icon 💡
# @raycast.description Toggle the office light group. Activates "Read" (08:00-18:00) or "Rest" (otherwise) when turning on.

# Thin wrapper around ~/bin/toggle_office_lights so the same logic is reachable
# from Raycast, the shell, and Neovim.
#
# Shebang is zsh so Raycast invocations source ~/.zshenv, which in turn sources
# ~/.env.local. That's how Hue credentials reach this process when Raycast
# launches it outside of any user shell session.

exec "$HOME/bin/toggle_office_lights" "$@"
