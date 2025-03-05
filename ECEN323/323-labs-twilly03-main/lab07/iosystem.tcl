##########################################################################
#
# Filname: iosystem_template.tcl
# Author: Mike Wirthlin
#
# This .tcl script will apply stimulus to the top-level pins of the FPGA
# 
#
##########################################################################


# Start the simulation over
restart

# Run circuit with no input stimulus settings
run 20 ns

# Set the clock to oscillate with a period of 10 ns
add_force clk {0} {1 5} -repeat_every 10
# Run the circuit for a bit
run 40 ns

# set the top-level inputs
add_force btnc 0
add_force btnl 0
add_force btnr 0
add_force btnu 0
add_force btnd 0
add_force sw 0
add_force RsTx 1
run 7 us

# Add your test stimulus here

#turn on btnr
add_force btnr 1
run 10us

#turn off btnr
add_force btnr 0
run 10us

#turn on btnl
add_force btnl 1
run 10us

#turn off btnl
add_force btnl 0
run 10us

#turn on btnu
add_force btnu 1
run 10us

#turn off btnu
add_force btnu 0
run 10us

#turn on btnd
add_force btnd 1
run 10us

#turn off btnd
add_force btnd 0
run 10us

#timer reach a value of 1 ms
run 1ms

#turn on btnc
add_force btnc 1
run 10us

#turn off btnc
add_force btnc 0
run 10us