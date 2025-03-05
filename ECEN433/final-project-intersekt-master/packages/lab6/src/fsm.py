#!/usr/bin/env python3
# https://docs.ros.org/en/api/apriltag_ros/html/msg/AprilTagDetectionArray.html

import rospy
import os
import numpy as np
from odometry.msg import WheelTicks
from geometry_msgs.msg import Pose2D, Point, PoseWithCovarianceStamped
from duckietown_msgs.msg import Twist2DStamped, WheelsCmdStamped, FSMState
from sensor_msgs.msg import Range
from std_msgs.msg import Float32, Bool, String
from collections import deque
from std_msgs.msg import UInt8

from enum import Enum

class MOTION(Enum):
	WAIT = 0
	AUTO = 1
	STOP_FOR_5 = 3
	LEFT  = 4
	STRAIGHT = 5
	RIGHT = 6
	MOVEMENT = 7
	EMERGENCY_STOP = 8

class LEFT_TURN_SEG(Enum):
	START_TURN = 0
	MID_TURN= 1
	END_TURN = 2
	END_TURN2 = 3
	END_TURN3 = 4 

class RIGHT_TURN_SEG(Enum):
	START_TURN = 0
	MID_TURN= 1
	END_TURN= 2
	END_TURN2 = 3
	END_TURN3 = 4 

class INTERSECTIONS(Enum):
	STRAIGHT_RIGHT = "straight_right_signs"
	STRAIGHT_LEFT = "straight_left_signs"
	RIGHT_LEFT = "right_left_signs"
	UNKNOWN = "unknown"
	STOP = "stop_signs"
	DEFAULT = "Default"


DEF_RATE = 5
LANE_FOLLOW_STATE = "LANE_FOLLOWING"
JOYSTICK_STATE = "NORMAL_JOYSTICK_CONTROL"
TIMER_STOP_CNT = 5
TIMER_LEFT_START = 6
TIMER_LEFT_MID = 2
TIMER_LEFT_END = 6
TIMER_LEFT_END2 = 0
TIMER_LEFT_END3 = 0

TIMER_LEFT_TURN_CNT = 3
TIMER_RIGHT_TURN_CNT = 3
TIMER_RIGHT_START = 3
TIMER_RIGHT_MID = 2
TIMER_RIGHT_END = 3
TIMER_RIGHT_END2 = 2
TIMER_RIGHT_END3 = 3

POST_INT_MAX_INT = rospy.get_param("/post_int_max_int", 4)
TIMER_STRAIGHT_CNT = 4


