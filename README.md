# sim_lab

A simulation lab for testing robotics algorithms — computer vision, PID control, Extended Kalman Filters — against a realistic drone simulator before touching real hardware.

**Milestone 1 (current):** an ArduCopter quadcopter with a 3-axis gimbaled camera, flying in Gazebo Harmonic via SITL, fully wired into ROS 2. Future milestones add the actual CV/PID/EKF packages on top of this foundation.

## Stack

| Layer | Choice |
|---|---|
| Flight stack | ArduPilot SITL (ArduCopter, stable release) |
| Simulator | Gazebo Harmonic, via the official [`ardupilot_gazebo`](https://github.com/ArduPilot/ardupilot_gazebo) plugin (JSON/gz-transport interface) |
| Vehicle | `iris_with_gimbal` in the `iris_warehouse` world — quad + 3-axis gimbal + RGB camera |
| Middleware | ROS 2 Jazzy |
| Sim ⟷ ROS 2 | `ros_gz_bridge` — camera image/info, TF, joint states, gimbal commands |
| Autopilot ⟷ ROS 2 | MAVROS (`apm` dialect) — vehicle telemetry and commands (mode, arm, setpoints) |
| GCS | MAVProxy (console/map) + QGroundControl |
| Orchestration | `tmuxp` — one command brings up the whole stack |

ROS 2 was chosen deliberately as the integration layer for future CV/PID/EKF nodes (over raw MAVLink or a custom ZMQ bus) — it's the dominant convention in published Gazebo+ArduPilot autonomy stacks and gives direct access to `rclpy`/`rclcpp`, `tf2`, `cv_bridge`, and message-filters for sensor fusion. ArduPilot's native ROS 2 interface (AP_DDS) is currently broken on ROS 2 Jazzy (see [ArduPilot#31942](https://github.com/ArduPilot/ardupilot/issues/31942)), so MAVROS stands in for that boundary until it's fixed upstream.

## Layout

```
sim_lab/
├── src/                      # colcon workspace — ROS 2 packages
│   └── sim_lab_bringup/      #   Gazebo bridge launch file + topic config
├── deps/                     # non-colcon dependencies (git submodules)
│   ├── ardupilot/            #   ArduPilot SITL, built with waf
│   └── ardupilot_gazebo/     #   the Gazebo plugin, built with cmake
├── tmux/
│   └── sim_lab.tmuxp.yaml    # tmuxp session: gazebo/sitl/bridge/mavros panes + qgc + logic windows
└── scripts/
    ├── install_system_deps.sh  # one-time system setup (run once, needs sudo)
    ├── start_sim_lab.sh        # launch the full stack
    └── stop_sim_lab.sh         # tear it down (validates every process actually stopped)
```

## Getting started

```bash
# one-time system setup (ROS 2, Gazebo, MAVROS, build prereqs, tmuxp - needs sudo)
./scripts/install_system_deps.sh

# build ArduPilot SITL
cd deps/ardupilot && ./waf configure --board sitl && ./waf copter && cd ../..

# build the ardupilot_gazebo plugin
cd deps/ardupilot_gazebo && export GZ_VERSION=harmonic && mkdir -p build && cd build \
  && cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo && make -j$(nproc) && cd ../../..

# build the ROS 2 workspace
colcon build --symlink-install

# launch everything
./scripts/start_sim_lab.sh
```

This brings up a `sim_lab` tmux session: a `sim` window with panes for Gazebo, SITL, the ROS 2 bridge, and MAVROS, plus separate `qgc` and `logic` windows (the latter is a blank pane with the environment already sourced, ready for the algorithm nodes that come next). Attach with `tmux attach -t sim_lab`; tear down with `./scripts/stop_sim_lab.sh`.

Cloning fresh? Pull the submodules too: `git clone --recurse-submodules <repo-url>`.

## What's next

Future CV, PID, and EKF packages will live in `src/`, alongside `sim_lab_bringup`, consuming its bridged camera/pose/joint-state topics and MAVROS's vehicle telemetry.
