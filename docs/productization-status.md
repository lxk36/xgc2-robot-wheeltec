# Wheeltec productization progress

Date: 2026-07-23

## Delivered in the current repository

- The original turn_on_wheeltec_robot source remains directly hosted in this
  repository, with its upstream BSD-2-Clause LICENSE retained.
- The driver now has an explicit supported launch entry point:
  launch/wheeltec_robot.launch.
- The driver package installs its node, supported launch file, and a manual
  installer for the known legacy controller udev identity.
- The vehicle-specific wheeltec_swarm_ros_bridge package owns the supplied
  /imu send and /cmd_vel receive configuration plus a launch wrapper around
  the separately released generic swarm_ros_bridge binary.
- The wheeltec_onboard_bringup package aggregates the driver and bridge in
  one manual launch command.
- The receive topic includes max_freq: 0 because the current generic bridge
  parser requires that field even though it does not use receive-side
  throttling.

## Deliberately not included

- handsfree_ros_imu and the HFI-A9 USB IMU source.  It will be evaluated only
  after the actual vehicle source and hardware are available.
- Legacy navigation, camera, LiDAR, mapping, and robot_pose_ekf launch chains.
  They reference packages and topic conventions that are not compatible with
  the directly hosted current driver without vehicle-level integration work.
- Systemd boot autostart.  It remains unsafe to enable before the controller
  device identity, ROS master policy, and bridge peer configuration are
  verified on the real vehicle.
- The old ugv-auto-launch directory.  It is retained locally as a reference
  and explicitly excluded from the released product.

## Required physical-vehicle validation

1. Confirm that the controller is the expected USB UART before installing the
   bundled udev rule.  Otherwise launch with an explicit usart_port_name.
2. With wheels safely off the ground, start the chassis-only launch and verify
   the cmd_vel, odom, imu, and PowerVoltage topics.
3. Confirm the actual bridge peer address and ports, then start the aggregate
   launch and verify that /imu reaches the peer and incoming /cmd_vel reaches
   the chassis driver.
4. Decide separately whether the vehicle uses an HFI-A9 IMU, navigation
   sensors, or boot-time autostart.  Each adds hardware-specific dependencies
   that are intentionally outside the current product boundary.

## Packaging status

The planned Debian packages are:

- ros-melodic-xgc2-wheeltec-driver
- ros-melodic-xgc2-wheeltec-swarm-ros-bridge
- ros-melodic-xgc2-wheeltec-onboard

The aggregate package depends on the first two and the standalone generic
ros-melodic-swarm-ros-bridge package.  The following change adds the release
metadata and reproducible build checks for this package set; no physical
vehicle test is implied by a successful container build.
