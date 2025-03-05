#!/usr/bin/env python3


# /luke/joy_mapper_node/joystick_override publishes to /luke/fsm/node 
#   It publishes a boolean False (Automatic Control) or True (Manual Control)
# 
# Needs to be OPEN LOOP? the output has no relevance to the input
# 
# /luke/fsm_node/mode
# "NORMAL_JOYSTICK_CONTROL" and "LANE_FOLLOWING"
# 
# 
# 
# 
# 
# 


import rospy
import numpy as np
from odometry.msg import Pose2D
from duckietown_msgs.msg import FSMState
from duckietown_msgs.msg import WheelsCmdStamped

class LShape:

    def __init__(self):
        # Subscribe to joystick_override
        rospy.Subscriber('/luke/fsm_node/mode', FSMState, self.callback)
        # Set sleep rate
        self.rate = rospy.Rate(1)
        # Publisher to publish to wheels
        self.wheel_pub = rospy.Publisher('/luke/wheels_driver_node/wheels_cmd', WheelsCmdStamped, queue_size=10)

    def callback(self, joystick_override):
        wheel_update = WheelsCmdStamped()
        # 
        if joystick_override.state == "LANE_FOLLOWING":
            # publish to right and left wheels to go straight
            wheel_update.vel_right = 0.2
            wheel_update.vel_left = 0.2
            self.wheel_pub.publish(wheel_update)
            self.rate.sleep()
            # publish to right and left wheels to turn left
            wheel_update.vel_right = 0.2
            wheel_update.vel_left = -0.2
            self.wheel_pub.publish(wheel_update)
            self.rate.sleep()
            # publish to right and left wheels to go straight
            wheel_update.vel_right = 0.2
            wheel_update.vel_left = 0.2
            self.wheel_pub.publish(wheel_update)
            self.rate.sleep()
            # publish to the right and left wheels to do nothing
            wheel_update.vel_right = 0.0
            wheel_update.vel_left = 0.0
            self.wheel_pub.publish(wheel_update)
            self.rate.sleep()
        else:
            # publish to the right and left wheels to do nothing
            wheel_update.vel_right = 0.0
            wheel_update.vel_left = 0.0
            self.wheel_pub.publish(wheel_update)

if __name__ == '__main__':
    rospy.init_node('LShape', anonymous=True)
    object = LShape()
    rospy.spin()
