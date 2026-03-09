.data
 
    	currentGrid: .space 16384   	# 64x64 pixels each 4 bytes resulting in 16384 bytes
    	nextGrid:    .space 16384	    # same idea but in order to calculate next generation we need to alter this instead of currentgrid
    	
    	menuColor:   .word 0x00FF8800  	# orange
    
    	# Screen Buffer (Where we write the actual hex colors for MARS to render)
    	displayBase: .word 0x10008000	# The exact hardware memory address where the MARS Bitmap Display starts looking for pixels
    	aliveColor:  .word 0x00FFFFFF  	# White
    	deadColor:   .word 0x00000000	# Black
	
.text
.globl main

main:

    	# need to find a way to erase the grids upon restart ineedtamaxwin
    
    	la   $t0, currentGrid	# Load the starting memory address of currentGrid into $t0 so we know where to start wiping
    	la   $t1, nextGrid	    # Load the starting memory address of nextGrid into $t1
    	add  $t2, $zero, $zero	# Set our Byte offset counter ($t2) to 0. We will use this to walk through memory.
    	addi $t3, $zero, 16384	# Set our stopping point ($t3) to 16384 bytes, which is the total size of our grid.
    
ClearLogicLoop:
    beq  $t2, $t3, DrawMenu
    add  $t4, $t0, $t2
    add  $t5, $t1, $t2
    sw   $zero, 0($t4)         # Write 0 (Dead) to Current
    sw   $zero, 0($t5)         # Write 0 (Dead) to Next
    addi $t2, $t2, 4
    j    ClearLogicLoop

DrawMenu:
    
    # Draw orange screen which is menu for now

    lw   $t0, displayBase
    lw   $t1, menuColor
    add  $t2, $zero, $zero     # Reset byte offset counter
    
FillOrangeLoop:
    beq  $t2, $t3, MenuLoop    # If 16384 bytes filled, go wait for input
    add  $t4, $t0, $t2
    sw   $t1, 0($t4)           # Draw Orange Pixel
    addi $t2, $t2, 4
    j    FillOrangeLoop    
    
MenuLoop:
    # Listening the keyboard here 
    lui  $t0, 0xFFFF           
    lw   $t1, 0($t0)           
    andi $t1, $t1, 1           
    beq  $t1, $zero, MenuLoop  # Keep waiting on the orange screen

    # Read the ASCII value here
    lw   $t2, 4($t0)           
    
    addi $t3, $zero, 49        # ASCII '1' (Glider)
    beq  $t2, $t3, LoadGlider  
    
    addi $t3, $zero, 50        # ASCII '2' (Blinker)
    beq  $t2, $t3, LoadBlinker 

    j    MenuLoop              # Ignore other keys more to be added i hope
        
LoadGlider:
    la   $t0, currentGrid
    addi $t1, $zero, 1
    # Row 1 of Glider
    sw   $t1, 524($t0)    # (x=3, y=2) -> ((2*64)+3)*4 = 524

    # Row 2 of Glider
    sw   $t1, 784($t0)    # (x=4, y=3) -> ((3*64)+4)*4 = 784

    # Row 3 of Glider
    sw   $t1, 1032($t0)   # (x=2, y=4) -> ((4*64)+2)*4 = 1032
    sw   $t1, 1036($t0)   # (x=3, y=4) -> ((4*64)+3)*4 = 1036
    sw   $t1, 1040($t0)   # (x=4, y=4) -> ((4*64)+4)*4 = 1040
    j    GameLoop              # Transition to Play State!

LoadBlinker:
    la   $t0, currentGrid
    addi $t1, $zero, 1
    # Row 1 of Blinker
    sw   $t1, 524($t0)    # (x=3, y=2) -> ((2*64)+3)*4 = 524

    # Row 2 of Blinker
    sw   $t1, 780($t0)    # (x=4, y=3) -> ((3*64)+4)*4 = 784

    # Row 3 of Blinker
    sw   $t1, 1036($t0)   # (x=3, y=4) -> ((4*64)+3)*4 = 1036
    j    GameLoop              
GameLoop:
    # keyboard checking for pause or reset
    
    lui  $t0, 0xFFFF           
    lw   $t1, 0($t0)           
    andi $t1, $t1, 1           
    beq  $t1, $zero, ResumeGen # No key pressed? Run the generation!

    lw   $t2, 4($t0)           # A key was pressed. Read the ASCII character.

    # Check for Reset ('r' = 114)
    addi $t3, $zero, 114
    beq  $t2, $t3, main        # Instantly jump to main to wipe the board!

    # Check for Pause (Spacebar = 32)
    addi $t3, $zero, 32
    bne  $t2, $t3, ResumeGen   # If it wasn't Spacebar or 'r', ignore it.

