#!/usr/bin/env python3

import sys
import rospy
from std_msgs.msg import Float32

K_P = 3
K_I = 0.00001
K_D = 4

DEF_RATE = 1

class PidNode:
	def __init__(self):
		init_str = "initializing PidNode to perform kinematics control"
		rospy.loginfo(init_str)
		rospy.Subscriber('error', Float32, self.callback)
		rospy.Subscriber('velocity', Float32, self.getVelocity)
		self.pub = rospy.Publisher('control_input', Float32, queue_size=10)
		self.rate = rospy.Rate(DEF_RATE)
		self.error = 0.0
		self.error_sum = 0.0
		self.error_prev = 0.0
		self.velocity = 0.0
		self.time_prev = rospy.get_time()
		self.time_now = self.time_prev
		rospy.set_param('controller_ready', "true")
		
	def getVelocity(self, data):
		self.velocity = data.data

	
	def callback(self, data):
		self.time_now = rospy.get_time()
		
		self.error_prev = self.error
		self.error = data.data
		
		delta_t = 0.1
		self.time_now = self.time_prev
		 
		#do proportional
		p_error = data.data
		
		#do integral
		self.error_sum = self.error_sum + delta_t * self.error
		i_error = self.error_sum
		
		#do derivative
		d_error = (self.error - self.error_prev) / delta_t
		
		control_input = p_error * K_P + i_error * K_I + d_error * K_D
		
		if(control_input >= 30):
			control_input = 30
		
		control_input_msg = Float32()
		control_input_msg.data = control_input


		self.pub.publish(control_input_msg)

if __name__ == '__main__':
	try:
		rospy.init_node('PidNode', anonymous=True)
		node = PidNode()
		while not rospy.is_shutdown():
			if rospy.has_param("/k_p"):
				K_P = rospy.get_param("/k_p")
			if rospy.has_param("/k_i"):
				K_I = rospy.get_param("/k_i")
			if rospy.has_param("/k_d"):
				K_D = rospy.get_param("/k_d")
			node.rate.sleep()
	except rospy.ROSInterruptException:
		pass
