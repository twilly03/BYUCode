##########################################################################
#
# regfile_top_sim.tcl
# Author: Thomas Williams
# Class: ECEN 323
#
# This .tcl script will apply the input stimulus to the circuit
# as shown in the waveform in the lab wiki.
#
##########################################################################

#restart simulation at time 0
restart

# Run circuit with no input stimulus settings
run 20 ns

# Set the clock to oscillate with a period of 10 ns
add_force clk {0} {1 5} -repeat_every 10

# Run circuit with no input stimulus settings
run 20 ns

#set everything to zero to start
add_force sw 0000 -radix hex
add_force btnl 0
add_force btnc 0
add_force btnu 1
run 20ns
add_force btnu 0
run 20ns

#1a 
add_force sw 0400 -radix hex
add_force btnl 1
run 20ns
add_force btnl 0
run 20ns

#1b 
add_force sw 9234 -radix hex
add_force btnc 1
run 20ns
add_force btnc 0
run 20ns

#2a 
add_force sw 0800 -radix hex
add_force btnl 1
run 20ns
add_force btnl 0
run 20ns

#2b 
add_force sw b678 -radix hex
add_force btnc 1
run 20ns
add_force btnc 0
run 20ns

#3a 
add_force sw 0c41 -radix hex
add_force btnl 1
run 20ns
add_force btnl 0
run 20ns

#3b 
add_force sw 0002 -radix hex 
add_force btnc 1
run 50ns
add_force btnc 0
run 20ns

#end of simulation comment