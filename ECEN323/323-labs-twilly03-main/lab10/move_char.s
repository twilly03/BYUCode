####################################################################################
#
# move_char.s
#
# For the final exercise, you are to create your own custom assembly language program 
#
# This program does not use the data segment.
#
# Memory Organization:
#   0x0000-0x1fff : text
#   0x2000-0x3fff : data
#   0x7f00-0x7fff : I/O
#   0x8000- : VGA
#
# Registers:
# x3(gp):   I/O base address
# x4(tp):   VGA Base address
# x8(s0):   Memory pointer to location to display character
# x9(s1):   Current column index
# x18(s2):  Current row index
#
####################################################################################
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
    .eqv SMILEY_FACE 0x01
    .eqv SPACE_CHAR 0x20
    .eqv HASH_CHAR 0x23
    .eqv T_NETID 0x74
    .eqv W_NETID 0x77
    .eqv I_NETID 0x69
    .eqv L_NETID 0x6c
    .eqv S_NETID 0x73
    .eqv ZERO_NETID 0x30
    .eqv LAST_COLUMN 9                 # 10 barrier
    .eqv LAST_ROW 9                    # 10 barrier
    .eqv ADDRESSES_PER_ROW 512
    .eqv NEG_ADDRESSES_PER_ROW -512

# Program constants
    .eqv IO_BASE_PRESHIFT 0x7f
    .eqv IO_BASE_SHFTLEFT 8
    .eqv VGA_BASE_PRESHIFT 0x40
    .eqv VGA_BASE_SHFTLEFT 9
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
    addi tp, x0, VGA_BASE_PRESHIFT # 0x40
    # Shift left 9 (0x8000)
    slli tp, tp, VGA_BASE_SHFTLEFT # 0x40 << 9 = 0x8000
    # 0x8000 should be in tp

CLEAR_VGA:
    # Clear the screen with the specified color (red=0x9, green=0x2, blue=0xe or 0x92e)
    addi t2, x0, 0x92           # Specify the color (red=0x9, green=0x2, blue=0xe or 0x92e)
    slli t2, t2, 4		#shift left by 4 to create room for e
    addi t2, t2, 0xe		#add e to t2 for the background color
    slli t2, t2, 12		#shift left 12 to put it in background color range
    addi t1, x0, 0xf8           # Specify the color (red=0x9, green=0x2, blue=0xe or 0x92e)
    slli t1, t1, 4		#shift left 4 to add 0
    or t3, t1, t2	  	# Merge the foreground and the background
    sw t3, CHAR_COLOR_OFFSET(gp)  # Write the color values
    
    addi s9, x0, 0		#create a register to store valid moves
    
    # Clear the seven-segment display
    sw x0, SEVENSEG_OFFSET(gp)

    # Write a space to all locations in VGA memory
    addi t0, x0, SPACE_CHAR       # ASCII character for space
    add t1, x0, tp                # Pointer to VGA space that will change
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
    # Initialize the VGA character netId constants
    addi s0, tp, 0              # s0: pointer to VGA locations
    addi s1, x0, 60              # s1: current column
    addi s2, x0, 24              # s2: current row
    
    #shift column and row registers
    slli s1, s1, 2		#shift column register left by 2
    slli s2, s2, 9		#shift row regisister left by 9
    
    #Create a temporary pointer to location
    add t1, s1, s0		#Add s0 and s1
    add t1, t1, s2		#Add up all three
    
    # Display the smiley face at the top-left corner
    addi t0, x0, 0x01           # ASCII character for smiley face
    sw t0, 0(s0)                # Write the smiley face character to the top-left corner
    
    #display netID at column 60 and row 24
    addi t0, x0, T_NETID        #ASCII character for t
    sw, t0, 0(t1)		#write t to the coordinate
    addi t0, x0, W_NETID	#ASCII character for w
    sw, t0, 4(t1)		#write w to the coordinate
    addi t0, x0, I_NETID	#ASCII character for i
    sw, t0, 8(t1)		#write i to the coordinate
    addi t0, x0, L_NETID	#ASCII character for l
    sw, t0, 12(t1)		#write l to the coordinate
    addi t0, x0, L_NETID	#ASCII character for l
    sw, t0, 16(t1)		#write l to the coordinate
    addi t0, x0, I_NETID	#ASCII character for i
    sw, t0, 20(t1)		#write i to the coordinate
    addi t0, x0, S_NETID	#ASCII character for s
    sw, t0, 24(t1)		#write s to the coordinate
    addi t0, x0, ZERO_NETID	#ASCII character for 0
    sw, t0, 28(t1)		#write s to the coordinate
    
    # Initialize the VGA character write constants
    addi s0, tp, 0              # s0: pointer to VGA locations
    addi s1, x0, 0              # s1: current column
    addi s2, x0, 0              # s2: current row
    
    # Clear Seven segment display and LEDs
    sw x0, SEVENSEG_OFFSET(gp)
    sw x0, LED_OFFSET(gp)

    # Wait until all the buttons are released before proceeding to check for status of buttons
    # (this is a one shot functionality to prevent one button press from causing more than one
    #  response)

BTN_RELEASE:
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
    beq t0, t1, CLEAR_VGA

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
    addi t1, x0, SPACE_CHAR                     #write space to t1
    sw t1, 0(s0)				#write space to location previous
    addi s9, s9, 1				#incremement valid move
    addi s1, s1, 1                              # Increment column
    addi s0, s0, 4                              # Increment pointer for next display location
    beq x0, x0, DISPLAY_LOCATION

PROCESS_BTNL:
    # Move pointer left
    beq s1, x0, BTN_RELEASE                     # Ignore if on first column
    addi t1, x0, SPACE_CHAR                     #write space to t1
    sw t1, 0(s0)				#write space to location previous
    addi s9, s9, 1				#incremement valid move
    addi s1, s1, -1                             # Decrement column
    addi s0, s0, -4                             # Decrement pointer for next display location
    beq x0, x0, DISPLAY_LOCATION

PROCESS_BTNU:
    # Move pointer Up
    beq s2, x0, BTN_RELEASE                     # Ignore if on first row
    addi t1, x0, SPACE_CHAR                     #write space to t1
    sw t1, 0(s0)				#write space to location previous
    addi s9, s9, 1				#incremement valid move
    addi s2, s2, -1                             # Decrement row
    addi s0, s0, NEG_ADDRESSES_PER_ROW          # Decrement pointer
    beq x0, x0, DISPLAY_LOCATION

PROCESS_BTND:
    # Move pointer Down
    addi t0, x0, LAST_ROW
    beq s2, t0, BTN_RELEASE                     # Ignore if on last row
    addi t1, x0, SPACE_CHAR                     #write space to t1
    sw t1, 0(s0)				#write space to location previous
    addi s9, s9, 1				#incremement valid move
    addi s2, s2, 1                              # Increment row
    addi s0, s0, ADDRESSES_PER_ROW              # Increment pointer
    beq x0, x0, DISPLAY_LOCATION

DISPLAY_LOCATION:
    # Display the character at the current location
    addi t1, x0, SMILEY_FACE                    #write smiley face to t1
    sw t1, 0(s0)                                # Write the character to the VGA
    sw s9, SEVENSEG_OFFSET(gp)			#write valid moves to 7 segment display
    # Go back to button release
    beq x0, x0, BTN_RELEASE
