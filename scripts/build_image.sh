#!/usr/bin/env bash
# Build the base devcontainer image (ROS 2 Jazzy + openarm_can + uv) — no
# workspace code baked in yet. This is what VS Code builds automatically
# when you open the repo in the devcontainer; this script does the same
# thing for a host that isn't using VS Code (e.g. a robot being provisioned
# by a script). Re-run whenever .devcontainer/Dockerfile changes — the ROS
# apt layer is the expensive part and Docker caches it.
#
# Usage:  ./scripts/build-image.sh [tag]     (default: openarm-ros2:base)
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${1:-openarm-ros2:base}"

echo "==> Building $TAG from .devcontainer/Dockerfile..."
sudo docker build --network=host -t "$TAG" .devcontainer
echo "==> Built $TAG"