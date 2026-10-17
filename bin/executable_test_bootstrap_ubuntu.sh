#!/bin/bash
set -euo pipefail

# End-to-end bootstrap test: runs bin/executable_bootstrap.sh non-interactively
# as a sudo-capable non-root user in a fresh ubuntu:26.04 container, applying
# this checkout's committed HEAD (uncommitted changes are not included).
# Slow — mise compiles Erlang, Ruby and Postgres from source — so not in CI.
#
# Usage: ./bin/executable_test_bootstrap_ubuntu.sh [image]   (needs docker)

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="${1:-ubuntu:26.04}"

# chsh is skipped (SHELL is preset to zsh) — it needs the user's password
docker run --rm -i -v "$REPO_DIR":/src:ro "$IMAGE" bash -s <<'EOF'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq sudo git curl ca-certificates > /dev/null
useradd -m -s /bin/bash tester
printf 'tester ALL=(ALL) NOPASSWD:ALL\nDefaults env_keep += "DEBIAN_FRONTEND"\n' > /etc/sudoers.d/tester
git config --system --add safe.directory '*'
git clone -q /src /home/tester/dotfiles
chown -R tester: /home/tester/dotfiles
sudo -u tester -H env \
  DEBIAN_FRONTEND=noninteractive \
  HOMEBREW_DOTFILES_WORK=0 \
  DOTFILES_EMAIL=test@example.com \
  DOTFILES_REPO=file:///home/tester/dotfiles \
  SHELL=/usr/bin/zsh \
  bash /home/tester/dotfiles/bin/executable_bootstrap.sh
EOF
