#!/usr/bin/env python3

import sys
import rospy
import cv2
import numpy as np
from sensor_msgs.msg import Image
from cv_bridge import CvBridge

DEF_RATE = 1

CANNY_LOW = 100
CANNY_HIGH = 200
CANNY_DIL = (1,1)

Y_HOUGH_RHO = 1
Y_HOUGH_THETA = np.pi / 180
Y_THRESH = 15
Y_MIN_LENGTH = 12
Y_MAX_GAP = 7

W_HOUGH_RHO = 1
W_HOUGH_THETA = np.pi / 180
W_THRESH = 15
W_MIN_LENGTH = 12
W_MAX_GAP = 7

R_HOUGH_RHO = 1
R_HOUGH_THETA = np.pi / 180
R_THRESH = 15
R_MIN_LENGTH = 12
R_MAX_GAP = 7

class HoughNode:
	def __init__(self):
		init_str = "initializing HoughNode to perform edge processing"
		rospy.loginfo(init_str)
		self.bridge = CvBridge()
		rospy.Subscriber('image_cropped', Image, self.canny_edge)
		rospy.Subscriber('image_yellow', Image, self.yellow_back)
		rospy.Subscriber('image_white', Image, self.white_back)
		rospy.Subscriber('image_red', Image, self.red_back)
		
		self.pub_canny = rospy.Publisher('image_edges', Image, queue_size=10)
		self.pub_white = rospy.Publisher('image_lines_white', Image, queue_size=10)
		self.pub_yellow = rospy.Publisher('image_lines_yellow', Image, queue_size=10)
		self.pub_red = rospy.Publisher('image_lines_red', Image, queue_size=10)
		self.pub_bit = rospy.Publisher('image_bitwise', Image, queue_size=10)
		
		self.rate = rospy.Rate(DEF_RATE)
		self.cropped = None
		self.cannyEdge = None
		self.cannyEdit = None
		self.received_first_image = False
		
		self.yellow = None
		self.white = None
		self.red = None
		
	def canny_edge(self, data):
		#Performs Canny edge detection on the cropped image. 
		#Publish this (for debug/grading purposes) to the topic /image_edges
		self.cropped = self.bridge.imgmsg_to_cv2(data, "bgr8")
		self.received_first_image = True
		self.cannyEdge = cv2.Canny(self.cropped, CANNY_LOW, CANNY_HIGH)
		
		dil_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, CANNY_DIL)
		self.cannyEdit = cv2.dilate(self.cannyEdge, dil_kernel)
		
		
		cannyEdgeRos = self.bridge.cv2_to_imgmsg(self.cannyEdge, "mono8")
		self.yellow_mask()
		self.white_mask()
		self.red_mask()
		self.pub_canny.publish(cannyEdgeRos)
		return
	def yellow_back(self, data):
		self.yellow = self.bridge.imgmsg_to_cv2(data, "mono8")
		return 
	def white_back(self, data):
		self.white = self.bridge.imgmsg_to_cv2(data, "mono8")
		return
	def red_back(self, data):
		self.red = self.bridge.imgmsg_to_cv2(data, "mono8")
		return
		
	def yellow_mask(self):
		#do masking
		maskedYellow = cv2.bitwise_and(self.cannyEdit, self.yellow)
		maskedYellowRos = self.bridge.cv2_to_imgmsg(maskedYellow, "mono8")
		self.pub_bit.publish(maskedYellowRos)
		#do hough
		yellLines = cv2.HoughLinesP(maskedYellow, rho=Y_HOUGH_RHO, theta=Y_HOUGH_THETA, threshold = Y_THRESH, minLineLength=Y_MIN_LENGTH, maxLineGap=Y_MAX_GAP)
		#do output_lines print lines on image
		final_yellow = self.output_lines(self.cropped, yellLines)
		#publish image
		finalYellowRos = self.bridge.cv2_to_imgmsg(final_yellow, "bgr8")
		self.pub_yellow.publish(finalYellowRos)
		return
		
	def white_mask(self):
		#do masking
		maskedWhite = cv2.bitwise_and(self.cannyEdge, self.white)
		#do hough
		whiteLines = cv2.HoughLinesP(maskedWhite, rho=W_HOUGH_RHO, theta=W_HOUGH_THETA, threshold = W_THRESH, minLineLength=W_MIN_LENGTH, maxLineGap=W_MAX_GAP)
		#do output_lines print lines on image
		final_white = self.output_lines(self.cropped, whiteLines)
		#publish image
		finalWhiteRos = self.bridge.cv2_to_imgmsg(final_white, "bgr8")
		self.pub_white.publish(finalWhiteRos)
		return
	
	def red_mask(self):
		#do masking
		maskedRed = cv2.bitwise_and(self.cannyEdge, self.red)
		#do hough
		redLines = cv2.HoughLinesP(maskedRed, rho = R_HOUGH_RHO, theta = R_HOUGH_THETA, threshold = R_THRESH, minLineLength = R_MIN_LENGTH, maxLineGap = R_MAX_GAP)
		#do output_lines print lines on image
		final_red = self.output_lines(self.cropped, redLines)
		#publish image
		finalRedRos = self.bridge.cv2_to_imgmsg(final_red, "bgr8")
		self.pub_red.publish(finalRedRos)
		return
		
	def output_lines(self,original_image, lines):
		output = np.copy(original_image)
		if lines is not None:
			for i in range(len(lines)):
				l = lines[i][0]
				cv2.line(output, (l[0],l[1]), (l[2],l[3]), (255,0,0), 2, cv2.LINE_AA)
				cv2.circle(output, (l[0],l[1]), 2, (0,255,0))
				cv2.circle(output, (l[2],l[3]), 2, (0,0,255))
		return output
	

