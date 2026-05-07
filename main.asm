.data
    currentGrid: .space 16384       
    nextGrid:    .space 16384       
    menuColor:   .word 0x00FF8800   # orange
    displayBase: .word 0x10008000   
    aliveColor:  .word 0x00FFFFFF   # White
    deadColor:   .word 0x00000000   # Black
    
    # Starting cursor at Top-Left
    cursorX:     .word 10           
    cursorY:     .word 10           
    
    
    delayValue:      .word 0          # Current delay (0) normal mode is the fastest mod
    slowDelayAmt:    .word 1000000    # delayed so to speak slow mod
    selectedPattern: .word 1          # 1=Dot, 2=Glider, 3=Gun, 4=Spaceship
    hologramColor:   .word 0x00FF0000 # Red


    # Hardcoded arrays of memory offsets (relative to a starting pixel).

    # 36 Byte offsets to draw a -Gosper Glider Gun-
    gunOffsets:  .word 96, 344, 352, 560, 564, 592, 596, 648, 652, 812, 828, 848, 852, 904, 908, 1024, 1028, 1064, 1088, 1104, 1108, 1280, 1284, 1320, 1336, 1344, 1348, 1368, 1376, 1576, 1600, 1632, 1836, 1852, 2096, 2100

    # 9 Byte offsets to draw a -Lightweight Spaceship-
    lwssOffsets: .word 4, 16, 256, 512, 528, 768, 772, 776, 780

    # 162 Byte offsets to draw the staggered CONWAY'S GAME OF LIFE
    titleOffsets: 
    .word 1584, 1588, 1592, 1840, 2096, 2352, 2608, 2612, 2616, 1600, 1604, 1608, 1856, 1864, 2112, 2120, 2368, 2376, 2624, 2628, 2632, 1616, 1624, 1872, 1876, 1880, 2128, 2136, 2384, 2392, 2640, 2648, 1632, 1640, 1888, 1896, 2144, 2152, 2400, 2404, 2408, 2656, 2664, 1652, 1904, 1912, 2160, 2164, 2168, 2416, 2424, 2672, 2680, 1664, 1672, 1920, 1928, 2180, 2436, 2692, 1684, 1940, 1692, 1696, 1944, 2200, 2204, 2464, 2712, 2716
    .word 3676, 3680, 3928, 4184, 4192, 4440, 4448, 4696, 4700, 4704, 3692, 3944, 3952, 4200, 4204, 4208, 4456, 4464, 4712, 4720, 3704, 3712, 3960, 3964, 3968, 4216, 4220, 4224, 4472, 4480, 4728, 4736, 3720, 3724, 3728, 3976, 4232, 4236, 4488, 4744, 4748, 4752
    .word 6280, 6284, 6288, 6536, 6544, 6792, 6796, 6800, 5788, 5792, 6040, 6296, 6300, 6304, 6552, 6808
    .word 7800, 8056, 8312, 8568, 8824, 8828, 8832, 7816, 7820, 7824, 8076, 8332, 8588, 8840, 8844, 8848, 7832, 7836, 7840, 8088, 8344, 8348, 8600, 8856, 7848, 7852, 7856, 8104, 8360, 8364, 8616, 8872, 8876, 8880

    

.text
.globl main

# =============================================================
# MACRO: Calculates 1D memory offset to replicate 2D (X,Y) coordinates
# Formula: Offset = ((Y * 64) + X) * 4
# =============================================================

.macro get_offset(%regY, %regX, %regOut)
    sll  %regOut, %regY, 6        
    add  %regOut, %regOut, %regX      
    sll  %regOut, %regOut, 2        
.end_macro

# ====================================
#       MAIN PROGRAM CONTROLLER
# ====================================
main:
    jal ClearGrids              # will clear the current and next grids in memory
    jal DrawMenu                # will reender the orange background and title text
    jal MenuInput               # will wait for user to press 1,2,3, or 4 to start

GameLoop:
    jal GameInput               # will check for pause/movement/drawing inputs
    jal CalculateNextGen        # will run Conway's rules on currentGrid, save to nextGrid
    jal SwapBuffer              # will love nextGrid to currentGrid, and draw pixels to screen
    jal ApplyDelay              # will pause execution briefly if slow mode is active
    j   GameLoop                # Jump unconditionally back to the top of GameLoop




# ============================================
#       ENGINE BY ENIS
# ============================================
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


# ============================================
#       GRAPHICS & DRAWING SUBROUTINES
# ============================================
DrawMenu:
    lw   $t0, displayBase
    lw   $t1, menuColor
    add  $t2, $zero, $zero     
    addi $t3, $zero, 16384
FillOrangeLoop:
    beq  $t2, $t3, DrawTitleText    
    add  $t4, $t0, $t2
    sw   $t1, 0($t4)           
    addi $t2, $t2, 4
    j    FillOrangeLoop    

DrawTitleText:
    la   $t2, titleOffsets
    addi $t3, $zero, 162            
    add  $t4, $zero, $zero          
    lw   $t6, aliveColor            
TitleLoop:
    beq  $t4, $t3, EndDrawMenu
    sll  $t5, $t4, 2                
    add  $t5, $t2, $t5              
    lw   $t8, 0($t5)                
    lw   $s4, displayBase
    add  $t9, $s4, $t8              
    sw   $t6, 0($t9)                
    addi $t4, $t4, 1
    j    TitleLoop
EndDrawMenu:
    jr   $ra                   