class IntersectionHandling:
	def __init__(self):
		init_str = "initializing IntersectionHandling"
		rospy.loginfo(init_str)
		self.botName = os.environ['VEHICLE_NAME']
		self.lane_follow_topic_dir = f"/{self.botName}/fsm_node/mode"
		self.movement_queue = deque(["Left", "Straight", "Right"])
        # Simulate the available movements from AprilTag reading
		self.available_movements = ["Left", "Straight", "Right"]  # Example input from AprilTag

		
		#subscribers
		rospy.Subscriber('duckiebot_position', Point, self.callbackDist) #this is the distance to red line topic
		rospy.Subscriber(self.lane_follow_topic_dir, FSMState, self.callback)
		#we 
		rospy.Subscriber('sign_detection', String, self.callbackSignDetection)
		#here we listen to TOF we should listen at every cycle in state machine and jump to 
		#rospy.Subscriber('front_center_tof_driver_node/range', Range, self.callbackTOF) #Range is a float measured in meters
		self.range = Range()
		self.tof_dist = 0.0
		self.pub_tof_dist = rospy.Publisher('tof/dist', Float32, queue_size=10)
		
		self.wheel_cmd_topic = f"/{self.botName}/wheels_driver_node/wheels_cmd"
		
		#publishers
		self.pub = rospy.Publisher(self.wheel_cmd_topic, WheelsCmdStamped, queue_size=10)
		self.pub_lane_enable = rospy.Publisher('fsm/enable_lane_control', Bool, queue_size=10)
		self.pub_april_reader_enable = rospy.Publisher('fsm/enable_tag_reader', Bool, queue_size=10)
		self.pub_fsm_state = rospy.Publisher('fsm/state', String, queue_size=10)

		# initialize variables
		self.distToRed = 100.0
		self.rate = rospy.Rate(DEF_RATE)
		self.state = MOTION.WAIT
		self.start_time = 0.0
		self.timerToLastInt = 0.0
		self.turnTimer = 0
		self.straightTimer = 0
		self.signID = "Default"
		self.leftTurnSubState = LEFT_TURN_SEG.START_TURN
		self.rightTurnSubState = RIGHT_TURN_SEG.START_TURN
		self.firstLoopFlag = True
		return
	
	def callbackTOF(self, data):
		# self.tof_dist = data.range
		# self.pub_tof_dist.publish(Float32(self.tof_dist))
		# if (self.tof_dist < 0.1 and self.state != MOTION.WAIT):
		# 	self.pub_lane_enable.publish(Bool(False)) #stops lane following temporarily
		# 	cmd = WheelsCmdStamped()
		# 	cmd.vel_left = 0.0
		# 	cmd.vel_right = 0.0
		# 	self.pub.publish(cmd)

		# 	if (self.state != MOTION.EMERGENCY_STOP):
		# 		self.prev_state = self.state
		# 		self.state = MOTION.EMERGENCY_STOP
		# elif (self.tof_dist >= 0.1 and self.state == MOTION.EMERGENCY_STOP):
		# 	if (self.prev_state == MOTION.AUTO):
		# 		self.pub_lane_enable.publish(Bool(True)) #starts lane following temporarily
		# 	self.state = self.prev_state
		return
	
	def callbackDist(self, data): #gets the distance to red
		self.distToRed = data.x
		return	
	
	def callback(self, data): #sets state to auto or wait
		self.POST_INT_MAX_INT = rospy.get_param("/post_int_max_int", 2.5)

		if (data.state == LANE_FOLLOW_STATE and self.state == MOTION.WAIT): #??? Note that there is a condition to make sure it's not always just setting it to AUTO
			self.state = MOTION.AUTO
			self.pub_lane_enable.publish(Bool(True))
		elif (data.state == JOYSTICK_STATE):
			self.state = MOTION.WAIT
			self.pub_lane_enable.publish(Bool(False))
		return
	
	def intersection_handling_state(self): #uses april tags and a queue to handle intersections
		if (self.state == MOTION.WAIT):
			self.pub_fsm_state.publish("Wait")
			# Do nothing lol
			return
		elif(self.state == MOTION.AUTO): #state for automatic lane following
			self.pub_fsm_state.publish("AUTO")
			time_now = rospy.get_time()
			if (self.distToRed < 0.15 and (time_now - self.timerToLastInt) > self.POST_INT_MAX_INT): #implemented red line lock for 1 sec after turn
				self.pub_lane_enable.publish(Bool(False)) #stops lane following temporarily
				cmd = WheelsCmdStamped()
				cmd.vel_left = 0
				cmd.vel_right = 0
				self.pub.publish(cmd) 
				self.pub_april_reader_enable.publish(Bool(True))
				self.state = MOTION.STOP_FOR_5
				self.firstLoopFlag = True
				self.start_time = rospy.get_time()
			else:
				self.state = MOTION.AUTO
			return
		elif (self.state == MOTION.STOP_FOR_5): #state that stops the robot for 5 seconds at an intersection
			self.pub_fsm_state.publish("STOP_FOR_5")
			if(self.firstLoopFlag == True):
				cmd = WheelsCmdStamped()
				cmd.vel_left = 0
				cmd.vel_right = 0
				self.pub.publish(cmd)
				self.firstLoopFlag = False 
			time_now = rospy.get_time()
			if (time_now - self.start_time < TIMER_STOP_CNT):
				pass
			else:
				self.firstLoopFlag = True
				#read april tags to understand intersection
				self.pub_fsm_state.publish("read april tags")
				tempSign = self.signID
				if (tempSign is not None and tempSign != INTERSECTIONS.UNKNOWN.value and tempSign != INTERSECTIONS.STOP.value): #determines intersection type based off april tag
					#lock self.signID
					self.pub_fsm_state.publish("check valid tag")
					self.pub_fsm_state.publish(tempSign)
					self.pub_april_reader_enable.publish(Bool(False))
					if (tempSign == INTERSECTIONS.STRAIGHT_RIGHT.value):
						self.available_movements = ["Straight", "Right"]
						self.pub_fsm_state.publish("Straight Right Intersection")
					elif (tempSign == INTERSECTIONS.STRAIGHT_LEFT.value):
						self.available_movements = ["Straight", "Left"]
						self.pub_fsm_state.publish("Straight Left Intersection")
					elif (tempSign == INTERSECTIONS.RIGHT_LEFT.value):
						self.available_movements = ["Right", "Left"]
						self.pub_fsm_state.publish("Right Left Intersection")
					elif (tempSign == INTERSECTIONS.STOP.value):
						self.pub_fsm_state.publish("STOP_SIGN")
					elif (tempSign == INTERSECTIONS.DEFAULT.value):
						self.pub_fsm_state.publish("DEFAULT")
					elif (tempSign == INTERSECTIONS.UNKNOWN.value):
						self.pub_fsm_state.publish("UNKNOWN")
					self.state = MOTION.MOVEMENT
				return
		elif(self.state == MOTION.MOVEMENT): #state that rotates the movement queue in the order left, straight, right
			self.pub_fsm_state.publish("turn queue")
			for _ in range(len(self.movement_queue)):
				next_movement = self.movement_queue[0]  # Peek at the front of the queue
				if next_movement in self.available_movements:
					self.movement_queue.rotate(-1)  # Rotate the queue to the next item
					if next_movement == "Left":
						self.pub_fsm_state.publish("LEFT Decision")
						self.state = MOTION.LEFT
					elif next_movement == "Straight":
						self.pub_fsm_state.publish("STRAIGHT Decision")
						self.state = MOTION.STRAIGHT
					elif next_movement == "Right":
						self.pub_fsm_state.publish("RIGHT Decision")
						self.state = MOTION.RIGHT
					return
				self.movement_queue.rotate(-1)  # Rotate if the current movement is not available
			rospy.logwarn("No valid movements available.")
			return

		elif(self.state == MOTION.LEFT): #turns the car left
			self.pub_fsm_state.publish("LEFT")
			if (self.leftTurnSubState == LEFT_TURN_SEG.START_TURN and self.turnTimer < TIMER_LEFT_START): #starts left turn
				self.pub_fsm_state.publish("START_LEFT")
				if(self.firstLoopFlag):
					cmd = WheelsCmdStamped()
					cmd.vel_left = 0.3
					cmd.vel_right = 0.3
					self.pub.publish(cmd)
					self.firstLoopFlag = False
				self.turnTimer += 1
				if(self.turnTimer == TIMER_LEFT_START):
					self.leftTurnSubState = LEFT_TURN_SEG.MID_TURN
					self.turnTimer = 0
					self.firstLoopFlag = True
			elif(self.leftTurnSubState == LEFT_TURN_SEG.MID_TURN and self.turnTimer < TIMER_LEFT_MID): #continues left turn
				self.pub_fsm_state.publish("MID_LEFT")
				if(self.firstLoopFlag):
					cmd = WheelsCmdStamped()
					cmd.vel_left = -0.1
					cmd.vel_right = 0.2
					self.pub.publish(cmd)
					self.firstLoopFlag = False
				self.turnTimer += 1
				if(self.turnTimer == TIMER_LEFT_MID):
					self.leftTurnSubState = LEFT_TURN_SEG.END_TURN
					self.turnTimer = 0
					self.firstLoopFlag = True
			elif(self.leftTurnSubState == LEFT_TURN_SEG.END_TURN and self.turnTimer < TIMER_LEFT_END): #ends left turn
				self.pub_fsm_state.publish("END_LEFT")
				if(self.firstLoopFlag):
					cmd = WheelsCmdStamped()
					cmd.vel_left = 0.3
					cmd.vel_right = 0.3
					self.pub.publish(cmd)
					self.firstLoopFlag = False
				self.turnTimer += 1
			# 	if(self.turnTimer == TIMER_LEFT_END):
			# 		self.leftTurnSubState = LEFT_TURN_SEG.END_TURN2
			# 		self.turnTimer = 0
			# elif(self.leftTurnSubState == LEFT_TURN_SEG.END_TURN2 and self.turnTimer < TIMER_LEFT_END2):
			# 	self.pub_fsm_state.publish("END_LEFT2")
			# 	cmd = WheelsCmdStamped()
			# 	cmd.vel_left = -0.1
			# 	cmd.vel_right = 0.2
			# 	self.pub.publish(cmd)
			# 	self.turnTimer += 1
			# 	if(self.turnTimer == TIMER_LEFT_END2):
			# 		self.leftTurnSubState = LEFT_TURN_SEG.END_TURN3
			# 		self.turnTimer = 0
			# elif(self.leftTurnSubState == LEFT_TURN_SEG.END_TURN3 and self.turnTimer < TIMER_LEFT_END3):
			# 	self.pub_fsm_state.publish("END_LEFT3")
			# 	cmd = WheelsCmdStamped()
			# 	cmd.vel_left = 0.3
			# 	cmd.vel_right = 0.3
			# 	self.pub.publish(cmd)
			# 	self.turnTimer += 1
			if (self.turnTimer == TIMER_LEFT_END):
				if(self.leftTurnSubState == LEFT_TURN_SEG.END_TURN):
					self.pub_lane_enable.publish(Bool(True)) #starts the lane following again
					self.timerToLastInt = rospy.get_time()
					self.leftTurnSubState = LEFT_TURN_SEG.START_TURN
					self.state = MOTION.AUTO
					self.turnTimer = 0
					self.firstLoopFlag = True
			return
		elif(self.state == MOTION.STRAIGHT): #turns the car straight
			self.pub_fsm_state.publish("STRAIGHT")
			if(self.straightTimer < TIMER_STRAIGHT_CNT):
				if(self.firstLoopFlag):
					cmd = WheelsCmdStamped()
					cmd.vel_left = .5
					cmd.vel_right = .5
					self.pub.publish(cmd)
					self.firstLoopFlag = False
				self.straightTimer += 1
			else:
				self.straightTimer = 0
				self.firstLoopFlag = True
				self.pub_lane_enable.publish(Bool(True)) #starts the lane following again
				self.timerToLastInt = rospy.get_time()
				self.state = MOTION.AUTO
			return
		elif(self.state == MOTION.RIGHT): #turns the car right
			self.pub_fsm_state.publish("RIGHT")
			if (self.rightTurnSubState == RIGHT_TURN_SEG.START_TURN and self.turnTimer < TIMER_RIGHT_START): #starts right turn
				self.pub_fsm_state.publish("START_RIGHT")
				if(self.firstLoopFlag):
					cmd = WheelsCmdStamped()
					cmd.vel_left = 0.3
					cmd.vel_right = 0.3
					self.pub.publish(cmd)
					self.firstLoopFlag = False
				self.turnTimer += 1
				if(self.turnTimer == TIMER_RIGHT_START):
					self.rightTurnSubState = RIGHT_TURN_SEG.MID_TURN
					self.turnTimer = 0
					self.firstLoopFlag = True
			elif (self.rightTurnSubState == RIGHT_TURN_SEG.MID_TURN and self.turnTimer < TIMER_RIGHT_MID): #continues the right turn
				self.pub_fsm_state.publish("MID_RIGHT")
				if(self.firstLoopFlag):
					cmd = WheelsCmdStamped()
					cmd.vel_left = 0.2
					cmd.vel_right = -0.1
					self.pub.publish(cmd)
					self.firstLoopFlag = False
				self.turnTimer += 1
				if(self.turnTimer == TIMER_RIGHT_MID):
					self.rightTurnSubState = RIGHT_TURN_SEG.END_TURN
					self.turnTimer = 0
					self.firstLoopFlag = True
			elif (self.rightTurnSubState == RIGHT_TURN_SEG.END_TURN and self.turnTimer < TIMER_RIGHT_END): #finishes right turn
				self.pub_fsm_state.publish("END_RIGHT")
				if(self.firstLoopFlag):
					cmd = WheelsCmdStamped()
					cmd.vel_left = 0.3
					cmd.vel_right = 0.3
					self.pub.publish(cmd)
					self.firstLoopFlag = False
				self.turnTimer += 1
			# 	if(self.turnTimer == TIMER_RIGHT_END):
			# 		self.rightTurnSubState = RIGHT_TURN_SEG.END_TURN2
			# 		self.turnTimer = 0
			# elif (self.rightTurnSubState == RIGHT_TURN_SEG.END_TURN2 and self.turnTimer < TIMER_RIGHT_END2):
			# 	self.pub_fsm_state.publish("END_RIGHT2")
			# 	cmd = WheelsCmdStamped()
			# 	cmd.vel_left = 0.2
			# 	cmd.vel_right = -0.1
			# 	self.pub.publish(cmd)
			# 	self.turnTimer += 1
			# 	if(self.turnTimer == TIMER_LEFT_END2):
			# 		self.rightTurnSubState = RIGHT_TURN_SEG.END_TURN3
			# 		self.turnTimer = 0
			# elif (self.rightTurnSubState == RIGHT_TURN_SEG.END_TURN3 and self.turnTimer < TIMER_RIGHT_END3):
			# 	self.pub_fsm_state.publish("END_RIGHT3")
			# 	cmd = WheelsCmdStamped()
			# 	cmd.vel_left = 0.3
			# 	cmd.vel_right = 0.3
			# 	self.pub.publish(cmd)
			# 	self.turnTimer += 1
			if(self.turnTimer == TIMER_RIGHT_END):
				if(self.rightTurnSubState == RIGHT_TURN_SEG.END_TURN):
					self.pub_lane_enable.publish(Bool(True)) #starts the lane following again
					self.timerToLastInt = rospy.get_time()
					self.rightTurnSubState = RIGHT_TURN_SEG.START_TURN
					self.state = MOTION.AUTO
					self.turnTimer = 0
					self.firstLoopFlag = True
			return
		elif(self.state == MOTION.EMERGENCY_STOP): #emergency stop state that stops if the car is too close to another object
			self.pub_fsm_state.publish("EMERGENCY_STOP")
			return
		else:
			self.pub_fsm_state.publish("unkown")
			rospy.logwarn(f"Unhandled state: {self.state}")
		return

	def callbackSignDetection(self, signValue): #gets the value of the april tag
		self.signID = signValue.data
		return
		
if __name__ == '__main__':
	try:
		rospy.init_node('IntersectionHandling', anonymous=True)
		node = IntersectionHandling()
		while not rospy.is_shutdown():
			node.intersection_handling_state()
			node.rate.sleep()
	
	except rospy.ROSInterruptException:
		pass