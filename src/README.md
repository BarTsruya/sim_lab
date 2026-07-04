# sim_lab ROS 2 packages

- `sim_lab_bringup` — launches Gazebo Harmonic (iris_with_gimbal in iris_warehouse.sdf) and the `ros_gz_bridge` topic bridge.

Future packages (CV pipeline, PID control, EKF estimator) will live here as siblings of `sim_lab_bringup`, consuming its bridged Gazebo topics and MAVROS's vehicle telemetry/command topics.
