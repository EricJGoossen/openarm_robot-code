#!/usr/bin/env bash
# Runs every time the devcontainer is (re)built, after the workspace bind
# mount is in place. Assumes setup.sh has already been run on the host —
# this script does not clone anything, it only builds what's already there.
set -uo pipefail  # not -e: rosdep/colcon failures shouldn't kill the container

WS_ROOT=/openarm_ws
SRC_DIR="$WS_ROOT/src"

SKIP_KEYS="openarm_can openarm_description moveit_ros_move_group moveit_kinematics \
moveit_planners moveit_simple_controller_manager moveit_configs_utils \
moveit_ros_visualization moveit_setup_assistant"

echo "==> rosdep update..."
rosdep update

echo "==> rosdep install..."
rosdep install --from-paths "$SRC_DIR" --ignore-src -r -y --skip-keys "$SKIP_KEYS"

echo "==> colcon build..."
cd "$WS_ROOT"
colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

echo "==> Linking compile_commands.json for clangd..."
ln -sf "$WS_ROOT/build/compile_commands.json" "$SRC_DIR/compile_commands.json"

echo "==> uv sync (container-side Python venv)..."
cd "$SRC_DIR"
UV_PROJECT_ENVIRONMENT="$WS_ROOT/.venv-container" uv sync

echo "==> Initializing bashrc..."

echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc
echo "source /openarm_ws/install/setup.bash" >> /root/.bashrc
echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /root/.bashrc
echo "alias cs='cd /openarm_ws && source ~/.bashrc && colcon build --symlink-install'" >> /root/.bashrc

echo "==> post-create complete."