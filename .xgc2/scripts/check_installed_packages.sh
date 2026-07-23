#!/usr/bin/env bash
set -euo pipefail

ROS_DISTRO="${ROS_DISTRO:-melodic}"
PREFIX="/opt/ros/$ROS_DISTRO"

# shellcheck disable=SC1090
source "$PREFIX/setup.bash"

for deb_package in "ros-$ROS_DISTRO-xgc2-wheeltec-driver" "ros-$ROS_DISTRO-xgc2-wheeltec-swarm-ros-bridge" "ros-$ROS_DISTRO-xgc2-wheeltec-onboard"; do
  dpkg -s "$deb_package" >/dev/null
done

test "$(rospack find turn_on_wheeltec_robot)" = "$PREFIX/share/turn_on_wheeltec_robot"
test "$(rospack find wheeltec_swarm_ros_bridge)" = "$PREFIX/share/wheeltec_swarm_ros_bridge"
test "$(rospack find wheeltec_onboard_bringup)" = "$PREFIX/share/wheeltec_onboard_bringup"

test -x "$PREFIX/lib/turn_on_wheeltec_robot/wheeltec_robot_node"
test -f "$PREFIX/share/turn_on_wheeltec_robot/launch/wheeltec_robot.launch"
test -x "$PREFIX/share/turn_on_wheeltec_robot/scripts/install_wheeltec_controller_udev_rule.sh"
test -f "$PREFIX/share/turn_on_wheeltec_robot/udev/99-xgc2-wheeltec-controller.rules"
test -f "$PREFIX/share/wheeltec_swarm_ros_bridge/config/ros_topics.yaml"
test -f "$PREFIX/share/wheeltec_swarm_ros_bridge/launch/wheeltec_swarm_ros_bridge.launch"
test -f "$PREFIX/share/wheeltec_onboard_bringup/launch/wheeltec_onboard.launch"

python3 - "$PREFIX/share/wheeltec_swarm_ros_bridge/config/ros_topics.yaml" <<'PY'
from __future__ import print_function

import sys
import yaml

with open(sys.argv[1], "r") as stream:
    config = yaml.safe_load(stream)

assert config["IP"]["qgc"] == "192.168.51.199"
assert config["send_topics"][0]["topic_name"] == "/imu"
assert config["send_topics"][0]["max_freq"] == 20
assert config["recv_topics"][0]["topic_name"] == "/cmd_vel"
assert config["recv_topics"][0]["max_freq"] == 0
PY

roslaunch --files turn_on_wheeltec_robot wheeltec_robot.launch >/dev/null
roslaunch --files wheeltec_swarm_ros_bridge wheeltec_swarm_ros_bridge.launch >/dev/null
roslaunch --files wheeltec_onboard_bringup wheeltec_onboard.launch >/dev/null

echo "Installed Wheeltec ROS1 package checks passed"
