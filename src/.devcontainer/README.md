# `.devcontainer` — macOS branch

Setup instructions live in the [repository README](../../README.md). This file is only a map of
what is in this folder.

## What is in here

| File | What it does | Runs where |
|---|---|---|
| `devcontainer.json` | The dev container definition VS Code reads: which image to pull, what to mount, what environment ROS sees. Pins the amd64 image from the `linux` branch with `--platform=linux/amd64` — see [`decision.md`](../../decision.md). | VS Code, on your Mac |
| `start_vnc.sh` | Creates the `ros` Docker network and starts the noVNC container. Called automatically by `initializeCommand`; also usable by hand. | On your Mac |
| `pull_image.sh` | Pulls the image pinned in `devcontainer.json` for `linux/amd64` if it isn't already present. On Apple Silicon a plain pull fails with `no matching manifest for linux/arm64`. Called automatically by `initializeCommand`. | On your Mac |

There is no `Dockerfile` or `setup.sh` on this branch. The container runs the `setup.sh` baked into
the image; both files live on the `linux` branch, which builds and publishes that image.

## start_vnc.sh by hand

```bash
./start_vnc.sh start     # create the network + start noVNC
./start_vnc.sh status    # is it running?
./start_vnc.sh restart   # stop, then start
./start_vnc.sh stop      # remove the container
```

Override the defaults with environment variables, e.g. `HOST_PORT=8081 ./start_vnc.sh restart`
if something else already owns port 8080.

## pull_image.sh by hand

```bash
./pull_image.sh          # pulls the pinned image for linux/amd64, or does nothing if present
```
