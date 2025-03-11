#!/usr/bin/env python3

import sys
import rospy
import os
import cv2
import numpy as np
from sensor_msgs.msg import Image
from sensor_msgs.msg import CompressedImage
from duckietown_msgs.msg import Segment
from duckietown_msgs.msg import SegmentList
from duckietown_msgs.msg import Vector2D
from cv_bridge import CvBridge
from std_srvs.srv import SetBool, SetBoolResponse

CSV_YELLOW_LOWER = (18, 53, 100)
CSV_YELLOW_UPPER = (30, 255, 255)

CSV_WHITE_LOWER = (80, 0, 148)
CSV_WHITE_UPPER = (255, 120, 255)

CSV_RED_LOWER = (178,0,0)
CSV_RED_UPPER = (255,102,102) 

YELLOW_ERR_KERNEL = (3,3)
YELLOW_DIL_KERNEL = (5,5)

WHITE_ERR_KERNEL = (3,3)
WHITE_DIL_KERNEL = (9,9)

RED_ERR_KERNEL = (3,3)
RED_DIL_KERNEL = (5,5)

CANNY_LOW = 100
CANNY_HIGH = 200

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

DEF_RATE = 0.5

class CombNode:
	def __init__(self):
		init_str = "initializing CombNode to perform image processing"
		rospy.loginfo(init_str)
		self.bridge = CvBridge()
		
		rospy.Service('line_detector_node/switch', SetBool, self.ld_switch)
		rospy.Service('lane_filter_node/switch', SetBool, self.lf_switch)
		
		self.botName = os.environ['VEHICLE_NAME']
		self.cameraTopic = f"/{self.botName}/camera_node/image/compressed"
		rospy.Subscriber(self.cameraTopic,CompressedImage,self.callback, queue_size=1,buff_size=2**24)
		
		self.projectionTopic = f"/{self.botName}/line_detector_node/segment_list"
		self.pub_ground = rospy.Publisher(self.projectionTopic, SegmentList, queue_size=10)
		self.redprojectionTopic = f"/{self.botName}/line_detector_node/segment_list"	
		self.pub_red = rospy.Publisher(self.redprojectionTopic, SegmentList, queue_size=10)
		
		self.cropped = None
		self.cannyEdge = None
		
		self.yellow = None
		self.white = None
		self.red = None
		
		self.image_size = (160, 120)
		self.offset = 40 # you can choose what this crop offset is
		
		self.yellLines = None
		self.whiteLines = None
		self.redLines = None
		
		self.rate = rospy.Rate(DEF_RATE)
	
	def callback(self, data):
		self.crop_image(data)
		
		#canny
		self.canny_edge(self.cropped)
			
		#hsv
		hsv = self.hsv_convert(self.cropped)
		
		#yellow filtering
		self.yellow = self.yellow_filter(hsv)
		
		#yellow masking
		self.yellow_mask()
			
		#white filtering
		self.white = self.white_filter(hsv)
		
		#white masking
		self.white_mask()

		#white filtering
		self.red = self.red_filter(hsv)
		
		#white masking
		self.red_mask()

		whiteYellowSegmentList = SegmentList()
		
		if(self.yellLines is not None):
			for i in range(len(self.yellLines)):
				arr_cutoff = np.array([0, self.offset, 0, self.offset])
				arr_ratio = np.array([1. / self.image_size[0], 1. / self.image_size[1], 1. /self.image_size[0], 1. /self.image_size[1]])
				line_normalized = (self.yellLines[i][0] + arr_cutoff) * arr_ratio
				thisSVector = Vector2D()
				thisEVector = Vector2D()
				thisSVector.x = line_normalized[0]
				thisSVector.y = line_normalized[1]
				thisEVector.x = line_normalized[2]
				thisEVector.y = line_normalized[3]
				pix_norm = [thisSVector, thisEVector]
				thisSeg = Segment(color=1, pixels_normalized = pix_norm)
				whiteYellowSegmentList.segments.append(thisSeg)
			
			
		if(self.whiteLines is not None):
			for i in range(len(self.whiteLines)):
				arr_cutoff = np.array([0, self.offset, 0, self.offset])
				arr_ratio = np.array([1. / self.image_size[0], 1. / self.image_size[1], 1. /self.image_size[0], 1. /self.image_size[1]])
				line_normalized = (self.whiteLines[i][0] + arr_cutoff) * arr_ratio
				thisSVector = Vector2D()
				thisEVector = Vector2D()
				thisSVector.x = line_normalized[0]
				thisSVector.y = line_normalized[1]
				thisEVector.x = line_normalized[2]
				thisEVector.y = line_normalized[3]
				pix_norm = [thisSVector, thisEVector]
				thisSeg = Segment(color=0, pixels_normalized = pix_norm)
				whiteYellowSegmentList.segments.append(thisSeg)


		if(self.redLines is not None):
			for i in range(len(self.redLines)):
				arr_cutoff = np.array([0, self.offset, 0, self.offset])
				arr_ratio = np.array([1. / self.image_size[0], 1. / self.image_size[1], 1. /self.image_size[0], 1. /self.image_size[1]])
				line_normalized = (self.redLines[i][0] + arr_cutoff) * arr_ratio
				thisSVector = Vector2D()
				thisEVector = Vector2D()
				thisSVector.x = line_normalized[0]
				thisSVector.y = line_normalized[1]
				thisEVector.x = line_normalized[2]
				thisEVector.y = line_normalized[3]
				pix_norm = [thisSVector, thisEVector]
				thisSeg = Segment(color=2, pixels_normalized = pix_norm) # TODO Make this red 
				whiteYellowSegmentList.segments.append(thisSeg)
		
		if(whiteYellowSegmentList.segments is not None):
			self.pub_ground.publish(whiteYellowSegmentList)
		return
	
	def canny_edge(self, data):
		self.cannyEdge = cv2.Canny(data, CANNY_LOW, CANNY_HIGH)
		return
	
	def crop_image(self, data):
		compressedRos = self.bridge.compressed_imgmsg_to_cv2(data, "bgr8")
		new_image = cv2.resize(compressedRos, self.image_size, interpolation=cv2.INTER_NEAREST)
		self.cropped = new_image[self.offset:, :]
		return

	def hsv_convert(self, data):
		hsv_img = cv2.cvtColor(data, cv2.COLOR_BGR2HSV)
		return hsv_img
	
	def yellow_filter(self, data):
		image_filtered = cv2.inRange(data, CSV_YELLOW_LOWER, CSV_YELLOW_UPPER)
		err_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, YELLOW_ERR_KERNEL)
		image_erode = cv2.erode(image_filtered, err_kernel)
		dil_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, YELLOW_DIL_KERNEL)
		image_dilate = cv2.dilate(image_erode, dil_kernel)
		return image_dilate
		
	def white_filter(self, data):
		CSV_WHITE_H_LOWER = rospy.get_param("/CSV_WHITE_H_LOWER", 80)
		CSV_WHITE_H_HIGHER = rospy.get_param("/CSV_WHITE_H_HIGHER", 255)
		CSV_WHITE_S_LOWER = rospy.get_param("/CSV_WHITE_S_LOWER", 0)
		CSV_WHITE_S_HIGHER = rospy.get_param("/CSV_WHITE_S_HIGHER", 120)
		CSV_WHITE_V_LOWER = rospy.get_param("/CSV_WHITE_V_LOWER", 148)
		CSV_WHITE_V_HIGHER = rospy.get_param("/CSV_WHITE_V_HIGHER", 255)
		image_filtered = cv2.inRange(data, (CSV_WHITE_H_LOWER, CSV_WHITE_S_LOWER, CSV_WHITE_V_LOWER), (CSV_WHITE_S_HIGHER, CSV_WHITE_V_HIGHER, CSV_WHITE_H_HIGHER))
		err_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, WHITE_ERR_KERNEL)
		image_erode = cv2.erode(image_filtered, err_kernel)
		dil_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, WHITE_DIL_KERNEL)
		image_dilate = cv2.dilate(image_erode, dil_kernel)
		return image_dilate
	
	def red_filter(self, data):
		CSV_RED_H_LOWER = rospy.get_param("/CSV_RED_H_LOWER", 150)
		CSV_RED_H_HIGHER = rospy.get_param("/CSV_RED_H_HIGHER", 255)
		CSV_RED_S_LOWER = rospy.get_param("/CSV_RED_S_LOWER", 0)
		CSV_RED_S_HIGHER = rospy.get_param("/CSV_RED_S_HIGHER", 255)
		CSV_RED_V_LOWER = rospy.get_param("/CSV_RED_V_LOWER", 0)
		CSV_RED_V_HIGHER = rospy.get_param("/CSV_RED_V_HIGHER", 255)
		image_filtered = cv2.inRange(data, (CSV_RED_H_LOWER, CSV_RED_S_LOWER, CSV_RED_V_LOWER), (CSV_RED_S_HIGHER, CSV_RED_V_HIGHER, CSV_RED_H_HIGHER))
		err_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, RED_ERR_KERNEL)
		image_erode = cv2.erode(image_filtered, err_kernel)
		dil_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, RED_DIL_KERNEL)
		image_dilate = cv2.dilate(image_erode, dil_kernel)
		return image_dilate
		
	def yellow_mask(self):
		#do masking
		maskedYellow = cv2.bitwise_and(self.cannyEdge, self.yellow)
		#do hough
		self.yellLines = cv2.HoughLinesP(maskedYellow, rho=Y_HOUGH_RHO, theta=Y_HOUGH_THETA, threshold = Y_THRESH, minLineLength=Y_MIN_LENGTH, maxLineGap=Y_MAX_GAP)
		return
		
	def white_mask(self):
		#do masking
		maskedWhite = cv2.bitwise_and(self.cannyEdge, self.white)
		#do hough
		self.whiteLines = cv2.HoughLinesP(maskedWhite, rho=W_HOUGH_RHO, theta=W_HOUGH_THETA, threshold = W_THRESH, minLineLength=W_MIN_LENGTH, maxLineGap=W_MAX_GAP)
		return
	
	def red_mask(self):
		#do masking
		maskedRed = cv2.bitwise_and(self.cannyEdge, self.red)
		#do hough
		self.redLines = cv2.HoughLinesP(maskedRed, rho = R_HOUGH_RHO, theta = R_HOUGH_THETA, threshold = R_THRESH, minLineLength = R_MIN_LENGTH, maxLineGap= R_MAX_GAP)
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
	def ld_switch(self, msg): return True, ""
		
	def lf_switch(self, msg): return True, ""

