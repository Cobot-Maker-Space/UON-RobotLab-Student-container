# UON-RobotLab-Student-container

A Docker-based ROS 2 Humble development container for TurtleBot3 simulation, with GUI access
via noVNC in the browser — so students don't need a local ROS/Gazebo install to get started.

**This `main` branch contains no container.** It is only this landing page and the workflow
entry point. Pick the branch that matches your machine and follow the README on that branch.

| Your machine | Branch | Image it pulls | Platform |
|---|---|---|---|
| Windows (via WSL2 + Docker Desktop) | [`windows`](../../tree/windows) | `ghcr.io/cobot-maker-space/robotlab-devcontainer-windows` | `linux/amd64` |
| Linux | [`linux`](../../tree/linux) | `ghcr.io/cobot-maker-space/robotlab-devcontainer-linux` | `linux/amd64` |
| macOS (Apple Silicon) | [`macos`](../../tree/macos) | `ghcr.io/cobot-maker-space/robotlab-devcontainer-macos` | `linux/arm64` |

> ⚠️ **Windows users: stop here and open the [`windows` branch README](../../tree/windows).**
> Do **not** run the command below in PowerShell, Command Prompt or GitHub Desktop. On Windows the
> clone must happen inside an Ubuntu (WSL2) terminal, and that README walks you through every step
> from installing WSL onwards. Cloning any other way stops the container from starting.

```bash
git clone --branch <windows|linux|macos> --single-branch https://github.com/Cobot-Maker-Space/UON-RobotLab-Student-container.git
```

After cloning one of those branches, open its **`src/` directory** in VS Code — that is where
`.devcontainer` lives — and run **Dev Containers: Reopen in Container**. Everything else, including
starting noVNC, happens automatically. The branch README covers the rest.

> ℹ️ A plain `git clone` without `--branch` gives you `main`, which has nothing to run. Always pass
> `--branch`.

## For maintainers

`main` is deliberately kept to `README.md`, `decision.md` and `.github/workflows/build-image.yml`.
**Never merge `main` into `windows`, `linux` or `macos`** (it would delete their `src/` and
`cache/`), and **never merge those branches into `main`** (it would bring everything back).
Each OS branch is maintained independently.

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
