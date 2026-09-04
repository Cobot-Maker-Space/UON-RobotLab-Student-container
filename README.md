# 🐢 TurtleBot Desktop Development Container (with noVNC) — Linux Edition

This branch provides a ready-to-use **Docker-based ROS 2 Humble development environment** for
**native Linux**, for TurtleBot3 simulation and development.

It includes:
- ROS 2 Humble preinstalled with navigation, SLAM, teleop, Gazebo, and visualization packages
- VS Code Dev Container configuration with useful extensions
- Integrated **noVNC support** for GUI access from your browser
- Persistent build and install caches, so rebuilds are incremental

> ℹ️ **On a different machine?** Use [`windows`](../../tree/windows) (Windows via WSL2) or
> [`macos`](../../tree/macos) (Apple Silicon). Each branch has its own image and its own README —
> there is no OS-agnostic setup here.

---

## 📦 Prerequisites

- **Docker Engine**, with your user in the `docker` group
- **Visual Studio Code**
- **Dev Containers extension**

---

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone --branch linux --single-branch https://github.com/Cobot-Maker-Space/UON-RobotLab-Student-container.git
cd UON-RobotLab-Student-container
```

---

### 2. Open in VS Code

Open the **`src/` directory** (not the repository root — that is where `.devcontainer` lives),
then press `Ctrl+Shift+P` and select:

```
Dev Containers: Reopen in Container
```

VS Code will:
1. Run `start_vnc.sh` on your machine, which creates the `ros` Docker network and starts the
   noVNC container on `http://localhost:8080` — this happens automatically, you do not need to
   run anything by hand
2. Pull the prebuilt ROS 2 image and start the dev container, attached to that same `ros` network
3. Run `setup.sh`, which builds the workspace

The first run takes a few minutes (image pull + first `colcon build`). Later runs are much faster.

---

### 3. Open the GUI

➡ **http://localhost:8080/vnc.html** and click **Connect**.

That browser tab *is* the container's display. Anything graphical you launch from the VS Code
terminal — RViz2, Gazebo, `rqt` — appears there, not in a window on your desktop.

Quick check, from the VS Code terminal:

```bash
xeyes
```

A pair of eyes should appear in the browser tab.

---

### 4. Test the Setup

Inside the VS Code terminal:

```bash
source /opt/ros/humble/setup.bash
ros2 topic list
```

If ROS 2 is installed correctly, you'll see a list of topics (or an empty list if nothing is
publishing).

---

## 🛠 Troubleshooting & Common Issues

| Issue | Solution |
|------|----------|
| **Permission denied: docker** | Add your user to the docker group:<br>`sudo usermod -aG docker $USER && newgrp docker` |
| **`network ros not found` when the container starts** | The noVNC container did not start. Run it by hand and look at the error:<br>`./src/.devcontainer/start_vnc.sh start` |
| **Cannot connect to noVNC** | `./src/.devcontainer/start_vnc.sh status`. To restart it: `./src/.devcontainer/start_vnc.sh restart` |
| **Port 8080 already in use** | Something else on your machine is using it. Stop that, or start noVNC on another port:<br>`HOST_PORT=8081 ./src/.devcontainer/start_vnc.sh restart` |
| **Gazebo spawn service failed** | Don't Ctrl+C — let it fail completely, then close and restart. |
| **Nothing appears in the browser** | Check `DISPLAY` inside the container is `novnc:0.0` (`echo $DISPLAY`), and that you clicked **Connect** in the noVNC page. |
| **I want to use a webcam** | Uncomment the `--device=/dev/video0` and `--group-add=video` lines in `devcontainer.json`'s `runArgs`. They are off by default because they break container creation on any machine without `/dev/video0`. |
| **The workspace won't rebuild from scratch** | `rm -f cache/humble/build/.built-for` and rebuild the container. That stamp file is what tells `setup.sh` the cache is still valid. |

---

## 💡 How it fits together

Two containers, on a shared Docker network called `ros`:

- **the dev container** — ROS 2, Gazebo, your code. Draws on `DISPLAY=novnc:0.0`, which is the
  *other* container, not your machine.
- **the noVNC container** (`theasp/novnc`) — runs the X server and serves it to your browser on
  port 8080. Started automatically by `start_vnc.sh` via `initializeCommand`.

Other things worth knowing:

- Default user inside container: `team`
- Your `src/` folder is mounted at `/home/ros2_ws/src`, and `cache/humble/{build,install,log}`
  at the matching workspace directories — so builds survive container rebuilds
- The image is pulled, not built locally: `ghcr.io/cobot-maker-space/robotlab-devcontainer-linux`.
  It is published by `.github/workflows/build-image.yml` — see [`decision.md`](decision.md)
- Includes Navigation2, SLAM Toolbox, Teleop, Gazebo + plugins, Cartographer, RViz2
- VS Code extensions preinstalled for ROS, C++, Python, and Git integration
