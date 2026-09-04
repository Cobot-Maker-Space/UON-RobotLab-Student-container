# 📘 What `build-image.yml` is, and where to read about it

This repo has no single, OS-agnostic devcontainer setup — `windows`, `linux`, and `macos` each
carry their own `src/.devcontainer/` and their own copy of `.github/workflows/build-image.yml`,
tuned for that OS (different published image, different CPU architecture). `main` exists mainly so
the Actions tab's **Run workflow** button appears at all — `workflow_dispatch` only shows up if a
workflow file with this path exists on the default branch — but the actual build always runs
whichever branch you pick in the **"Use workflow from"** dropdown, not `main`.

The copy of `build-image.yml` sitting on `main` used to be a leftover from before these branches
existed: copied from a different, older project with a similar setup, targeting a GHCR package
name (`windows-robot-simulation`) that isn't any of the three OS branches' packages, and expecting
an `"image"` field in `devcontainer.json` that `main` doesn't have. It has been replaced with a
short guard workflow that does nothing but fail with a clear message naming the three branches —
the button still appears, the inputs still render, and nobody gets a build that silently targets
the wrong package.

**For an actual walkthrough of the workflow — block by block, what it publishes, and exactly how
to run it — read the `decision.md` on the branch you care about:**

| Branch | What it targets | Publishes | `decision.md` |
|---|---|---|---|
| [`windows`](../../tree/windows) | amd64, via WSL2 + Docker Desktop | `robotlab-devcontainer-windows` | [`decision.md` on `windows`](../../blob/windows/decision.md) |
| [`linux`](../../tree/linux) | amd64, native Docker | `robotlab-devcontainer-linux` | [`decision.md` on `linux`](../../blob/linux/decision.md) |
| [`macos`](../../tree/macos) | arm64, Apple Silicon | `robotlab-devcontainer-macos` | [`decision.md` on `macos`](../../blob/macos/decision.md) |

Each of those documents its branch's specific image name, why it targets the CPU architecture it
does, and a step-by-step "how to run this, specifically, on `<branch>`" section (which button,
which dropdown selection, what tag to type, what publishing actually does and doesn't do).

## A note on `ghcr.io/cobot-maker-space/windows-robot-simulation`

That package already exists and is public, but it was published by a **different** repository's
workflow. It is `linux/amd64` only, and it bakes a fully-compiled ROS workspace into
`/home/ros2_ws` — which this repo's `devcontainer.json` immediately shadows with bind mounts from
the host. It works as a stopgap on the `windows` and `linux` branches; it cannot work on `macos`,
which needs arm64. Nothing in this repo can rebuild or retag it, which is why each branch
publishes its own package instead.
