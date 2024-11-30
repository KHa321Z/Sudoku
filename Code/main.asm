[org 0x0100]

    JMP start

%include "Code/assets/font.asm"
%include "Code/assets/btns.asm"
%include "Code/assets/sound.asm"
%include "Code/src/clrscrn.asm"
%include "Code/src/rand.asm"
%include "Code/src/drawH.asm"
%include "Code/src/drawV.asm"
%include "Code/src/drawC.asm"
%include "Code/src/drawR.asm"
%include "Code/src/gengrid.asm"
%include "Code/src/printf.asm"
%include "Code/src/timer.asm"
%include "Code/src/keyb.asm"
%include "Code/src/boardgen.asm"
%include "Code/src/load.asm"
%include "Code/src/undo.asm"

; MAIN SCREEN
title:  db 'SUDOKU'
cols:   dw 640
rows:   dw 480

start:

    ; 640x480 video mode
    MOV AX, 0x0012
    INT 0x10

    ; Turn off Blinking Attribute
    ; To Access all 16 colors
    ; Doesn't Work for Emulators
    MOV AX, 0x1003
    MOV BX, 0
    INT 0x10

    CALL startscreen
    ; MOV AX, 0
    ; INT 0x16

    CALL loadingscreen

    CALL gamescreen
    MOV AX, 0
    INT 0x16

    CALL endingscreen
    MOV AX, 0
    INT 0x16

    ; Reverting back to 80x25 mode
    MOV AX, 0x0003
    INT 0x10

    ; Terminating Program
    MOV AX, 0x4C00
    INT 0x21


box_size:       dw 42
grid_length:    dw 400
fill:           dw 5, 1, 1, 3, 1, 1, 3, 1, 1, 5

solved:         times 41 dw 0
board:          times 41 dw 0
notes:          times 9 * 9 dw 0
remaining_nos:  times 9 db 9
empty_values:   dw 0

score_mult:     dw 10
score_sec:      dw 18
score:          dw 0
score_text:     db 'Score:'
score_size:     dw score_size - score_text

mistake_count:  dw 0x30
mistakes:       db 'Mistakes: '
m_size:         dw m_size - mistakes

difficulty:     dw 0
gamemode:       db 'Mode:'
mode:           db 'Easy'
mode_size:      dw mode_size - mode

timestr:        db 'Time:'
time_size:      dw time_size - timestr
empty_timer:    db '00:00'

undo:           db 'UNDO'
undo_size:      dw undo_size - undo
erase:          db 'ERASE'
erase_size:     dw erase_size - erase
edit:           db 'EDIT'
edit_size:      db edit_size - edit
hint:           db 'HINT'
hint_size:      db hint_size - hint

palette_data:   db 62, 54, 46               ; 0x0 Background
                db 58, 35, 09               ; 0x1 Grid Border
                db 59, 47, 35               ; 0x2 Highlighted Grid Boxes
                db 63, 55, 47               ; 0x3 Not Filled Grid Boxes
                db 47, 26, 00               ; 0x4 Pre Filled Numbers
                db 63, 28, 00               ; 0x5 Custom Filled Numbers
                db 63, 00, 00               ; 0x6 Highlighted Grid Boxes Border
                db 59, 37, 37               ; 0x7 Mistake Grid Box Background
palette_size:   dw $ - palette_data

; Send Palette Data to DAC
setPalette:
    PUSHA

    ; DAC Pallete Write Port
    MOV DX, 0x3C8
    ; Pallete Color Index 0
    XOR AL, AL
    OUT DX, AL

    MOV SI, palette_data
    MOV CX, [palette_size]
    ; DAC Port for RGB Values
    MOV DX, 0x3C9

palette_loop:
    MOV AL, [SI]
    OUT DX, AL
    
    INC SI
    LOOP palette_loop

    POPA

    RET

startscreen:

    PUSHA

    CALL setPalette

    POPA

    RET

; Multitask with Loading Screen
loadingscreen:

    PUSHA
    PUSH ES

    ; Set Task for Loading Animation
    CALL setLoadingTask

    PUSH word loadTimer
    CALL hookTimer

    ; Background Task of Board Generation
    PUSH word solved
    CALL fillDiagonalSubGrids

    PUSH word 0
    PUSH word 1
    PUSH word solved
    PUSH word 0
    CALL checkSolutions
    POP BX

    PUSH DS
    POP ES

    ; Use this when selecting levels
    MOV word [difficulty], 60

generate_new_board:
    MOV CX, 41
    MOV SI, solved
    MOV DI, board

    REP MOVSW

    MOV CX, 81
    SUB CX, [difficulty]

    ; Add Difficulties
    PUSH word board
    PUSH word CX
    CALL removeValues
    ; Change this to help in Winning Condition
    MOV word [empty_values], CX

    PUSH word 0
    PUSH word 2
    PUSH word board
    PUSH word 0
    CALL checkSolutions
    POP BX

    CMP BX, 2
    JE generate_new_board

    ; Board Generation Complete
    CALL unhookTimer

    POP ES
    POPA

    RET

