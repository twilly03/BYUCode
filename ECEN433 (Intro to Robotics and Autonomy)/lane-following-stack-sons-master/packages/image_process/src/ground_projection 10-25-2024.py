#!/usr/bin/env python3

# Subscribes to the cropped image from your masking node.

# Performs Canny edge detection on the cropped image. 
# You may use a different method if you find it works better. 

# Publish this (for debug/grading purposes) to the topic /image_edges.

# Subscribes to the white and yellow filtered images from your masking node

# Combines the result of edge detection with EACH of the filtered images using the OpenCV bitwise_and operator. 
# This will produce a two images composed of just the boundaries of the white or yellow markers. 
# If it doesn't produce good boundaries, refine your filter and/or edge detector. 

# You may need to tune your erode/dilate steps from the masking node to do this. 

# You may need to modify your masking node as well.

# Performs a Hough transform on each of the images from step 4

# Draws the lines found in the Hough transform on the yellow and white masked images. 
# This should produce one color image with lines on it for the white lane markers 
# and one color image with lines on it for yellow lane markers. 

# Publish these two images as “/image_lines_white” and “/image_lines_yellow”

import rospy
import numpy as np
import sys
import cv2
from sensor_msgs.msg import Image
from sensor_msgs.msg import CompressedImage
from cv_bridge import CvBridge
from std_srvs.srv import SetBool, SetBoolResponse

