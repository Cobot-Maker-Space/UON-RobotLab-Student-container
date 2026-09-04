# 📘 `build-image.yml` explained, block by block — macOS branch

**What this is:** a walkthrough of `.github/workflows/build-image.yml` **as it exists on this
`macos` branch** - what it publishes, why it's built the way it is, and exactly how to run it.
Each OS branch (`windows`, `linux`, `macos`) carries its own copy of this workflow, tuned for that
OS; this file documents the `macos` branch's copy specifically. If you're comparing branches,
the shape is identical everywhere - only `IMAGE_BASENAME`, `platforms`, and a couple of smoke-test
details change.

**Who it is for:** someone who has not written CI before, who needs to understand not just *what*
each block does but *why it is there*, well enough to defend it in a review - and who wants to
actually click the button and run it without guessing.

Read Part 1 if "workflow", "runner" and "action" are new words. Skip to Part 3 if they aren't. If
you just want to run this thing right now, skip straight to Part 4.

---

## Part 0 — What changed on this branch (and why this file was rewritten)

This branch used to have a `build-image.yml` copied verbatim from a different, older project of
mine with a similar setup. That original file assumed three things that were not true here:

1. **That `devcontainer.json` pulls a prebuilt image via an `"image"` field.** This repo's
   `devcontainer.json` instead had a `"build"` block (a local `Dockerfile` build) with an unused
   `BASE_IMAGE` arg - the Dockerfile's `FROM` line was hardcoded and silently ignored it. Both are
   now fixed: the Dockerfile takes `ARG BASE_IMAGE` properly, and `devcontainer.json` on this
   branch now has an `"image"` field pointing at what this workflow publishes.
