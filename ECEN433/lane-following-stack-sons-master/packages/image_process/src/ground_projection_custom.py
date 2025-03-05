#!/usr/bin/env python3

# /luke/line_detector_node/segment_list
# /luke/line_detector_node
#duckietown_msgs/Segment[] segments
#   uint8 WHITE=0
#   uint8 YELLOW=1
#   uint8 RED=2
#   uint8 color
#   duckietown_msgs/Vector2D[2] pixels_normalized
#     float32 x
#     float32 y
# roslaunch image_process ground_projection_custom.launch


import rospy
import numpy as np
import sys
import cv2
from sensor_msgs.msg import Image
from sensor_msgs.msg import CompressedImage
from cv_bridge import CvBridge
from std_srvs.srv import SetBool, SetBoolResponse
from duckietown_msgs.msg import Segment, SegmentList, Vector2D

class GroundProjectionCustom:

    def __init__(self):
        self.image_cropped_cv = None
        self.image_cropped_canny_cv = None
        rospy.Service('line_detector_node/switch', SetBool, self.ld_switch)
        rospy.Service('lane_filter_node/switch', SetBool, self.lf_switch)
        rospy.Subscriber('/luke/camera_node/image/compressed', CompressedImage, self.callback, queue_size=1,buff_size=2**24)
        self.segment_pub = rospy.Publisher('/luke/line_detector_node/segment_list', SegmentList, queue_size=10)
        self.bridge = CvBridge() #???
        # Set sleep rate
        # self.rate = rospy.Rate(10)
        
    def ld_switch(self, msg): return True, ""
		
    def lf_switch(self, msg): return True, ""

    def draw_lines_on_image(self, original_image, lines):
        output = np.copy(original_image)
        if lines is not None:
            for i in range(len(lines)):
                l = lines[i][0]
                cv2.line(output, (l[0],l[1]), (l[2],l[3]), (255,0,0), 2, cv2.LINE_AA)
                cv2.circle(output, (l[0],l[1]), 2, (0,255,0))
                cv2.circle(output, (l[2],l[3]), 2, (0,0,255))
        return output

    def canny_filter_image_cropped(self, image_cropped_cv_bgr8):
        self.image_cropped_cv = image_cropped_cv_bgr8
        canny_lower = rospy.get_param("/canny_lower")
        canny_upper = rospy.get_param("/canny_upper")
        l2gradient = rospy.get_param("/l2gradient")
        self.image_cropped_canny_cv = cv2.Canny(self.image_cropped_cv, canny_lower, canny_upper, l2gradient)
        
    def hough_filter_image_white(self, image_white_8uc1):
        if self.image_cropped_cv is None:
            rospy.logwarn("image_cropped_cv is not initialized yet.")
            return
        if self.image_cropped_canny_cv is None:
            rospy.logwarn("image_cropped_canny_cv is not initialized yet.")
            return
        rho = rospy.get_param("/rho")
        theta = rospy.get_param("/theta")
        threshold = rospy.get_param("/threshold")
        min_line_length = rospy.get_param("/min_line_length")
        max_line_gap = rospy.get_param("/max_line_gap")
        image_white_anded = cv2.bitwise_and(self.image_cropped_canny_cv, image_white_8uc1)
        self.image_white_lines = cv2.HoughLinesP(image_white_anded, rho, theta, threshold, None, min_line_length, max_line_gap)
        self.image_white_hough = self.draw_lines_on_image(self.image_cropped_cv, self.image_white_lines)
        return self.image_white_lines
    
    def hough_filter_image_yellow(self, image_yellow_8uc1):
        if self.image_cropped_cv is None:
            rospy.logwarn("image_cropped_cv is not initialized yet.")
            return
        if self.image_cropped_canny_cv is None:
            rospy.logwarn("image_cropped_canny_cv is not initialized yet.")
            return
        rho = rospy.get_param("/rho")
        theta = rospy.get_param("/theta")
        threshold = rospy.get_param("/threshold")
        min_line_length = rospy.get_param("/min_line_length")
        max_line_gap = rospy.get_param("/max_line_gap")
        image_yellow_anded = cv2.bitwise_and(self.image_cropped_canny_cv, image_yellow_8uc1)
        self.image_yellow_lines = cv2.HoughLinesP(image_yellow_anded, rho, theta, threshold, None, min_line_length, max_line_gap)
        self.image_yellow_hough = self.draw_lines_on_image(self.image_cropped_cv, self.image_yellow_lines)
        return self.image_yellow_lines

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
        compressed_image_cv = self.bridge.compressed_imgmsg_to_cv2(compressed_image, "bgr8")
        # Crops the top half out of the received image. 
        image_size = (160, 120)
        offset = 40 # you can choose what this crop offset is
        ground_image_cv = cv2.resize(compressed_image_cv, image_size, interpolation=cv2.INTER_NEAREST)
        self.ground_image_cv_cropped = ground_image_cv[offset:, :]
    
        image_hsv = cv2.cvtColor(self.ground_image_cv_cropped, cv2.COLOR_BGR2HSV)
        # Filters the image for white pixels such that you can clearly see the lane lines and nothing else for each sample image
        image_white_hsv = cv2.inRange(image_hsv, (white_hue_min, white_sat_min, white_val_min),(white_hue_max, white_sat_max, white_val_max))
        image_white_erode_hsv = cv2.erode(image_white_hsv, erode_kernel, iterations=erode_iterations)
        image_white_dilate_hsv = cv2.dilate(image_white_erode_hsv, dilate_kernel, iterations=dilate_iterations)

        # Filters the image for yellow pixels such that you can clearly see at least the first few dashed markers in the middle of the lane
        image_yellow_hsv = cv2.inRange(image_hsv, (yellow_hue_min, yellow_sat_min, yellow_val_min),(yellow_hue_max, yellow_sat_max, yellow_val_max))
        image_yellow_erode_hsv = cv2.erode(image_yellow_hsv, erode_kernel, iterations=erode_iterations)
        image_yellow_dilate_hsv = cv2.dilate(image_yellow_erode_hsv, dilate_kernel, iterations=dilate_iterations)
        
        self.canny_filter_image_cropped(self.ground_image_cv_cropped)
        white_lines = self.hough_filter_image_white(image_white_dilate_hsv)
        yellow_lines = self.hough_filter_image_yellow(image_yellow_dilate_hsv)


        arr_cutoff = np.array([0, offset, 0, offset])
        arr_ratio = np.array([1. / image_size[0], 1. / image_size[1], 1. / image_size[0], 1. / image_size[1]])

        segments = []

        # Normalize and add white lines
        if white_lines is not None:
            for line in white_lines:
                line = np.array(line)
                # print("White Line ", line)
                # print("White Cutoff ",arr_cutoff)
                # print("White Ratio ", arr_ratio)
                line_normalized = (line + arr_cutoff) * arr_ratio
                # print("White Normal",line_normalized)
                segment = Segment()
                segment.color = Segment.WHITE
                # Initialize pixels_normalized with two Vector2D objects
                segment.pixels_normalized = [Vector2D(), Vector2D()]
                # Set the coordinates for each point
                segment.pixels_normalized[0].x = line_normalized[0][0]
                segment.pixels_normalized[0].y = line_normalized[0][1]
                segment.pixels_normalized[1].x = line_normalized[0][2]
                segment.pixels_normalized[1].y = line_normalized[0][3]
                segments.append(segment)

        # Normalize and add yellow lines
        if yellow_lines is not None:
            for line in yellow_lines:
                line = np.array(line)
                # print("White Line ", line)
                # print("White Cutoff ",arr_cutoff)
                # print("White Ratio ", arr_ratio)
                line_normalized = (line + arr_cutoff) * arr_ratio
                # print("White Normal",line_normalized)
                segment = Segment()
                segment.color = Segment.YELLOW
                # Initialize pixels_normalized with two Vector2D objects
                segment.pixels_normalized = [Vector2D(), Vector2D()]
                # Set the coordinates for each point
                segment.pixels_normalized[0].x = line_normalized[0][0]
                segment.pixels_normalized[0].y = line_normalized[0][1]
                segment.pixels_normalized[1].x = line_normalized[0][2]
                segment.pixels_normalized[1].y = line_normalized[0][3]
                segments.append(segment)
        # Publish SegmentList
        segment_list = SegmentList()
        segment_list.segments = segments
        self.segment_pub.publish(segment_list)

        # self.rate.Sleep()

if __name__ == '__main__':
    rospy.init_node('GroundProjectionCustom', anonymous=True)
    object = GroundProjectionCustom()
    rospy.spin()