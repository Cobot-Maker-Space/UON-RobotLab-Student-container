# 📘 What `build-image.yml` is, and where to read about it

This repo has no single, OS-agnostic devcontainer setup — `windows`, `linux`, and `macos` each
carry their own `src/.devcontainer/` and their own copy of `.github/workflows/build-image.yml`,
tuned for that OS (different published image, different CPU architecture). `main` exists mainly so
the Actions tab's **Run workflow** button appears at all — `workflow_dispatch` only shows up if a
workflow file with this path exists on the default branch — but the actual build always runs
whichever branch you pick in the **"Use workflow from"** dropdown, not `main`.

The copy of `build-image.yml` sitting on `main` is a leftover from before these branches existed:
it was copied from a different, older project of mine with a similar setup, targets a GHCR package
name (`windows-robot-simulation`) that isn't any of the three OS branches' actual packages, and
expects an `"image"` field in `devcontainer.json` that `main` doesn't have. Dispatching it from
`main` fails safely at the "verify pin" step — nothing gets built or published — which is by
design (see each branch's own `decision.md` for why that check exists). It's left as-is here
rather than rewritten, since `main` doesn't publish anything itself.

**For an actual walkthrough of the workflow — block by block, what it publishes, and exactly how
to run it — read the `decision.md` on the branch you care about:**

| Branch | What it targets | `decision.md` |
|---|---|---|
| [`windows`](../../tree/windows) | amd64, via WSL2 + Docker Desktop | [`decision.md` on `windows`](../../blob/windows/decision.md) |
| [`linux`](../../tree/linux) | amd64, native Docker | [`decision.md` on `linux`](../../blob/linux/decision.md) |
| [`macos`](../../tree/macos) | arm64, Apple Silicon | [`decision.md` on `macos`](../../blob/macos/decision.md) |

Each of those documents its branch's specific image name, why it targets the CPU architecture it
does, and a step-by-step "how to run this, specifically, on `<branch>`" section (which button,
which dropdown selection, what tag to type, what publishing actually does and doesn't do).
