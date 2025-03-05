#######################
#
# fib.s
#
# Thomas Williams
#
# Template for completing Fibinnoci sequence in lab 11
#
# Memory Organization:
#   0x0000-0x1fff : text
#   0x2000-0x3fff : data
# Registers:
#   x0: Zero
#   x1: return address
#   x2 (sp): stack pointer (starts at 0x3ffc)
#   x3 (gp): global pointer (to data: 0x2000)
#   s0: Loop index for Fibonacci call
#   s1: Pointer to 'fib_count' in data segment
#   x10-x11: function arguments/return values
#
#######################
.globl  main

.eqv ITERATIONS 15

.text
main:

    #########################
    # Program Initialization
    #########################

    # Setup the stack: sp = 0x3ffc
    lui sp, 4				    # 4 << 12 = 0x4000
    addi sp, sp, -4			    # 0x4000 - 4 = 0x3ffc
    # setup the global pointer to the data segment (2<<12 = 0x2000)
    lui gp, 2
    
    # Prepare the loop to iterate over each Fibonacci call
    addi s0, x0, 0			    # Loop index (initialize to zero)

    # Load the loop terminal count value (in the .data segment)

    # The following assembly language macro is useful for accessing variables
    # in the data segment. This macro helps determine the address of data variables.
    # The form of the macro is '%lo(label)(register). The 'label' refers to
    # a label in the data segment and the register refers to the RISC-V base
    # register used to access the memory. In this case, the label is 
    # 'fib_count' (see the .data segment) and the register is 'gp' which points
    # to the data segment. The assembler will figure out what the offset is for
    # 'fib_count' from the data segment.
    lw s1,%lo(fib_count)(gp)	 # Load terminal count into s1

    # This loop will call both the iterative and the recursive version of the
    # Fibinocci sequence for each value of the loop index. The total number
    # of loops is deteremined by the 'fib_count' memory location in the data
    # segment.
FIB_LOOP:
    # Set up argument for call to iterative fibinnoci
    mv a0, s0
    jal iterative_fibinnoci
    # Save the result into s2
    mv s2, a0
    # Set up argument for call to recursive fibinnoci
    mv a0, s0	
    jal recursive_fibinnoci
    # Save the result into s3
    mv s3, a0
    
    # Determine index in circular buffer on where to store result
    andi s4, s0, 0xf	# keep lower 4 bits (between zero and fifteen)
    # multiply by 4 (shift left by 2) to get offset
    slli s4, s4, 2
    
    # Compute base pointer to iterative_data
    addi s5, x3, %lo(iterative_data)
    # add the offset into the table based on the current index
    add s5, s5, s4
    # Store result
    sw s2,(s5)
    
    # Compute base pointer to recursive_data
    addi s5, x3, %lo(recursive_data)
    add s5, s5, s4
    # Store result
    sw s3,(s5)
    
    # Increment pointer and see if we are done
    addi s0, s0, 1              # This could be a nice breakpoint when debugging
    beq s0, s1, done
    # Not done, jump back to do another iteration
    j FIB_LOOP

done:
    
    # Now add the results and place in a0
    addi t0, x0, 0     	        # Counter (initialize to zero)
    addi t1, x0, ITERATIONS		# Terminal count for loop
    addi a0, x0, 0		        # Intialize a0 t0 zero
    # create a pointer to the iterative data
    addi t2, gp, %lo(iterative_data)
    # create a pointer to the recursive data
    addi t3, gp, %lo(recursive_data)
    
    # Add the results of all the calls
final_add:
    lw t4, (t2)
    add a0, a0, t4
    lw t4, (t3)
    add a0, a0, t4
    addi t2, t2, 4		        # increment pointer
    addi t3, t3, 4		        # increment pointer
    addi t0, t0, 1
    blt t0, t1, final_add
    
    # Done here!
END:
    addi a7, x0, 10   # Exit system call
    ebreak
    # Should never get here
    jal x0, END
    # Extra NOPs at the end to make sure there is something in the pipeline
    nop
    nop
    nop

