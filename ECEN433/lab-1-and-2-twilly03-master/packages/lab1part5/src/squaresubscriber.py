#!/usr/bin/env python3

import rospy
from std_msgs.msg import String
from geometry_msgs.msg import Twist
import numpy as np

last_data = "Nothing"
started = False
pub = rospy.Publisher('turtlemoves', String, queue_size=1000)

def callback(data):
    global started, last_data
    if (not started):
        started = True

    if (data.linear.x==0):
        if (data.linear.y<0):
            last_data = "down"
        elif (data.linear.y>0):
            last_data = "up"
    elif (data.linear.y==0):
        if (data.linear.x<0):
                last_data = "left"
        elif (data.linear.x>0):
            last_data = "right"
    
    
def timer_callback(event):
    global started, pub, last_data
    if (started):
        pub.publish(last_data)

def listener():
    rospy.init_node('listener', anonymous=True)
    rospy.Subscriber("turtlesim/turtle1/cmd_vel", Twist, callback)

    x = rospy.get_param("/direction_pub_rate")

    timer = rospy.Timer(rospy.Duration(1/x), timer_callback) #use x or rate?

    # spin() simply keeps python from exiting until this node is stopped
    rospy.spin()
    timer.shutdown()
  
if __name__ == '__main__':
    listener()