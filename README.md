# 🐢 TurtleBot Desktop Development Container (with noVNC) — Windows Edition

This branch provides a ready-to-use **Docker-based ROS 2 Humble development environment** for
**Windows**, running through WSL2, for TurtleBot3 simulation and development.

It includes:
- ROS 2 Humble preinstalled with navigation, SLAM, teleop, Gazebo, and visualization packages
- VS Code Dev Container configuration with useful extensions
- Integrated **noVNC support** for GUI access from your browser
- Persistent build and install caches, so rebuilds are incremental

> ℹ️ **On a different machine?** Use [`linux`](../../tree/linux) (native Linux) or
> [`macos`](../../tree/macos) (Apple Silicon). Each branch has its own image and its own README —
> there is no OS-agnostic setup here.

> ℹ️ **Why WSL2?** Docker Desktop for Windows needs the WSL2 backend to run Linux containers at
> all. Rather than porting the shell scripts to PowerShell, everything here runs inside a real
> Ubuntu (WSL2) shell, which behaves identically to native Linux — no rewritten commands.
> **Follow these steps from a WSL2 terminal, not PowerShell.**

---

## 📦 Prerequisites

- Windows 10 (2004+) or Windows 11
- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/), with the
  **WSL 2 based engine** enabled
- [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) with an Ubuntu distro installed
- Visual Studio Code
- VS Code extensions: **Dev Containers** and **WSL**

---

## 🔧 Setup Instructions

### 1. Install WSL2 and Ubuntu

Open an elevated PowerShell and run:

```powershell
wsl --install
```

Reboot if prompted. This installs WSL2 with Ubuntu as the default distro.

---

### 2. Configure Docker Desktop

- Install Docker Desktop for Windows.
- **Settings → General** → confirm **"Use the WSL 2 based engine"** is checked.
- **Settings → Resources → WSL Integration** → enable integration with your Ubuntu distro.

---

### 3. Install VS Code extensions

Install **Dev Containers** and **WSL** from the VS Code marketplace.

---

### 4. Prepare Git inside WSL2

Open an Ubuntu (WSL2) terminal and run:

```bash
git config --global core.autocrlf input
git config --global core.longpaths true
```

This avoids line-ending corruption and long-path clone failures — `DynamixelSDK` in this repo has
paths long enough to trip the second one.

---

### 5. Clone the Repository (inside WSL2, not on the Windows filesystem)

Clone into your Linux home directory rather than `C:\Users\...`. Bind mounts across the
Windows↔WSL2 filesystem boundary are dramatically slower.

```bash
cd ~
git clone --branch windows --single-branch https://github.com/Cobot-Maker-Space/UON-RobotLab-Student-container.git
cd UON-RobotLab-Student-container
```

---

### 6. Open in VS Code

From the same WSL2 terminal, open the **`src/` directory** (not the repository root — that is
where `.devcontainer` lives):

```bash
code src
```

Then press `Ctrl+Shift+P` and select:

```
Dev Containers: Reopen in Container
```

VS Code will:
1. Run `start_vnc.sh` inside WSL2, which creates the `ros` Docker network and starts the noVNC
   container on port 8080 — this happens automatically, you do not need to run anything by hand
2. Pull the prebuilt ROS 2 image and start the dev container, attached to that same `ros` network
3. Run `setup.sh`, which builds the workspace

The first run takes a few minutes (image pull + first `colcon build`). Later runs are much faster.

---

### 7. Open the GUI

Docker Desktop forwards WSL2 ports to Windows `localhost` automatically, so from any Windows
browser:

➡ **http://localhost:8080/vnc.html** and click **Connect**.

That browser tab *is* the container's display. Anything graphical you launch from the VS Code
terminal — RViz2, Gazebo, `rqt` — appears there, not in a window on your desktop.

Quick check, from the VS Code terminal:

```bash
xeyes
```

A pair of eyes should appear in the browser tab.

---

### 8. Test the Setup

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
|---|---|
| **`docker` not found / permission denied in WSL2** | Enable Docker Desktop's WSL Integration for your Ubuntu distro (**Settings → Resources → WSL Integration**). Unlike native Linux, you do **not** need a `docker` group. |
| **`start_vnc.sh: bad interpreter: /bin/bash^M`** | The script has Windows (CRLF) line endings. Run `dos2unix src/.devcontainer/start_vnc.sh` inside WSL2, or re-clone after setting `git config --global core.autocrlf input` (step 4). |
| **`network ros not found` when the container starts** | The noVNC container did not start. Run it by hand and look at the error:<br>`./src/.devcontainer/start_vnc.sh start` |
| **Cannot connect to noVNC** | `./src/.devcontainer/start_vnc.sh status`. To restart it: `./src/.devcontainer/start_vnc.sh restart` |
| **Port 8080 already in use** | Something else on Windows is using it. Stop that, or start noVNC on another port:<br>`HOST_PORT=8081 ./src/.devcontainer/start_vnc.sh restart` |
| **`initializeCommand` failed / `bash` not recognised** | You opened the folder in Windows VS Code instead of through WSL. Close it, then reopen from a WSL2 terminal with `code src`. |
| **Gazebo spawn service failed** | Don't Ctrl+C — let it fail completely, then close and restart. |
| **`Unable to create file [..]: Filename too long` on clone** | `git config --global core.longpaths true` (step 4). |
| **Dev container is very slow / VS Code feels laggy** | Make sure the repo was cloned inside the WSL2 filesystem (`~/...`), not under `/mnt/c/...`. |
| **I need a real webcam** | `/dev/video0` has no Windows equivalent through Docker Desktop. Attaching a USB camera into WSL2 requires [usbipd-win](https://github.com/dorssel/usbipd-win) first; only then is it worth adding `--device=/dev/video0` to `runArgs`. |
| **The workspace won't rebuild from scratch** | `rm -f cache/humble/build/.built-for` and rebuild the container. That stamp file is what tells `setup.sh` the cache is still valid. |

---

## 💡 How it fits together

Two containers, on a shared Docker network called `ros`:

- **the dev container** — ROS 2, Gazebo, your code. Draws on `DISPLAY=novnc:0.0`, which is the
  *other* container, not your PC.
- **the noVNC container** (`theasp/novnc`) — runs the X server and serves it to your browser on
  port 8080. Started automatically by `start_vnc.sh` via `initializeCommand`.

Other things worth knowing:

- Default user inside container: `team`
- Once you are inside WSL2, everything behaves exactly as on the `linux` branch — Docker Desktop
  always mediates through a Linux VM, so no command in this repo needed a Windows variant
- Your `src/` folder is mounted at `/home/ros2_ws/src`, and `cache/humble/{build,install,log}`
  at the matching workspace directories — so builds survive container rebuilds
- The image is pulled, not built locally:
  `ghcr.io/cobot-maker-space/robotlab-devcontainer-windows`. It is published by
  `.github/workflows/build-image.yml` — see [`decision.md`](decision.md)
- Includes Navigation2, SLAM Toolbox, Teleop, Gazebo + plugins, Cartographer, RViz2
- VS Code extensions preinstalled for ROS, C++, Python, and Git integration