iterative_fibinnoci:

    # This is where you should create your iterative Fibinnoci function.
    # The input argument arrives in a0. You should create a new stack frame
    # and put your result in a0 when you return.
    # Save registers on the stack
    addi sp, sp, -12     # Adjust stack pointer
    sw ra, 0(sp)         # Save return address
    sw s0, 4(sp)         # Save s0
    sw s1, 8(sp)         # Save s1

    # Load n (argument) into s0 as the loop limit
    mv s0, a0

    # Check if n is 0 or 1
    addi t0, x0, 1
    blt s0, t0, fib_zero_or_one_i
    
    # Initialize Fibonacci numbers
    addi s1, x0, 0     # fib_2
    addi a0, x0, 1     # fib_1

    # Loop initialization
    add t0, x0, x0   # t0 is the loop variable (initialized to 0)
    add t1, x0, s0    # t1 is the loop limit constant

loop_init:
    # Check loop condition
    bge t0, t1, loop_end_i # if true go to loop end

    # Loop body: Calculate next Fibonacci number
    add a1, s1, a0   # fib = fib_1 + fib_2
    mv s1, a0        # fib_2 = fib_1
    mv a0, a1        # fib_1 = fib

    # Post loop update
    addi t0, t0, 1   # Decrement i
    beq x0, x0 loop_init       # Jump back to loop initialization


loop_end_i:

    # Place result in a0
    mv a0, a1

    beq x0, x0 fib_end_i         # jump to the end

fib_zero_or_one_i:
    # If n is 0 or 1, fib(n) is n
    mv a0, s0    # Place n in a0 (result)
    beq x0, x0 fib_end_i     # Jump to the end of the function

fib_end_i:

    # Restore registers from the stack
    lw ra, 0(sp)     # Restore return address
    lw s0, 4(sp)     # Restore s0
    lw s1, 8(sp)     # Restore s1
    addi sp, sp, 12  # Restore stack pointer
    ret


recursive_fibinnoci:

    # This is where you should create your iterative Fibinnoci function.
    # The input argument arrives in a0. You should create a new stack frame
    # and put your result in a0 when you return.
    # Save registers on the stack
	
    addi sp, sp, -24	# Allocate space for 6 words on the stack
    sw ra, 0(sp)		# Store the return address in memory
  
  	# Check for base case n<= 2
    addi t0, x0, 2		# Load 2 to into t0
    bge t0, a0, base_case   # Branch if t0 >= a0
    beq x0, x0 base_case             # Jump to base_case (if t0 < a0)
  	
  	# Recursive call for n-1
    sw a0, 8(sp)		# Save the value of a0 on the stack
    addi a0, a0, -1	# Decrement a0 by n-1
    jal recursive_fibinnoci		# Jump to fibonacci section
    sw a0, 16(sp)		# Restore value of a0 from stack
  
  	# Recursive call for n-2
    lw a0, 8(sp)		# Load the value of a0 from the stack
    addi a0, a0, -2	# Decrement a0 by 2(n-2) for the second recursive call.
    jal recursive_fibinnoci		# Jump to fibonacci section
  
    lw t0, 16(sp)		# Load result of first recursive call from stack into t0
    add a0, a0, t0	# Add result of two recursive calls (n-1 and n-2) into a0
    beq x0, x0 return	# Jump to return	

base_case:	# Base case for n<=2
    addi a0, x0, 1	# Return value of 1 in arg

return:		
    lw ra, 0(sp)	# Reload return address from memory
    addi sp, sp, 24	# Deallocate stack memory
    ret		# Return to main (at return address)
    # Extra NOPs inserted to make sure we have instructions in the pipeline for the last instruction
    nop
    nop
    nop

.data

# Indicates how many Fibonacci sequences to compute
fib_count:
    .word ITERATIONS   # Number of Fibonacci sequences to compute

# Reserve 16 words for results of iterative sequences
# (16 words of 4 bytes each for a total of 64 bytes)
iterative_data:
    .space 64 

# Reserve 16 words for results of recursive sequences
# (16 words of 4 bytes each for a total of 64 bytes)
recursive_data:
    .space 64 

