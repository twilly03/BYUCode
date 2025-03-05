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

# add random hexidecimal numers to op1 and op2
add_force op1 f3212f37 -radix hex
add_force op2 621c3ee7 -radix hex
run 10ns

#set alu_op to a an operand
add_force alu_op 0000
run 10ns

#cylce through each operand to ensure correctness
add_force alu_op 0001
run 10ns
add_force alu_op 0010
run 10ns
add_force alu_op 0011
run 10ns
add_force alu_op 0110
run 10ns
add_force alu_op 0111
run 10ns
add_force alu_op 1000
run 10ns
add_force alu_op 1001
run 10ns
add_force alu_op 1010
run 10ns
add_force alu_op 1101
run 10ns





