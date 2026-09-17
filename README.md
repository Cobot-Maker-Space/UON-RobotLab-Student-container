# 🐢 TurtleBot Desktop Development Container (with noVNC) — macOS Edition

This branch gives you a ready-to-use **ROS 2 Humble development environment** on a **Mac**, for
TurtleBot3 simulation and development. You do not install ROS, Gazebo or RViz on your Mac yourself —
they all live inside a Docker container, and their windows appear in your web browser.

It works on **both Apple Silicon (M1/M2/M3/M4) and Intel Macs**.

It includes:
- ROS 2 Humble preinstalled with navigation, SLAM, teleop, Gazebo, and visualization packages
- VS Code Dev Container configuration with useful extensions
- Integrated **noVNC support** so graphical programs (Gazebo, RViz2) show up in your browser
- Persistent build and install caches, so rebuilds are incremental

> ℹ️ **On a different machine?** Use [`windows`](../../tree/windows) (Windows via WSL2) or
> [`linux`](../../tree/linux) (native Linux). Each branch has its own README.

> ℹ️ **Good to know on Apple Silicon:** the container is an Intel (x86-64) Linux container, run
> through Apple's **Rosetta** translation. There is no native Apple Silicon version, because the
> Gazebo simulator this course uses doesn't exist for ARM. Everything works; it is just **slower
> than on a PC**, especially Gazebo. See [`decision.md`](decision.md) for the details.

---

## 📦 What you need

- macOS 13 (Ventura) or newer — **macOS 15 (Sequoia) or newer recommended** on Apple Silicon
- An administrator account on the Mac (to install apps)
- At least **16 GB RAM** recommended (8 GB works, but Gazebo will struggle)
- Roughly **30 GB free disk space**
- An internet connection — the first setup downloads several GB

You will install, in order: **Docker Desktop → Git → VS Code**.

---

## 🔧 One-time setup

### Step 1 — Check which kind of Mac you have

Click the **Apple menu ()** → **About This Mac**.

- **Chip: Apple M1 / M2 / M3 / M4 …** → you have **Apple Silicon**. Follow every step.
- **Processor: … Intel …** → you have an **Intel Mac**. Follow every step, but skip the Rosetta
  parts — they don't apply to you.

---

### Step 2 — Open Terminal

You'll type a few commands in **Terminal**:

1. Press `Cmd` + `Space` to open Spotlight.
2. Type `Terminal` and press `Return`.

A window opens with a prompt ending in `%`, like `yourname@MacBook ~ %`. That's where commands in
this guide go. To paste, use `Cmd` + `V`. To stop a running command, press `Ctrl` + `C`.

---

### Step 3 — Install Rosetta (Apple Silicon only)

In **Terminal**, run:

```bash
softwareupdate --install-rosetta --agree-to-license
```

