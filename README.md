# UON-RobotLab-Student-container

A Docker-based ROS 2 Humble development container for TurtleBot3 simulation, with GUI access
via noVNC in the browser — so students don't need a local ROS/Gazebo install to get started.

There is no OS-agnostic setup: pick the branch that matches your machine and follow the README
on that branch.

| Your machine | Branch |
|---|---|
| Windows (via WSL2 + Docker Desktop) | [`windows`](../../tree/windows) |
| Linux | [`linux`](../../tree/linux) |
| macOS (Apple Silicon / arm64) | [`macos`](../../tree/macos) |

```bash
git clone --branch <windows|linux|macos> --single-branch https://github.com/Cobot-Maker-Space/UON-RobotLab-Student-container.git
```

Each branch publishes its own prebuilt image via `.github/workflows/build-image.yml` (Actions
tab → **Run workflow**, then pick the branch you want to build/publish from — this file only
needs to exist here on `main` for that button to appear at all).
