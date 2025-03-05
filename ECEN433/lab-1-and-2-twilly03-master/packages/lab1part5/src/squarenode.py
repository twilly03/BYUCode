#!/usr/bin/env python3

import rospy
from std_msgs.msg import String
from geometry_msgs.msg import Twist

def talker():
   pub = rospy.Publisher('turtlesim/turtle1/cmd_vel', Twist, queue_size=10)
   rospy.init_node('lab1p5node', anonymous=True)
   rate = rospy.Rate(1) # 1hz
   vel_cmd = Twist()

   index = 0
   while not rospy.is_shutdown():
      index += 1
      if index == 5:
         index = 1
      if index == 1:
         vel_cmd.linear.x = 0
         vel_cmd.linear.y = 3
      elif index == 2:
         vel_cmd.linear.x = -3
         vel_cmd.linear.y = 0
      elif index == 3:
         vel_cmd.linear.x = 0
         vel_cmd.linear.y = -3
      elif index == 4:
         vel_cmd.linear.x = 3
         vel_cmd.linear.y = 0   
               
               
      pub.publish(vel_cmd)
      rate.sleep()

if __name__ == '__main__':
   try:
      talker()
   except rospy.ROSInterruptException:
      pass
