#!/usr/bin/env bash
# pull_image.sh — make sure the dev container image is present, as linux/amd64, before VS Code
# looks for it.
#
# The image pinned in devcontainer.json is amd64 only (see decision.md for why). On an Apple
# Silicon Mac, Docker's default platform is linux/arm64, so the plain 'docker pull' that VS Code
# runs fails with "no matching manifest for linux/arm64". Pulling it here with an explicit
# --platform first means VS Code finds it locally and never tries that pull.
#
# Called automatically by initializeCommand; safe to run by hand. Written for macOS's bash 3.2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="linux/amd64"

info(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }

# Read the image from devcontainer.json, so the tag is only ever written in one place.
IMAGE="$(grep -E '^[[:space:]]*"image"[[:space:]]*:' "${SCRIPT_DIR}/devcontainer.json" \
  | head -n 1 | sed -E 's/.*:[[:space:]]*"([^"]+)".*/\1/')"

if [ -z "$IMAGE" ]; then
  err "Could not read the \"image\" field from ${SCRIPT_DIR}/devcontainer.json."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  err "docker CLI not found. Install Docker Desktop and make sure it is running."
  exit 1
fi

# Already pulled: do nothing, so starting the container still works offline.
if docker image inspect "$IMAGE" >/dev/null 2>&1; then
  info "Image ${IMAGE} is already present."
  exit 0
fi

info "Pulling ${IMAGE} for ${PLATFORM}. First time only — about 1.5 GB, this can take a while..."
if ! docker pull --platform "$PLATFORM" "$IMAGE"; then
  err "Pull failed. Check your internet connection and that Docker Desktop is running, then retry:"
  echo "  ./src/.devcontainer/pull_image.sh"
  exit 1
fi
info "Pulled ${IMAGE}."
