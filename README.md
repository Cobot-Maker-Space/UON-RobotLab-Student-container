# 🐢 TurtleBot Desktop Development Container (with noVNC) — macOS Edition

This branch provides a ready-to-use **Docker-based ROS 2 Humble development environment** for
**Apple Silicon Macs** (M1/M2/M3/M4 — arm64), for TurtleBot3 simulation and development.

It includes:
- ROS 2 Humble preinstalled with navigation, SLAM, teleop, Gazebo, and visualization packages
- VS Code Dev Container configuration with useful extensions
- Integrated **noVNC support** for GUI access from your browser
- Persistent build and install caches, so rebuilds are incremental

> ℹ️ **On a different machine?** Use [`windows`](../../tree/windows) (Windows via WSL2) or
> [`linux`](../../tree/linux) (native Linux). Each branch has its own image and its own README —
> there is no OS-agnostic setup here.

> ⚠️ **Intel Mac?** This branch's image is arm64 only. Use the [`linux`](../../tree/linux) branch
> instead — its amd64 image runs natively on Intel hardware.

---

## 📦 Prerequisites

- **[Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)** (Apple Silicon
  build), running. There is no `docker` group to join on macOS — Docker Desktop handles it.
- **Visual Studio Code**
- **Dev Containers extension**

---

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone --branch macos --single-branch https://github.com/Cobot-Maker-Space/UON-RobotLab-Student-container.git
cd UON-RobotLab-Student-container
```

---

### 2. Open in VS Code

Open the **`src/` directory** (not the repository root — that is where `.devcontainer` lives),
then press `Cmd+Shift+P` and select:

```
Dev Containers: Reopen in Container
```

VS Code will:
1. Run `start_vnc.sh` on your Mac, which creates the `ros` Docker network and starts the noVNC
   container on `http://localhost:8080` — this happens automatically, you do not need to run
   anything by hand
2. Pull the prebuilt arm64 ROS 2 image and start the dev container, attached to that same network
3. Run `setup.sh`, which builds the workspace

The first run takes a while (image pull + first `colcon build`). Later runs are much faster.

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
| **Permission denied: docker** | Make sure Docker Desktop is actually running — there is no `docker` group to join on macOS. |
| **`network ros not found` when the container starts** | The noVNC container did not start. Run it by hand and look at the error:<br>`./src/.devcontainer/start_vnc.sh start` |
| **Cannot connect to noVNC** | `./src/.devcontainer/start_vnc.sh status`. To restart it: `./src/.devcontainer/start_vnc.sh restart` |
| **Port 8080 already in use** | Something else on your Mac is using it. Stop that, or start noVNC on another port:<br>`HOST_PORT=8081 ./src/.devcontainer/start_vnc.sh restart` |
| **Gazebo spawn service failed** | Don't Ctrl+C — let it fail completely, then close and restart. |
| **Gazebo is slow, or a rendering plugin fails to load** | Expected on Apple Silicon. There is no GPU passthrough into an arm64 container, so `LIBGL_ALWAYS_SOFTWARE=1` is set in `devcontainer.json` and everything renders on the CPU. Simulations run, just slower than on an amd64 machine. Keep worlds small. |
| **`The requested image's platform (linux/amd64) does not match`** | Expected, and harmless. It refers to the noVNC container, not yours — `theasp/novnc` is published for amd64 only and runs under emulation on Apple Silicon. It only serves an X server over the network, so the architecture mismatch does not matter. |
| **`no matching manifest for linux/arm64`** | You are pointed at an amd64 image. This branch pins the arm64 one; check the `image` field in `devcontainer.json` still reads `robotlab-devcontainer-macos`. |
| **The workspace won't rebuild from scratch** | `rm -f cache/humble/build/.built-for` and rebuild the container. That stamp file is what tells `setup.sh` the cache is still valid. |

---

## 💡 How it fits together

Two containers, on a shared Docker network called `ros`:

- **the dev container** — ROS 2, Gazebo, your code. Draws on `DISPLAY=novnc:0.0`, which is the
  *other* container, not your Mac.
- **the noVNC container** (`theasp/novnc`) — runs the X server and serves it to your browser on
  port 8080. Started automatically by `start_vnc.sh` via `initializeCommand`. This one is an
  amd64 image and runs emulated on Apple Silicon; that is fine, because all it does is speak the
  X protocol over the network. Only the dev container needs to be native arm64.

Other things worth knowing:

- Default user inside container: `team`
- No webcam passthrough: Docker Desktop runs a Linux VM that cannot reach host USB devices, so
  `--device=/dev/video0` is deliberately absent from `runArgs`
- The repo ships a pre-populated `cache/humble/` built on **amd64**. `setup.sh` notices the
  mismatch on first run here, clears it once, and rebuilds for arm64 — after that, rebuilds are
  incremental
- The image is pulled, not built locally: `ghcr.io/cobot-maker-space/robotlab-devcontainer-macos`.
  It is published by `.github/workflows/build-image.yml` — see [`decision.md`](decision.md)
- Includes Navigation2, SLAM Toolbox, Teleop, Gazebo + plugins, Cartographer, RViz2
- VS Code extensions preinstalled for ROS, C++, Python, and Git integration
