####################################################################################3#
#
# buttoncount.s
#
# This simple test program demonstrates the operation of all the LEDs, switches,
# buttons, and seven segment display in the I/O sub-system. 
#
#  - The timer value is copied to the seven segment display
#  - Button behavior:
#    - BTNC clears the LEDS
#    - BTND decrement the LEDS by 1
#    - BTNU increment the LEDS by 1
#    - No button:
#      The value of the switches are continuously copied to the seven segment #display
#
# This version of the program is written using the primitive instruction set
# for the multi-cycle RISC-V processor developed in the first labs.
#
# This program does not use the data segment.
#
# Memory Organization:
#   0x0000-0x1fff : text
#   0x2000-0x3fff : data
#   0x7f00-0x7fff : I/O
#
# Registers:
#  x3(gp):  I/O base address
#  x8(s0):  Value of buttons
#  x9(s1):  Value of switches
#  x18(s2): Value to write in LEDs
#
####################################################################################3#
.globl  main
.data
.word 0
.text

# I/O address offset constants
.eqv LED_OFFSET 0x0
.eqv SWITCH_OFFSET 0x4
.eqv SEVENSEG_OFFSET 0x18
.eqv BUTTON_OFFSET 0x24

# I/O mask constants
.eqv BUTTON_C_MASK 0x01
.eqv BUTTON_D_MASK 0x04
.eqv BUTTON_U_MASK 0x10

main:
# Prepare I/O base address
addi gp, x0, 0x7f
# Shift left 8
slli gp, gp, 8

# Set constants
# Clear seven segment display
sw x0, SEVENSEG_OFFSET(gp)          
# Initialize s2 to zero (led value)
addi s2, x0, 0

LOOP_START:
# Read and set button, switch, seven segment, and led values
lw s0, BUTTON_OFFSET(gp) # Load the buttons
lw s1, SWITCH_OFFSET(gp) # Read the switches
sw s1, SEVENSEG_OFFSET(gp) # Write switches to seven seg
sw s2, LED_OFFSET(gp) # Write current led value to leds

BTNC_CHK: # Check btnc
# Mask btnc
andi t0, s0, BUTTON_C_MASK
# If button is not pressed, jump to BTNU_CHK
beq t0, x0, BTNU_CHK
# Button C pressed - turn off leds
add s2, x0, x0
# Jump to BTNC_ONESHOT to wait for button release
beq x0, x0, BTNC_ONESHOT

BTNC_ONESHOT: # Wait for BTNC to be released
# Read and set button, switch, seven segment, and led values
lw s0, BUTTON_OFFSET(gp) # Load the buttons
lw s1, SWITCH_OFFSET(gp) # Read the switches
sw s1, SEVENSEG_OFFSET(gp) # Write switches to seven seg
sw s2, LED_OFFSET(gp) # Write current led value to leds
# Mask btnc
andi t0, s0, BUTTON_C_MASK
# If button is released exit ONESHOT loop
beq t0, x0, WRITE_LED
# Button C pressed - stay in the loop 
beq x0, x0, BTNC_ONESHOT

BTNU_CHK: # Check btnu
# Mask btnu
andi t0, s0, BUTTON_U_MASK
# If button is not pressed, jump to BNTD_CHK
beq t0, x0, BTND_CHK
# Button U pressed - increment led value by 1
addi s2, s2, 1
# Jump to BTNU_ONESHOT to wait for button release
beq x0, x0, BTNU_ONESHOT

BTNU_ONESHOT: # Wait for BTNU to be released
# Read and set button, switch, seven segment, and led values
lw s0, BUTTON_OFFSET(gp) # Load the buttons
lw s1, SWITCH_OFFSET(gp) # Read the switches
sw s1, SEVENSEG_OFFSET(gp) # Write switches to seven seg
sw s2, LED_OFFSET(gp) # Write current led value to leds
# Mask btnu
andi t0, s0, BUTTON_U_MASK
# If button is released exit ONESHOT loop
beq t0, x0, WRITE_LED
# Button U pressed - stay in the loop 
beq x0, x0, BTNU_ONESHOT

BTND_CHK: # Check btnd
# mask btnd
andi t0, s0, BUTTON_D_MASK
# If button is not pressed, jump to WRITE_LED
beq t0, x0, WRITE_LED
# Button D pressed - decrement led value by 1
addi s2, s2, -1
# Jump to BTND_ONESHOT to wait for button release
beq x0, x0, BTND_ONESHOT

BTND_ONESHOT: # Wait for BTND to be released
# Read and set button, switch, seven segment, and led values
lw s0, BUTTON_OFFSET(gp) # Load the buttons
lw s1, SWITCH_OFFSET(gp) # Read the switches
sw s1, SEVENSEG_OFFSET(gp) # Write switches to seven seg
sw s2, LED_OFFSET(gp) # Write current led value to leds
# Mask btnd
andi t0, s0, BUTTON_D_MASK
# If button is released exit ONESHOT loop
beq t0, x0, WRITE_LED
# Button D pressed - stay in the loop 
beq x0, x0, BTND_ONESHOT

WRITE_LED:
# Update led display and end loop
sw s2, LED_OFFSET(gp) # Write current led value to leds
beq x0, x0, LOOP_START   # Jump back to start
	
