# Officially published multi-arch ROS base. Kept as ros:humble (not osrf/ros:humble-desktop-full,
# which is amd64-only) so the same Dockerfile also works unchanged on the arm64 macOS branch.
# Windows runs this through WSL2, which is real amd64 Linux, so nothing here is Windows-specific.
ARG BASE_IMAGE=ros:humble
FROM ${BASE_IMAGE}

ARG USERNAME=team
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG WORKSPACE_DIR=/home/ros2_ws

# Create user
RUN groupadd --gid $USER_GID $USERNAME \
&& useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
&& apt-get update \
&& apt-get install -y sudo \
&& echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
&& chmod 0440 /etc/sudoers.d/$USERNAME

ENV SHELL=/bin/bash
ENV DEBIAN_FRONTEND=noninteractive

# Install ROS packages and other dependencies.
#
# No VNC server or desktop environment here on purpose: the X server students actually draw on
# lives in the separate theasp/novnc container (see start_vnc.sh and DISPLAY=novnc:0.0 in
# devcontainer.json). This container only ever needs to be an X *client*. ubuntu-mate-desktop,
# tigervnc and supervisor used to be installed here and were never started by anything - they
# cost ~2 GB and, on the arm64 macOS build, hours of QEMU emulation.
RUN apt-get update && apt-get install -y \
    python3-pip \
    net-tools nano iputils-ping curl fswebcam gnupg2 lsb-release sudo \
    build-essential mesa-utils python3-colcon-common-extensions \
    ros-humble-navigation2 ros-humble-nav2-bringup ros-humble-slam-toolbox \
    ros-humble-teleop-twist-keyboard \
    ros-humble-rqt* \
    ros-humble-gazebo-ros-pkgs \
    ros-humble-gazebo-plugins \
    ros-humble-cartographer ros-humble-cartographer-ros \
    ros-humble-rviz2 \
    # X client side only - openbox so a stray window has something to manage it, x11-apps for
    # xeyes, which is the quickest way to prove the noVNC display is reachable.
    openbox x11-apps \
    git wget tini locales tzdata dos2unix \
    && rm -rf /var/lib/apt/lists/*

# dos2unix because a Windows clone without core.autocrlf=input rewrites this script with CRLF
# line endings, and the container then fails with 'bad interpreter: /bin/bash^M'.
COPY setup.sh /usr/local/bin/setup.sh
RUN dos2unix /usr/local/bin/setup.sh \
&& chmod +x /usr/local/bin/setup.sh

# Setup ROS environment. The overlay is guarded: devcontainer.json bind-mounts an empty
# install/ over this path on a fresh clone, so sourcing it unconditionally makes every new
# terminal open with an error until the first colcon build has run.
RUN printf '%s\n' \
    'source /opt/ros/humble/setup.bash' \
    '[ -f /home/ros2_ws/install/setup.bash ] && source /home/ros2_ws/install/setup.bash' \
    >> /home/$USERNAME/.bashrc

# Add user to video group (for rendering access), and create the workspace directories up front
# so they are owned by $USERNAME. devcontainer.json bind-mounts host directories over
# build/install/log; without this they arrive root-owned and colcon cannot write to them.
RUN usermod -aG video $USERNAME \
&& mkdir -p ${WORKSPACE_DIR}/src ${WORKSPACE_DIR}/build ${WORKSPACE_DIR}/install ${WORKSPACE_DIR}/log \
&& chown -R $USER_UID:$USER_GID ${WORKSPACE_DIR}

USER $USERNAME
WORKDIR ${WORKSPACE_DIR}

# No EXPOSE 8080 here: port 8080 is published by the noVNC container, not by this one.
