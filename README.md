# 🐢 TurtleBot Desktop Development Container (with noVNC) — Linux Edition

This branch provides a ready-to-use **Docker-based ROS 2 Humble development environment** for **native Linux** for TurtleBot3 simulation and development.

It includes:
- ROS 2 Humble preinstalled with navigation, SLAM, teleop, Gazebo, and visualization packages
- VS Code Dev Container configuration with useful extensions
- Integrated **noVNC support** for GUI access from your browser
- Persistent build and install caches for faster rebuilds

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
```

---

### 2. Start the noVNC Service

Before opening the devcontainer, make sure the shared Docker network and noVNC service are running.

Run:

```bash
cd ~/UON-RobotLab-Student-container/src/.devcontainer/
./start_vnc.sh start
```

This will:
- Create a `ros` Docker network if it doesn't exist
- Launch a `theasp/novnc:latest` container mapped to `http://localhost:8080`

Once running, open:

➡ **http://localhost:8080/vnc.html** and click **Connect** to access the container's desktop GUI.

---

### 3. Open in VS Code

Launch VS Code → open the `src/` directory → press `Ctrl+Shift+P` → select:

```
Dev Containers: Reopen in Container
```

VS Code will now pull the prebuilt ROS 2 development image and launch it, automatically attaching it to the `ros` network so it can reach the noVNC container.

---

### 4. Test the Setup

Inside the VS Code terminal:

```bash
source /opt/ros/humble/setup.bash
ros2 topic list
```

If ROS 2 is installed correctly, you'll see a list of topics (or an empty list if nothing is publishing).

---

## 🛠 Troubleshooting & Common Issues

| Issue | Solution |
|------|----------|
| **Permission denied: docker** | Add your user to the docker group:<br>`sudo usermod -aG docker $USER && newgrp docker` |
| **Gazebo spawn service failed** | Don't Ctrl+C — let it fail completely, then close and restart. |
| **Cannot connect to noVNC** | Run `./start_vnc.sh status` to check if the container is running. |
| **No webcam / `--device=/dev/video0` fails** | Remove `--device=/dev/video0` and `--group-add=video` from `devcontainer.json`'s `runArgs` if your machine has no `/dev/video0`. |

---

## 💡 Notes

- Default user inside container: `team`
- Workspace is mounted to `/home/ros2_ws/src`
- Network: `ros` (shared between devcontainer and noVNC container)
- GUI apps (RViz2, Gazebo) accessible via **browser** at `http://localhost:8080/vnc.html`
- Includes:
  - Navigation2, SLAM Toolbox, Teleop
  - Gazebo + plugins
  - Cartographer, RViz2
- VS Code extensions preinstalled for:
  - ROS
  - C++
  - Python
  - Git integration
