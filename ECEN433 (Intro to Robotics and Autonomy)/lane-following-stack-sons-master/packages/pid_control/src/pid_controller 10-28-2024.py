#!/usr/bin/env python3

import rospy
from std_msgs.msg import Float32
import time

class PIDController:
    def __init__(self):
        # Controller variables
        self.error_sum = 0.0
        self.last_error = 0.0
        self.last_time = time.time()

        # Initialize ROS node
        rospy.init_node('pid_controller', anonymous=True)
        
        # ROS Publishers and Subscribers
        self.pub_control_input = rospy.Publisher('control_input', Float32, queue_size=10)
        self.sub_position = rospy.Subscriber('error', Float32, self.error_callback)
        while not rospy.is_shutdown():
            if rospy.has_param("controller_ready"):
                rospy.set_param("controller_ready", "true")

    def error_callback(self, error_msg):
        # Extract error data (float32)
        error = error_msg.data

        # Calculate time elapsed
        current_time = time.time()
        delta_time = current_time - self.last_time if self.last_time else 0.01

        # Get parameters for kp, ki, and kd
        self.k_proportional = rospy.get_param("/k_proportional")
        self.k_integral = rospy.get_param("/k_integral")
        self.k_derivative = rospy.get_param("/k_derivative")

        # Proportional term
        p = self.k_proportional * error

        # Integral term
        self.error_sum += error * delta_time
        i = self.k_integral * self.error_sum

        # Derivative term
        d = self.k_derivative * (error - self.last_error) / delta_time if delta_time > 0 else 0.0

        # PID output
        control_msg = Float32()
        control = p + i + d
        control_msg.data = control

        # Limit control input to ensure it does not exceed the max velocity of 30 m/s
        control_msg = max(min(control, 30.0), -30.0)

        # Publish the control input to the 'control_input' topic
        self.pub_control_input.publish(control_msg)

        # Update for the next iteration
        self.last_error = error
        self.last_time = current_time

    def run(self):
        # Start the ROS loop
        rospy.spin()

if __name__ == '__main__':
    try:
        pid_controller = PIDController()
        pid_controller.run()
    except rospy.ROSInterruptException:
        pass
