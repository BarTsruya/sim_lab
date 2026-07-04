#!/usr/bin/env bash
# One-time system dependency install for sim_lab Milestone 1.
# Run this yourself (it needs interactive sudo): bash scripts/install_system_deps.sh
set -euo pipefail

echo "=== 1. ROS 2 Jazzy ==="
sudo apt install -y software-properties-common curl
sudo add-apt-repository -y universe

ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
sudo apt install -y /tmp/ros2-apt-source.deb

sudo apt update
sudo apt install -y ros-jazzy-desktop ros-dev-tools

if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
  echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi
# ROS 2's setup.bash references some variables (e.g. AMENT_TRACE_SETUP_FILES)
# without guarding them, which trips `set -u` - disable it just for the source.
set +u
source /opt/ros/jazzy/setup.bash
set -u

sudo rosdep init || true   # ok if already initialized
rosdep update

echo "=== 2. Gazebo Harmonic ==="
echo "Checking for conflicting pre-existing Gazebo installs..."
if apt list --installed 2>/dev/null | grep -E "gz-garden|gz-ionic|gazebo11"; then
  echo "WARNING: another Gazebo version is already installed - this is the known cause of the protobuf symbol-conflict crash. Resolve before continuing." >&2
  exit 1
fi

sudo apt-get install -y curl lsb-release gnupg
sudo curl https://packages.osrfoundation.org/gazebo.gpg -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] \
  https://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/gazebo-stable.list

sudo apt-get update
sudo apt-get install -y gz-harmonic
apt policy gz-harmonic | head -5

echo "=== 3. ros-jazzy-ros-gz (bridge packages) ==="
sudo apt install -y ros-jazzy-ros-gz

echo "=== 4. ardupilot_gazebo plugin build dependencies ==="
sudo apt install -y libgz-sim8-dev rapidjson-dev
sudo apt install -y libopencv-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl

echo "=== 5. ArduPilot SITL build prerequisites ==="
if [ -d "$(dirname "$0")/../deps/ardupilot" ]; then
  ( cd "$(dirname "$0")/../deps/ardupilot" && Tools/environment_install/install-prereqs-ubuntu.sh -y ) || \
    echo "NOTE: install-prereqs-ubuntu.sh reported an error (often the wxPython GUI-extras step) - this typically does not block the SITL build itself, continue on."
else
  echo "SKIPPED: deps/ardupilot not found yet - run this script from sim_lab/ after the repo has been cloned."
fi

echo "=== 6. MAVROS ==="
sudo apt install -y ros-jazzy-mavros ros-jazzy-mavros-extras
GEO_SCRIPT=$(find /opt/ros/jazzy -iname "install_geographiclib_datasets.sh" 2>/dev/null | head -1)
if [ -n "$GEO_SCRIPT" ]; then
  sudo bash "$GEO_SCRIPT"
else
  echo "WARNING: could not locate install_geographiclib_datasets.sh - find it manually under /opt/ros/jazzy and run it with sudo before using MAVROS." >&2
fi

echo "=== 7. QGroundControl prerequisite ==="
sudo apt install -y libfuse2

echo "=== 8. tmux / tmuxp ==="
# Ubuntu 24.04's system pip is "externally managed" (PEP 668) and blocks a plain
# `pip install --user`, so install tmuxp via apt rather than fighting that.
sudo apt install -y tmux tmuxp

echo "=== All system dependencies installed. ==="