gamescreen:

    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    PUSH word timerISR
    CALL hookTimer
    CALL hookKb

    ; Changes Background of Grid
    ; PUSH word 120
    ; PUSH word 70
    ; PUSH word [grid_length]
    ; PUSH word [grid_length]
    ; PUSH word 0x3
    ; CALL clearBg

    ; Draw Grid
    PUSH word 120
    PUSH word 70
    PUSH word 0x1
    PUSH word fill
    PUSH word [grid_length]
    PUSH word [box_size]
    CALL create_grid

    ; Print Score
    PUSH word 0x0124
    CALL printScore

    ; Print Mistakes
    PUSH word 0x030F
    CALL printMistakes

    ; Print Game Mode
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, [mode_size]
    MOV DX, 0x0326
    MOV BP, mode
    INT 0x10

    ; Print Empty Timer
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, 5
    MOV DX, 0x033C
    MOV BP, empty_timer
    INT 0x10

    ; Print Notes Button
    PUSH word 580
    PUSH word 200
    PUSH word 19
    PUSH word 0x1
    PUSH word 0
    CALL drawCircle
    PUSH word 580
    PUSH word 200
    PUSH word 20
    PUSH word 0x1
    PUSH word 0
    CALL drawCircle
    
    PUSH word 569
    PUSH word 188
    PUSH word 24
    PUSH word 24
    PUSH word 0x1
    PUSH word pencil_btn
    CALL printfont

    ; Print Erase Button
    PUSH word 580
    PUSH word 270
    PUSH word 19
    PUSH word 0x1
    PUSH word 0
    CALL drawCircle
    PUSH word 580
    PUSH word 270
    PUSH word 20
    PUSH word 0x1
    PUSH word 0
    CALL drawCircle
    
    PUSH word 568
    PUSH word 258
    PUSH word 24
    PUSH word 24
    PUSH word 0x1
    PUSH word eraser_btn
    CALL printfont

    ; Print Undo Button
    PUSH word 580
    PUSH word 340
    PUSH word 20
    PUSH word 0x1
    PUSH word 0x1
    CALL drawCircle
    
    PUSH word 568
    PUSH word 328
    PUSH word 24
    PUSH word 24
    PUSH word 0xF
    PUSH word undo_btn
    CALL printfont

    ; Print Pre-filled Numbers in Grid
    MOV BX, 0
    MOV DX, 0

fill_all_numbers:
    MOV AX, 9
    MUL DL
    ADD AX, BX
    MOV SI, AX

    CMP byte [board + SI], 0
    JZ skip_number

    ; Reduce Number Card values
    MOV DI, [board + SI]
    AND DI, 0xFF
    DEC DI
    DEC byte [remaining_nos + DI]

    PUSH word BX
    PUSH word DX
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    PUSH word 0x4
    CALL printNumbers

skip_number:
    INC BX
    CMP BX, 9
    JNE next_dabba

    XOR BX, BX
    INC DX

next_dabba:
    CMP DX, 9
    JNE fill_all_numbers

    PUSH word 15
    PUSH word 100
    PUSH word 40
    PUSH word 60
    PUSH word 10
    PUSH word 10
    PUSH word 0x1
    PUSH word 0xF
    call drawCards

    PUSH word 0x6
    PUSH word 0x2
    CALL redrawCell

game_loop:
    CMP word [empty_values], 0
    JE game_loop_end

    CMP word [mistake_count], 0x33
    JE game_loop_end

    JMP game_loop

game_loop_end:

    CALL unhookTimer
    CALL unhookKb

    POP ES
    POPA

    RET


congrats:   db 'Congratulations!'
cong_size:  dw cong_size - congrats
quit:       db 'Quit Game'
quit_size:  dw quit_size - quit
newgame:    db 'New Game'
new_size:   dw new_size - newgame


endingscreen:
    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    PUSH word 160
    PUSH word 120
    PUSH word 320
    PUSH word 240
    PUSH word 0x0
    PUSH word 0x1
    CALL drawRect

    PUSH word 160
    PUSH word 120
    PUSH word 320
    PUSH word 240
    PUSH word 0x1
    PUSH word 0x0
    CALL drawRect

    PUSH word 159
    PUSH word 119
    PUSH word 322
    PUSH word 242
    PUSH word 0x1
    PUSH word 0x0
    CALL drawRect
    
    MOV AX, 0x1300
    MOV BX, 0x0004
    MOV CX, [cong_size]
    MOV DX, 0x0A20
    MOV BP, congrats
    INT 0x10
    
    MOV AX, 0x1301
    MOV BX, 0x0001
    MOV CX, [score_size]
    MOV DX, 0x0D18
    MOV BP, score_text
    INT 0x10

    MOV AX, 0x0E20
    MOV BX, 0x0001
    INT 0x10
    MOV AX, 0x0E30
    MOV BX, 0x0001
    INT 0x10
    
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, [time_size]
    MOV DX, 0x0D2C
    MOV BP, timestr
    INT 0x10
    
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, 5
    MOV DX, 0x0D32
    MOV BP, empty_timer
    INT 0x10
    
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, 5
    MOV DX, 0x0F18
    MOV BP, gamemode
    INT 0x10
    
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, [mode_size]
    MOV DX, 0x0F1E
    MOV BP, mode
    INT 0x10

    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, [m_size]
    MOV DX, 0x0F2C
    MOV BP, mistakes
    INT 0x10

    MOV AX, 0x1300
    MOV BX, 0x0004
    MOV CX, [new_size]
    MOV DX, 0x131C
    MOV BP, newgame
    INT 0x10

    PUSH word 219
    PUSH word 300
    PUSH word 72
    PUSH word 24
    PUSH word 0x1
    PUSH word 0x0
    CALL drawRect

    MOV AX, 0x1300
    MOV BX, 0x0004
    MOV CX, [quit_size]
    MOV DX, 0x132C
    MOV BP, quit
    INT 0x10

    PUSH word 348
    PUSH word 300
    PUSH word 80
    PUSH word 24
    PUSH word 0x1
    PUSH word 0x0
    CALL drawRect

    JMP $

    POP ES
    POPA

    RET