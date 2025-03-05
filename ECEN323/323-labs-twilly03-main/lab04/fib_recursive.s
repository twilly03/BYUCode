#########################################################################
# 
# Filename: fib_recursive.s
#
# Author: Thomas Williams
# Date: 1/30/24
#
# Description: calculating the nth value of the fibonacci sequence given the nth iteration
# using a recursive method
#
# Functions:
#  - fibonacci:
#  - main
#  - fib_zero_or_one
#  - fib_end
#
#########################################################################

.globl  main

# Constant defines for system calls
.eqv PRINT_INT 1
.eqv PRINT_STR 4
.eqv EXIT_CODE 93

# Global data segment
.data
fib_input:               # The location for the input factorial value
    .word 10             # Allocates 4 bytes and sets the input to 10 (arbitrary)
shift_sign:               # The location for the input factorial value
    .word -1             # Allocates 4 bytes and sets the input to -1 (arbitrary)    
result_str:              # The location for the result string data
    .string "\nFibonacci Number is "    # Allocates 1 byte per character plus null character
netid_str:               # The location for the netid string data
                          # Change the string below to include your net id
    .string "\nNet ID=<twillis0>"       # Allocates 1 byte per character plus null character

.text

# Main function that calls your fibonacci function
main:

    # Load n into a0 as the argument
    lw a0, fib_input
    
    lw a1, shift_sign
    
    # Call the fibonacci function
    jal fibonacci
    
    # Save the result into s2
    mv s2, a0 

    # Print the Result string
    la a0,result_str          # Put string pointer in a0
    li a7,PRINT_STR           # System call code for print_str
    ecall                     # Make system call

    # Print the number        
    mv a0, s2
    li a7,PRINT_INT           # System call code for print_int
    ecall                     # Make system call

    # Print the netid string
    la a0,netid_str           # Put string pointer in a0
    li a7,PRINT_STR           # System call code for print_str
    ecall                     # Make system call

    # Exit (93) with code 0
    li a0,0
    li a7,EXIT_CODE
    ecall
    ebreak

fibonacci:

    # Save registers on the stack
    addi sp, sp, -12     # Adjust stack pointer
    sw ra, 0(sp)         # Save return address
    sw s0, 4(sp)         # Save s0
    sw s1, 8(sp)         # Save s1

    # Load n (argument) into s0
    mv s0, a0

    # Check if n is 0 or 1
    li t0, 1
    blt s0, t0, fib_zero_or_one # if yes send the loop zero_one

    # If n is not 0 or 1, call the recursive function
    addi a0, s0, -1     # a0 = a - 1
    jal fibonacci       # Call fib_recursive(a - 1)
    mv s1, a0           # Save result in s1
   

    addi a0, s0, -2     # a0 = a - 2
    jal fibonacci       # Call fib_recursive(a - 2)
    add a0, a0, s1      # Add result of fib_recursive(a - 1) to result of fib_recursive(a - 2)

    j fib_end           #jump to the end

fib_zero_or_one:
    # If n is 0 or 1, fib(n) is n
    mul s0, s0, a1
    mv a0, s0    # Place n in a0 (result)
    j fib_end     # Jump to the end of the function

fib_end:

    # Restore registers from the stack
    lw ra, 0(sp)     # Restore return address
    lw s0, 4(sp)     # Restore s0
    lw s1, 8(sp)     # Restore s1
    addi sp, sp, 12  # Restore stack pointer

    ret

