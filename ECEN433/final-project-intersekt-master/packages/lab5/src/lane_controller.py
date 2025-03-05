#!/usr/bin/env python3

import numpy as np
import sys
import rospy
from std_msgs.msg import Float32, Bool
from duckietown_msgs.msg import (
    Twist2DStamped,
    LanePose,
)

DEF_RATE = 1

KP_DIST = -11
KI_DIST = 0
KD_DIST = -0.02

KP_PHI = -8
KI_PHI = 0
KD_PHI = -0.05

K_DIST_WINDOW = 50
K_PHI_WINDOW = 50
K_UPDATE_DIST = False
K_UPDATE_PHI = False

ERROR_READ_RATE = 5

ERROR_STATUS = 1

VEL = 0.2


class LaneControllerNode:
	def __init__(self):
		init_str = "initializing LaneController to perform lane control"
		rospy.loginfo(init_str)
		
		## publishers
		self.pub_car_cmd = rospy.Publisher("lane_controller_node/car_cmd",Twist2DStamped,queue_size=10)
		
		## subscribers
		rospy.Subscriber('lane_filter_node/lane_pose', LanePose, self.callback)
		rospy.Subscriber('fsm/enable_lane_control', Bool, self.enable_lane_control)
		
		# Initialize class variables
		self.pose = LanePose()
		
		self.d_err = 0
		self.phi_err = 0
		self.status = 0
		
		self.dist_sum_err = 0.0
		self.dist_prev_err = 0.0
		
		self.phi_sum_err = 0.0
		self.phi_prev_err_ = 0.0
		
		self.time_prev = rospy.get_time()
		self.time_now = self.time_prev
		self.dist_control = 0
		self.phi_control = 0

		self.lane_control_enabled = False
		
		self.rate = rospy.Rate(DEF_RATE)

	# Callback to determine if lane_control is enabled
	def enable_lane_control(self, data):
		self.lane_control_enabled = data.data
		return

	# General call back for d and phi error adjusting
	def callback(self, data):
		
		# Set values
		self.pose = data
		self.dist_prev_err = self.d_err
		self.phi_prev_err = self.phi_err
		self.d_err = data.d
		self.phi_err = data.phi
		self.status = data.status
	
		self.time_prev = self.time_now
		self.time_now = rospy.get_time()
	
		self.calcDistControl()
		self.calcPhiControl()
		
		cmd = Twist2DStamped(v=VEL, omega=self.dist_control+self.phi_control)
		if self.lane_control_enabled:
			self.pub_car_cmd.publish(cmd)
	
	# Calculate 
	def calcDistControl(self):
	
		delta_t = self.time_now - self.time_prev
		p_error = self.d_err
		partial = delta_t * self.d_err
		self.dist_sum_err = self.dist_sum_err + partial
		i_error = self.dist_sum_err
		d_error = (self.d_err - self.dist_prev_err) / delta_t
		self.dist_control = p_error * KP_DIST + i_error * KI_DIST + d_error * KD_DIST
		
	def calcPhiControl(self):
	
		delta_t = self.time_now - self.time_prev
		p_error = self.phi_err
		partial = delta_t * self.phi_err
		self.phi_sum_err = self.phi_sum_err + partial
		i_error = self.phi_sum_err
		d_error = (self.phi_err - self.phi_prev_err) / delta_t
		self.phi_control = p_error * KP_PHI + i_error * KI_PHI + d_error * KD_PHI
		

if __name__ == '__main__':
	try:
		rospy.init_node('LaneControllerNode', anonymous=True)
		node = LaneControllerNode()
		while not rospy.is_shutdown():
			if rospy.has_param("/kp_dist"):
				KP_DIST = rospy.get_param("/kp_dist")
			if rospy.has_param("/ki_dist"):
				KI_DIST = rospy.get_param("/ki_dist")
			if rospy.has_param("/kd_dist"):
				KD_DIST = rospy.get_param("/kd_dist")
			if rospy.has_param("/kp_phi"):
				KP_PHI = rospy.get_param("/kp_phi")
			if rospy.has_param("/ki_phi"):
				KI_PHI = rospy.get_param("/ki_phi")
			if rospy.has_param("/kd_phi"):
				KD_PHI = rospy.get_param("/kd_phi")
			if rospy.has_param("/vel"):
				VEL = rospy.get_param("/vel")
			if rospy.has_param("/k_dist_window"):
				if (rospy.get_param("/k_dist_window" != K_DIST_WINDOW)):
					K_DIST_WINDOW = rospy.get_param("/k_dist_window")
					K_UPDATE_DIST = True
			if rospy.has_param("/k_phi_window"):
				if (rospy.get_param("/k_phi_window" != K_PHI_WINDOW)):
					K_PHI_WINDOW = rospy.get_param("/k_phi_window")
					K_UPDATE_PHI = True
			if rospy.has_param("/error_read_rate"):
				ERROR_READ_RATE = rospy.get_param("/error_read_rate")
			node.rate.sleep()
	except rospy.ROSInterruptException:
		pass
