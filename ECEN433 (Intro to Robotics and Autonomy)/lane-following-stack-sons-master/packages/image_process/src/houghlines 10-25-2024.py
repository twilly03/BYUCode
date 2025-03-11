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
from cv_bridge import CvBridge

class HoughLines:

    def __init__(self):
        # Instantiate variables
        self.bridge = CvBridge()
        self.image_cropped_canny_cv = None
        # Subscribers
        rospy.Subscriber('/image_cropped', Image, self.on_image_cropped)
        rospy.Subscriber('/image_white', Image, self.on_image_white)
        rospy.Subscriber('/image_yellow', Image, self.on_image_yellow)
        # Publishers
        self.image_edges_pub = rospy.Publisher('/image_edges', Image, queue_size=10)
        self.image_lines_white_pub = rospy.Publisher('/image_lines_white', Image, queue_size=10)
        self.image_lines_yellow_pub = rospy.Publisher('/image_lines_yellow', Image, queue_size=10)

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
        self.image_cropped_canny_cv = cv2.Canny(self.image_cropped_cv, canny_lower, canny_upper, l2gradient)
        self.image_cropped_canny = self.bridge.cv2_to_imgmsg(self.image_cropped_canny_cv, "mono8")
        self.image_edges_pub.publish(self.image_cropped_canny)
        
    def on_image_white(self, image_white):
        if self.image_cropped_canny_cv is None:
            rospy.logwarn("image_cropped_canny_cv is not initialized yet.")
            return
        if self.image_cropped_cv is None:
            rospy.logwarn("image_cropped_cv is not initialized yet.")
            return
        rho = rospy.get_param("/rho")
        theta = rospy.get_param("/theta")
        threshold = rospy.get_param("/threshold")
        min_line_length = rospy.get_param("/min_line_length")
        max_line_gap = rospy.get_param("/max_line_gap")
        image_white_cv = self.bridge.imgmsg_to_cv2(image_white, "8UC1")
        self.image_white_new = cv2.bitwise_and(self.image_cropped_canny_cv, image_white_cv)
        self.image_white_lines = cv2.HoughLinesP(self.image_white_new, rho, theta, threshold, None, min_line_length, max_line_gap)
        self.image_white_hough = self.output_image(self.image_cropped_cv, self.image_white_lines)
        image_white_anded = self.bridge.cv2_to_imgmsg(self.image_white_hough, "bgr8")
        self.image_lines_white_pub.publish(image_white_anded)
    
    def on_image_yellow(self, image_yellow):
        if self.image_cropped_canny_cv is None:
            rospy.logwarn("image_cropped_canny_cv is not initialized yet.")
            return
        if self.image_cropped_cv is None:
            rospy.logwarn("image_cropped_cv is not initialized yet.")
            return
        rho = rospy.get_param("/rho")
        theta = rospy.get_param("/theta")
        threshold = rospy.get_param("/threshold")
        min_line_length = rospy.get_param("/min_line_length")
        max_line_gap = rospy.get_param("/max_line_gap")
        image_yellow_cv = self.bridge.imgmsg_to_cv2(image_yellow, "8UC1")
        self.image_yellow_new = cv2.bitwise_and(self.image_cropped_canny_cv, image_yellow_cv)
        self.image_yellow_lines = cv2.HoughLinesP(self.image_yellow_new, rho, theta, threshold, None, min_line_length, max_line_gap)
        self.image_yellow_hough = self.output_image(self.image_cropped_cv, self.image_yellow_lines)
        image_yellow_anded = self.bridge.cv2_to_imgmsg(self.image_yellow_hough, "bgr8")
        self.image_lines_yellow_pub.publish(image_yellow_anded)

    

    def callback(self, image):
        return

if __name__ == '__main__':
    rospy.init_node('HoughLines', anonymous=True)
    object = HoughLines()
    rospy.spin()
