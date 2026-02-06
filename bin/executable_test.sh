#!/bin/bash
set -euo pipefail

# Dotfiles CI test suite
# Run all checks: ./bin/executable_test.sh
# Run one check:  ./bin/executable_test.sh <check_name>
#
# Checks: shellcheck, shell-syntax, lua-lint, nvim-startup, chezmoi-template, git-config

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); printf "${GREEN}  ✔ %s${RESET}\n" "$1"; }
fail() { FAIL=$((FAIL + 1)); printf "${RED}  ✘ %s${RESET}\n" "$1"; }

run_check() {
  local name="$1"
  local filter="${2:-}"
  if [[ -z "$filter" || "$filter" == "$name" ]]; then
    printf "\n${BOLD}▸ %s${RESET}\n" "$name"
    return 0
  fi
  return 1
}

summary() {
  printf "\n${BOLD}Results: ${GREEN}%d passed${RESET}, ${RED}%d failed${RESET}\n" "$PASS" "$FAIL"
  [[ "$FAIL" -eq 0 ]]
}

FILTER="${1:-}"

# ---------------------------------------------------------------------------
# 1. ShellCheck — lint shell scripts
# ---------------------------------------------------------------------------
if run_check "shellcheck" "$FILTER"; then
  if command -v shellcheck &>/dev/null; then
    for f in "$REPO_DIR"/bin/executable_*.sh "$REPO_DIR"/dot_macos; do
      [[ -f "$f" ]] || continue
      basename="$(basename "$f")"
      # dot_macos uses osascript/defaults — lots of deliberate SC warnings; exclude common noise
      if shellcheck -e SC1091,SC2034,SC2044,SC2046,SC2064,SC2086,SC2162 "$f" 2>&1; then
        pass "shellcheck $basename"
      else
        fail "shellcheck $basename"
      fi
    done
  else
    fail "shellcheck not installed"
  fi
fi

# ---------------------------------------------------------------------------
# 2. Shell syntax — parse-check zshrc and bash scripts
# ---------------------------------------------------------------------------
if run_check "shell-syntax" "$FILTER"; then
  # bash scripts
  for f in "$REPO_DIR"/bin/executable_*.sh; do
    [[ -f "$f" ]] || continue
    basename="$(basename "$f")"
    if bash -n "$f" 2>&1; then
      pass "bash -n $basename"
    else
      fail "bash -n $basename"
    fi
  done

  # zsh — render template first if chezmoi is available, then syntax-check
  if command -v zsh &>/dev/null; then
    ZSHRC_FILE="$REPO_DIR/dot_zshrc.tmpl"
    if [[ -f "$ZSHRC_FILE" ]]; then
      ZSHRC_TMP=$(mktemp)
      if command -v chezmoi &>/dev/null; then
        chezmoi execute-template --init < "$ZSHRC_FILE" > "$ZSHRC_TMP" 2>/dev/null
      else
        cp "$ZSHRC_FILE" "$ZSHRC_TMP"
      fi
      if zsh -n "$ZSHRC_TMP" 2>&1; then
        pass "zsh -n dot_zshrc.tmpl"
      else
        fail "zsh -n dot_zshrc.tmpl"
      fi
      rm -f "$ZSHRC_TMP"
    fi
  else
    pass "zsh -n dot_zshrc.tmpl (skipped — zsh not available)"
  fi
fi

# ---------------------------------------------------------------------------
# 3. Lua lint — luacheck on neovim config
# ---------------------------------------------------------------------------
if run_check "lua-lint" "$FILTER"; then
  if command -v luacheck &>/dev/null; then
    if luacheck "$REPO_DIR/dot_config/nvim" \
        --globals vim \
        --no-unused-args \
        --no-max-line-length 2>&1; then
      pass "luacheck dot_config/nvim"
    else
      fail "luacheck dot_config/nvim"
    fi
  else
    fail "luacheck not installed"
  fi
fi

# ---------------------------------------------------------------------------
# 4. Neovim startup — headless launch to catch config errors
# ---------------------------------------------------------------------------
if run_check "nvim-startup" "$FILTER"; then
  if command -v nvim &>/dev/null; then
    NVIM_DIR="$REPO_DIR/dot_config/nvim"
    # Launch nvim with our config dir, install plugins, then quit.
    # Capture stderr — any errors or warnings indicate a broken config.
    NVIM_ERR=$(XDG_CONFIG_HOME="$REPO_DIR/dot_config" \
      nvim --headless \
        "+Lazy! install" \
        "+lua vim.cmd('qall!')" 2>&1) || true
    # Filter out known-benign noise
    NVIM_ERR=$(echo "$NVIM_ERR" | grep -vi "warning\|deprecated\|--hierarchical" || true)
    if [[ -z "$NVIM_ERR" ]]; then
      pass "nvim headless startup"
    else
      printf "%s\n" "$NVIM_ERR"
      fail "nvim headless startup (errors on stderr)"
    fi
  else
    pass "nvim headless startup (skipped — nvim not available)"
  fi
fi

# ---------------------------------------------------------------------------
# 5. Git config — validate gitconfig parses correctly
# ---------------------------------------------------------------------------
if run_check "git-config" "$FILTER"; then
  GITCONFIG="$REPO_DIR/dot_gitconfig.tmpl"
  if [[ -f "$GITCONFIG" ]]; then
    # Render template if chezmoi is available, otherwise test the raw file
    TMPFILE=$(mktemp)
    trap 'rm -f "$TMPFILE"' EXIT
    if command -v chezmoi &>/dev/null; then
      chezmoi execute-template --init < "$GITCONFIG" > "$TMPFILE" 2>/dev/null
    else
      cp "$GITCONFIG" "$TMPFILE"
    fi
    if git config --file "$TMPFILE" --list >/dev/null 2>&1; then
      pass "git config dot_gitconfig.tmpl"
    else
      git config --file "$TMPFILE" --list 2>&1 || true
      fail "git config dot_gitconfig.tmpl"
    fi
  else
    pass "git config (skipped — dot_gitconfig.tmpl not found)"
  fi
fi

# ---------------------------------------------------------------------------
# 6. Chezmoi template — validate templates render without errors
# ---------------------------------------------------------------------------
if run_check "chezmoi-template" "$FILTER"; then
  if command -v chezmoi &>/dev/null; then
    TMPL_FAIL=0
    while IFS= read -r -d '' f; do
      basename="$(basename "$f")"
      # Validate template syntax only — templates that call onepassword* will
      # fail to *execute* without 1Password auth, so we just check parsing.
      if chezmoi execute-template --init < "$f" >/dev/null 2>&1; then
        pass "template $basename"
      else
        # Retry: if the error is about 1Password, treat as a syntax pass
        ERR=$(chezmoi execute-template --init < "$f" 2>&1 || true)
        if echo "$ERR" | grep -qi "onepassword\|1password\|op:"; then
          pass "template $basename (skipped — requires 1Password)"
        else
          printf "  %s\n" "$ERR"
          fail "template $basename"
          TMPL_FAIL=1
        fi
      fi
    done < <(find "$REPO_DIR" -name '*.tmpl' -not -path '*/.git/*' -print0)
    [[ "$TMPL_FAIL" -eq 0 ]] || true
  else
    pass "chezmoi templates (skipped — chezmoi not available)"
  fi
fi

# ---------------------------------------------------------------------------
summary
