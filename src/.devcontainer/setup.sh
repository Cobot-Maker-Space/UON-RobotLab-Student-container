
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
    echo "Using sudo for package installs"
  else
    echo "Note: not running as root and sudo not found — skipping apt installs"
    SUDO=""
  fi
else
  echo "Running as root"
fi

# Install Gazebo packages only if apt is available
if [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
  echo "Updating apt and installing gazebo packages..."
  $SUDO apt-get update -y
  $SUDO apt-get install -y ros-humble-gazebo-ros-pkgs ros-humble-gazebo-plugins || {
    echo "Warning: apt-get install failed (continuing)."
  }
fi

# Ensure src folder exists
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# Clean build/install/log only if they exist and have content
if [ -d "$WORKSPACE_DIR/build" ] || [ -d "$WORKSPACE_DIR/install" ] || [ -d "$WORKSPACE_DIR/log" ]; then
  echo "Cleaning build/install/log directories (only inside) ..."
  rm -rf "${WORKSPACE_DIR}/build/"* "${WORKSPACE_DIR}/install/"* "${WORKSPACE_DIR}/log/"* || true
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


echo "=== setup.sh finished successfully ==="
