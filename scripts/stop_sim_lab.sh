#!/usr/bin/env bash
# Thorough teardown for the sim_lab tmuxp stack.
#
# `tmux kill-session` only kills the pane shells - it does NOT reap:
#   - gz sim's forked `gz sim server` / `gz sim gui` child processes
#   - MAVProxy's `--console` / `--map` GUI modules, which sim_vehicle.py's
#     mavproxy.py spawns as SEPARATE child processes (not threads)
#   - the arducopter SITL binary itself (and, on some setups, the xterm
#     RiTW wraps it in)
# All of the above were observed surviving a plain `tmux kill-session`
# during milestone-1 verification, so each is killed and verified by name
# below rather than assumed dead.
set -u

# pattern -> human label
declare -A PATTERNS=(
  ["gz sim"]="Gazebo (server+gui)"
  ["xterm.*ArduCopter"]="ArduCopter xterm wrapper"
  ["bin/arducopter"]="ArduCopter SITL binary"
  ["sim_vehicle\.py"]="sim_vehicle.py"
  ["mavproxy\.py"]="MAVProxy (+ console/map child processes)"
  ["ros2 launch mavros"]="ros2 launch mavros"
  ["mavros_node"]="MAVROS node"
  ["ros2 launch sim_lab_bringup"]="ros2 launch sim_lab_bringup"
  ["parameter_bridge"]="ros_gz_bridge parameter_bridge"
  ["QGroundControl"]="QGroundControl"
)

tmux kill-session -t sim_lab 2>/dev/null || true
sleep 1

for pattern in "${!PATTERNS[@]}"; do
  pkill -9 -f "$pattern" 2>/dev/null || true
done
sleep 2

# Second pass: kill anything that survived the first sweep by exact PID
# (observed happening for mavproxy.py's child processes specifically).
for pattern in "${!PATTERNS[@]}"; do
  pids=$(pgrep -f "$pattern" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    kill -9 $pids 2>/dev/null || true
  fi
done
sleep 1

failed=0
for pattern in "${!PATTERNS[@]}"; do
  label="${PATTERNS[$pattern]}"
  pids=$(pgrep -f "$pattern" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    echo "FAILED to stop: $label (pid(s): $pids)" >&2
    failed=1
  else
    echo "confirmed stopped: $label"
  fi
done

if [ "$failed" -ne 0 ]; then
  echo "One or more processes did not stop - inspect the PIDs above manually." >&2
  exit 1
fi
echo "sim_lab stack fully stopped and verified."
