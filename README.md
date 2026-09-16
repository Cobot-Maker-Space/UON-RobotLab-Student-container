# 🐢 TurtleBot Desktop Development Container (with noVNC) — Windows Edition

This branch gives you a ready-to-use **ROS 2 Humble development environment** on **Windows**, for
TurtleBot3 simulation and development. You do not install ROS, Gazebo or RViz on Windows yourself —
they all live inside a Docker container, and their windows appear in your web browser.

It includes:
- ROS 2 Humble preinstalled with navigation, SLAM, teleop, Gazebo, and visualization packages
- VS Code Dev Container configuration with useful extensions
- Integrated **noVNC support** so graphical programs (Gazebo, RViz2) show up in your browser
- Persistent build and install caches, so rebuilds are incremental

> ℹ️ **On a different machine?** Use [`linux`](../../tree/linux) (native Linux) or
> [`macos`](../../tree/macos) (Apple Silicon). Each branch has its own image and its own README.

---

## ⚠️ Read this first: there is exactly one way to do this

Every step below happens in one of three places. The guide always tells you which one.

| Where | What it looks like | Used for |
|---|---|---|
| **PowerShell (Administrator)** | A blue/black window, prompt looks like `PS C:\Windows\system32>` | Step 1 only — installing WSL |
| **Ubuntu terminal** (also called "the WSL2 terminal") | Prompt looks like `yourname@YOUR-PC:~$` | Cloning the repository and opening VS Code |
| **VS Code terminal, inside the container** | Prompt looks like `team@abc123def:/home/ros2_ws$` | Running ROS 2, Gazebo, RViz — your actual coursework |

**Do not** clone the repository with GitHub Desktop, a Windows Git client, or PowerShell, and do not
open the folder with *File → Open Folder* from a VS Code you launched from the Start menu. The
container will not start if you do. Always go through the Ubuntu terminal, exactly as described.

---

## 📦 What you need

- Windows 10 (version 2004 or newer) or Windows 11
- An account with **administrator** rights on the PC (needed once, for step 1)
- At least **8 GB RAM** (16 GB recommended) and roughly **30 GB free disk space**
- An internet connection — the first setup downloads several GB

You will install, in order: **WSL2 + Ubuntu → Docker Desktop → VS Code**.

---

## 🔧 One-time setup

### Step 1 — Check that virtualization is enabled

WSL2 and Docker both need hardware virtualization.

1. Press `Ctrl` + `Shift` + `Esc` to open **Task Manager**.
2. Click the **Performance** tab, then **CPU** on the left.
3. Look for **Virtualization** in the bottom-right: it should say **Enabled**.

If it says **Disabled**, it has to be turned on in your PC's BIOS/UEFI settings (often called
*Intel VT-x*, *Intel Virtualization Technology*, *SVM Mode* or *AMD-V*). How to get into the BIOS
depends on the manufacturer — search for "enable virtualization" plus your laptop model. You cannot
continue until this says Enabled.

---

### Step 2 — Install WSL2 and Ubuntu (PowerShell)

WSL (Windows Subsystem for Linux) runs a real Ubuntu Linux inside Windows. Everything in this
project runs from that Ubuntu.

1. Click the **Start** button and type `PowerShell`.
2. On **Windows PowerShell**, **right-click → Run as administrator**. Click **Yes** when Windows asks
   for permission. The window title should start with *Administrator:*.
3. Type the following and press `Enter`:

   ```powershell
   wsl --install
   ```

4. Wait for it to finish, then **restart your PC** when asked (or restart it anyway).

> 💡 If WSL was already installed and this just prints help text, run
> `wsl --install -d Ubuntu` instead.

---

### Step 3 — First launch of Ubuntu: create your Linux user