PauseLoop:
    # The game is Paused. We wait here forever until a key is pressed.
    lw   $t1, 0($t0)           
    andi $t1, $t1, 1           
    beq  $t1, $zero, PauseLoop 

    lw   $t2, 4($t0)           # Read new keypress
    
    # Check for Reset ('r') even while paused!
    addi $t3, $zero, 114
    beq  $t2, $t3, main        

    # Check for Unpause (Spacebar)
    addi $t3, $zero, 32
    bne  $t2, $t3, PauseLoop   # If not spacebar, stay paused.
ResumeGen:
    
    # GRID TRAVERSAL (y=1 to 62, x=1 to 62)
   
    addi $s0, $zero, 1     # Initialize y = 1
    
OuterLoop:
    slti $t0, $s0, 63      
    beq  $t0, $zero, SwapBuffer  
    
    addi $s1, $zero, 1     # Initialize x = 1
    
InnerLoop:
    slti $t1, $s1, 63      
    beq  $t1, $zero, NextY 

    # Calculate exact Byte Offset: ((y * 64) + x) * 4
    sll  $t9, $s0, 6       
    add  $t9, $t9, $s1     
    sll  $t9, $t9, 2       
    
    la   $t8, currentGrid
    add  $t2, $t8, $t9     # $t2 = Exact address in CURRENT Grid
    
    la   $t8, nextGrid
    add  $t6, $t8, $t9     # $t6 = Exact address in NEXT Grid

   
    # Neighboor counting 
   
    add  $t3, $zero, $zero 
    
    lw   $t4, -260($t2)    # Top-Left
    add  $t3, $t3, $t4     
    lw   $t4, -256($t2)    # Top Direct
    add  $t3, $t3, $t4
    lw   $t4, -252($t2)    # Top-Right
    add  $t3, $t3, $t4
    lw   $t4, -4($t2)      # Left
    add  $t3, $t3, $t4
    lw   $t4, 4($t2)       # Right
    add  $t3, $t3, $t4
    lw   $t4, 252($t2)     # Bottom-Left
    add  $t3, $t3, $t4
    lw   $t4, 256($t2)     # Bottom Direct
    add  $t3, $t3, $t4
    lw   $t4, 260($t2)     # Bottom-Right
    add  $t3, $t3, $t4

    
    # conway rules
    
    lw   $t5, 0($t2)       # Current state of the cell (0 or 1)
    add  $t7, $zero, $zero # Default assumption: DEAD (0)

    addi $t8, $zero, 3       
    beq  $t3, $t8, SetAlive   

    addi $t8, $zero, 2       
    beq  $t3, $t8, SetCurrent 

    j    WriteNextState       

SetAlive:
    addi $t7, $zero, 1        
    j    WriteNextState       

SetCurrent:
    add  $t7, $zero, $t5      

WriteNextState:
    sw   $t7, 0($t6)          

    
    # LOOP INCREMENTS
    
    addi $s1, $s1, 1       # x++
    j    InnerLoop         

NextY:
    addi $s0, $s0, 1       # y++
    j    OuterLoop         

    
    #swapping screens and render the current one 
   
SwapBuffer:
    add  $t0, $zero, $zero # Byte offset counter = 0
    addi $t1, $zero, 16384 # Stopping point (64 * 64 * 4)
    
    la   $t2, currentGrid
    la   $t3, nextGrid
    lw   $s4, displayBase  # Base address of the actual screen
    
    lw   $s5, aliveColor
    lw   $s6, deadColor

SwapLoop:
    beq  $t0, $t1, GameLoop     # If we reach the end, jump back up to GameLoop to simulate forever!
    
    add  $t4, $t3, $t0          # Calculate Address in Next Grid
    add  $t5, $t2, $t0          # Calculate Address in Current Grid
    add  $t7, $s4, $t0          # Calculate Address on Bitmap Display Screen
    
    lw   $t6, 0($t4)       # Read raw logic (1 or 0) from Next Grid
    sw   $t6, 0($t5)       # Save it to Current Grid
    
    # Translate logic to screen colors
    beq  $t6, $zero, DrawDead
    sw   $s5, 0($t7)       # Draw Alive (White) to the screen
    j    NextPixel
    
DrawDead:
    sw   $s6, 0($t7)       # Draw Dead (Black) to the screen

NextPixel:
    addi $t0, $t0, 4       # Move to the next pixel (+4 bytes)
    j    SwapLoop
