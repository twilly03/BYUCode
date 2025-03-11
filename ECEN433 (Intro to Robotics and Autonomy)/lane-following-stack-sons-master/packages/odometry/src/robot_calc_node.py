#!/usr/bin/env python3

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
from duckietown_msgs.msg import WheelEncoderStamped


class RobotCalcNode:
    def __init__(self):
        self.distTraveledRight = 0
        self.distTraveledLeft = 0
        self.totalDistTraveled = 0
        #
        self.deltaThetaRight = 0
        self.deltaThetaLeft = 0
        self.deltaTheta = 0
        # 
        self.deltaX = 0
        self.deltaY = 0
        # 
        self.x = 0.0
        self.y = 0.0
        self.theta = 0.0
        # 
        self.currentTicksRight = 0.0
        self.prevTicksRight = 0.0
        self.deltaTicksRight = 0.0
        # 
        self.currentTicksLeft = 0.0
        self.prevTicksLeft = 0.0
        self.deltaTicksLeft = 0.0
        # 
        self.radius = 0.0318 # Wheel radius
        self.length = 0.05 # Distance from wheel to origin (so 2L is wheel to wheel)
        ticksPerRotation = 135
        self.alpha = (2 * np.pi) / ticksPerRotation # Change in angle per tick

        # Subscribe to ticks from each wheel encoder
        self.tick_sub = rospy.Subscriber('/luke/right_wheel_encoder_node/tick', WheelEncoderStamped, self.update_pose_right)
        self.tick_sub = rospy.Subscriber('/luke/left_wheel_encoder_node/tick', WheelEncoderStamped, self.update_pose_left)
        
        # Publisher to publish to odom_graph
        self.pose_pub = rospy.Publisher('pose', Pose2D, queue_size=10)

    def update_pose_right(self, right_encoder_data):
        self.currentTicksRight = right_encoder_data.data
    
    def update_pose_left(self, left_encoder_data):
        self.currentTicksLeft = left_encoder_data.data

    def calculate_pose(self):
        # Calculate deltaTicksLeft
        self.deltaTicksLeft = self.currentTicksLeft - self.prevTicksLeft
        self.prevTicksLeft += self.deltaTicksLeft 

        # Calculate deltaTicksRight
        self.deltaTicksRight = self.currentTicksRight - self.prevTicksRight
        self.prevTicksRight += self.deltaTicksRight

        # 1) Determining the rotation of each wheel through the wheel encoder measurements
        self.deltaThetaRight = self.deltaTicksRight * self.alpha
        self.deltaThetaLeft = self.deltaTicksLeft * self.alpha
        # 2) Deriving the total distance travelled by each wheel
        self.distTraveledRight = self.radius * self.deltaThetaRight
        self.distTraveledLeft = self.radius * self.deltaThetaLeft
        # 3) Finding the rotation and distance travelled by the robot (frame)
        self.totalDistTraveled = (self.distTraveledRight + self.distTraveledLeft) / 2.0
        self.deltaTheta = (self.distTraveledRight - self.distTraveledLeft) / (2 * self.length)
        # 4) Expressing the robot motion in the world reference frame
        self.deltaX = self.totalDistTraveled * np.cos(self.theta + self.deltaTheta/2.0)
        self.deltaY = self.totalDistTraveled * np.sin(self.theta + self.deltaTheta/2.0)
        
        self.x += self.deltaX
        self.y += self.deltaY
        self.theta += self.deltaTheta

        # Create and publish the new pose
        pose = Pose2D()
        pose.x = self.x
        pose.y = self.y
        pose.theta = self.theta
        self.pose_pub.publish(pose)
        

if __name__ == '__main__':
    rospy.init_node('calc_node', anonymous=True)
    updater = RobotCalcNode()
    # Run calculator function at certain rate
    rate = rospy.Rate(20)
    while not rospy.is_shutdown():
        updater.calculate_pose()
        rate.sleep()
    rospy.spin()