After the restart an **Ubuntu** window usually opens on its own. If it doesn't, click **Start**,
type `Ubuntu`, and open it. The first launch takes a minute or two ("Installing, this may take a few
minutes...").

It will then ask:

```
Enter new UNIX username:
```

1. Type a short username — **lowercase, no spaces** (e.g. `alex`) — and press `Enter`.
2. It asks for a **New password**. Type one and press `Enter`.
   **Nothing appears on screen while you type the password — no dots, no stars. That is normal.**
3. Type the same password again to confirm.

**Remember this password.** Ubuntu asks for it whenever a command starts with `sudo`. It does not
have to match your Windows password.

When you see a prompt like this, Ubuntu is ready:

```
alex@YOUR-PC:~$
```

---

### Step 4 — Confirm you are on WSL **2** (PowerShell)

Open PowerShell (a normal one is fine this time) and run:

```powershell
wsl -l -v
```

You should see something like:

```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

The **VERSION** column must be **2**. If it says **1**, run:

```powershell
wsl --set-version Ubuntu 2
```

---

### 📖 How to open an Ubuntu (WSL2) terminal — you'll do this every time

Any of these opens the same Ubuntu:

- **Start menu:** click **Start**, type `Ubuntu`, press `Enter`. *(Easiest.)*
- **Windows Terminal:** open **Terminal**, click the **˅** arrow next to the tab, choose **Ubuntu**.
- **From PowerShell:** type `wsl` and press `Enter`. The prompt changes from `PS C:\...>` to
  `yourname@YOUR-PC:...$`.

**How to tell you're in the right place:** the prompt ends in `$` and contains `@`.
If it starts with `PS`, you're still in PowerShell.

A few basics you'll need in that terminal:

| To do this | Type |
|---|---|
| Go to your Linux home folder | `cd ~` |
| Show which folder you're in | `pwd` |
| List files in the current folder | `ls` |
| Paste text | **Right-click**, or `Ctrl` + `Shift` + `V` (plain `Ctrl` + `V` may not work) |
| Copy selected text | `Ctrl` + `Shift` + `C` |
| Stop a running command | `Ctrl` + `C` |

---

### Step 5 — Install Docker Desktop

1. Download **Docker Desktop for Windows** from
   <https://www.docker.com/products/docker-desktop/> and run the installer.
2. When the installer shows **"Use WSL 2 instead of Hyper-V"**, make sure it is **ticked**.
3. Restart or log out if the installer asks you to.
4. Open **Docker Desktop** from the Start menu. Accept the terms. You can skip signing in.
5. Click the ⚙️ **Settings** icon (top right) and check:
   - **General** → **Use the WSL 2 based engine** is ticked.
   - **Resources → WSL integration** → **Enable integration with my default WSL distro** is ticked,
     **and** the switch next to **Ubuntu** is turned **on**.
   - Click **Apply & restart**.
6. Wait until the bottom-left of Docker Desktop shows **Engine running** (green).

> ⚠️ **Docker Desktop must be running every time you work on this project.** If it's closed,
> nothing below will work. Open it from the Start menu first and wait for *Engine running*.

**Check it works** — open an **Ubuntu terminal** and run:

```bash
docker run hello-world
```

You should see `Hello from Docker!` in the output. If you see an error instead, look at the
Docker rows in [Troubleshooting](#-troubleshooting).

---

### Step 6 — Install VS Code and its extensions

1. Download **Visual Studio Code** from <https://code.visualstudio.com/> and install it **on
   Windows** (not inside Ubuntu). Keep the installer option **Add to PATH** ticked (it is by
   default).
2. Open VS Code, click the **Extensions** icon on the left bar (four squares), or press
   `Ctrl` + `Shift` + `X`.
3. Search for and **Install** both of these (both published by Microsoft):
   - **WSL**
   - **Dev Containers**
4. Close VS Code.

---

### Step 7 — Check Git is available (Ubuntu terminal)

Ubuntu normally comes with Git. In an **Ubuntu terminal**, run:

```bash
git --version
```

If it prints a version (e.g. `git version 2.34.1`), you're done. If it says `command not found`:

```bash
sudo apt update && sudo apt install -y git
```

(Enter your Ubuntu password from step 3 when asked — again, it won't show while you type.)

---

### Step 8 — Clone the repository (Ubuntu terminal)

In an **Ubuntu terminal**, copy and paste these three lines, one at a time, pressing `Enter` after
each:

```bash
cd ~
git clone --branch windows --single-branch https://github.com/Cobot-Maker-Space/UON-RobotLab-Student-container.git
cd UON-RobotLab-Student-container
```

Check you're in the right place:

```bash
pwd
```

It must print `/home/yourname/UON-RobotLab-Student-container`.
If it starts with `/mnt/c/`, you're on the Windows drive — go back to `cd ~` and clone again.
The Windows drive is many times slower for Docker and causes errors.

> 💡 Want to see these files in Windows Explorer? From that folder, run `explorer.exe .`
> (note the dot). Look, but do your editing in VS Code.

---

### Step 9 — Open the project in VS Code (Ubuntu terminal)

Still in the **Ubuntu terminal**, inside `UON-RobotLab-Student-container`, run:

```bash
code src
```

Open **`src`**, not the whole repository — `src` is where the `.devcontainer` folder lives.

What happens:

1. The first time, it prints *Installing VS Code Server...* for a minute. That's normal.
2. VS Code opens. The **bottom-left corner** shows a coloured box reading **`WSL: Ubuntu`**.
   That means VS Code is connected to Ubuntu. ✅
3. If VS Code asks **"Do you trust the authors of the files in this folder?"**, click
   **Yes, I trust the authors**.

If the bottom-left does **not** say `WSL: Ubuntu`, close VS Code and repeat this step from the
Ubuntu terminal.

---

### Step 10 — Start the dev container (VS Code)

1. A pop-up may appear in the bottom-right: *"Folder contains a Dev Container configuration file"*.
   Click **Reopen in Container**.

   If you don't see it: press `Ctrl` + `Shift` + `P`, type `Reopen in Container`, and select
   **Dev Containers: Reopen in Container**.

2. VS Code reloads and shows *Starting Dev Container (show log)*. Click **show log** if you want to
   watch. Automatically, it will:
   1. Run `start_vnc.sh` inside Ubuntu, which creates the `ros` Docker network and starts the noVNC
      container on port 8080 — you don't run anything by hand
   2. Download the prebuilt ROS 2 image and start the dev container on that same `ros` network
   3. Run `setup.sh`, which builds the ROS 2 workspace with `colcon build`

3. **The first time takes a while** — typically 10–20 minutes, depending on your internet and PC,
   mostly downloading the image and the first build. **Don't close VS Code while it's working.**
   Later starts take seconds to a couple of minutes.

4. When it's finished, the bottom-left box reads **`Dev Container: ROS 2 Development Container`**,
   and the terminal panel reports `=== setup.sh finished successfully ===`.

---

### Step 11 — Open the GUI in your browser

In any browser on Windows (Chrome, Edge, Firefox), go to:

➡ **<http://localhost:8080/vnc.html>** and click **Connect**.

You'll see an empty (black or grey) desktop. That's expected. **That browser tab is the
container's screen.** Anything graphical you start from the VS Code terminal — Gazebo, RViz2,
`rqt` — shows up **there**, not as a normal window on your Windows desktop.

> 💡 The virtual screen is large. If it doesn't fit, open the noVNC side menu (the small tab on the
> left edge) → ⚙️ **Settings** → **Scaling Mode** → **Local Scaling**.

---

### Step 12 — Test that everything works (VS Code terminal, inside the container)

Open a terminal in VS Code: menu **Terminal → New Terminal** (or `Ctrl` + `` ` ``).
The prompt should look like `team@<letters-and-numbers>:/home/ros2_ws$`.

