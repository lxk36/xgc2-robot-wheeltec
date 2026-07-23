#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT=""
OUTPUT_DIR=""
ROS_DISTRO="${ROS_DISTRO:-melodic}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

product_version() {
  awk -F': *' '/^version:[[:space:]]*/ {print $2; exit}' "$REPO_ROOT/.xgc2/product.yml"
}

VERSION="${PACKAGE_VERSION:-$(product_version)}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-root)
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$INSTALL_ROOT" || -z "$OUTPUT_DIR" ]]; then
  echo "--install-root and --output-dir are required" >&2
  exit 1
fi
if [[ -z "$VERSION" ]]; then
  echo "package version is missing" >&2
  exit 1
fi

ARCH="$(dpkg --print-architecture)"
PREFIX="/opt/ros/$ROS_DISTRO"
PREFIX_ROOT="$INSTALL_ROOT$PREFIX"
BUILD_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"

copy_path() {
  local source_path="$1"
  local package_root="$2"
  local relative
  local target_path

  if [[ ! -e "$source_path" ]]; then
    return
  fi

  relative="$(realpath --relative-to="$INSTALL_ROOT" "$source_path")"
  target_path="$package_root/$relative"
  mkdir -p "$(dirname "$target_path")"
  cp -a "$source_path" "$target_path"
}

copy_ros_package_paths() {
  local ros_package="$1"
  local package_root="$2"

  copy_path "$PREFIX_ROOT/share/$ros_package" "$package_root"
  copy_path "$PREFIX_ROOT/lib/$ros_package" "$package_root"
  copy_path "$PREFIX_ROOT/include/$ros_package" "$package_root"
  copy_path "$PREFIX_ROOT/share/common-lisp/ros/$ros_package" "$package_root"
  copy_path "$PREFIX_ROOT/share/gennodejs/ros/$ros_package" "$package_root"
  copy_path "$PREFIX_ROOT/share/roseus/ros/$ros_package" "$package_root"
}

write_control() {
  local package_root="$1"
  local deb_package="$2"
  local depends="$3"
  local description="$4"

  mkdir -p "$package_root/DEBIAN"
  cat > "$package_root/DEBIAN/control" <<EOF
Package: $deb_package
Version: $VERSION
Section: misc
Priority: optional
Architecture: $ARCH
Maintainer: XGC2 <apt@example.com>
Depends: $depends
Description: $description
 XGC2 Wheeltec ROS $ROS_DISTRO package generated from the directly hosted
 vehicle source and split by the supported ROS package boundary.
EOF
}

write_readme() {
  local package_root="$1"
  local deb_package="$2"
  local ros_package="$3"

  mkdir -p "$package_root/usr/share/doc/$deb_package"
  cat > "$package_root/usr/share/doc/$deb_package/README" <<EOF
$deb_package

ROS package:
  $ros_package

Version:
  $VERSION

Install prefix:
  $PREFIX
EOF
}

build_deb() {
  local deb_package="$1"
  local ros_package="$2"
  local depends="$3"
  local description="$4"
  local package_root="$BUILD_DIR/$deb_package"
  local deb_path="${OUTPUT_DIR}/${deb_package}_${VERSION}_${ARCH}.deb"

  mkdir -p "$package_root"
  copy_ros_package_paths "$ros_package" "$package_root"

  if [[ ! -f "$package_root$PREFIX/share/$ros_package/package.xml" ]]; then
    echo "missing installed package.xml for $ros_package" >&2
    exit 1
  fi

  write_control "$package_root" "$deb_package" "$depends" "$description"
  write_readme "$package_root" "$deb_package" "$ros_package"

  find "$package_root" -type d -exec chmod 0755 {} +
  find "$package_root" -type f -exec chmod 0644 {} +
  chmod 0755 "$package_root/DEBIAN"
  chmod 0644 "$package_root/DEBIAN/control"

  if [[ -d "$package_root$PREFIX/lib/$ros_package" ]]; then
    find "$package_root$PREFIX/lib/$ros_package" -type f -exec chmod 0755 {} +
  fi
  if [[ -d "$package_root$PREFIX/share/$ros_package/scripts" ]]; then
    find "$package_root$PREFIX/share/$ros_package/scripts" -type f -exec chmod 0755 {} +
  fi

  fakeroot dpkg-deb --build "$package_root" "$deb_path" >/dev/null
}

driver_deb="ros-$ROS_DISTRO-xgc2-wheeltec-driver"
bridge_deb="ros-$ROS_DISTRO-xgc2-wheeltec-swarm-ros-bridge"
onboard_deb="ros-$ROS_DISTRO-xgc2-wheeltec-onboard"

build_deb "$driver_deb" "turn_on_wheeltec_robot" "ros-$ROS_DISTRO-geometry-msgs, ros-$ROS_DISTRO-nav-msgs, ros-$ROS_DISTRO-roscpp, ros-$ROS_DISTRO-roslaunch, ros-$ROS_DISTRO-serial, ros-$ROS_DISTRO-sensor-msgs, ros-$ROS_DISTRO-std-msgs, ros-$ROS_DISTRO-tf" "XGC2 Wheeltec serial chassis driver"
build_deb "$bridge_deb" "wheeltec_swarm_ros_bridge" "ros-$ROS_DISTRO-roslaunch, ros-$ROS_DISTRO-swarm-ros-bridge (>= 1.1.0-7)" "XGC2 Wheeltec swarm ROS bridge configuration"
build_deb "$onboard_deb" "wheeltec_onboard_bringup" "ros-$ROS_DISTRO-roslaunch, $driver_deb (>= $VERSION), $bridge_deb (>= $VERSION)" "XGC2 Wheeltec aggregate manual onboard bringup"

find "$OUTPUT_DIR" -maxdepth 1 -type f -name "*.deb" -print | sort