if __name__ == '__main__':
	try:
		rospy.init_node('CombNode', anonymous=True)
		node = CombNode()
		while not rospy.is_shutdown():
			if rospy.has_param("/csv_yellow_lower"):
				CSV_YELLOW_LOWER = eval(rospy.get_param("/csv_yellow_lower"))
			if rospy.has_param("/csv_yellow_upper"):
				CSV_YELLOW_UPPER = eval(rospy.get_param("/csv_yellow_upper"))
			if rospy.has_param("/csv_white_lower"):
				CSV_WHITE_LOWER = eval(rospy.get_param("/csv_white_lower"))
			if rospy.has_param("/csv_white_upper"):
				CSV_WHITE_UPPER = eval(rospy.get_param("/csv_white_upper"))
			if rospy.has_param("/csv_red_lower"):
				CSV_RED_LOWER = eval(rospy.get_param("/csv_red_lower"))
			if rospy.has_param("/csv_red_upper"):
				CSV_RED_UPPER = eval(rospy.get_param("/csv_red_upper"))
			if rospy.has_param("/yellow_err_kernel"):
				YELLOW_ERR_KERNEL = eval(rospy.get_param("/yellow_err_kernel"))
			if rospy.has_param("/yellow_dil_kernel"):
				YELLOW_DIL_KERNEL = eval(rospy.get_param("/yellow_dil_kernel"))
			if rospy.has_param("/white_err_kernel"):
				WHITE_ERR_KERNEL = eval(rospy.get_param("/white_err_kernel"))
			if rospy.has_param("/white_dil_kernel"):
				WHITE_DIL_KERNEL = eval(rospy.get_param("/white_dil_kernel"))
			if rospy.has_param("/red_err_kernel"):
				RED_ERR_KERNEL = eval(rospy.get_param("/red_err_kernel"))
			if rospy.has_param("/red_dil_kernel"):
				RED_DIL_KERNEL = eval(rospy.get_param("/red_dil_kernel"))
				
				
			if rospy.has_param("/canny_lower"):
				CANNY_LOW = (rospy.get_param("/canny_lower"))
			if rospy.has_param("/canny_upper"):
				CANNY_HIGH = (rospy.get_param("/canny_upper"))
				
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
