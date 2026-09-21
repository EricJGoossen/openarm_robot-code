# openarm_robot-code

Controller for the openarms

## Quick Start

```bash
git clone https://github.com/personalrobotics/robot-code
cd openarm_robot-code
./setup.sh        # clones all repos, runs uv sync
```

ros2 action send_goal /right_joint_trajectory_controller/follow_joint_trajectory control_msgs/action/FollowJointTrajectory \
  '{trajectory: {joint_names: ["openarm_right_joint1", "openarm_right_joint2", "openarm_right_joint3", "openarm_right_joint4", "openarm_right_joint5", "openarm_right_joint6", "openarm_right_joint7"], points: [{positions: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], time_from_start: {sec: 3, nanosec: 0}}]}}'

  ros2 action send_goal /right_gripper_controller/follow_joint_trajectory control_msgs/action/FollowJointTrajectory \
  '{trajectory: {joint_names: ["openarm_right_finger_joint1"], points: [{positions: [0.0], time_from_start: {sec: 2, nanosec: 0}}]}}'