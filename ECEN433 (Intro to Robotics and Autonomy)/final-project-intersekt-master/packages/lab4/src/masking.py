#!/usr/bin/env python3

import sys
import rospy
import cv2
from sensor_msgs.msg import Image
from cv_bridge import CvBridge

CSV_YELLOW_LOWER = (18, 53, 100)
CSV_YELLOW_UPPER = (30, 255, 255)

CSV_WHITE_LOWER = (80, 0, 148)
CSV_WHITE_UPPER = (255, 120, 255) 

CSV_RED_LOWER = (178,0,0)
CSV_RED_UPPER = (255,102,102) 

YELLOW_ERR_KERNEL = (3,3)
YELLOW_DIL_KERNEL = (5,5)

WHITE_ERR_KERNEL = (3,3)
WHITE_DIL_KERNEL = (7,7)

RED_ERR_KERNEL = (3,3)
RED_DIL_KERNEL = (5,5)

DEF_RATE = 1

class MaskNode:
	def __init__(self):
		init_str = "initializing MaskNode to perform image processing"
		rospy.loginfo(init_str)
		self.bridge = CvBridge()
		rospy.Subscriber('image', Image, self.callback)
		self.pub_crop = rospy.Publisher('image_cropped', Image, queue_size=10)
		self.pub_yel = rospy.Publisher('image_yellow', Image, queue_size=10)
		self.pub_whi = rospy.Publisher('image_white', Image, queue_size=10)
		self.pub_red = rospy.Publisher('image_red', Image, queue_size=10)
		
		self.rate = rospy.Rate(DEF_RATE)

	
	def crop_image(self, data):
		cv_img = self.bridge.imgmsg_to_cv2(data, "bgr8")
		height, width, _ = cv_img.shape
		cropped_img = cv_img[height//2:, 0:width]
		ros_crop = self.bridge.cv2_to_imgmsg(cropped_img, "bgr8")
		self.pub_crop.publish(ros_crop)
		return cropped_img

	def hsv_convert(self, data):
		hsv_img = cv2.cvtColor(data, cv2.COLOR_BGR2HSV)
		return hsv_img
	
	def yellow_filter(self, data):
		image_filtered = cv2.inRange(data, CSV_YELLOW_LOWER, CSV_YELLOW_UPPER)
		err_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, YELLOW_ERR_KERNEL)
		image_erode = cv2.erode(image_filtered, err_kernel)
		dil_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, YELLOW_DIL_KERNEL)
		image_dilate = cv2.dilate(image_erode, dil_kernel)
		ros_yellow_filtered = self.bridge.cv2_to_imgmsg(image_dilate, "mono8")
		self.pub_yel.publish(ros_yellow_filtered)
		return
		
	def white_filter(self, data):
		image_filtered = cv2.inRange(data, CSV_WHITE_LOWER, CSV_WHITE_UPPER)
		err_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, WHITE_ERR_KERNEL)
		image_erode = cv2.erode(image_filtered, err_kernel)
		dil_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, WHITE_DIL_KERNEL)
		image_dilate = cv2.dilate(image_erode, dil_kernel)
		ros_white_filtered = self.bridge.cv2_to_imgmsg(image_dilate, "mono8")
		self.pub_whi.publish(ros_white_filtered)
		return
	
	def red_filter(self, data):
		image_filtered = cv2.inRange(data, CSV_RED_LOWER, CSV_RED_UPPER)
		err_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, RED_ERR_KERNEL)
		image_erode = cv2.erode(image_filtered, err_kernel)
		dil_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, RED_DIL_KERNEL)
		image_dilate = cv2.dilate(image_erode, dil_kernel)
		ros_red_filtered = self.bridge.cv2_to_imgmsg(image_dilate, "mono8")
		self.pub_red.publish(ros_red_filtered)
		return
	
	def callback(self, data):
		cropped = self.crop_image(data)
		hsv = self.hsv_convert(cropped)
		self.yellow_filter(hsv)
		self.white_filter(hsv)
		self.red_filter(hsv)
		str_out =  " %s" % rospy.get_time()
		rospy.loginfo(str_out)

if __name__ == '__main__':
	try:
		rospy.init_node('MaskNode', anonymous=True)
		node = MaskNode()
		while not rospy.is_shutdown():
			if rospy.has_param("/csv_yellow_lower"):
				CSV_YELLOW_LOWER = eval(rospy.get_param("/csv_yellow_lower"))
			if rospy.has_param("/csv_yellow_upper"):
				CSV_YELLOW_UPPER = eval(rospy.get_param("/csv_yellow_upper"))
			if rospy.has_param("/csv_white_lower"):
				CSV_WHITE_LOWER = eval(rospy.get_param("/csv_white_lower"))
			if rospy.has_param("/csv_white_upper"):
				CSV_WHITE_UPPER = eval(rospy.get_param("/csv_white_upper"))
			if rospy.has_param("/yellow_err_kernel"):
				YELLOW_ERR_KERNEL = eval(rospy.get_param("/yellow_err_kernel"))
			if rospy.has_param("/yellow_dil_kernel"):
				YELLOW_DIL_KERNEL = eval(rospy.get_param("/yellow_dil_kernel"))
			if rospy.has_param("/white_err_kernel"):
				WHITE_ERR_KERNEL = eval(rospy.get_param("/white_err_kernel"))
			if rospy.has_param("/white_dil_kernel"):
				WHITE_DIL_KERNEL = eval(rospy.get_param("/white_dil_kernel"))

			#red
			if rospy.has_param("/csv_red_lower"):
				CSV_RED_LOWER = eval(rospy.get_param("/csv_red_lower"))
			if rospy.has_param("/csv_red_upper"):
				CSV_RED_UPPER = eval(rospy.get_param("/csv_white_upper"))
			if rospy.has_param("/red_err_kernel"):
				RED_ERR_KERNEL = eval(rospy.get_param("/red_err_kernel"))
			if rospy.has_param("/red_dil_kernel"):
				RED_DIL_KERNEL = eval(rospy.get_param("/red_dil_kernel"))
			node.rate.sleep()
	except rospy.ROSInterruptException:
		pass
