#!/usr/bin/env python3

import rospy
import math
from duckietown_msgs.msg import SegmentList, Segment
from geometry_msgs.msg import Point
from std_msgs.msg import Float64

class RedLinePositionEstimator:
    def __init__(self):
        self.sub_ground_segments = rospy.Subscriber(
            "ground_projection_node/lineseglist_out",
            SegmentList,
            self.ground_segment_callback
        )
        self.pub_position = rospy.Publisher("duckiebot_position", Point, queue_size=1)
        self.pub_angle = rospy.Publisher("duckiebot_angle", Float64, queue_size=1)

    def ground_segment_callback(self, seglist_msg):
        red_segments = [seg for seg in seglist_msg.segments if seg.color == Segment.RED]
        if not red_segments:
            # rospy.logwarn("No red line segments detected")
            self.pub_position.publish(Point(x=100.0, y=100.0, z=100.0))
            self.pub_angle.publish(100.0)
            return

        closest_segment = min(red_segments, key=self.segment_distance)
        relative_position = self.calculate_relative_position(closest_segment)
        angle = self.calculate_angle(closest_segment)

        self.pub_position.publish(relative_position)
        self.pub_angle.publish(angle)

    def segment_distance(self, segment):
        mid_x = (segment.points[0].x + segment.points[1].x) / 2
        mid_y = (segment.points[0].y + segment.points[1].y) / 2
        return math.sqrt(mid_x**2 + mid_y**2)

    def calculate_relative_position(self, segment):
        mid_x = (segment.points[0].x + segment.points[1].x) / 2
        mid_y = (segment.points[0].y + segment.points[1].y) / 2
        return Point(x=mid_x, y=mid_y, z=0)

    def calculate_angle(self, segment):
        dx = segment.points[1].x - segment.points[0].x
        dy = segment.points[1].y - segment.points[0].y
        return (math.atan2(dy, dx) + math.pi/2) # Add pi/2 so it's lined up

if __name__ == '__main__':
    rospy.init_node('red_line_position_estimator')
    RedLinePositionEstimator()
    rospy.spin()