**a) Display test**

```bash
xeyes
```

A pair of eyes should appear in the browser tab from step 11. Press `Ctrl` + `C` in the terminal to
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

Gazebo with a TurtleBot3 should appear in the browser tab. The first launch can take a minute.
Stop it with `Ctrl` + `C`.

🎉 **Setup is complete.**

---

## 🔁 Every time you work on the project

1. Open **Docker Desktop** and wait for **Engine running**.
2. Open an **Ubuntu terminal** (Start → `Ubuntu`).
3. Run:

   ```bash
   cd ~/UON-RobotLab-Student-container
   code src
   ```

4. VS Code usually reopens straight into the container. If the bottom-left shows only
   `WSL: Ubuntu`, press `Ctrl` + `Shift` + `P` → **Dev Containers: Reopen in Container**.
5. Open <http://localhost:8080/vnc.html> and click **Connect**.

### When you're finished

- Close VS Code. Your files in `src/` stay on your PC.
- The noVNC container keeps running in the background. To stop it, run this in an
  **Ubuntu terminal**:

  ```bash
  ~/UON-RobotLab-Student-container/src/.devcontainer/start_vnc.sh stop
  ```

- To free up memory completely, run this in **PowerShell**, then quit Docker Desktop:

  ```powershell
  wsl --shutdown
  ```

---

## 🛠 Troubleshooting

Unless a row says otherwise, run the commands in an **Ubuntu terminal**, from inside
`~/UON-RobotLab-Student-container`.

### Installing WSL

