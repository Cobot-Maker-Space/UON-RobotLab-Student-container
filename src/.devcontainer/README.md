# `.devcontainer` — Linux branch

Setup instructions live in the [repository README](../../README.md). This file used to be a
verbatim copy of it, which meant the two drifted apart; it is a pointer now so there is only ever
one set of instructions to keep correct.

## What is in here

| File | What it does | Runs where |
|---|---|---|
| `devcontainer.json` | The dev container definition VS Code reads: which image to pull, what to mount, what environment ROS sees. | VS Code, on your machine |
| `Dockerfile` | Builds the image that `devcontainer.json` pins. Not built locally — CI builds and publishes it, see [`decision.md`](../../decision.md). | GitHub Actions |
| `setup.sh` | `postCreateCommand`. Clones any missing turtlebot3 packages and runs `colcon build`. Incremental after the first run. | Inside the container |
| `start_vnc.sh` | Creates the `ros` Docker network and starts the noVNC container. Called automatically by `initializeCommand`; also usable by hand. | On your machine |

## start_vnc.sh by hand

```bash
./start_vnc.sh start     # create the network + start noVNC
./start_vnc.sh status    # is it running?
./start_vnc.sh restart   # stop, then start
./start_vnc.sh stop      # remove the container
```

Override the defaults with environment variables, e.g. `HOST_PORT=8081 ./start_vnc.sh restart`
if something else already owns port 8080.
