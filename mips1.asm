.text
.globl main

main:
    
	addi $t0, $zero, 5 
	addi $t1, $zero, 9 
	
	

Loop:
	slt $t3, $t0, $t1
	
	beq $t3, $zero, Exit
	
	addi $t0, $t0, 1
	
	j Loop



Exit:
    # Exit the program (standard SPIM/MARS syscall)
    li   $v0, 10
    syscall	