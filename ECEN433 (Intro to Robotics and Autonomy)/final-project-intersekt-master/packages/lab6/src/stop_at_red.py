#!/usr/bin/env python3

#https://samuelfneumann.github.io/posts/duckie_4/

import numpy as np
import sys
import rospy
from std_msgs.msg import Float32, Float64
from geometry_msgs.msg import Point
from duckietown_msgs.msg import (
    Twist2DStamped,
    LanePose,
)
from duckietown_messages.sensors.range import Range
from apriltags import AprilTagDetection, AprilTagDetectionArray

DEF_RATE = 1

KP_DIST = -11
KI_DIST = 0
KD_DIST = -0.02

VEL = 0.2

class StopAtRedPIDNode:
	def __init__(self):
		init_str = "initializing StopAtRedPIDNode to perform stopping"
		rospy.loginfo(init_str)
		
		## publishers
		self.pub_car_cmd = rospy.Publisher("lane_controller_node/car_cmd",Twist2DStamped,queue_size=10)
		
		## subscribers
		rospy.Subscriber('duckiebot_position', Point, self.callbackDist)
		
		self.d_err = 0
		self.dist_sum_err = 0.0
		self.dist_prev_err = 0.0
		
		
		
		self.time_prev = rospy.get_time()
		self.time_now = self.time_prev
		self.dist_control = 0
		
		
		self.rate = rospy.Rate(DEF_RATE)
		
	
	def callbackDist(self, data):
		self.d_err = data.x		
	
	def doPID(self):
		self.calcDistControl()
		self.calcTOFControl()
		#where we decide

		cmd = Twist2DStamped(v=VEL, omega=self.dist_control+self.phi_control)
		self.pub_car_cmd.publish(cmd)
		return 
		
	def calcTOFControl(self):
		
		return
	def calcDistControl(self):
	
		delta_t = self.time_now - self.time_prev
		
		#do proportional
		p_error = self.d_err
		
		#do integral
		partial = delta_t * self.d_err
		self.dist_sum_err = self.dist_sum_err + partial
		i_error = self.dist_sum_err
		
		#do derivative
		d_error = (self.d_err - self.dist_prev_err) / delta_t
		
		self.dist_control = p_error * KP_DIST + i_error * KI_DIST + d_error * KD_DIST

if __name__ == '__main__':
	try:
		rospy.init_node('StopAtRedPIDNode', anonymous=True)
		node = StopAtRedPIDNode()
		while not rospy.is_shutdown():
			if rospy.has_param("/kp_dist"):
				KP_DIST = rospy.get_param("/kp_dist")
			if rospy.has_param("/ki_dist"):
				KI_DIST = rospy.get_param("/ki_dist")
			if rospy.has_param("/kd_dist"):
				KD_DIST = rospy.get_param("/kd_dist")
			if rospy.has_param("/vel"):
				VEL = rospy.get_param("/vel")
			node.doPID()
			node.rate.sleep()
	except rospy.ROSInterruptException:
		pass
