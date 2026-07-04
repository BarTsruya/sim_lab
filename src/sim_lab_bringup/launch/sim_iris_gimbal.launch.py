import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
    # Gazebo itself is started separately (its own tmuxp pane: `gz sim -r
    # iris_warehouse.sdf`), not here - this launch file only owns the
    # ros_gz_bridge process, so it has no dependency on GZ_SIM_RESOURCE_PATH.
    bringup_share = get_package_share_directory('sim_lab_bringup')
    bridge_config = os.path.join(bringup_share, 'config', 'iris_gimbal_bridge.yaml')

    bridge = Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        name='ros_gz_bridge',
        parameters=[{'config_file': bridge_config, 'use_sim_time': True}],
        output='screen',
    )

    return LaunchDescription([bridge])
