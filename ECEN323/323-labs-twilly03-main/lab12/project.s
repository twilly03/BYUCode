#####################################################################################
#
# project.s
#
# This is the final processor lab
# 
# This program implements a simple game in which the user moves a character across the screen   # and uses the switches to switch across characters. 
#
# Memory Organization:
#   0x0000-0x1fff : text
#   0x2000-0x3fff : data
#   0x7f00-0x7fff : I/O
#   0x8000-0xbfff : VGA
#
# The stack will operate in the data segment and thus starts at 0x3ffc 
# and works its way down.
#
# Registers:
#  x1(ra):  Return address
#  x2(sp):  Stack Pointer
#  x3(gp):  Data segment pointer
#  x4(tp):  I/O base address
#  x8(s0):  VGA base address
#
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
    .eqv CHAR_COLOR_OFFSET 0x34

# I/O mask constants
    .eqv BUTTON_C_MASK 0x01
    .eqv BUTTON_L_MASK 0x02
    .eqv BUTTON_D_MASK 0x04
    .eqv BUTTON_R_MASK 0x08
    .eqv BUTTON_U_MASK 0x10

# ASCII SPACE
    .eqv SPACE_CHAR 0x20
    .eqv HASH_CHAR 0x23
    .eqv FIRST_COLUMN 1
    .eqv FIRST_ROW 2
    .eqv LAST_COLUMN 78                 # 79 - last two columns don't show on screen
    .eqv LAST_ROW 29                    # 31 - last two rows down't show on screen
    .eqv ADDRESSES_PER_ROW 512
    .eqv NEG_ADDRESSES_PER_ROW -512

# Program constants
    .eqv IO_BASE_PRESHIFT 0x7f
    .eqv IO_BASE_SHFTLEFT 8
    .eqv VGA_BASE_PRESHIFT 0x40
    .eqv VGA_BASE_SHFTLEFT 9
    .eqv SWITCH_MASK_15 0x8000
    .eqv SWITCH_MASK_7 0x7f
    .eqv SWITCH_MASK_12_PRESHIFT 0x7ff
    .eqv LOOP_CONSTANT_PRESHIFT 0x400

main:

    # Prepare I/O base address (0x7f00). 
    # We don't have the LUI instruction to do this more naturally
    addi gp, x0, IO_BASE_PRESHIFT
    # Shift left 8 (0x7f00)
    slli gp, gp, IO_BASE_SHFTLEFT
    # 0x7f00 should be in gp

    # Prepare VGA base address (0x8000)
    li tp, 0x00009A60
    li s3, 0x8401 #Pointer to VGA space that will change
    
reset: 
    # Clear the screen with the specified color (red=0x9, green=0x2, blue=0xe or 0x92e)
    addi t2, x0, 0x000           # Specify the color (red=0x9, green=0x2, blue=0xe or 0x92e)
    slli t2, t2, 4		#shift left by 4 to create room for e
    addi t2, t2, 0x000		#add e to t2 for the background color
    slli t2, t2, 12		#shift left 12 to put it in background color range
    addi t1, x0, 0xe           # Specify the color (red=0x9, green=0x2, blue=0xe or 0x92e)
    slli t1, t1, 4		#shift left 4 to add 0
    or t3, t1, t2	  	# Merge the foreground and the background
    sw t3, CHAR_COLOR_OFFSET(gp)  # Write the color values
    addi s9, x0, 0		#create a register to store valid moves
    
    # Write a space to all locations in VGA memory
    addi t0, x0, SPACE_CHAR       # ASCII character for space
    add t1, x0, s3                # Pointer to VGA space that will change
    # Create constant 0x1000
    addi t2, x0, LOOP_CONSTANT_PRESHIFT  # 0x400
    # should get 0x1000
    slli t2, t2, 2

L5:
    sw t0, 0(t1)                # Write 'space' character to pointer in VGA space
    addi t2, t2, -1             # Decrement counter
    beq t2, x0, L6              # Exit loop when done
    addi t1, t1, 4              # Increment memory pointer by 4 to next character address
    beq x0, x0, L5
L6:
    # Done initializing screen
    # Initialize the VGA character write constants
    li s0, 0x00009A60     	# s0: pointer to VGA locations
    addi s1, x0, 24              # s1: current column
    addi s2, x0, 13              # s2: current row
    # Clear Seven segment display and LEDs
    sw x0, SEVENSEG_OFFSET(gp)
    sw x0, LED_OFFSET(gp)
    beq x0, x0, DISPLAY_LOCATION

    # Wait until all the buttons are released before proceeding to check for status of buttons
    # (this is a one shot functionality to prevent one button press from causing more than one
    #  response)
BTN_RELEASE:
    # Set the foreground based on switches (t2)
    lw t2, SWITCH_OFFSET(gp)
    lw t0, BUTTON_OFFSET(gp)
    # Keep jumping back until a button is pressed
    beq x0, t0, BTN_PRESS
    beq x0, x0, BTN_RELEASE

BTN_PRESS:
    # Wait for button press
    lw t0, BUTTON_OFFSET(gp)
    # Keep jumping back until a button is pressed
    beq x0, t0, BTN_PRESS

    # See if BUTTON_C is pressed. If so, clear VGA
    addi t1, x0, BUTTON_C_MASK
    beq t0, t1, reset

UPDATE_DISPLAY_POINTER:
    # Any other button means print the character of the switches on the VGA and move the pointer

    # Update the pointer based on the button
    addi t1, x0, BUTTON_L_MASK
    beq t0, t1, PROCESS_BTNL
    addi t1, x0, BUTTON_R_MASK
    beq t0, t1, PROCESS_BTNR
    addi t1, x0, BUTTON_U_MASK
    beq t0, t1, PROCESS_BTNU
    addi t1, x0, BUTTON_D_MASK
    beq t0, t1, PROCESS_BTND

    # Shouldn't get here
    beq x0, x0, BTN_RELEASE

    # These code segments update the data to print on the SSD as well
    # as determine the new next location for printing characters
