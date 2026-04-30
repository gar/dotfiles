#!/usr/bin/env bash
# Claude Code status line script
# Receives JSON on stdin from Claude Code

input=$(cat)

# ANSI colours
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

SEP=" | "

# ---------------------------------------------------------------------------
# Model tag — derive short name and any modifier from display_name / model id
# ---------------------------------------------------------------------------
model_display=$(echo "$input" | jq -r '.model.display_name // ""')
model_id=$(echo "$input" | jq -r '.model.id // ""')

model_short=""
model_mod=""

if [ -n "$model_display" ]; then
  case "$model_display" in
    *Opus*)   model_short="Opus"   ;;
    *Sonnet*) model_short="Sonnet" ;;
    *Haiku*)  model_short="Haiku"  ;;
    *)        model_short="$model_display" ;;
  esac
fi

# Detect modifiers from the model id
if [ -n "$model_id" ]; then
  case "$model_id" in
    *1m*|*-1m*|*1M*|-1M*)  model_mod="1M" ;;
  esac
  if echo "$model_id" | grep -qiE 'think'; then
    model_mod="${model_mod:+$model_mod · }thinking"
  fi
fi

case "$model_display" in
  *thinking*|*Thinking*) model_mod="${model_mod:-thinking}" ;;
esac

# Reasoning effort level — read from ~/.claude/settings.json
effort_level=""
settings_file="$HOME/.claude/settings.json"
if [ -f "$settings_file" ] && command -v jq >/dev/null 2>&1; then
  effort_level=$(jq -r '.effortLevel // empty' "$settings_file")
fi

if echo "$model_id" | grep -qiE '\[1m\]|1m'; then
  model_mod="${model_mod:-1M}"
fi

model_tag=""
if [ -n "$model_short" ]; then
  label="$model_short"
  if [ -n "$model_mod" ]; then
    label="${label} · ${model_mod}"
  fi
  if [ -n "$effort_level" ]; then
    label="${label} · ${effort_level}"
  fi
  model_tag="[${label}]"
fi

# ---------------------------------------------------------------------------
# cwd
# ---------------------------------------------------------------------------
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
cwd_display=""
[ -n "$cwd" ] && cwd_display="\033[2m~\033[0m $(basename "$cwd")"

# ---------------------------------------------------------------------------
# git branch
# ---------------------------------------------------------------------------
git_branch=""
if [ -n "$cwd" ] && command -v git >/dev/null 2>&1; then
  git_dir=$(git -C "$cwd" -c core.hooksPath=/dev/null rev-parse --git-dir 2>/dev/null)
  if [ -n "$git_dir" ]; then
    git_branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null \
      || git -C "$cwd" -c core.hooksPath=/dev/null rev-parse --short HEAD 2>/dev/null)
  fi
fi

# ---------------------------------------------------------------------------
# Context bar + percent
#   0–40%  → green,  40–60% → yellow,  60%+ → red
# ---------------------------------------------------------------------------
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_display=""
if [ -n "$used_pct" ]; then
  raw_pct=$(awk "BEGIN { printf \"%.0f\", $used_pct }")
  bar_width=10
  filled=$(( raw_pct * bar_width / 100 ))
  empty=$(( bar_width - filled ))

  if [ "$raw_pct" -ge 60 ]; then
    bar_color="$RED"
  elif [ "$raw_pct" -ge 40 ]; then
    bar_color="$YELLOW"
  else
    bar_color="$GREEN"
  fi

  bar=""
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done

  if [ "$raw_pct" -ge 60 ]; then
    ctx_emoji="🤪"
  elif [ "$raw_pct" -ge 40 ]; then
    ctx_emoji="🤨"
  else
    ctx_emoji="😎"
  fi

  ctx_display="${ctx_emoji} ${bar_color}${bar}${RESET} ${raw_pct}%"
fi

# ---------------------------------------------------------------------------
# Cumulative session token counts — ↑ input / ↓ output
# ---------------------------------------------------------------------------
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
tokens_display=""
if [ "$total_in" -gt 0 ] || [ "$total_out" -gt 0 ]; then
  fmt_k() {
    local n="$1"
    if [ "$n" -ge 1000 ]; then
      awk "BEGIN { printf \"%.0fk\", $n / 1000 }"
    else
      echo "$n"
    fi
  }
  in_fmt=$(fmt_k "$total_in")
  out_fmt=$(fmt_k "$total_out")
  tokens_display="${DIM}↑ ${in_fmt} / ↓ ${out_fmt}${RESET}"
fi

# ---------------------------------------------------------------------------
# Cost
# ---------------------------------------------------------------------------
cost_val=$(echo "$input" | jq -r '.cost.total_cost // empty')
cost_display=""
if [ -n "$cost_val" ]; then
  cost_display="\$$(printf '%.2f' "$cost_val")"
else
  if [ "$total_in" -gt 0 ] || [ "$total_out" -gt 0 ]; then
    cost_est=$(awk "BEGIN { printf \"%.2f\", ($total_in / 1000000 * 3) + ($total_out / 1000000 * 15) }")
    cost_display="\$${cost_est}"
  fi
fi

# ---------------------------------------------------------------------------
# Duration
# ---------------------------------------------------------------------------
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
duration_display=""
if [ -n "$duration_ms" ] && [ "$duration_ms" != "0" ]; then
  total_s=$(( duration_ms / 1000 ))
  hours=$(( total_s / 3600 ))
  mins=$(( (total_s % 3600) / 60 ))
  secs=$(( total_s % 60 ))
  if [ "$hours" -gt 0 ]; then
    duration_display="⏱  ${hours}h ${mins}m"
  else
    duration_display="⏱  ${mins}m ${secs}s"
  fi
fi

# ---------------------------------------------------------------------------
# Single line: [Model] | <bar> % | tokens | $cost | ⏱ duration | ~ cwd | % branch
# ---------------------------------------------------------------------------
line=""

if [ -n "$model_tag" ]; then
  line="${CYAN}${model_tag}${RESET}"
fi
if [ -n "$ctx_display" ]; then
  line="${line:+${line}${SEP}}${ctx_display}"
fi
if [ -n "$tokens_display" ]; then
  line="${line:+${line}${SEP}}${tokens_display}"
fi
if [ -n "$cost_display" ]; then
  line="${line:+${line}${SEP}}${YELLOW}${cost_display}${RESET}"
fi
if [ -n "$duration_display" ]; then
  line="${line:+${line}${SEP}}${duration_display}"
fi
if [ -n "$cwd_display" ]; then
  line="${line:+${line}${SEP}}${cwd_display}"
fi
if [ -n "$git_branch" ]; then
  line="${line:+${line}${SEP}}${GREEN}\033[2m%\033[0m${GREEN} ${git_branch}${RESET}"
fi

if [ -n "$line" ]; then
  printf "%b${RESET}\n" "$line"
fi