Enter your Mac password if asked (**nothing appears on screen while you type it — that's normal**).
If it says Rosetta is already installed, that's fine.

---

### Step 4 — Install Docker Desktop

1. Download **Docker Desktop for Mac** from <https://www.docker.com/products/docker-desktop/>.
   Pick **Apple Silicon** or **Intel chip** to match step 1.
2. Open the downloaded `.dmg` and drag **Docker** into **Applications**.
3. Open **Docker** from Applications. Accept the terms and allow the privileged helper when asked.
   You can skip signing in.
4. Click the ⚙️ **Settings** icon (top right) and check:
   - **General** → **Use Rosetta for x86_64/amd64 emulation on Apple Silicon** is **ticked**
     *(Apple Silicon only)*. In newer versions it sits under **Virtual Machine Options**, and
     requires **Apple Virtualization framework** to be selected there.
   - **Resources** → **Memory**: at least **8 GB** if your Mac has 16 GB or more.
   - Click **Apply & restart**.
5. Wait until Docker Desktop shows **Engine running** (bottom left, green).

> ⚠️ **Docker Desktop must be running every time you work on this project.** You'll see the whale
> icon in the menu bar at the top of the screen when it is.

**Check it works** — in **Terminal**, run:

```bash
docker run hello-world
```

You should see `Hello from Docker!`.

**Apple Silicon only — check Rosetta works in Docker:**

```bash
docker run --rm --platform linux/amd64 alpine uname -m
```

It must print `x86_64`. If it prints an error, go back to step 4 and check the Rosetta setting.

---

### Step 5 — Check Git is available

In **Terminal**, run:

```bash
git --version
```

- If it prints a version (e.g. `git version 2.39.5`), you're done.
- If a pop-up asks to install **command line developer tools**, click **Install**, wait for it to
  finish, then run `git --version` again.

---

### Step 6 — Install VS Code and the Dev Containers extension

1. Download **Visual Studio Code** for Mac from <https://code.visualstudio.com/>.
2. Open the download and drag **Visual Studio Code** into your **Applications** folder.
   (Running it straight from Downloads causes problems later.)
3. Open VS Code from Applications.
4. Click the **Extensions** icon on the left bar (four squares), or press `Cmd` + `Shift` + `X`.
5. Search for **Dev Containers** (published by Microsoft) and click **Install**.
6. Install the `code` command, so you can open folders from Terminal:
   press `Cmd` + `Shift` + `P`, type `shell command`, and choose
   **Shell Command: Install 'code' command in PATH**.
7. Quit VS Code (`Cmd` + `Q`).

---

### Step 7 — Clone the repository (Terminal)

In **Terminal**, run these three lines one at a time:

```bash
cd ~
git clone --branch macos --single-branch https://github.com/Cobot-Maker-Space/UON-RobotLab-Student-container.git
cd UON-RobotLab-Student-container
```

Check you're in the right place:

```bash
pwd
```

It should print `/Users/yourname/UON-RobotLab-Student-container`.

> ⚠️ Clone into your home folder as shown, **not** into Desktop, Documents or iCloud Drive. Folders
> synced by iCloud are slow for Docker and can make files vanish mid-build.

---

### Step 8 — Open the project in VS Code (Terminal)

Still in **Terminal**, inside `UON-RobotLab-Student-container`, run:

```bash
code src
```

Open **`src`**, not the whole repository — `src` is where the `.devcontainer` folder lives.

If VS Code asks **"Do you trust the authors of the files in this folder?"**, click
**Yes, I trust the authors**.

---

### Step 9 — Start the dev container (VS Code)

1. A pop-up may appear in the bottom-right: *"Folder contains a Dev Container configuration file"*.
   Click **Reopen in Container**.

   If you don't see it: press `Cmd` + `Shift` + `P`, type `Reopen in Container`, and select
   **Dev Containers: Reopen in Container**.

2. VS Code reloads and shows *Starting Dev Container (show log)*. Click **show log** if you want to
   watch. Automatically, it will:
   1. Run `start_vnc.sh` on your Mac, which creates the `ros` Docker network and starts the noVNC
      container on port 8080
   2. Run `pull_image.sh`, which downloads the ROS 2 image (about 1.5 GB) the first time
   3. Start the dev container on that same `ros` network
   4. Run `setup.sh`, which builds the ROS 2 workspace with `colcon build`

3. **The first time takes a while** — often 15–30 minutes on Apple Silicon, mostly the download and
   the first build running through Rosetta. **Don't close VS Code while it's working.** Later
   starts take seconds to a couple of minutes.

   > You may see *"The requested image's platform (linux/amd64) does not match the detected host
   > platform"*. On Apple Silicon that's **expected and harmless**.

4. When it's finished, the bottom-left box reads **`Dev Container: ROS 2 Development Container`**,
   and the terminal panel reports `=== setup.sh finished successfully ===`.

---

### Step 10 — Open the GUI in your browser

In Safari, Chrome or Firefox, go to:

➡ **<http://localhost:8080/vnc.html>** and click **Connect**.

You'll see an empty (black or grey) desktop. That's expected. **That browser tab is the
container's screen.** Anything graphical you start from the VS Code terminal — Gazebo, RViz2,
`rqt` — shows up **there**, not as a normal window on your Mac.

> 💡 The virtual screen is large. If it doesn't fit, open the noVNC side menu (the small tab on the
> left edge) → ⚙️ **Settings** → **Scaling Mode** → **Local Scaling**.

