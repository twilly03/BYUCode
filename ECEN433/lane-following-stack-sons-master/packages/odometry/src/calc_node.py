#!/usr/bin/env python3
# Analyze the two nodes that are already in the directory, 
# and make a node that receives tick information from the "odom_test_pub" node 
# and publishes the updated (x,y, theta) pose to the odom_graph node. 
# Create a launch file that will run all three nodes.

# 1) Determining the rotation of each wheel through the wheel encoder mesurements

# deltaThetaRight = numTicksRight * alpha = numTicksRight * (2*pi/ numTicksPerRotation)
# deltaThetaLeft = numTicksLeft * alpha = numTicksLeft * (2*pi/ numTicksPerRotation)

# 2) Deriving the total distance travelled by each wheel

# distTraveledRight = radius * deltaThetaRight
# distTraveledLeft = radius * deltaThetaLeft

# 3) Finding the rotation and distance travelled by the robot (frame)

# totalDistTraveled = deltaS = (distTraveledRight + distTraveledLeft) / 2
# deltaTheta = (distTraveledRight - distTraveledLeft) / (2 * length)

# 4) Expressing the robot motion in the world reference frame

# deltaX = totalDistTraveled * cos(theta + deltaTheta/2)
# deltaY = totalDistTraveled * sin(theta + deltaTheta/2)


import rospy
import numpy as np
from odometry.msg import Pose2D
from odometry.msg import WheelTicks


class CalcNode:
    def __init__(self):
        self.x = 0.0
        self.y = 0.0
        self.theta = 0.0

        # Subscribe to ticks from odom_test_pub
        self.tick_sub = rospy.Subscriber('dist_wheel', WheelTicks, self.update_pose)
        
        # Publisher to publish to odom_graph
        self.pose_pub = rospy.Publisher('pose', Pose2D, queue_size=10)

    def update_pose(self, tick_data):
        length = .05 # Distance from wheel to origin (so 2L is wheel to wheel)
        radius = 0.0318 # Wheel radius
        circumference = 2 * np.pi * radius # Wheel circumference
        ticksPerRotation = 135 # Number of ticks per wheel rotation
        tickDistance = circumference / ticksPerRotation
        
        ticks_x = tick_data.wheel_ticks_right * tickDistance
        ticks_y = tick_data.wheel_ticks_left * tickDistance
        ticks = (ticks_x + ticks_y) / 2

        # Calculate change in x and y
        delta_theta = (ticks_x - ticks_y) / (2*length)
        
        delta_x = ticks*np.cos(self.theta + (delta_theta/2))
        delta_y = ticks*np.sin(self.theta + (delta_theta/2))

        # Update pose based on ticks
        self.x += delta_x
        self.y += delta_y
        self.theta += delta_theta

        # Create and publish the new pose
        pose = Pose2D()
        pose.x = self.x
        pose.y = self.y
        pose.theta = self.theta
        self.pose_pub.publish(pose)

if __name__ == '__main__':
    rospy.init_node('calc_node', anonymous=True)
    updater = CalcNode()
    rospy.spin()
