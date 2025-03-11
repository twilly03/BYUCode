#!/usr/bin/env python3


# Consider looking at https://github.com/duckietown/dt-core/tree/daffy/packages/lane_control

import rospy
from std_msgs.msg import Float32
from duckietown_msgs.msg import LanePose, Twist2DStamped
import time

class LaneFollowingPIDController:
    def __init__(self):
        # Initialize node
        rospy.init_node("lane_following_pid_controller", anonymous=True)
        # Controller variables
        self.d_error_sum = 0.0
        self.d_last_error = 0.0
        self.d_last_time = rospy.get_time()
        self.phi_error_sum = 0.0
        self.phi_last_error = 0.0
        self.phi_last_time = rospy.get_time()
        self.d_max_control_velocity = rospy.get_param("/max_control_velocity")
        self.d_min_control_velocity = rospy.get_param("/min_control_velocity")
        self.phi_max_control_velocity = rospy.get_param("/max_control_velocity")
        self.phi_min_control_velocity = rospy.get_param("/min_control_velocity")
        self.d_control = rospy.get_param("/d_control")
        self.phi_control = rospy.get_param("/phi_control")
        self.velocity = rospy.get_param("/velocity")

        # Set up subscriptions and publishers
        self.lane_pose_sub = rospy.Subscriber("lane_filter_node/lane_pose", LanePose, self.lane_pose_callback)
        self.command_pub = rospy.Publisher("lane_controller_node/car_cmd", Twist2DStamped, queue_size=1)

        # Control parameters
        self.max_control_output = rospy.get_param("/max_control_output")

    def lane_pose_callback(self, msg):
        # Extract lateral (d) and angular (phi) errors from LanePose message
        d_error = msg.d
        phi_error = msg.phi

        # Calculate control signals from PID controllers for both d and phi
        self.d_control = self.d_error_calculate(d_error)
        self.phi_control = self.phi_error_calculate(phi_error)

        # Combine control outputs, applying limits if necessary
        control_signal = self.d_control + self.phi_control
        # control_signal = max(min(self.max_control_output, control_signal), -self.max_control_output)

        # Publish the Twist2DStamped command
        command_msg = Twist2DStamped()
        command_msg.v = self.velocity  # Constant forward velocity (can be adjusted as needed)
        command_msg.omega = control_signal  # Steering control based on PID output
        self.command_pub.publish(command_msg)
        

    def d_error_calculate(self, d_error_float32):

        # Calculate time elapsed
        d_current_time = rospy.get_time() #??? Potentially an issue with two functions calls and one time
        d_delta_time = d_current_time - self.d_last_time if self.d_last_time else 0.01

        # Get parameters for kp, ki, and kd
        self.d_k_proportional = rospy.get_param("/d_kp")
        self.d_k_integral = rospy.get_param("/d_ki")
        self.d_k_derivative = rospy.get_param("/d_kd")
        self.phi_k_derivative = rospy.get_param("/d_error_threshold")

        # Proportional term
        d_p = self.d_k_proportional * d_error_float32

        # Integral term
        self.d_error_sum += d_error_float32 * d_delta_time
        d_i = self.d_k_integral * self.d_error_sum

        # Derivative term
        d_d = self.d_k_derivative * (d_error_float32 - self.d_last_error) / d_delta_time if d_delta_time > 0 else 0.0

        # PID output
        d_control = d_p + d_i + d_d

        # Limit control input to ensure it does not exceed the max velocity of 30 m/s
        #d_control = max(min(d_control, self.d_max_control_velocity), self.d_min_control_velocity)


        if abs(d_error_float32) < 1:
            d_error_float32 = 0

        # Update for the next iteration
        self.d_last_error = d_error_float32
        self.d_last_time = d_current_time
        return d_control
    
    def phi_error_calculate(self, phi_error_float32):

        # Calculate time elapsed
        phi_current_time = rospy.get_time() #??? Potentially an issue with two functions calls and one time
        phi_delta_time = phi_current_time - self.phi_last_time if self.phi_last_time else 0.01

        # Get parameters for kp, ki, and kd
        self.phi_k_proportional = rospy.get_param("/phi_kp")
        self.phi_k_integral = rospy.get_param("/phi_ki")
        self.phi_k_derivative = rospy.get_param("/phi_kd")
        self.phi_k_derivative = rospy.get_param("/phi_error_threshold")

        # Proportional term
        phi_p = self.phi_k_proportional * phi_error_float32

        # Integral term
    
        self.phi_error_sum += phi_error_float32 * phi_delta_time
        phi_i = self.phi_k_integral * self.phi_error_sum

        # Derivative term
        phi_d = self.phi_k_derivative * (phi_error_float32 - self.phi_last_error) / phi_delta_time if phi_delta_time > 0 else 0.0

        # PID output
        phi_control = phi_p + phi_i + phi_d

        # Limit control input to ensure it does not exceed the max velocity of 30 m/s
        #phi_control = max(min(phi_control, self.phi_max_control_velocity), self.phi_min_control_velocity)

        if abs(phi_error_float32) < 1:
            phi_error_float32 = 0

        # Update for the next iteration
        self.phi_last_error = phi_error_float32
        self.phi_last_time = phi_current_time
        return phi_control

    def run(self):
        # Start the ROS loop
        rospy.spin()

if __name__ == "__main__":
    try:
        controller = LaneFollowingPIDController()
        controller.run()
    except rospy.ROSInterruptException:
        pass