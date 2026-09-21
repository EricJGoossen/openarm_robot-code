#!/bin/bash
# Bring up can4 and can5 with OpenArm CAN FD settings (1M nominal / 5M data)
set -e

for IFACE in can4 can5; do
    sudo ip link set "$IFACE" down 2>/dev/null || true
    sudo ip link set "$IFACE" type can bitrate 1000000 dbitrate 5000000 fd on
    sudo ip link set "$IFACE" up
    echo "$IFACE up:"
    ip link show "$IFACE"
done