---

### Step 11 — Test that everything works (VS Code terminal, inside the container)

Open a terminal in VS Code: menu **Terminal → New Terminal** (or `Ctrl` + `` ` ``).
The prompt should look like `team@<letters-and-numbers>:/home/ros2_ws$`.

**a) Display test**

```bash
xeyes
```

A pair of eyes should appear in the browser tab from step 10. Press `Ctrl` + `C` in the terminal to
close it.

**b) ROS 2 test**

```bash
source /opt/ros/humble/setup.bash
ros2 topic list
```

You should see a short list such as `/parameter_events` and `/rosout`.

**c) Simulation test** *(optional)*

Open a **new** terminal (so it picks up the freshly built workspace) and run:

```bash
ros2 launch turtlebot3_gazebo empty_world.launch.py
```

Gazebo with a TurtleBot3 should appear in the browser tab. On Apple Silicon the first launch can
take a couple of minutes, so let it run smoothly without any interrrupts. You would see `Spawn Service failed` 
on first try and then Gazebo would load but without a Robot. Now Press `Ctrl + C` in the terminal and then rerun the command.
It should all be working fine now.

🎉 **Setup is complete.**

---

## 🔁 Every time you work on the project

1. Open **Docker Desktop** and wait for **Engine running**.
2. Open **Terminal** and run:

   ```bash
   cd ~/UON-RobotLab-Student-container
   code src
   ```

3. VS Code usually reopens straight into the container. If it doesn't, press `Cmd` + `Shift` + `P`
   → **Dev Containers: Reopen in Container**.
4. Open <http://localhost:8080/vnc.html> and click **Connect**.

### When you're finished

- Close VS Code. Your files in `src/` stay on your Mac.
- The noVNC container keeps running in the background. To stop it, run in **Terminal**:

  ```bash
  ~/UON-RobotLab-Student-container/src/.devcontainer/start_vnc.sh stop
  ```

- To free up memory completely, quit Docker Desktop from the whale icon in the menu bar.

---

## 🛠 Troubleshooting

Unless a row says otherwise, run the commands in **Terminal**, from inside
`~/UON-RobotLab-Student-container`.

### Docker

| Problem | Solution |
|---|---|
| **`Cannot connect to the Docker daemon`** / **`docker: command not found`** | Docker Desktop isn't running. Open it from Applications and wait for **Engine running**. |
| **`no matching manifest for linux/arm64 in the manifest list entries`** | The image wasn't pulled for the right platform. Run `./src/.devcontainer/pull_image.sh`, then **Dev Containers: Rebuild Container**. |
| **`The requested image's platform (linux/amd64) does not match the detected host platform`** | Expected on Apple Silicon, and harmless. |
| **`docker run --platform linux/amd64 alpine uname -m` fails, or the container crashes with `qemu: uncaught target signal`** | Rosetta isn't being used. Docker Desktop → Settings → turn on **Use Rosetta for x86_64/amd64 emulation on Apple Silicon** → **Apply & restart**. If the option is missing, run step 3 again and update Docker Desktop. |

### VS Code and the container

| Problem | Solution |
|---|---|
| **`code: command not found`** | Do step 6.6 (**Shell Command: Install 'code' command in PATH**), then open a new Terminal window. |
| **`network ros not found` when the container starts** | The noVNC container didn't start. Start it by hand to see the error:<br>`./src/.devcontainer/start_vnc.sh start` |
| **`Operation not permitted`, or files missing inside the container** | The repository is in Desktop, Documents or iCloud Drive. Clone it again into your home folder (step 7). |
| **First build is extremely slow** | Normal on Apple Silicon — it runs through Rosetta. Give Docker more memory and CPUs (Docker Desktop → Settings → **Resources**) and don't let the Mac sleep. |
| **The workspace won't rebuild from scratch** | `rm -f cache/humble/build/.built-for`, then `Cmd` + `Shift` + `P` → **Dev Containers: Rebuild Container**. That stamp file tells `setup.sh` the cache is still valid. |

### Gazebo and the browser GUI (noVNC)

| Problem | Solution |
|---|---|
| **Browser can't open `localhost:8080`** | Check the container: `./src/.devcontainer/start_vnc.sh status`. Restart it: `./src/.devcontainer/start_vnc.sh restart`. |
| **Port 8080 already in use** | Another app is using that port. Quit it, or start noVNC on another port:<br>`HOST_PORT=8081 ./src/.devcontainer/start_vnc.sh restart`<br>then open `http://localhost:8081/vnc.html`. |
| **Commands run but nothing appears in the browser** | Make sure you clicked **Connect** in noVNC and are running the command in the **VS Code** terminal (prompt starts with `team@`), not the Mac Terminal. |
| **Gazebo is very slow** | Expected on a Mac: no GPU passthrough, so it renders on the CPU (`LIBGL_ALWAYS_SOFTWARE=1`), and on Apple Silicon it also runs through Rosetta. Use small worlds such as `empty_world`, and close other heavy apps. |
| **Gazebo crashes with `Illegal instruction`** | Update macOS (15 Sequoia or newer adds support for more Intel instructions to Rosetta) and update Docker Desktop. |
| **Gazebo spawn service failed** | Don't press `Ctrl` + `C` — let it fail completely, then close it and launch again. |
| **I need a webcam** | Not possible: Docker Desktop on macOS cannot pass USB devices into containers. |

---

## 💡 How it fits together

```
Mac
 ├─ Browser ──► http://localhost:8080 ──────────────┐
 ├─ ~/UON-RobotLab-Student-container   (your files) │
 └─ Docker Desktop (Linux VM, Rosetta for x86-64)   │
     ├─ noVNC container  (theasp/novnc) ◄───────────┘  X server, port 8080
     └─ dev container    (ROS 2, Gazebo)  ──►  draws on DISPLAY=novnc:0.0
          both on the Docker network "ros"
```

Two containers, on a shared Docker network called `ros`:

- **the dev container** — ROS 2, Gazebo, your code. Draws on `DISPLAY=novnc:0.0`, which is the
  *other* container, not your Mac.
- **the noVNC container** (`theasp/novnc`) — runs the X server and serves it to your browser on
  port 8080. Started automatically by `start_vnc.sh` via `initializeCommand`.

Other things worth knowing:

- Default user inside the container: `team`
- **Both containers are x86-64 (amd64).** On Apple Silicon, Docker Desktop runs them through
  Rosetta; on an Intel Mac they run natively. There is no ARM version because Gazebo Classic, which
  the TurtleBot3 Humble simulation needs, isn't published for ARM — see [`decision.md`](decision.md)
- The image is the same one the `linux` branch uses:
  `ghcr.io/cobot-maker-space/robotlab-devcontainer-linux`. `devcontainer.json` pins it with
  `--platform=linux/amd64`, and `pull_image.sh` pulls it for that platform
- Your `src/` folder is mounted at `/home/ros2_ws/src`, and `cache/humble/{build,install,log}`
  at the matching workspace folders — so builds survive container rebuilds. `cache/humble/` starts
  empty in a fresh clone; the first start fills it
- No webcam passthrough: Docker Desktop runs a Linux VM that cannot reach host USB devices, so
  `--device=/dev/video0` is deliberately absent from `runArgs`
- Includes Navigation2, SLAM Toolbox, Teleop, Gazebo + plugins, Cartographer, RViz2
- VS Code extensions preinstalled for ROS, C++, Python, and Git integration
