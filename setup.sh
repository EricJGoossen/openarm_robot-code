#!/usr/bin/env bash
# Bootstrap the robot-code workspace.
# Run once after cloning this repo to clone all sibling repos and install
# the shared Python environment. Safe to re-run (idempotent).
set -euo pipefail

# uv-workspace members: pure Python, built by `uv sync`. Get a COLCON_IGNORE
# stamped in so colcon doesn't crawl them looking for package.xml.
UV_REPOS=(
    "https://github.com/personalrobotics/asset_manager"
    "https://github.com/personalrobotics/mj_environment"
    "https://github.com/EricJGoossen/mj_manipulator"
    "https://github.com/personalrobotics/mj_viser"
    "https://github.com/personalrobotics/prl_assets"
    "https://github.com/personalrobotics/pycbirrt"
    "https://github.com/personalrobotics/tsr"
    "https://github.com/ericjgoossen/openarm_assets"
    "https://github.com/ericjgoossen/openarm"
)

# ROS-side repos: built by colcon inside the devcontainer. mj_manipulator_ros
# is ament_python and dual-purpose (imported by uv AND colcon-built for the
# ROS overlay), so it's NOT colcon-ignored and is also a uv workspace member.
ROS_REPOS=(
    "https://github.com/EricJGoossen/mj_manipulator_ros"
    "https://github.com/ericjgoossen/openarm_impedance_control"
    "https://github.com/ericjgoossen/rosbag_recorder"
    "https://github.com/enactic/openarm_ros2"
    "https://github.com/enactic/openarm_description"
)

# mujoco_menagerie is an external asset repo (not a Python package, not ROS)
# needed by demos.
MENAGERIE_URL="https://github.com/google-deepmind/mujoco_menagerie"

cd "$(dirname "$0")"

clone_if_missing() {
    local url="$1"
    local dir
    dir=$(basename "$url")
    # Several siblings are tracked as gitlinks (submodule-style pointers) but
    # there is no .gitmodules, so a fresh checkout leaves them as EMPTY
    # placeholder directories. A plain `[ ! -d ]` guard would see the dir and
    # skip it, leaving an empty (broken) uv workspace member. Detect a populated
    # repo by its .git entry instead, and clone into the empty placeholder.
    if [ -e "$dir/.git" ]; then
        echo "    $dir already present, skipping"
    else
        echo "    cloning $dir"
        rm -rf "$dir"        # drop the empty gitlink placeholder, if any
        git clone "$url"
    fi
}

echo "==> Cloning Python (uv) siblings..."
for url in "${UV_REPOS[@]}"; do
    clone_if_missing "$url"
done

echo ""
echo "==> Cloning ROS (colcon) siblings..."
for url in "${ROS_REPOS[@]}"; do
    clone_if_missing "$url"
done

echo ""
echo "==> Cloning mujoco_menagerie (robot models)..."
if [ ! -d "mujoco_menagerie" ]; then
    git clone "$MENAGERIE_URL"
else
    echo "    mujoco_menagerie already present, skipping"
fi

echo ""
echo "==> Marking Python-only siblings as COLCON_IGNORE..."
# Keeps colcon from crawling uv packages/assets when it builds inside the
# devcontainer. Re-run-safe: touch is a no-op if the marker already exists.
for url in "${UV_REPOS[@]}"; do
    dir=$(basename "$url")
    [ -d "$dir" ] && touch "$dir/COLCON_IGNORE"
done
touch "mujoco_menagerie/COLCON_IGNORE"

echo ""
echo "==> Removing stale per-package venvs (workspace uses shared root .venv)..."
# `uv run` inside a workspace member with its own .venv ignores the shared
# workspace venv, which is a common silent footgun. See robot-code#62.
shopt -s nullglob
for d in */.venv; do
    echo "    removing $d"
    rm -rf "$d"
done
shopt -u nullglob

echo ""
echo "==> Installing Python workspace (uv sync)..."
uv sync

echo ""
echo "==> Generating WebXR teleop certs..."
if [ -x openarm/scripts/generate_certs.sh ]; then
    (cd openarm && ./scripts/generate_certs.sh)
else    
    echo "     skipped: openarm/scripts/generate_certs.sh not found or not executable"
fi

echo ""
echo "Done. Verify with:"
echo "  uv run python mj_manipulator/demos/cartesian_control.py"
echo ""
echo "For hardware/ROS work, open this folder in the devcontainer (.devcontainer/) —"
echo "it runs rosdep + colcon on top of what setup.sh just cloned."