2. **That the image bakes a fully-compiled ROS workspace into `/home/ros2_ws`.** This repo instead
   bind-mounts the host's `src/` folder and `cache/humble/{build,install,log}` over that same
   path (see `devcontainer.json`'s `mounts`), and builds the workspace at *container-creation*
   time via `postCreateCommand` → `setup.sh`. A baked-in workspace would be immediately shadowed
   by those mounts, so it's not something this workflow tries to do. What it publishes instead is
   a **base image**: ROS 2 Humble, the Gazebo/Nav2/RViz apt packages, and `setup.sh` - nothing
   from `src/` at all. Students still get one `colcon build` at first container creation; after
   that `setup.sh` builds incrementally, so a container rebuild is seconds rather than minutes.
   What they skip entirely is the ~10 minute apt-get-everything step that used to happen on every
   local `docker build`.

3. **That `context: .` (the repository root) was a safe default.** It was not: the Dockerfile does
   `COPY setup.sh`, which resolves relative to the build context, and there is no `setup.sh` at the
   repository root. Every run would have failed at that line. The context is now
   `src/.devcontainer`, which is both correct and a far smaller upload.

Everything below documents the workflow **as it now stands** on this branch - not the file it was
copied from.

---

## Part 0.5 — The 60-second version

The workflow does five useful things, in order:

1. Works out **what image name and tag** it is about to publish:
   `ghcr.io/cobot-maker-space/robotlab-devcontainer-macos:<tag>`.
2. **Refuses to run** if that does not match what this branch's `devcontainer.json` pins.
3. Builds the arm64 image on a GitHub-hosted runner, cross-built under QEMU emulation since GitHub's runners are amd64.
4. Pushes it to GHCR (GitHub's container registry).
5. **Pulls it back and smoke-tests it**, to prove the thing it just published actually has ROS,
   Gazebo, and noVNC in it - then reminds you to make the package public.

Step 2 is the one worth defending most. Step 5 is the one that catches a "successful" build that's
actually useless.

---

## Part 1 — The concepts, briefly

| Term | What it means here |
|---|---|
| **GitHub Actions** | GitHub's built-in automation. You commit a YAML file describing a job; GitHub runs it on their machines. |
| **Workflow** | One YAML file under `.github/workflows/`. Every OS branch has its own copy of this same file. |
| **Runner** | The temporary virtual machine your job runs on: `ubuntu-latest`, always amd64 even when the *image being built* targets a different architecture (see the Build and push step in Part 3). It is destroyed after the run - nothing persists except explicit caches. |
| **Job** | A group of steps that run on one runner. We have a single job, `build`. |
| **Step** | One thing in the list: a shell command (`run:`) or a prebuilt component (`uses:`). |
| **Action** | A reusable component someone else wrote, referenced with `uses:`. `actions/checkout@v4` means version 4 of GitHub's official checkout action. |
| **GHCR** | GitHub Container Registry, `ghcr.io`. Where the built image is stored so machines can pull it. |
| **Expression** `${{ ... }}` | Evaluated **by GitHub before the shell ever sees it** - see the security note in Part 3.4. |

One idea that trips everyone up at first: **the runner starts empty every time.** Your repository
is not there until you check it out. Nothing you build survives unless you push it somewhere.

---

## Part 2 — Why this workflow exists at all

Before any of this existed, images were built by hand on a laptop and pushed manually, which is
exactly the kind of process that produces a tag mismatch nobody notices until a whole room of
students hits `manifest unknown` at the same time: the registry has one tag, `devcontainer.json`
pins a different (or nonexistent) one, and nothing ever checked that the two agreed.

**So this workflow is not really about automation. It is about making that mismatch structurally
impossible**, and about not needing a local macOS apt-get-everything build before you can even
open the devcontainer. That is the argument to lead with if anyone asks why this exists.

---

## Part 3 — The file, block by block

### 3.1 `name:`

```yaml
name: Build dev container image (macOS / arm64)
```

The label shown in the Actions tab, and how you'll tell this branch's run apart from the other two
OS branches' runs when several show up in the same Actions history.

### 3.2 `on:` — what makes it run

Two triggers, and **notably not a third**:

| Trigger | Fires when |
|---|---|
| `workflow_dispatch` | You click **Run workflow** in the Actions tab and fill in the form (`inputs: tag`, `inputs: push_latest`). |
| `push: tags: "humble-sim-*"` | Someone pushes a git tag matching that pattern, **on a commit that's on this branch**. |
| ~~`push: branches:`~~ | **Absent on purpose.** Pushing a commit to `macos` publishes nothing by itself. |

**Why no branch trigger?** This job takes real time and publishes something students pull directly.
Publishing on every commit would mean an unfinished edit could silently become what someone
downloads. Publishing must be a deliberate act.

**A gotcha worth knowing:** `workflow_dispatch` only shows a **Run workflow** button in the Actions
tab if a workflow file with this path exists on the repository's **default branch** (`main`). `main`
carries its own copy of this file for exactly that reason - the button doesn't care what's in
main's copy, it just needs a file to exist there. When you actually dispatch, use the **"Use
workflow from"** dropdown to pick `macos` - GitHub then runs *that branch's* copy of this file,
not main's. Picking the wrong branch there is the single most common way to get a confusing result
(see Part 5).

### 3.3 `env:` — values used across the job

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_BASENAME: robotlab-devcontainer-macos
```

The org is `Cobot-Maker-Space` with capitals, but GHCR rejects uppercase in image names, so the
owner gets lowercased at runtime in step 3.5 rather than hardcoded here.

### 3.4 `jobs:` — the runner and its permissions

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
```

Every run gets an automatic, short-lived credential called `GITHUB_TOKEN`. This block narrows what
it may do: read the repo, publish packages, nothing else. Even a compromised build script couldn't
use this token to touch the repo itself or any other repo.

> ⚠️ **Security note on `${{ }}`.** Expressions are substituted by GitHub into the script *as
> text* before bash ever runs. Untrusted text turned into `run:` blocks unmodified is the most
> common Actions vulnerability. Every expression in this file comes from something only a
> collaborator with write access controls (a form they filled in, or a tag they pushed) - never
> from a fork's PR title or similar - so the exposure here is low, but never copy this pattern
> onto a value an outside contributor controls.

### 3.5 Steps 1–3 — checkout, disk space, resolve name/tag

Standard housekeeping, identical across all three branches:

- **Check out repository** (`actions/checkout@v4`) - the runner starts empty; this clones the repo.
- **Free up disk space** - deletes ~20 GB of preinstalled toolchains (.NET, Android SDK, Haskell,
  Boost) the runner ships with but this build never uses, so a ROS+Gazebo image doesn't die
  partway through with "no space left on device".
- **Resolve image name and tag** (`id: meta`) - assembles `ghcr.io/cobot-maker-space/robotlab-devcontainer-macos`
  once, plus the tag (from the dispatch form, or from `GITHUB_REF_NAME` on a tag push), and writes
  them to `$GITHUB_OUTPUT` so later steps can read `steps.meta.outputs.*`. Shell variables don't
  survive between steps - this file-based mechanism is why `id: meta` exists.

### 3.6 Step 4 — Verify devcontainer.json pins the tag being built ⭐

```yaml
- name: Verify devcontainer.json pins the tag being built
  run: |
    PINNED=$(grep -oP '^\s*"image"\s*:\s*"\K[^"]+' src/.devcontainer/devcontainer.json)
    EXPECTED="${{ steps.meta.outputs.image }}:${{ steps.meta.outputs.tag }}"
    if [ "${PINNED}" != "${EXPECTED}" ]; then
      echo "::error::devcontainer.json pins '${PINNED}' but this run publishes '${EXPECTED}'."
      exit 1
    fi
```

**The most important block in the file.** It reads the image name+tag this branch's
`devcontainer.json` actually points students at, compares it to what this run is about to publish,
and **aborts before pushing anything** if they differ. Costs milliseconds; makes a whole-class
`manifest unknown` outage structurally impossible.

This is also *why* `devcontainer.json` on this branch was changed from a `"build"` block to an
`"image"` field as part of the same set of changes that added this workflow - the check has
nothing to grep for otherwise (a `"build"` block has no `"image"` key), and would have failed
every single run.

There's a useful side effect: dispatching from the wrong branch (e.g. `main`, which has no
`"image"` field) fails here, safely, before anything is built or pushed.


### 3.7 Step — Set up QEMU (arm64 only, this branch)

```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3
  with:
    platforms: arm64
```

`ubuntu-latest` runners are amd64. There is no free arm64-hosted GitHub runner, so building for
`linux/arm64` here means cross-building under emulation. This step registers the QEMU binfmt
handlers that let the amd64 runner execute arm64 instructions (slowly) during both the `docker
build` and the later `docker run` smoke-test calls. Skip this step and `platforms: linux/arm64`
below fails outright with no usable binfmt handler.

### 3.8 Steps — Buildx, GHCR login, build and push

```yaml
- uses: docker/setup-buildx-action@v3
- uses: docker/login-action@v3
  with:
    registry: ${{ env.REGISTRY }}
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
- uses: docker/build-push-action@v6
  with:
    context: src/.devcontainer
    file: src/.devcontainer/Dockerfile
    platforms: linux/arm64
    push: true
    tags: |
      ${{ steps.meta.outputs.image }}:${{ steps.meta.outputs.tag }}
      ${{ (github.event_name == 'push' || inputs.push_latest) && format('{0}:latest', steps.meta.outputs.image) || '' }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

No secret to manage: `GITHUB_TOKEN` is generated automatically per run and expires with it, and
`github.actor` is whoever triggered the run. Nothing long-lived to leak or rotate.

**`context: src/.devcontainer`** is the directory the Dockerfile lives in, not the repository
root. This matters more than it looks: the Dockerfile does `COPY setup.sh /usr/local/bin/setup.sh`,
and `COPY` paths are resolved **relative to the build context**, not to the Dockerfile. With the
context at the repository root there is no `setup.sh` to find, and the build fails on that line
every time. Pointing it here also means the upload is four small files rather than the whole repo
including the 212 MB `cache/` directory - which is why there is no longer a `.dockerignore`; there
is nothing left for it to exclude.

**`platforms: linux/arm64`** - Apple Silicon Macs are arm64. `osrf/ros:humble-desktop-full` (tried earlier on this branch) publishes amd64 only, which is why the Dockerfile's base was moved back to `ros:humble` - the one official ROS image with a real arm64 manifest. Building for the wrong architecture here doesn't fail
loudly; it produces an image that pulls fine and then fails to *run* on the target machine, which
is a much worse debugging experience. See the other branches for their own targets:
windows and linux (both amd64, no QEMU needed).

**`cache-from`/`cache-to: type=gha`** - Docker layers cached in GitHub's cache between runs.
`mode=max` caches intermediate layers too, so a change near the end of the Dockerfile doesn't
force a full apt-get rebuild.

### 3.9 Step — Smoke test the published image ⭐

```yaml
- name: Smoke test the published image
  run: |
    IMAGE="${{ steps.meta.outputs.image }}:${{ steps.meta.outputs.tag }}"
    docker pull "$IMAGE"
    echo "--- core ROS packages resolve? ---"
    docker run --rm --platform linux/arm64 "$IMAGE" bash -lc 'source /opt/ros/humble/setup.bash && ros2 pkg prefix navigation2 && ros2 pkg prefix slam_toolbox'

    echo "--- gazebo baked in, not apt-installed at runtime? ---"
    docker run --rm --platform linux/arm64 "$IMAGE" bash -lc 'source /opt/ros/humble/setup.bash && ros2 pkg prefix gazebo_ros' \
      || echo "::warning::gazebo_ros did not resolve on arm64 - falls back to the runtime apt-get in setup.sh"

    echo "--- X client tooling present? ---"
    docker run --rm --platform linux/arm64 "$IMAGE" bash -lc 'command -v xeyes'

    echo "--- setup.sh present and executable? ---"
    docker run --rm --platform linux/arm64 "$IMAGE" test -x /usr/local/bin/setup.sh

    echo "--- workspace writable by the 'team' user? ---"
    docker run --rm --platform linux/arm64 "$IMAGE" bash -lc 'touch /home/ros2_ws/build/.write-test && rm /home/ros2_ws/build/.write-test'
```

Pulls the image **back from the registry** - not the local build cache - and checks five things
that would otherwise only be discovered by a student:

| Check | The disaster it catches |
|---|---|
| `navigation2` / `slam_toolbox` resolve | The apt-get step silently failed or a package was renamed upstream; the "ROS install" is missing the packages this repo actually needs. |
| `gazebo_ros` resolves | Gazebo Classic's arm64 packaging is known to be flaky, so this check is a warning, not a hard failure (see setup.sh, which apt-get-installs it at runtime as a fallback). |
| `xeyes` present | The X client tooling didn't make it into the image. `xeyes` is also the one-line check a student can run to prove the noVNC display is reachable, so it needs to be there. |
| `/usr/local/bin/setup.sh` present and executable | `postCreateCommand` (`bash /usr/local/bin/setup.sh`) would fail for every single student at container creation. |
| `/home/ros2_ws` writable by `team` | The workspace directories were created root-owned, so the very first `colcon build` dies on a permission error. This one had actually regressed once. |

The general principle: **an image that builds is not the same as an image that works.** These
checks are the difference between finding out here and finding out in a classroom.

### 3.10 Step — Remind about package visibility

Writes a note to the run's summary page (`$GITHUB_STEP_SUMMARY`): new GHCR packages are **private**
by default. A private package means every machine needs `docker login` before it can pull -
a failure that looks like a networking problem and isn't. Includes a copy-pasteable anonymous-pull
check using the package name from step 3.5.

---

## Part 4 — How to run this, specifically, on `macos`

**Manually (normal case):**

1. GitHub → **Actions** tab → **Build dev container image (macOS / arm64)** in the
   left sidebar.
2. Click **Run workflow**.
3. **Use workflow from:** the dropdown - pick **`macos`**. This is the step people get wrong;
   picking `main` here runs main's copy of this file against main's `devcontainer.json`, which has
   no `"image"` field and will fail step 3.6 immediately (safely - nothing gets published).
4. **tag:** type the tag exactly as it appears in `macos`'s `src/.devcontainer/devcontainer.json`
   `"image"` field, e.g. `humble-sim-2026-09`. If it doesn't match, step 3.6 stops the run and
   tells you both values.
5. **push_latest:** leave checked to also move `robotlab-devcontainer-macos:latest`, or uncheck to publish
   only the dated tag.
6. Click the green **Run workflow** button, then watch step 3.6 first - it fails in seconds if
   something is out of sync, well before the arm64 build even starts.

**What this actually does, end to end:** builds an arm64 image containing ROS 2 Humble, the
navigation/SLAM/teleop/Gazebo packages, and `setup.sh`, from `src/.devcontainer/Dockerfile`
at whatever's currently committed on `macos`; pushes it to
`ghcr.io/cobot-maker-space/robotlab-devcontainer-macos` under the tag you typed (and `:latest` if ticked);
pulls it back and runs the five smoke-test checks above against the *published* image; and posts a
visibility reminder to the run summary. It does **not** touch `devcontainer.json`, does not touch
any other branch, and does not deploy anything to a machine - see Part 7.

**By tag push (alternative, needs nothing on `main`):**

```bash
git tag humble-sim-2026-09 macos
git push origin humble-sim-2026-09
```

To re-run after a fix you must delete and re-push the tag:

```bash
git push origin :refs/tags/humble-sim-2026-09
git tag -d humble-sim-2026-09
```

**Afterwards (first publish only):** set the package visibility to Public - GitHub → the org's
Packages tab → `robotlab-devcontainer-macos` → Package settings → Change visibility. Then verify anonymous
pull:

```bash
R=cobot-maker-space/robotlab-devcontainer-macos
T=$(curl -s "https://ghcr.io/token?scope=repository:$R:pull&service=ghcr.io" | jq -r .token)
curl -s -H "Authorization: Bearer $T" "https://ghcr.io/v2/$R/tags/list"
```

Expect a tag list back. `denied` means it's still private.

---

## Part 5 — Reading a failure

| Step that failed | Almost certainly |
|---|---|
| Verify devcontainer.json pins... | The tag you typed ≠ the pin in `macos`'s `devcontainer.json`, **or** you dispatched from the wrong branch in step 3 of Part 4 (e.g. `main`, which has no `"image"` field at all). The log prints both values - compare them. |
| Free up disk space / Build | Out of disk. Check the `df -h` output in the log. |
| Set up QEMU / Build, arm64-related | Emulated arm64 builds are slow and occasionally flaky under QEMU. Re-run once; if it keeps failing, check whether the failing apt package has an arm64 build at all. |
| Build and push, `denied` | Permissions. Check `packages: write` is still in the `permissions:` block. |
| Build, an `apt-get` line | An upstream package changed or a mirror was down. Re-run once before assuming it's a real regression. |
| Smoke test, ROS packages | The apt-get step actually failed silently, or a package was renamed upstream. |
| Smoke test, `gazebo_ros` | Expected sometimes on arm64 - this is a warning, not a failure, on this branch. setup.sh apt-get-installs Gazebo at container creation as a fallback if the image build didn't get it. |
| Smoke test, X client tooling | `x11-apps` was removed or renamed in the Dockerfile without updating this check (or vice versa). |
| Smoke test, workspace writable | The `mkdir -p` + `chown -R` of `/home/ros2_ws` was dropped from the Dockerfile, or moved after `USER $USERNAME`. |
| Smoke test, `setup.sh` | The `COPY setup.sh /usr/local/bin/setup.sh` line in the Dockerfile was changed or removed. |
| Build, `"/setup.sh": not found` | The build context was moved back to the repository root. `COPY` resolves against the context - see Part 3.8. |

---

## Part 6 — Decisions you may be asked to defend

**"Why not build on a laptop and push? It worked before."**
It's exactly what produced the original `manifest unknown` outage this whole approach exists to
prevent: two things (the registry tag, the `devcontainer.json` pin) that have to agree, with
nothing checking that they do. CI adds the tag-vs-pin guard, a smoke test against the *published*
artefact, and no long-lived registry credential sitting on someone's machine.

**"Why publish a base image instead of building locally like before?"**
The apt-get-everything step (ROS, navigation2, SLAM, Gazebo, a full desktop, noVNC) took real time
on every fresh clone. Doing it once in CI and publishing the result means a student's first
`docker pull` replaces that with a download.

**"Why not bake the compiled turtlebot3 workspace into the image too, like the other project's
image does?"**
Because this repo's `devcontainer.json` bind-mounts the host `src/` and `cache/humble/` directly
over `/home/ros2_ws/{src,build,install,log}`. A workspace baked into the image at that path would
be immediately shadowed by those mounts the moment the container starts - you'd pay the CI time
and image-size cost and get nothing for it. The workspace build stays where it already worked:
`postCreateCommand` → `setup.sh`, at container creation, with `cache/humble/` in the repo keeping
it fast after the first run. `setup.sh` stamps that cache with the architecture it was built for
and only clears it on a mismatch, so an amd64 cache can't quietly corrupt an arm64 build.

**"Why does publishing need a manual click, or a deliberately pushed tag?"**
Because the artefact is pulled by everyone using this branch. Automatic publishing on every commit
would let an unfinished edit silently become what someone downloads. Deliberate action is the
safety property, not an inconvenience.

**"Why arm64 only?"**
Apple Silicon Macs are arm64. `osrf/ros:humble-desktop-full` (tried earlier on this branch) publishes amd64 only, which is why the Dockerfile's base was moved back to `ros:humble` - the one official ROS image with a real arm64 manifest. Building the wrong architecture wouldn't fail the build - it would produce an image
that pulls fine and then doesn't run, which is worse to debug than a build failure.

**"Are the smoke tests not overkill?"**
Every one of them corresponds to something that has actually gone wrong here: an image that built
cleanly but had no `setup.sh` in it, and a workspace whose directories were root-owned so the first
`colcon build` failed on permissions. Five `docker run` commands is a very cheap insurance premium
against finding either out in front of a class.

---

## Part 7 — What this workflow does *not* do

- **It does not set package visibility.** First publish is private; a human must change it. The
  workflow can only remind you (step 3.10).
- **It does not update `devcontainer.json`.** It only checks the pin (step 3.6). Moving to a new
  tag is a deliberate, separate commit.
- **It does not bake a compiled workspace into the image.** See Part 0 and Part 6 - that build
  still happens at container-creation time via `setup.sh`.
- **It does not deploy anything to a machine.** Publishing an image and a student actually pulling
  it via VS Code's Dev Containers extension are separate steps.
- **It does not build any architecture other than arm64** on this branch. See windows and linux (both amd64, no QEMU needed)
  for the others.
- **It does not touch any other branch's image or workflow.** Each OS branch publishes to its own,
  differently-named GHCR package.

---

## Glossary

| Term | Meaning |
|---|---|
| **Runner** | The throwaway VM a job runs on. Always `ubuntu-latest`/amd64 here, even for the arm64 build on this branch. |
| **`uses:`** | Run a prebuilt action written by someone else. |
| **`run:`** | Run shell commands. Uses `bash -e`, so a failing command aborts the step. |
| **`GITHUB_TOKEN`** | An automatic, short-lived credential scoped by the `permissions:` block. |
| **`$GITHUB_OUTPUT`** | A file a step writes `key=value` into so later steps can read `steps.<id>.outputs.<key>`. |
| **`$GITHUB_STEP_SUMMARY`** | A file whose Markdown is rendered on the run summary page. |
| **`::error::` / `::warning::`** | Workflow commands; GitHub renders the line as a red or yellow annotation on the run. |
| **Build context** | The files sent to the Docker builder, and what `COPY` paths resolve against. Here `src/.devcontainer/`. |
| **Buildx / BuildKit** | Docker's modern builder. Needed for the layer caching used here (and, on this branch, cross-arch emulation via QEMU). |
| **Layer cache (`type=gha`)** | Docker layers stored in GitHub's cache between runs, so unchanged steps aren't rebuilt. |
| **GHCR** | GitHub Container Registry, `ghcr.io`. New packages are private by default. |
| **`manifest unknown`** | Registry-speak for "that tag does not exist". The failure step 3.6 exists to prevent. |