PROCESS_BTNR:
    # Move pointer right
    addi t0, x0, LAST_COLUMN
    beq s1, t0, BTN_RELEASE                     # Ignore if on last column
    lw t1, SWITCH_OFFSET(gp)                    # Read the switches
    addi t3, x0, 0x8
    slli t3, t3, 12
    and t2, t1, t3
    beq t2, x0, PRINT_SPACE_R
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack
    jal INCREMENT_P
    lw ra, 0(sp)
    addi sp, sp, 4
    addi s1, s1, 1                              # Increment column
    addi s0, s0, 4                              # Increment pointer for next display location
    beq x0, x0, DISPLAY_LOCATION
    
PRINT_SPACE_R:
    addi t1, x0, SPACE_CHAR                     #write space to t1
    sw t1, 0(s0)
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack
    jal INCREMENT_P
    lw ra, 0(sp)
    addi sp, sp, 4
    addi s1, s1, 1                              # Increment column
    addi s0, s0, 4                              # Increment pointer for next display location
    beq x0, x0, DISPLAY_LOCATION  

PROCESS_BTNL:
    # Move pointer left
    addi t0, x0, FIRST_COLUMN
    beq s1, t0, BTN_RELEASE                     # Ignore if on first column
    lw t1, SWITCH_OFFSET(gp)                    # Read the switches
    addi t3, x0, 0x8
    slli t3, t3, 12
    and t2, t1, t3
    beq t2, x0, PRINT_SPACE_L
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack
    jal INCREMENT_P
    lw ra, 0(sp)
    addi sp, sp, 4
    addi s1, s1, -1                             # Decrement column
    addi s0, s0, -4                             # Decrement pointer for next display location
    beq x0, x0, DISPLAY_LOCATION

PRINT_SPACE_L:
    addi t1, x0, SPACE_CHAR                     #write space to t1
    sw t1, 0(s0)
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack
    jal INCREMENT_P
    lw ra, 0(sp)
    addi sp, sp, 4
    addi s1, s1, -1                             # Decrement column
    addi s0, s0, -4                             # Decrement pointer for next display location
    beq x0, x0, DISPLAY_LOCATION

PROCESS_BTNU:
    # Move pointer Up
    addi t0, x0, FIRST_ROW
    beq s2, t0, BTN_RELEASE                     # Ignore if on first row
    lw t1, SWITCH_OFFSET(gp)                    # Read the switches
    addi t3, x0, 0x8
    slli t3, t3, 12
    and t2, t1, t3
    beq t2, x0, PRINT_SPACE_U
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack
    jal INCREMENT_P
    lw ra, 0(sp)
    addi sp, sp, 4
    addi s2, s2, -1                             # Decrement row
    addi s0, s0, NEG_ADDRESSES_PER_ROW          # Decrement pointer
    beq x0, x0, DISPLAY_LOCATION
    
PRINT_SPACE_U:
    addi t1, x0, SPACE_CHAR                     #write space to t1
    sw t1, 0(s0)
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack
    jal INCREMENT_P
    lw ra, 0(sp)
    addi sp, sp, 4
    addi s2, s2, -1                             # Decrement row
    addi s0, s0, NEG_ADDRESSES_PER_ROW          # Decrement pointer
    beq x0, x0, DISPLAY_LOCATION
    
PROCESS_BTND:
    # Move pointer Down
    addi t0, x0, LAST_ROW
    beq s2, t0, BTN_RELEASE                     # Ignore if on last row
    lw t1, SWITCH_OFFSET(gp)                    # Read the switches
    addi t3, x0, 0x8
    slli t3, t3, 12
    and t2, t1, t3
    beq t2, x0, PRINT_SPACE_D
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack
    jal INCREMENT_P
    lw ra, 0(sp)
    addi sp, sp, 4
    addi s2, s2, 1                              # Increment row
    addi s0, s0, ADDRESSES_PER_ROW              # Increment pointer
    beq x0, x0, DISPLAY_LOCATION
    
PRINT_SPACE_D:
    addi t1, x0, SPACE_CHAR                     #write space to t1
    sw t1, 0(s0)
    addi sp, sp, -4	    # Make room to save return address on stack
    sw ra, 0(sp)		# Put return address on stack
    jal INCREMENT_P
    lw ra, 0(sp)
    addi sp, sp, 4
    addi s2, s2, 1                              # Increment row
    addi s0, s0, ADDRESSES_PER_ROW              # Increment pointer
    beq x0, x0, DISPLAY_LOCATION
    
INCREMENT_P:
    addi s9, s9, 1				#incremement valid move
    ret

DISPLAY_LOCATION:
    # Display the character at the current location
    lw t1, SWITCH_OFFSET(gp)                    # Read the switches
    addi t2, x0, SWITCH_MASK_7                  # Create mask for switches (only look at bottom 7)
    and t1, t1, t2                              # Keep only lower 7 bits of switches
    sw t1, 0(s0)                                # Write the character to the VGA

    # Display pointer on LCD
    sw s9, SEVENSEG_OFFSET(gp)
    # Display col,row on LEDs
    add t0, s1, x0                              # Load s1 (column) to t0
    # Shift by 8
    slli t0, t0, 8
    # Or s2 (row)
    or t0, t0, s2
    # Write to LEDs
    sw t0, LED_OFFSET(gp)

    # Go back to button release
    beq x0, x0, BTN_RELEASE

