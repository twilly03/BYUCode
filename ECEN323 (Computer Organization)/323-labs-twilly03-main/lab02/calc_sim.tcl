##########################################################################
#
# alu_sim.tcl
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

# Issue a reset (btnu)
add_force btnu 1
run 20ns

#turn off reset
add_force btnu 0
run 20ns

#turn off everything
add_force btnl 0
add_force btnc 0
add_force btnr 0
add_force sw 0000 -radix hex
run 20ns

#press update button
add_force btnd 1
run 20ns
#release update button
add_force btnd 0
run 20ns

#run tests from table #1
add_force btnl 0
add_force btnc 1
add_force btnr 1
add_force sw 1234 -radix hex
run 20ns

#press update button
add_force btnd 1
run 20ns
#release update button
add_force btnd 0
run 20ns

#run tests from table #2
add_force btnl 0
add_force btnc 1
add_force btnr 0
add_force sw 0ff0 -radix hex
add_force btnd 1
run 20ns

#press update button
add_force btnd 1
run 20ns
#release update button
add_force btnd 0
run 20ns

#run tests from table #3
add_force btnl 0
add_force btnc 0
add_force btnr 0
add_force sw 324f -radix hex
add_force btnd 1
run 20ns

#press update button
add_force btnd 1
run 20ns
#release update button
add_force btnd 0
run 20ns

#run tests from table #4
add_force btnl 0
add_force btnc 0
add_force btnr 1
add_force sw 2d31 -radix hex
add_force btnd 1
run 20ns

#press update button
add_force btnd 1
run 20ns
#release update button
add_force btnd 0
run 20ns

#run tests from table #5
add_force btnl 1
add_force btnc 0
add_force btnr 0
add_force sw ffff -radix hex
add_force btnd 1
run 20ns

#press update button
add_force btnd 1
run 20ns
#release update button
add_force btnd 0
run 20ns

#run tests from table #6
add_force btnl 1
add_force btnc 0
add_force btnr 1
add_force sw 7346 -radix hex
add_force btnd 1
run 20ns

#press update button
add_force btnd 1
run 20ns
#release update button
add_force btnd 0
run 20ns

#run tests from table #7
add_force btnl 1
add_force btnc 0
add_force btnr 1
add_force sw ffff -radix hex
add_force btnd 1
run 20ns

#press update button
add_force btnd 1
run 20ns
#release update button
add_force btnd 0
run 20ns

