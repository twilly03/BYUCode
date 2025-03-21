#!/bin/bash

HW_PACKAGE="lab1part5"
HW_LAUNCH="lab1p5launch.launch"

cat /assignments/lab1.txt

source /environment.sh

# initialize launch file
dt-launchfile-init

# YOUR CODE BELOW THIS LINE
# ----------------------------------------------------------------------------


# NOTE: Use the variable DT_REPO_PATH to know the absolute path to your code
# NOTE: Use `dt-exec COMMAND` to run the main process (blocking process)

# launching app
roslaunch $HW_PACKAGE $HW_LAUNCH


# ----------------------------------------------------------------------------
# YOUR CODE ABOVE THIS LINE

# wait for app to end
dt-launchfile-join
