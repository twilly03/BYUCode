# Duckiebot Intersection Navigation
# Our Duckiebot should be be able to…
1. Detect Intersection & Stop at Red Line 
2. Read April Tag to Determine Intersection Type 
3. Select Valid Turn Type (Left, Straight, or Right) & Execute Turn 
4. Add Capability to Detect Car Direction in Front (In Your Lane) and Wait 
5. Add Turn Signals

# Nodes
**red_line_position**: Estimates the position of the red line relative to the Duckiebot. It subscribes to ground projection data and publishes the estimated position.
**lane_controller**: Implements a PID controller for lane following. It subscribes to lane pose information and publishes wheel commands.
**fsm** (Finite State Machine): Manages the overall state of the Duckiebot, including intersection handling and lane following modes.
**combined**: A node that combines image processing tasks, including line detection for yellow, white, and red lines.
**camera_node**: Captures and publishes camera images.
**lane_filter_node**: Processes line segment information to estimate the robot's pose within the lane.
**line_detector_node**: Detects lane lines in the processed image.
**wheels_driver_node**: Controls the wheel motors based on received commands.
**ground_projection_node**: Projects detected line segments onto the ground plane.
**apriltag_reade**r: Interprets detected AprilTags to determine intersection types and available movements.

# Topics
**lineseglist_out**: Line segment information published by the ground_projection_node.
**position**: Red line position published by the red_line_position node.
**lane_pose**: Estimated lane pose published by the lane_filter_node.
**enable_control**: Control enable signal published by the fsm node.
**car_cmd**: Wheel commands published by the lane_controller.
**wheels_cmd**: Direct wheel commands published by the fsm node.
**image**: Camera images published by the camera_node.
**segment_list**: Detected line segments published by the combined node and line_detector_node.
**detections**: AprilTag detections published by the apriltag_detector.
**sign_detection**: Interpreted sign information published by the apriltag_reader.
**enable_reader**: Signal to enable/disable the apriltag_reader, published by the fsm node.

# Python Code to generate the Nodes and Topics Diagram

import networkx as nx
import matplotlib.pyplot as plt

nodes = {
    "red_line_position": "lightblue",
    "lane_controller": "lightgreen",
    "fsm": "lightcoral",
    "combined": "lightyellow",
    "camera_node": "lightsalmon",
    "lane_filter_node": "lightgray",
    "line_detector_node": "wheat",
    "wheels_driver_node": "orchid",
    "ground_projection_node": "lightseagreen",
    "apriltag_detector": "plum",
    "apriltag_reader": "yellow",
}

connections = [
    ("ground_projection_node", "red_line_position", "lineseglist_out"),
    ("red_line_position", "fsm", "position"),
    ("lane_filter_node", "lane_controller", "lane_pose"),
    ("fsm", "lane_controller", "enable_control"),
    ("lane_controller", "wheels_driver_node", "car_cmd"),
    ("fsm", "wheels_driver_node", "wheels_cmd"),
    ("camera_node", "combined", "image"),
    ("combined", "line_detector_node", "segment_list"),
    ("line_detector_node", "ground_projection_node", "segment_list"),
    ("ground_projection_node", "lane_filter_node", "lineseglist_out"),
    ("camera_node", "apriltag_detector", "image"),
    ("apriltag_detector", "apriltag_reader", "detections"),
    ("apriltag_reader", "fsm", "sign_detection"),
    ("fsm", "apriltag_reader", "enable_reader"),
]

G = nx.DiGraph()
G.add_nodes_from(nodes.keys())
G.add_edges_from((src, dst) for src, dst, _ in connections)

node_colors = [nodes[node] for node in G.nodes()]

pos = nx.spring_layout(G, k=0.9, iterations=50)

plt.figure(figsize=(16, 12))
nx.draw(G, pos, node_color=node_colors, node_size=3000, font_size=10,
        font_weight="bold", arrowsize=20, with_labels=True)

edge_labels = {(src, dst): label for src, dst, label in connections}
nx.draw_networkx_edge_labels(G, pos, edge_labels=edge_labels, font_size=8)

plt.title("Duckiebot ROS Nodes and Topics", fontsize=16, fontweight="bold")
plt.axis("off")
plt.tight_layout()
plt.show()

# Class: AprilTagReader
This implementation focuses on detecting the first valid sign in each set of AprilTag detections and publishing it as a string. The node can be enabled or disabled using a separate topic, although the current implementation always publishes when a sign is detected, regardless of the enable state.
# Method: init
Initialize the ROS node.
Set up subscribers for AprilTag detections and tag reader enable signal.
Create a publisher for sign detections.
Initialize variables for tag reader state and detected signs.
# Method: get_sign_type
Input: AprilTag ID
Iterate through predefined APRIL_TAG_SIGNS dictionary.
If the tag ID matches any in the dictionary, return the corresponding sign type.
If no match is found, return "unknown".
# Method: tag_callback
Clear previously detected signs.
Iterate through AprilTag detections in the received message.
For each detection:
a. Get the tag ID.
b. Determine the sign type using get_sign_type method.
c. Log the detected tag ID and sign type.
d. If the sign type is not "unknown", add it to the detected signs list.
e. Break the loop after the first valid sign is found.
If any signs were detected, call publish_detected_signs method.
# Method: publish_detected_signs
Join the detected signs into a comma-separated string.
Publish the string using the sign detection publisher.
# Method: enable_tag_reader
Update the tag reader enable state based on the received boolean value.
Function: main
Create an instance of AprilTagReader.
Enter the ROS event loop (rospy.spin()).

