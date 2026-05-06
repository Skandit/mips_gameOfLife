MenuInput:
    addi $sp, $sp, -4          # push stack
    sw   $ra, 0($sp)

MenuLoop:
    lui  $t0, 0xFFFF           # keyboard base address
    lw   $t1, 0($t0)           # read status
    andi $t1, $t1, 1           # check if key ready
    beq  $t1, $zero, MenuLoop  # wait until key is pressed
    
    lw   $t2, 4($t0)           # get key value
    addi $t3, $zero, 49        # '1'
    beq  $t2, $t3, StartWithDot
    addi $t3, $zero, 50        # '2'
    beq  $t2, $t3, StartWithGlider
    addi $t3, $zero, 51        # '3'
    beq  $t2, $t3, StartWithGun
    addi $t3, $zero, 52        # '4'
    beq  $t2, $t3, StartWithLWSS
    j    MenuLoop              
        
StartWithDot:
    addi $t3, $zero, 1
    sw   $t3, selectedPattern
    addi $a2, $zero, 1
    jal  ApplyPattern
    j    EndMenu              
StartWithGlider:
    addi $t3, $zero, 2
    sw   $t3, selectedPattern
    addi $a2, $zero, 1
    jal  ApplyPattern
    j    EndMenu              
StartWithGun:
    addi $t3, $zero, 3
    sw   $t3, selectedPattern
    addi $a2, $zero, 1
    jal  ApplyPattern
    j    EndMenu              
StartWithLWSS:
    addi $t3, $zero, 4
    sw   $t3, selectedPattern
    addi $a2, $zero, 1
    jal  ApplyPattern
    j    EndMenu              

EndMenu:
    lw   $ra, 0($sp)           # pop stack
    addi $sp, $sp, 4
    jr   $ra                  

GameInput:
    addi $sp, $sp, -4          
    sw   $ra, 0($sp)

    lui  $t0, 0xFFFF           
    lw   $t1, 0($t0)           
    andi $t1, $t1, 1           # check if user pressed a button
    beq  $t1, $zero, EndGameInput   

    lw   $t2, 4($t0)           # get the key
    
    addi $t3, $zero, 110       # 'n'
    beq  $t2, $t3, SetSlow
    addi $t3, $zero, 109       # 'm'
    beq  $t2, $t3, SetNormal
    
    addi $t3, $zero, 114       # 'r'
    beq  $t2, $t3, main        # hard reset game
    addi $t3, $zero, 32        # 'space'
    bne  $t2, $t3, EndGameInput     

    j    PauseLoop             # enter editing mode

SetSlow:
    lw   $t4, slowDelayAmt
    sw   $t4, delayValue       # set delay to slow
    j    EndGameInput
SetNormal:
    sw   $zero, delayValue     # set delay to zero (fast mode)
    j    EndGameInput

PauseLoop:
    jal  RenderStaticGrid      # show current state
    jal  DrawHologram          # show ghost of selected pattern

WaitKey:
    lui  $t0, 0xFFFF           
    lw   $t1, 0($t0)           
    andi $t1, $t1, 1           
    beq  $t1, $zero, WaitKey   # wait for edit command

    lw   $t2, 4($t0)        

    # Movement controls
    addi $t3, $zero, 119       # 'w'
    beq  $t2, $t3, MoveUp
    addi $t3, $zero, 115       # 's'
    beq  $t2, $t3, MoveDown
    addi $t3, $zero, 97        # 'a'
    beq  $t2, $t3, MoveLeft
    addi $t3, $zero, 100       # 'd'
    beq  $t2, $t3, MoveRight
    
    # Switch patterns while paused
    addi $t3, $zero, 49        # '1'
    beq  $t2, $t3, SetPat1
    addi $t3, $zero, 50        # '2'
    beq  $t2, $t3, SetPat2
    addi $t3, $zero, 51        # '3'
    beq  $t2, $t3, SetPat3
    addi $t3, $zero, 52        # '4'
    beq  $t2, $t3, SetPat4
    
    # Place or remove patterns
    addi $t3, $zero, 122       # 'z' 
    beq  $t2, $t3, ApplyZ      # draw pattern
    addi $t3, $zero, 120       # 'x' 
    beq  $t2, $t3, ApplyX      # delete pattern

    # Global controls
    addi $t3, $zero, 32         # 'space'
    beq  $t2, $t3, EndGameInput # resume simulation
    addi $t3, $zero, 114        # 'r'
    beq  $t2, $t3, main        
    
    j    PauseLoop          

MoveUp:
    la   $t9, cursorY
    lw   $s3, 0($t9)
    beq  $s3, $zero, PauseLoop
    addi $s3, $s3, -1           
    sw   $s3, 0($t9)
    j    PauseLoop
MoveDown:
    la   $t9, cursorY
    lw   $s3, 0($t9)
    addi $t4, $zero, 63
    beq  $s3, $t4, PauseLoop
    addi $s3, $s3, 1            
    sw   $s3, 0($t9)
    j    PauseLoop
MoveLeft:
    la   $t8, cursorX
    lw   $s2, 0($t8)
    beq  $s2, $zero, PauseLoop
    addi $s2, $s2, -1           
    sw   $s2, 0($t8)
    j    PauseLoop
MoveRight:
    la   $t8, cursorX
    lw   $s2, 0($t8)
    addi $t4, $zero, 63
    beq  $s2, $t4, PauseLoop
    addi $s2, $s2, 1            
    sw   $s2, 0($t8)
    j    PauseLoop

SetPat1:
    addi $t3, $zero, 1
    sw   $t3, selectedPattern
    j    PauseLoop
SetPat2:
    addi $t3, $zero, 2
    sw   $t3, selectedPattern
    j    PauseLoop
SetPat3:
    addi $t3, $zero, 3
    sw   $t3, selectedPattern
    j    PauseLoop
SetPat4:
    addi $t3, $zero, 4
    sw   $t3, selectedPattern
    j    PauseLoop

ApplyZ:
    addi $a2, $zero, 1         # alive
    jal  ApplyPattern
    j    PauseLoop
ApplyX:
    addi $a2, $zero, 0         # dead
    jal  ApplyPattern
    j    PauseLoop

EndGameInput:
    lw   $ra, 0($sp)          
    addi $sp, $sp, 4
    jr   $ra