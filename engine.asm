ClearGrids:
    la   $t0, currentGrid   
    la   $t1, nextGrid      
    add  $t2, $zero, $zero  
    addi $t3, $zero, 16384  # 64x64 grid * 4 bytes per cell
ClearLogicLoop:
    beq  $t2, $t3, EndClear
    add  $t4, $t0, $t2
    add  $t5, $t1, $t2
    sw   $zero, 0($t4)         
    sw   $zero, 0($t5)         
    addi $t2, $t2, 4
    j    ClearLogicLoop
EndClear:
    jr   $ra               

CalculateNextGen:
    addi $s0, $zero, 1     # we start at row 1 to avoid edge cells
OuterLoop:
    slti $t0, $s0, 63      
    beq  $t0, $zero, EndCalc  
    addi $s1, $zero, 1     
InnerLoop:
    slti $t1, $s1, 63      # only process rows 1-62
    beq  $t1, $zero, NextY 

    get_offset($s0, $s1, $t9)  # converting y, x coords into linear memory offset
    la   $t8, currentGrid
    add  $t2, $t8, $t9     
    la   $t8, nextGrid
    add  $t6, $t8, $t9     

    add  $t3, $zero, $zero # count all 8 neighboring live cells
    lw   $t4, -260($t2)    # top left
    add  $t3, $t3, $t4     
    lw   $t4, -256($t2)    # top
    add  $t3, $t3, $t4
    lw   $t4, -252($t2)    # top right
    add  $t3, $t3, $t4
    lw   $t4, -4($t2)      # left
    add  $t3, $t3, $t4
    lw   $t4, 4($t2)       # right
    add  $t3, $t3, $t4
    lw   $t4, 252($t2)     # bottom left
    add  $t3, $t3, $t4
    lw   $t4, 256($t2)     # bottom
    add  $t3, $t3, $t4
    lw   $t4, 260($t2)     # bottom right
    add  $t3, $t3, $t4

    lw   $t5, 0($t2)       
    add  $t7, $zero, $zero 
    addi $t8, $zero, 3       
    beq  $t3, $t8, SetAlive   # exactly 3 neighbors means alive
    addi $t8, $zero, 2       
    beq  $t3, $t8, SetCurrent # exactly 2 neighbors means preserve state
    j    WriteNextState       
SetAlive:
    addi $t7, $zero, 1        
    j    WriteNextState       
SetCurrent:
    add  $t7, $zero, $t5      
WriteNextState:
    sw   $t7, 0($t6)          

    addi $s1, $s1, 1       
    j    InnerLoop         
NextY:
    addi $s0, $s0, 1       
    j    OuterLoop         
EndCalc:
    jr   $ra               

ApplyDelay:
    lw   $t0, delayValue
    beq  $t0, $zero, EndDelay   
    add  $t1, $zero, $zero
DelayWait:                    # busy-wait loop
    beq  $t1, $t0, EndDelay
    addi $t1, $t1, 1
    j    DelayWait
EndDelay:
    jr   $ra