if __name__ == '__main__':
	try:
		rospy.init_node('HoughNode', anonymous=True)
		node = HoughNode()
		while not rospy.is_shutdown():
			if rospy.has_param("/canny_lower"):
				CANNY_LOW = (rospy.get_param("/canny_lower"))
			if rospy.has_param("/canny_upper"):
				CANNY_HIGH = (rospy.get_param("/canny_upper"))
			if rospy.has_param("/canny_dil"):
				CANNY_DIL = eval(rospy.get_param("/canny_dil"))
				
			if rospy.has_param("/y_hough_rho"):
				Y_HOUGH_RHO = (rospy.get_param("/y_hough_rho"))
			if rospy.has_param("/y_hough_theta"):
				Y_HOUGH_THETA = (rospy.get_param("/y_hough_theta"))	
			if rospy.has_param("/y_thresh"):
				Y_THRESH = (rospy.get_param("/y_thresh"))
			if rospy.has_param("/y_min_length"):
				Y_MIN_LENGTH = (rospy.get_param("/y_min_length"))
			if rospy.has_param("/y_max_gap"):
				Y_MAX_GAP = (rospy.get_param("/y_max_gap"))
			
				
			if rospy.has_param("/w_hough_rho"):
				W_HOUGH_RHO = (rospy.get_param("/w_hough_rho"))
			if rospy.has_param("/w_hough_theta"):
				W_HOUGH_THETA = (rospy.get_param("/w_hough_theta"))	
			if rospy.has_param("/w_thresh"):
				W_THRESH = (rospy.get_param("/w_thresh"))
			if rospy.has_param("/w_min_length"):
				W_MIN_LENGTH = (rospy.get_param("/w_min_length"))
			if rospy.has_param("/w_max_gap"):
				W_MAX_GAP = (rospy.get_param("/w_max_gap"))


			if rospy.has_param("/r_hough_rho"):
				R_HOUGH_RHO = (rospy.get_param("/r_hough_rho"))
			if rospy.has_param("/r_hough_theta"):
				R_HOUGH_THETA = (rospy.get_param("/r_hough_theta"))	
			if rospy.has_param("/r_thresh"):
				R_THRESH = (rospy.get_param("/r_thresh"))
			if rospy.has_param("/r_min_length"):
				R_MIN_LENGTH = (rospy.get_param("/r_min_length"))
			if rospy.has_param("/r_max_gap"):
				R_MAX_GAP = (rospy.get_param("/r_max_gap"))
			
			node.rate.sleep()
	except rospy.ROSInterruptException:
		pass
