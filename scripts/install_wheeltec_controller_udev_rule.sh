#!/usr/bin/env bash
set -euo pipefail

RULE_NAME="99-xgc2-wheeltec-controller.rules"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RULE_SOURCE="$SCRIPT_DIR/../udev/$RULE_NAME"
RULE_DEST="/etc/udev/rules.d/$RULE_NAME"

if [[ $EUID -ne 0 ]]; then
  echo "This script installs a udev rule and must run as root." >&2
  echo "Inspect the controller USB attributes first, then run: sudo $0" >&2
  exit 1
fi

if [[ ! -f "$RULE_SOURCE" ]]; then
  echo "Packaged udev rule is missing: $RULE_SOURCE" >&2
  exit 1
fi

install -m 0644 "$RULE_SOURCE" "$RULE_DEST"
udevadm control --reload-rules
udevadm trigger --subsystem-match=tty || true

echo "Installed $RULE_DEST"
echo "Reconnect the controller USB UART if /dev/wheeltec_controller does not appear."
