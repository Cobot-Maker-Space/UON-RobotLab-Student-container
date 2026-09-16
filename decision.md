# 📘 Why the macOS branch runs the amd64 image under Rosetta

**What this is:** the reasoning behind how the `macos` branch gets its dev container image, and
what to do when a new image is published. For the block-by-block walkthrough of the image build
workflow itself, read [`decision.md` on the `linux` branch](../../blob/linux/decision.md) — that
is the workflow Macs now depend on.

---

## Part 1 — The 60-second version

- The `macos` branch **publishes no image**. Its `devcontainer.json` pins
  `ghcr.io/cobot-maker-space/robotlab-devcontainer-linux`, the **amd64** image built from the
  `linux` branch.
- On an Apple Silicon Mac, Docker Desktop runs that image under **Rosetta** (Apple's x86-64
  translator). On an Intel Mac it runs natively.
- Two settings in this branch make that work: `"--platform=linux/amd64"` in `runArgs`, and
  `pull_image.sh`, called from `initializeCommand`, which pulls the image with that platform
  before VS Code looks for it.
- The price is speed: everything in the container, Gazebo included, runs translated. The benefit is
  that Mac students get exactly the same image, simulator and launch files as Windows and Linux
  students.

---

## Part 2 — What went wrong with a native arm64 image

This branch originally built its own `linux/arm64` image with the same Dockerfile as the other
branches, cross-built under QEMU on GitHub's amd64 runners. That build failed:

```
process "/bin/sh -c apt-get update && apt-get install -y ... ros-humble-gazebo-ros-pkgs
ros-humble-gazebo-plugins ..." did not complete successfully: exit code: 100
```

Exit code 100 is `apt-get` saying a package could not be installed. Checking the published arm64
package indexes directly shows why:

| Source | Gazebo Classic on arm64 (Ubuntu 22.04 "jammy")? |
|---|---|
| ROS 2 apt repo, `packages.ros.org` | ❌ `ros-humble-gazebo-ros-pkgs` and `ros-humble-gazebo-plugins` do not exist for arm64 (all 28 `ros-humble-gazebo*` packages exist for amd64) |
| Ubuntu ports, `jammy` main + universe | ❌ no `gazebo` or `libgazebo-dev` |
| Gazebo's own repo, `packages.osrfoundation.org` | ❌ no `gazebo11` or `libgazebo11` |

Every other package in that `apt-get` line **does** exist for arm64. Gazebo Classic is the only
gap — and it is not optional: `src/turtlebot3_simulations/turtlebot3_gazebo/package.xml` declares
`<depend>gazebo_ros_pkgs</depend>`, so even an image built without it would fail at
`colcon build` the first time a student opened the container.

---

## Part 3 — The options that were considered

| Option | Verdict |
|---|---|
| **Run the amd64 image under Rosetta** | ✅ **Chosen.** Same image, simulator and coursework as every other OS. Slower. |
| Native arm64 image without Gazebo | ❌ RViz, Nav2 and `turtlebot3_fake_node` would work, but Mac students would have no simulator. |
| Native arm64 with new Gazebo (Fortress, `ros_gz`, which *does* exist for arm64) | ❌ TurtleBot3's Humble simulation targets Gazebo Classic. Macs would need different worlds, plugins and launch files from everyone else. |
| Build Gazebo Classic from source for arm64 | ❌ Very long, fragile builds under emulation, for a simulator that reached end of life in January 2025. |

---

## Part 4 — How the pieces fit

**`"image"` in `devcontainer.json`** points at `robotlab-devcontainer-linux:<tag>`. That image is
published with one real platform entry, `linux/amd64` (plus a build-attestation entry).

**`pull_image.sh` (via `initializeCommand`).** On Apple Silicon, Docker's default platform is
`linux/arm64`. A plain `docker pull` of an image list that has no arm64 entry fails:

```
no matching manifest for linux/arm64 in the manifest list entries
```

That plain pull is what VS Code runs when the image is missing, so the script pulls it first with
`--platform linux/amd64`. It reads the image name out of `devcontainer.json`, so the tag is only
written once, and it does nothing if the image is already present — starting the container still
works offline.

**`"--platform=linux/amd64"` in `runArgs`.** Without it, `docker run` also looks for an arm64
image and fails.

**`--platform linux/amd64` for noVNC in `start_vnc.sh`.** `theasp/novnc` is also amd64 only. It is
published as a single image rather than a multi-platform list, and Docker on a Mac will usually run
such an image under emulation with only a warning. Asking for the platform explicitly removes that
warning and does not depend on the fallback. Override it with `NOVNC_PLATFORM=...` if ever needed.

**`LIBGL_ALWAYS_SOFTWARE=1`** stays set: Docker Desktop has no GPU passthrough on a Mac, so Gazebo
and RViz render on the CPU either way.

**The build cache** in `cache/humble/` is stamped `x86_64-humble` by `setup.sh`, the same as on
Linux and Windows, because the container really is x86-64.

### How this was tested

On an amd64 Linux machine with `DOCKER_DEFAULT_PLATFORM=linux/arm64`, which makes the Docker CLI
choose images the way it does on Apple Silicon:

- a plain `docker pull` of the image failed with `no matching manifest for linux/arm64` —
  reproducing the problem;
- starting noVNC *without* an explicit platform failed in this simulation (`image ... was found but
  its platform (linux/amd64) does not match the specified platform (linux/arm64)`), which is why
  `start_vnc.sh` on this branch now passes `--platform linux/amd64`;
- with both fixes, the Dev Containers CLI (`devcontainer up`, the same engine the VS Code extension
  uses) ran `initializeCommand`, pulled the image for `linux/amd64`, started the container with
  `--platform=linux/amd64`, and `setup.sh` built all 16 workspace packages;
- a second run of `pull_image.sh` skipped the pull;
- `xeyes` reached the noVNC display, the TurtleBot3 packages resolved in a new shell, and
  `ros2 launch turtlebot3_gazebo empty_world.launch.py` spawned the waffle robot. (The very first
  Gazebo launch in a new container failed with `Spawn service failed` and worked on the next launch —
  the known first-launch issue listed in the README's troubleshooting.)

What could not be tested without a Mac: **Rosetta itself**, and how fast Gazebo is under it.

---

## Part 5 — Publishing a new image for Macs

There is nothing to build on this branch. The `build-image.yml` here is a guard that fails straight
away with instructions, so that choosing **Use workflow from: macos** by mistake cannot publish
anything.

1. Publish from `linux`: **Actions → Build dev container image → Run workflow**, set
   **Use workflow from** to **`linux`**, enter the tag. See the `linux` branch's `decision.md`.
2. If the tag changed, update the `image` field in `src/.devcontainer/devcontainer.json` on
   **this** branch to the same tag, and commit.

Nothing else needs changing: `pull_image.sh` reads the new tag from `devcontainer.json`.

---

## Part 6 — What this branch deliberately does not contain

- **No `Dockerfile` or `setup.sh`.** The container runs the `setup.sh` baked into the linux image
  at `/usr/local/bin/setup.sh`. Copies here would never be used and would drift from the real ones
  on the `linux` branch.
- **No image-building workflow.** See Part 5.
- **No webcam passthrough.** Docker Desktop's VM cannot reach host USB devices, so
  `--device=/dev/video0` is not in `runArgs`.