| Problem | Solution |
|---|---|
| **`WslRegisterDistribution failed with error: 0x80370102`** | Virtualization is off. Go back to [step 1](#step-1--check-that-virtualization-is-enabled) and enable it in the BIOS. |
| **`WslRegisterDistribution failed with error: 0x800701bc`** | The WSL kernel needs updating. In PowerShell (Administrator): `wsl --update`, then open Ubuntu again. |
| **`wsl -l -v` shows VERSION 1** | In PowerShell: `wsl --set-version Ubuntu 2`. |
| **Forgot your Ubuntu password** | In PowerShell: `wsl -u root`, then `passwd yourname` (your Ubuntu username), set a new one, then `exit`. |
| **`wsl --install` just prints help text** | WSL is already present. Run `wsl --install -d Ubuntu`. |

### Docker

| Problem | Solution |
|---|---|
| **`The command 'docker' could not be found in this WSL 2 distro`** | Docker Desktop → Settings → **Resources → WSL integration** → turn on **Ubuntu** → **Apply & restart**. |
| **`Cannot connect to the Docker daemon`** | Docker Desktop isn't running. Open it and wait for **Engine running**. |
| **`permission denied` on the Docker socket** | Same fix as the two rows above. Unlike native Linux, you do **not** need to add yourself to a `docker` group. |

### VS Code and the container

| Problem | Solution |
|---|---|
| **`initializeCommand` failed / `'bash' is not recognized`** | You opened the folder from Windows, not through WSL. Close VS Code and follow [step 9](#step-9--open-the-project-in-vs-code-ubuntu-terminal): `code src` from an Ubuntu terminal. The bottom-left must say `WSL: Ubuntu` before you reopen in the container. |
| **`code: command not found` in Ubuntu** | VS Code wasn't added to PATH, or Ubuntu was open during the install. Close all Ubuntu windows, open a new one and try again. If it still fails, reinstall VS Code with **Add to PATH** ticked. |
| **`start_vnc.sh: bad interpreter: /bin/bash^M`** | The repository was cloned from Windows, not Ubuntu. Delete that copy and clone again inside Ubuntu, following [step 8](#step-8--clone-the-repository-ubuntu-terminal). |
| **`network ros not found` when the container starts** | The noVNC container didn't start. Start it by hand to see the error:<br>`./src/.devcontainer/start_vnc.sh start` |
| **Dev container is very slow / VS Code feels laggy** | Run `pwd`. If it starts with `/mnt/c/`, the repository is on the Windows drive — re-clone under `~` (step 8). |
| **The workspace won't rebuild from scratch** | `rm -f cache/humble/build/.built-for`, then `Ctrl` + `Shift` + `P` → **Dev Containers: Rebuild Container**. That stamp file tells `setup.sh` the cache is still valid. |

### The browser GUI (noVNC)

| Problem | Solution |
|---|---|
| **Browser can't open `localhost:8080`** | Check the container: `./src/.devcontainer/start_vnc.sh status`. Restart it: `./src/.devcontainer/start_vnc.sh restart`. |
| **Port 8080 already in use** | Another Windows program is using that port. Close it, or start noVNC on another port:<br>`HOST_PORT=8081 ./src/.devcontainer/start_vnc.sh restart`<br>then open `http://localhost:8081/vnc.html`. |
| **Commands run but nothing appears in the browser** | Make sure you clicked **Connect** in noVNC and are running the command in the **VS Code** terminal (prompt starts with `team@`), not the Ubuntu one. |
| **Gazebo spawn service failed** | Don't press `Ctrl` + `C` — let it fail completely, then close it and launch again. |
| **I need a real webcam** | `/dev/video0` isn't passed through Docker Desktop. Getting a USB camera into WSL2 needs [usbipd-win](https://github.com/dorssel/usbipd-win) first; only then is it worth adding `--device=/dev/video0` to `runArgs`. Ask your instructor before attempting this. |

---

## 💡 How it fits together

```
Windows
 ├─ Browser ──► http://localhost:8080 ─────────────┐
 └─ WSL2 (Ubuntu)                                  │
     ├─ ~/UON-RobotLab-Student-container   (your files)
     └─ Docker Desktop engine                      │
         ├─ noVNC container  (theasp/novnc) ◄──────┘  X server, port 8080
         └─ dev container    (ROS 2, Gazebo)  ──►  draws on DISPLAY=novnc:0.0
              both on the Docker network "ros"
```

Two containers, on a shared Docker network called `ros`:

- **the dev container** — ROS 2, Gazebo, your code. Draws on `DISPLAY=novnc:0.0`, which is the
  *other* container, not your PC.
- **the noVNC container** (`theasp/novnc`) — runs the X server and serves it to your browser on
  port 8080. Started automatically by `start_vnc.sh` via `initializeCommand`.

Other things worth knowing:

- Default user inside the container: `team`
- Once you're inside WSL2, everything behaves exactly as on the `linux` branch. Docker Desktop
  always goes through a Linux VM, so no command in this repo needed a Windows version
- Your `src/` folder is mounted at `/home/ros2_ws/src`, and `cache/humble/{build,install,log}`
  at the matching workspace folders — so builds survive container rebuilds
- The image is downloaded, not built on your PC:
  `ghcr.io/cobot-maker-space/robotlab-devcontainer-windows`. It's published by
  `.github/workflows/build-image.yml` — see [`decision.md`](decision.md)
- Includes Navigation2, SLAM Toolbox, Teleop, Gazebo + plugins, Cartographer, RViz2
- VS Code extensions preinstalled for ROS, C++, Python, and Git integration