SwapBuffer:
    add  $t0, $zero, $zero 
    addi $t1, $zero, 16384 
    la   $t2, currentGrid
    la   $t3, nextGrid
    lw   $s4, displayBase  
    lw   $s5, aliveColor
    lw   $s6, deadColor
SwapLoop:
    beq  $t0, $t1, EndSwap     
    add  $t4, $t3, $t0          
    add  $t5, $t2, $t0          
    add  $t7, $s4, $t0          
    
    lw   $t6, 0($t4)       
    sw   $t6, 0($t5)       
    beq  $t6, $zero, DrawDead
    sw   $s5, 0($t7)       
    j    NextPixel
DrawDead:
    sw   $s6, 0($t7)       
NextPixel:
    addi $t0, $t0, 4       
    j    SwapLoop
EndSwap:
    jr   $ra                   

RenderStaticGrid:
    add  $t0, $zero, $zero
    addi $t1, $zero, 16384
    la   $t2, currentGrid
    lw   $s4, displayBase
    lw   $s5, aliveColor
    lw   $s6, deadColor
RSGLoop:
    beq  $t0, $t1, EndRSG
    add  $t5, $t2, $t0     
    add  $t7, $s4, $t0     
    lw   $t6, 0($t5)
    beq  $t6, $zero, RSGDead
    sw   $s5, 0($t7)
    j    RSGNext
RSGDead:
    sw   $s6, 0($t7)
RSGNext:
    addi $t0, $t0, 4
    j    RSGLoop
EndRSG:
    jr   $ra

DrawHologram:
    la   $t8, cursorX
    lw   $s2, 0($t8)
    la   $t9, cursorY
    lw   $s3, 0($t9)
    get_offset($s3, $s2, $t9)

    lw   $s4, displayBase
    add  $a1, $s4, $t9     
    lw   $t6, hologramColor  

    lw   $t2, selectedPattern
    addi $t3, $zero, 1
    beq  $t2, $t3, HoloDot
    addi $t3, $zero, 2
    beq  $t2, $t3, HoloGlider
    addi $t3, $zero, 3
    beq  $t2, $t3, HoloGun
    addi $t3, $zero, 4
    beq  $t2, $t3, HoloLWSS
    jr   $ra               

HoloDot:
    sw   $t6, 0($a1)
    jr   $ra
HoloGlider:
    sw   $t6, 4($a1)
    sw   $t6, 264($a1)
    sw   $t6, 512($a1)
    sw   $t6, 516($a1)
    sw   $t6, 520($a1)
    jr   $ra
HoloGun:
    la   $t2, gunOffsets
    addi $t3, $zero, 36
    add  $t4, $zero, $zero
HoloGunLoop:
    beq  $t4, $t3, EndHoloGun
    sll  $t5, $t4, 2
    add  $t5, $t2, $t5
    lw   $t8, 0($t5)
    add  $t0, $a1, $t8
    sw   $t6, 0($t0)
    addi $t4, $t4, 1
    j    HoloGunLoop
EndHoloGun:
    jr   $ra
HoloLWSS:
    la   $t2, lwssOffsets
    addi $t3, $zero, 9
    add  $t4, $zero, $zero
HoloLWSSLoop:
    beq  $t4, $t3, EndHoloLWSS
    sll  $t5, $t4, 2
    add  $t5, $t2, $t5
    lw   $t8, 0($t5)
    add  $t0, $a1, $t8
    sw   $t6, 0($t0)
    addi $t4, $t4, 1
    j    HoloLWSSLoop
EndHoloLWSS:
    jr   $ra

ApplyPattern:
    la   $t8, cursorX
    lw   $s2, 0($t8)
    la   $t9, cursorY
    lw   $s3, 0($t9)
    get_offset($s3, $s2, $t9)

    la   $t8, currentGrid
    add  $a0, $t8, $t9     

    lw   $t2, selectedPattern
    addi $t3, $zero, 1
    beq  $t2, $t3, ApplyDot
    addi $t3, $zero, 2
    beq  $t2, $t3, ApplyGlider
    addi $t3, $zero, 3
    beq  $t2, $t3, ApplyGun
    addi $t3, $zero, 4
    beq  $t2, $t3, ApplyLWSS
    jr   $ra

ApplyDot:
    sw   $a2, 0($a0)
    jr   $ra
ApplyGlider:
    sw   $a2, 4($a0)
    sw   $a2, 264($a0)
    sw   $a2, 512($a0)
    sw   $a2, 516($a0)
    sw   $a2, 520($a0)
    jr   $ra
ApplyGun:
    la   $t2, gunOffsets
    addi $t3, $zero, 36
    add  $t4, $zero, $zero
ApplyGunLoop:
    beq  $t4, $t3, EndApplyGun
    sll  $t5, $t4, 2
    add  $t5, $t2, $t5
    lw   $t8, 0($t5)
    add  $t9, $a0, $t8
    sw   $a2, 0($t9)
    addi $t4, $t4, 1
    j    ApplyGunLoop
EndApplyGun:
    jr   $ra
ApplyLWSS:
    la   $t2, lwssOffsets
    addi $t3, $zero, 9
    add  $t4, $zero, $zero
ApplyLWSSLoop:
    beq  $t4, $t3, EndApplyLWSS
    sll  $t5, $t4, 2
    add  $t5, $t2, $t5
    lw   $t8, 0($t5)
    add  $t9, $a0, $t8
    sw   $a2, 0($t9)
    addi $t4, $t4, 1
    j    ApplyLWSSLoop
EndApplyLWSS:
    jr   $ra



//bymustafa


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