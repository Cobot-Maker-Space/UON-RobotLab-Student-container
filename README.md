# UON-RobotLab-Student-container

A Docker-based ROS 2 Humble development container for TurtleBot3 simulation, with GUI access
via noVNC in the browser — so students don't need a local ROS/Gazebo install to get started.

There is no OS-agnostic setup: pick the branch that matches your machine and follow the README
on that branch.

| Your machine | Branch | Image it pulls | Platform |
|---|---|---|---|
| Windows (via WSL2 + Docker Desktop) | [`windows`](../../tree/windows) | `ghcr.io/cobot-maker-space/robotlab-devcontainer-windows` | `linux/amd64` |
| Linux | [`linux`](../../tree/linux) | `ghcr.io/cobot-maker-space/robotlab-devcontainer-linux` | `linux/amd64` |
| macOS (Apple Silicon) | [`macos`](../../tree/macos) | `ghcr.io/cobot-maker-space/robotlab-devcontainer-macos` | `linux/arm64` |

```bash
git clone --branch <windows|linux|macos> --single-branch https://github.com/Cobot-Maker-Space/UON-RobotLab-Student-container.git
```

Then open the **`src/` directory** in VS Code — that is where `.devcontainer` lives — and run
**Dev Containers: Reopen in Container**. Everything else, including starting noVNC, happens
automatically. The branch README covers the rest.

## Building and publishing the images

Each OS branch has its own `.github/workflows/build-image.yml`, targeting its own GHCR package
and CPU architecture. To publish: **Actions → Build dev container image → Run workflow**, and set
**Use workflow from** to the branch you want.

The copy of that workflow on `main` builds nothing — it exists only because GitHub hides the
**Run workflow** button entirely unless a `workflow_dispatch` workflow with that path exists on
the default branch. Dispatching it from `main` fails immediately with a message telling you to
pick a branch.

For a block-by-block walkthrough of what the real workflow does and how to run it, read the
`decision.md` on the branch you care about — see [`decision.md`](decision.md) here for the index.
