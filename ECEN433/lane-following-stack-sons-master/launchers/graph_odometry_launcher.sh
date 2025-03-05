#!/bin/bash

source /environment.sh

# initialize launch file
dt-launchfile-init

# YOUR CODE BELOW THIS LINE
# ----------------------------------------------------------------------------

roslaunch odometry robot_odom.launch

# NOTE: Use the variable DT_REPO_PATH to know the absolute path to your code
# NOTE: Use `dt-exec COMMAND` to run the main process (blocking process)

# launching app

# ----------------------------------------------------------------------------
# YOUR CODE ABOVE THIS LINE

# wait for app to end
dt-launchfile-join
