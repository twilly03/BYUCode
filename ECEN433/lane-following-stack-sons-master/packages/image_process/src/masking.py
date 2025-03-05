#!/usr/bin/env python3

# Subscribes to the “/image” topic (NOTE: this assumes you start the publisher mentioned below in the “/” namespace, adjust as needed)
# Crops the top half out of the received image. The new image should be half as tall as the input image and contain only the bottom half of the input image. This should remove most of the non-lane portion of the image. Feel free to experiment with the exact amount that you crop the image but leave a comment to justify if you choose something besides 50%.
# Publishes the new image on a ROS topic called “/image_cropped”
# Convert this cropped image to HSV (unless you’d rather experiment with other methods)
# Filters the image for yellow pixels such that you can clearly see at least the first few dashed markers in the middle of the lane
# Filters the image for white pixels such that you can clearly see the lane lines and nothing else for each sample image
# Tip: Sometimes the middle yellow lines will still show up in your filtered white lane detector. You can use the result from your yellow detector to remove the yellow dashed line markings when trying to filter for the white lines.
# Optionally, use erode and/or dilate to improve your results.
# Publishes BOTH the white and yellow filtered images as the ROS topics “/image_white” and “/image_y


import rospy
import numpy as np
import sys
import cv2
from sensor_msgs.msg import Image
from cv_bridge import CvBridge

class Masking:

    def __init__(self):
        # Instantiate variables
        self.image = Image()
        self.bridge = CvBridge() #???
        # Subscribes to the “/image” topic (NOTE: this assumes you start the publisher mentioned below in the “/” namespace, adjust as needed)
        rospy.Subscriber('/image', Image, self.callback)
        # Set sleep rate
        self.rate = rospy.Rate(10)
        # Publishes BOTH the white and yellow filtered images as the ROS topics “/image_white” and “/image_yellow” respectively.
        self.image_white_pub = rospy.Publisher('/image_white', Image, queue_size=10)
        self.image_yellow_pub = rospy.Publisher('/image_yellow', Image, queue_size=10)
        
        # Publishes the new image on a ROS topic called “/image_cropped”
        self.image_cropped_pub = rospy.Publisher('/image_cropped', Image, queue_size=10)

    def callback(self, image):
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
        cv_img = self.bridge.imgmsg_to_cv2(image, "bgr8")
        # Crops the top half out of the received image. 
        height,_,_ = cv_img.shape
        new_height = int(height / 2)
        image_cropped = cv_img[new_height:,:]
        ros_output_img_cropped = self.bridge.cv2_to_imgmsg(image_cropped, "bgr8")
        self.image_cropped_pub.publish(ros_output_img_cropped)

        image_hsv = cv2.cvtColor(image_cropped, cv2.COLOR_BGR2HSV)
        # Filters the image for white pixels such that you can clearly see the lane lines and nothing else for each sample image
        image_white = cv2.inRange(image_hsv, (white_hue_min, white_sat_min, white_val_min),(white_hue_max, white_sat_max, white_val_max))
        image_white_erode = cv2.erode(image_white, erode_kernel, iterations=erode_iterations)
        image_white_dilate = cv2.dilate(image_white_erode, dilate_kernel, iterations=dilate_iterations)
        ros_output_img_white = self.bridge.cv2_to_imgmsg(image_white_dilate, "8UC1")
        self.image_white_pub.publish(ros_output_img_white)
        # Filters the image for yellow pixels such that you can clearly see at least the first few dashed markers in the middle of the lane
        # Tip: Sometimes the middle yellow lines will still show up in your filtered white lane detector. You can use the result from your yellow detector to remove the yellow dashed line markings when trying to filter for the white lines.
        image_yellow = cv2.inRange(image_hsv, (yellow_hue_min, yellow_sat_min, yellow_val_min),(yellow_hue_max, yellow_sat_max, yellow_val_max))
        image_yellow_erode = cv2.erode(image_yellow, erode_kernel, iterations=erode_iterations)
        image_yellow_dilate = cv2.dilate(image_yellow_erode, dilate_kernel, iterations=dilate_iterations)
        ros_output_img_yellow = self.bridge.cv2_to_imgmsg(image_yellow_dilate, "8UC1")
        self.image_yellow_pub.publish(ros_output_img_yellow)
        
        # Optionally, use erode and/or dilate to improve your results.

if __name__ == '__main__':
    rospy.init_node('Masking', anonymous=True)
    object = Masking()
    rospy.spin()
