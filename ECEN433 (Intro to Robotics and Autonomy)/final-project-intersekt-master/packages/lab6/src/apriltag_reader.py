#!/usr/bin/env python3

import rospy
from geometry_msgs.msg import Pose2D, Point, PoseWithCovarianceStamped, PoseWithCovariance
from duckietown_msgs.msg import AprilTagDetectionArray, AprilTagDetection
from std_msgs.msg import String, Bool

# Pre-numbered april tag signs
APRIL_TAG_SIGNS = {
    "stop_signs": [20, 22, 23, 24, 25, 26, 31, 32, 33],
    "straight_right_signs": [9, 57],
    "straight_left_signs": [10, 61],
    "right_left_signs": [11, 65]
}

# Custom array of strings
class SignArray:
    def __init__(self):
        self.signs = []

class AprilTagReader:
    def __init__(self):
        # Subscribers
        rospy.init_node('apriltag_reader', anonymous=True)
        self.subscription = rospy.Subscriber(
            'apriltag_detector_node/detections',
            AprilTagDetectionArray,
            self.tag_callback
        )
        rospy.Subscriber('fsm/enable_tag_reader', Bool, self.enable_tag_reader)
        # Publishers
        self.pub_sign_detection = rospy.Publisher("sign_detection", String, queue_size=1)
        # Initialize variables
        self.tagReaderEnable = False
        self.detected_signs = SignArray()

    # Get the sign type in a string form, not number form
    def get_sign_type(self, tag_id):
        for sign_type, ids in APRIL_TAG_SIGNS.items():
            if tag_id in ids:
                return sign_type
        return "unknown"

    # Callback method when detecting a new tag
    def tag_callback(self, msg):
        self.detected_signs.signs.clear()  # Clear previous detections
        # Iterate over all detections
        for detection in msg.detections:
            tag_id = detection.tag_id
            sign_type = self.get_sign_type(tag_id)
            rospy.loginfo(f'Detected tag ID {tag_id}: {sign_type}')
            if (sign_type != "unknown" and sign_type != "stop_signs"):
                self.detected_signs.signs.append(sign_type)
                break # Exit the loop after the first valid sign
        # Publish if there any valid signs
        if self.detected_signs.signs:
            self.publish_detected_signs()

    # Publish detected signs
    def publish_detected_signs(self):
        signs_str = ",".join(self.detected_signs.signs)
        self.pub_sign_detection.publish(signs_str)

    # Determine if tag reader is enabled
    def enable_tag_reader(self, data):
        self.tagReaderEnable = data.data

# Main method
def main():
    apriltag_reader = AprilTagReader()
    rospy.spin()

if __name__ == '__main__':
    main()