class GroundProjection:

    def __init__(self):
        rospy.Service('line_detector_node/switch', SetBool, self.ld_switch)
        rospy.Service('lane_filter_node/switch', SetBool, self.lf_switch)
        rospy.Subscriber('/luke/camera_node/image/compressed', CompressedImage, self.callback, queue_size=1,buff_size=2**24)
        self.bridge = CvBridge() #???
        # Set sleep rate
        self.rate = rospy.Rate(10)
        
    def ld_switch(self, msg): return True, ""
		
    def lf_switch(self, msg): return True, ""

    def output_image(self, original_image, lines):
        output = np.copy(original_image)
        if lines is not None:
            for i in range(len(lines)):
                l = lines[i][0]
                cv2.line(output, (l[0],l[1]), (l[2],l[3]), (255,0,0), 2, cv2.LINE_AA)
                cv2.circle(output, (l[0],l[1]), 2, (0,255,0))
                cv2.circle(output, (l[2],l[3]), 2, (0,0,255))
        return output

    def on_image_cropped(self, image_cropped):
        self.image_cropped_cv = self.bridge.imgmsg_to_cv2(image_cropped, "bgr8")
        canny_lower = rospy.get_param("/canny_lower")
        canny_upper = rospy.get_param("/canny_upper")
        l2gradient = rospy.get_param("/l2gradient")
        image_cropped_canny = cv2.Canny(self.image_cropped_cv, canny_lower, canny_upper, l2gradient)
        return image_cropped_canny
        
    def on_image_white(self, image_white):
        rho = rospy.get_param("/rho")
        theta = rospy.get_param("/theta")
        threshold = rospy.get_param("/threshold")
        min_line_length = rospy.get_param("/min_line_length")
        max_line_gap = rospy.get_param("/max_line_gap")
        image_white_cv = self.bridge.imgmsg_to_cv2(image_white, "8UC1")
        self.image_white_new = cv2.bitwise_and(self.image_cropped_canny_cv, image_white_cv)
        self.image_white_lines = cv2.HoughLinesP(self.image_white_new, rho, theta, threshold, None, min_line_length, max_line_gap)
        image_white_hough = self.output_image(self.image_cropped_cv, self.image_white_lines)
        return image_white_hough
    
    def on_image_yellow(self, image_yellow):
        rho = rospy.get_param("/rho")
        theta = rospy.get_param("/theta")
        threshold = rospy.get_param("/threshold")
        min_line_length = rospy.get_param("/min_line_length")
        max_line_gap = rospy.get_param("/max_line_gap")
        image_yellow_cv = self.bridge.imgmsg_to_cv2(image_yellow, "8UC1")
        self.image_yellow_new = cv2.bitwise_and(self.image_cropped_canny_cv, image_yellow_cv)
        self.image_yellow_lines = cv2.HoughLinesP(self.image_yellow_new, rho, theta, threshold, None, min_line_length, max_line_gap)
        image_yellow_hough = self.output_image(self.image_cropped_cv, self.image_yellow_lines)
        return image_yellow_hough

    def callback(self, compressed_image):
        white_hue_min = rospy.get_param("/white_hue_min")
        white_hue_max = rospy.get_param("/white_hue_max")
        white_sat_min = rospy.get_param("/white_sat_min")
        white_sat_max = rospy.get_param("/white_sat_max")
        white_val_min = rospy.get_param("/white_val_min")
        white_val_max = rospy.get_param("/white_val_max")
        yellow_hue_min = rospy.get_param("/yellow_hue_min")
        yellow_hue_max = rospy.get_param("/yellow_hue_max")
        yellow_sat_min = rospy.get_param("/yellow_sat_min")
        yellow_sat_max = rospy.get_param("/yellow_sat_max")
        yellow_val_min = rospy.get_param("/yellow_val_min")
        yellow_val_max = rospy.get_param("/yellow_val_max")
        erode_kernel_size = rospy.get_param("/erode_kernel_size")
        erode_iterations = rospy.get_param("/erode_iterations")
        dilate_kernel_size = rospy.get_param("/dilate_kernel_size")
        dilate_iterations = rospy.get_param("/dilate_iterations")

        # Taking a matrix of size 5 as the kernel 
        erode_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (erode_kernel_size, erode_kernel_size))
        dilate_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (dilate_kernel_size, dilate_kernel_size))
        # Convert this cropped image to HSV (unless you’d rather experiment with other methods)
        cv_img = self.bridge.imgmsg_to_cv2(compressed_image, "bgr8")
        # Crops the top half out of the received image. 
        image_size = (160, 120)
        offset = 40 # you can choose what this crop offset is
        new_image = cv2.resize(cv_img, image_size, interpolation=cv2.INTER_NEAREST)
        image_cropped = new_image[offset:, :]
    
        # Filters the image for white pixels such that you can clearly see the lane lines and nothing else for each sample image
        image_hsv = cv2.cvtColor(image_cropped, cv2.COLOR_BGR2HSV)
        image_white = cv2.inRange(image_hsv, (white_hue_min, white_sat_min, white_val_min),(white_hue_max, white_sat_max, white_val_max))
        image_white_erode = cv2.erode(image_white, erode_kernel, iterations=erode_iterations)
        image_white_dilate = cv2.dilate(image_white_erode, dilate_kernel, iterations=dilate_iterations)
        # Filters the image for yellow pixels such that you can clearly see at least the first few dashed markers in the middle of the lane
        # Tip: Sometimes the middle yellow lines will still show up in your filtered white lane detector. You can use the result from your yellow detector to remove the yellow dashed line markings when trying to filter for the white lines.
        image_yellow = cv2.inRange(image_hsv, (yellow_hue_min, yellow_sat_min, yellow_val_min),(yellow_hue_max, yellow_sat_max, yellow_val_max))
        image_yellow_erode = cv2.erode(image_yellow, erode_kernel, iterations=erode_iterations)
        image_yellow_dilate = cv2.dilate(image_yellow_erode, dilate_kernel, iterations=dilate_iterations)
        
        image_cropped_processed = self.on_image_cropped(image_cropped)
        image_white_processed = self.on_image_white(image_white_dilate)
        image_yellow_processed = self.on_image_yellow(image_yellow_dilate)

        

if __name__ == '__main__':
    rospy.init_node('GroundProjection', anonymous=True)
    object = GroundProjection()
    rospy.spin()