# Class: IntersectionHandling
This implementation uses a state machine to handle different stages of intersection navigation, including detection, stopping, reading signs, and executing turns based on the intersection type and a predefined movement queue.
# Method: init
Initialize ROS node and set up subscribers and publishers.
Initialize variables for robot state, timers, and movement queues.
# Method: callbackDist
Update the distance to the red line.
# Method: callback
Handle state transitions based on FSM state messages.
Switch between WAIT and AUTO states.
# Method: intersection_handling_state
This is the main state machine method, handling different states:
**WAIT**: Do nothing.
**AUTO**:
Check if close to red line and sufficient time has passed since last intersection.
If conditions met, stop the robot and enable AprilTag reader.
**STOP_FOR_5**:
Wait for 5 seconds.
Read AprilTag to determine intersection type.
Set available movements based on intersection type.
**MOVEMENT**:
Rotate movement queue and choose next available movement.
Transition to LEFT, STRAIGHT, or RIGHT state.
**LEFT**:
Execute left turn in stages (START_TURN, MID_TURN, END_TURN).
Control wheel velocities for each stage.
Transition back to AUTO state after completing the turn.
**STRAIGHT**:
Move straight for a set duration.
Transition back to AUTO state.
**RIGHT**:
Execute right turn in stages (similar to LEFT).
Transition back to AUTO state after completing the turn.
# Method: callbackSignDetection
Update the detected sign ID.
# Function: main
Initialize the IntersectionHandling node.
Run the intersection_handling_state method in a loop until shutdown.

# Class: RedLinePositionEstimator
This implementation continuously estimates the position and orientation of the Duckiebot relative to the closest detected red line segment. It publishes this information for use by other nodes in the system, such as the intersection handling node.
# Method: init
Initialize a subscriber for ground segments.
Set up publishers for duckiebot position and angle.
# Method: ground_segment_callback
Filter red segments from the received segment list.
If no red segments are detected:
Publish default position (100.0, 100.0, 100.0) and angle (100.0).
If red segments are detected:
Find the closest red segment.
Calculate relative position and angle.
Publish the calculated position and angle.
# Method: segment_distance
Calculate the midpoint of the segment.
Return the Euclidean distance of the midpoint from the origin.
# Method: calculate_relative_position
Calculate the midpoint of the segment.
Return the midpoint as a Point message.
# Method: calculate_angle
Calculate the angle of the segment using its endpoints.
Adjust the angle by adding π/2 radians.
# Function: main
Initialize the ROS node.
Create an instance of RedLinePositionEstimator.
Enter the ROS event loop (rospy.spin()).

# Class: LaneControllerNode
This implementation uses a PID controller for both distance and angle (phi) to maintain the Duckiebot's position in the lane. It continuously updates control parameters from the ROS parameter server, allowing for dynamic tuning of the controller.
# Method: init
Initialize ROS node and set up publishers and subscribers.
Initialize variables for lane pose, errors, and control parameters.
Set up a ROS rate object for the main loop.
# Method: enable_lane_control
Update the lane control enabled flag based on the received boolean value.
# Method: callback
Update lane pose data and calculate errors.
Update time variables.
Calculate distance and phi control values.
Create and publish a Twist2DStamped message if lane control is enabled.
# Method: calcDistControl
Calculate time delta.
Compute proportional error for distance.
Update integral error for distance.
Calculate derivative error for distance.
Compute final distance control value using PID formula.
# Method: calcPhiControl
Calculate time delta.
Compute proportional error for phi.
Update integral error for phi.
Calculate derivative error for phi.
Compute final phi control value using PID formula.
# Main function
Initialize the ROS node.
Create an instance of LaneControllerNode.
Enter a loop that continues until ROS shutdown:
Update PID and other parameters from ROS parameter server.
Sleep according to the defined rate.

# Class: CombNode
The main loop of the program continuously updates various parameters from the ROS parameter server, allowing for dynamic reconfiguration of the image processing pipeline.
# Method: init
Initializes the node and sets up subscribers and publishers.
Creates a CvBridge object for converting between ROS and OpenCV images.
Sets up parameters for image processing and line detection.
# Method: callback
Processes incoming compressed camera images.
Performs the following steps:
Crops and resizes the image
Applies Canny edge detection
Converts the image to HSV color space
Filters and masks yellow, white, and red colors
Detects lines using Hough transform for each color
Normalizes detected line segments and publishes them as SegmentList messages.
# Method: canny_edge
Applies Canny edge detection to the input image.
# Method: crop_image
Resizes and crops the input compressed image.
# Method: hsv_convert
Converts the input image from BGR to HSV color space.
# Method: yellow_filter, white_filter, red_filter
Apply color filtering for yellow, white, and red colors respectively:
Use cv2.inRange to filter colors based on HSV thresholds.
Apply erosion and dilation to clean up the filtered image.
# Method: yellow_mask, white_mask, red_mask
For each color:
Create a masked image by combining the Canny edge detection result with the color filter.
Apply Hough transform to detect lines in the masked image.
# Method: output_lines
Draws detected lines on the input image (for debugging purposes).

---

## Setup Instructions

1. **Dependencies**
   - ROS (Robot Operating System)
   - `duckietown_msgs` and related packages
   - AprilTag detector libraries
   - OpenCV and NumPy

2. **Running the Project**
   - Start the Launcher File:
     ```bash
     roslaunch <your_package_name> lab6.launch
     ```

3. **Testing**
   - Place the Duckiebot in an environment with lane markings, intersections, and AprilTags.
   - Enable the FSM and observe its behavior at intersections.

---

## Customization

- Modify the movement queue in `fsm.py` to change the intersection navigation order.
- Update the AprilTag dictionary in `apriltag_reader.py` to add new sign types.
