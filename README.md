# XGC2 Wheeltec Robot

This repository directly maintains the ROS 1 Wheeltec serial chassis driver
and its XGC2 vehicle integration.

## Packaged ROS 1 surface

| Debian package | ROS package | Purpose |
| --- | --- | --- |
| ros-melodic-xgc2-wheeltec-driver | turn_on_wheeltec_robot | Wheeltec serial chassis node and its supported launch entry point |
| ros-melodic-xgc2-wheeltec-swarm-ros-bridge | wheeltec_swarm_ros_bridge | Wheeltec topic and peer configuration for the generic bridge |
| ros-melodic-xgc2-wheeltec-onboard | wheeltec_onboard_bringup | Aggregated manual chassis and bridge bringup |

The aggregate package is the normal installation entry point:

    sudo apt update
    sudo apt install ros-melodic-xgc2-wheeltec-onboard

Start the currently supported vehicle surface manually:

    roslaunch wheeltec_onboard_bringup wheeltec_onboard.launch

The default bridge configuration sends /imu at 20 Hz and receives /cmd_vel
from the configured qgc peer.  Edit a copied configuration file and pass it as
bridge_config_file when a vehicle uses different addresses or ports.

## Hardware setup

The chassis driver defaults to /dev/wheeltec_controller at 115200 baud.  A
manual installer for the known legacy controller USB UART rule is included:

    sudo /opt/ros/melodic/share/turn_on_wheeltec_robot/scripts/install_wheeltec_controller_udev_rule.sh

Inspect the USB attributes on the physical vehicle before running that command.
The rule is intentionally not installed or enabled automatically.

## Scope

Only the serial chassis driver, its IMU and odometry topics, the configured
swarm bridge, and their aggregate launch are part of the current product.
Legacy navigation, camera, LiDAR, map, and external HandsFree IMU resources
remain source references and are not installed as supported runtime features.
There is no systemd autostart package yet.

See docs/productization-status.md for the current implementation and physical
vehicle validation boundary.

## Upstream provenance

- Upstream: <https://github.com/WheelBoard/turn_on_wheeltec_robot>
- Imported commit: c3a49e9 (Delete map_saver.launch)
- License: BSD-2-Clause; the upstream LICENSE file is retained unchanged.

The upstream project is no longer actively maintained. XGC2 hosts the source
here so future maintenance can be reviewed and released from this repository.
