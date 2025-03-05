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
        ticksRight = tick_data.wheel_ticks_right
        ticksLeft = tick_data.wheel_ticks_left
        # 0) Define variables and determine alpha
        radius = 0.0318 # Wheel radius
        length = 0.05 # Distance from wheel to origin (so 2L is wheel to wheel)
        ticksPerRotation = 135
        alpha = (2 * np.pi) / ticksPerRotation # Change in angle per tick
        # 1) Determining the rotation of each wheel through the wheel encoder measurements
        deltaThetaRight = ticksRight * alpha
        deltaThetaLeft = ticksLeft * alpha
        # 2) Deriving the total distance travelled by each wheel
        distTraveledRight = radius * deltaThetaRight
        distTraveledLeft = radius * deltaThetaLeft
        # 3) Finding the rotation and distance travelled by the robot (frame)
        totalDistTraveled = (distTraveledRight + distTraveledLeft) / 2
        deltaTheta = (distTraveledRight - distTraveledLeft) / (2 * length)
        # 4) Expressing the robot motion in the world reference frame
        deltaX = totalDistTraveled * np.cos(self.theta + deltaTheta/2)
        deltaY = totalDistTraveled * np.sin(self.theta + deltaTheta/2)
        
        self.x += deltaX
        self.y += deltaY
        self.theta += deltaTheta

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
