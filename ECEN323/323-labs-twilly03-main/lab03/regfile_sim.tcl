##########################################################################
#
# regfile_sim.tcl
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

#set all values to zero to start clean
add_force readReg1 0
add_force readReg2 0
add_force writeReg 0
add_force writeData 0
add_force write 0

# Write to two different registers (not x0). Write a negative value to one register and a positive value to the other
add_force writeReg 1010 
add_force writeData 1100
add_force write 1
run  10ns

add_force writeReg 1000
add_force writeData 10101
run  10ns

#Write a non-zero value to register x0
add_force writeReg 0
add_force writeData 1001
run  10ns

#stop writing
add_force write 0

#Read the three registers you wrote to (making sure that you read a 0 from x0)
add_force readReg1 1010
add_force readReg2 0
run 10ns

add_force readReg1 1000
add_force readReg2 0
run 10ns

add_force readReg1 0
add_force readReg2 0
run 10ns

