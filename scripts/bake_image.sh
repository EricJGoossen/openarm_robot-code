#!/usr/bin/env bash
# Bake a deployable image: build the base image, build this workspace inside
# a throwaway container the same way post-create.sh does for a devcontainer,
# commit the result, and copy build/install/log out to the host so a rebuild
# survives the container being recreated.
#
# This exists so a caller outside this repo (e.g. opendubs' openarm-setup.md)
# only needs to know two paths — an output tag and a state dir — instead of
# reproducing the devcontainer dance by hand. Everything about *how* the
# image gets built stays here, next to the Dockerfile it builds from.
#
# Usage:
#   ./scripts/bake-image.sh <output-tag> <state-dir> [ssik-path]
#
#   output-tag   image tag to commit the built workspace as, e.g. openarm-ros2:$(hostname)
#   state-dir    host directory to copy build/install/log into (created if missing)
#   ssik-path    path to a sibling clone of personalrobotics/ssik
#                (default: ../ssik, same default the devcontainer itself uses)
#
# Env overrides:
#   BASE_TAG     tag for the intermediate base image (default: openarm-ros2:base)
set -euo pipefail
cd "$(dirname "$0")/.."
REPO="$(pwd)"

OUT_TAG="${1:?usage: bake-image.sh <output-tag> <state-dir> [ssik-path]}"
STATE_DIR="${2:?usage: bake-image.sh <output-tag> <state-dir> [ssik-path]}"
SSIK="${3:-$REPO/../ssik}"
BASE_TAG="${BASE_TAG:-openarm-ros2:base}"
SETUP_CONTAINER=openarm-setup

[ -d "$SSIK" ] || {
  echo "!! ssik not found at $SSIK — clone personalrobotics/ssik there, or pass its path as \$3"
  exit 1
}

echo "==> Running setup.sh (clone workspace siblings: openarm_impedance_control etc.)..."
"$REPO/setup.sh"

echo "==> Building base image..."
"$(dirname "$0")/build-image.sh" "$BASE_TAG"

echo "==> Starting throwaway container ($SETUP_CONTAINER)..."
sudo docker rm -f "$SETUP_CONTAINER" >/dev/null 2>&1 || true
sudo docker run -d --name "$SETUP_CONTAINER" --privileged --network=host \
  -v "$REPO:/openarm_ws/src" -v "$SSIK:/openarm_ws/ssik" \
  "$BASE_TAG" sleep infinity >/dev/null

echo "==> Running post-create.sh (rosdep + colcon build) — this is the slow step..."
sudo docker exec "$SETUP_CONTAINER" bash -c \
  "apt-get update && source /opt/ros/jazzy/setup.bash && bash /openarm_ws/src/.devcontainer/post-create.sh"

echo "==> Committing $SETUP_CONTAINER -> $OUT_TAG..."
sudo docker stop "$SETUP_CONTAINER" >/dev/null
sudo docker commit "$SETUP_CONTAINER" "$OUT_TAG" >/dev/null

echo "==> Copying build/install/log out to $STATE_DIR..."
mkdir -p "$STATE_DIR"
for d in build install log; do
  sudo docker cp "$SETUP_CONTAINER:/openarm_ws/$d" "$STATE_DIR/"
done
sudo chown -R "$(id -u):$(id -g)" "$STATE_DIR"
sudo docker rm "$SETUP_CONTAINER" >/dev/null

echo "==> Done."
echo "    Image: $OUT_TAG"
echo "    State: $STATE_DIR/{build,install,log}"
echo "    Mount these into the long-running container at /openarm_ws/{build,install,log}."