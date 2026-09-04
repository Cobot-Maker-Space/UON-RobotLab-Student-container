#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

echo "=== devcontainer setup.sh starting ==="

# Hardcode the correct workspace directory
WORKSPACE_DIR="/home/ros2_ws"
SRC_DIR="${WORKSPACE_DIR}/src"

echo "Workspace dir: $WORKSPACE_DIR"
echo "Src dir: $SRC_DIR"

# Determine if we can run apt (root or sudo)
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "Note: not running as root and sudo not found — skipping apt installs"
  fi
fi

# Gazebo is baked into the published image, so this is normally a no-op that costs nothing.
# It only fires if you are on an older image, or on arm64 where Gazebo Classic's packaging is
# occasionally incomplete — in which case it is worth the wait rather than failing later.
if [ -d /opt/ros/humble/share/gazebo_ros ]; then
  echo "✅ Gazebo ROS packages already in the image — skipping apt."
elif [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
  echo "⬇️  Gazebo ROS packages missing — installing them (this takes a few minutes)..."
  $SUDO apt-get update -y
  $SUDO apt-get install -y ros-humble-gazebo-ros-pkgs ros-humble-gazebo-plugins || {
    echo "Warning: apt-get install failed (continuing)."
  }
fi

# Ensure src folder exists
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# The repo ships a pre-populated cache/humble/{build,install,log}, bind-mounted over
# ${WORKSPACE_DIR}/{build,install,log}. Those artefacts are architecture-specific and full of
# absolute paths, so reusing an amd64 cache inside an arm64 container produces baffling link
# errors. Stamp the cache with what produced it, and only wipe when the stamp does not match —
# that way a normal rebuild is incremental (seconds) instead of a full build (many minutes).
STAMP_FILE="${WORKSPACE_DIR}/build/.built-for"
STAMP="$(uname -m)-${ROS_DISTRO:-humble}"

if [ -f "$STAMP_FILE" ] && [ "$(cat "$STAMP_FILE")" = "$STAMP" ]; then
  echo "✅ Existing build cache was built for ${STAMP} — building incrementally."
else
  echo "♻️  Build cache is missing or was built for something other than ${STAMP} — clearing it."
  rm -rf "${WORKSPACE_DIR}/build/"* "${WORKSPACE_DIR}/install/"* "${WORKSPACE_DIR}/log/"* || true
  rm -f "$STAMP_FILE"
fi

# Repos to ensure present (name|url)
repos=(
  "DynamixelSDK|https://github.com/ROBOTIS-GIT/DynamixelSDK.git"
  "turtlebot3|https://github.com/ROBOTIS-GIT/turtlebot3.git"
  "turtlebot3_msgs|https://github.com/ROBOTIS-GIT/turtlebot3_msgs.git"
  "turtlebot3_simulations|https://github.com/ROBOTIS-GIT/turtlebot3_simulations.git"
)

clone_if_missing() {
  local folder="$1"; shift
  local url="$1"; shift
  if [ -d "${SRC_DIR}/${folder}" ]; then
    echo "✅ ${folder} already exists — skipping clone."
  else
    echo "⬇️  Cloning ${folder}..."
    git clone -b humble "${url}" "${SRC_DIR}/${folder}" || {
      echo "Error cloning ${folder}. Continuing..."
    }
  fi
}

for entry in "${repos[@]}"; do
  name="${entry%%|*}"
  url="${entry##*|}"
  clone_if_missing "$name" "$url"
done


# Source ROS and build
if [ -f /opt/ros/humble/setup.bash ]; then
  echo "Sourcing ROS 2 humble setup..."
  set +u
  source /opt/ros/humble/setup.bash
  set -u
fi

# Build the workspace
cd "$WORKSPACE_DIR"
echo "Running colcon build --symlink-install ..."
if command -v colcon >/dev/null 2>&1; then
  colcon build --symlink-install || {
    echo "colcon build failed. Check logs in ${WORKSPACE_DIR}/log"
    exit 1
  }
else
  echo "colcon not found in PATH. Please install colcon inside the container and re-run this script."
  exit 1
fi

# Only stamp after a build that actually succeeded, so a failed build is retried from clean.
echo "$STAMP" > "$STAMP_FILE"

echo "=== setup.sh finished successfully ==="
