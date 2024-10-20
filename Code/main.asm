[org 0x0100]

    JMP start

%include "Code/assets/font.asm"
%include "Code/assets/btns.asm"
%include "Code/src/clrscrn.asm"
%include "Code/src/drawH.asm"
%include "Code/src/drawV.asm"
%include "Code/src/drawC.asm"
%include "Code/src/drawR.asm"
%include "Code/src/gengrid.asm"
%include "Code/src/printf.asm"
%include "Code/src/timer.asm"

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

grid_values:    times 9 * 9 db 0
notes_values:   times 9 * 9 dw 0xFFFF

score:          db 'Score:'
score_size:     dw score_size - score
mistakes:       db 'Mistakes: 0/3'
m_size:         dw m_size - mistakes
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

startscreen:

    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    MOV AL, 0x0
    MOV DX, 0x3C8
    OUT DX, AL

    MOV DX, 0x3C9

    ; BG
    MOV AL, 62
    OUT DX, AL
    MOV AL, 54
    OUT DX, AL
    MOV AL, 46
    OUT DX, AL

    ; GRID_BORDER
    MOV AL, 58
    OUT DX, AL
    MOV AL, 35
    OUT DX, AL
    MOV AL, 9
    OUT DX, AL

    ; FILLED_GRID_BOXES
    MOV AL, 59
    OUT DX, AL
    MOV AL, 47
    OUT DX, AL
    MOV AL, 35
    OUT DX, AL

    ; NOT_FILLED_GRID_BOXES
    MOV AL, 63
    OUT DX, AL
    MOV AL, 58
    OUT DX, AL
    MOV AL, 50
    OUT DX, AL

    ; NUMBERS
    MOV AL, 63
    OUT DX, AL
    MOV AL, 28
    OUT DX, AL
    MOV AL, 0
    OUT DX, AL

    POP ES
    POPA

    RET

gamescreen:

    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    CALL hookTimer

    ; Make Grid
    PUSH word 120
    PUSH word 70
    PUSH word 0x1
    PUSH word fill
    PUSH word [grid_length]
    PUSH word [box_size]
    CALL create_grid

    ; Print Score
    MOV AX, 0x1301
    MOV BX, 0x0004
    MOV CX, [score_size]
    MOV DX, 0x0124
    MOV BP, score
    INT 0x10

    MOV AX, 0x0E20
    MOV BX, 0x0004
    INT 0x10
    MOV AX, 0x0E30
    MOV BX, 0x0004
    INT 0x10

    ; Print Mistakes
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, [m_size]
    MOV DX, 0x030F
    MOV BP, mistakes
    INT 0x10

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
    PUSH word 180
    PUSH word 20
    PUSH word 0x1
    PUSH word 0x1
    CALL drawCircle
    
    PUSH word 569
    PUSH word 168
    PUSH word 24
    PUSH word 24
    PUSH word 0xF
    PUSH word pencil_btn
    CALL printfont

    ; Print Erase Button
    PUSH word 580
    PUSH word 240
    PUSH word 20
    PUSH word 0x1
    PUSH word 0x1
    CALL drawCircle
    
    PUSH word 568
    PUSH word 228
    PUSH word 24
    PUSH word 24
    PUSH word 0xF
    PUSH word eraser_btn
    CALL printfont

    ; Print Undo Button
    PUSH word 580
    PUSH word 300
    PUSH word 20
    PUSH word 0x1
    PUSH word 0x1
    CALL drawCircle
    
    PUSH word 568
    PUSH word 288
    PUSH word 24
    PUSH word 24
    PUSH word 0xF
    PUSH word undo_btn
    CALL printfont

    ; Print Hint Button
    ; PUSH word 580
    ; PUSH word 360
    ; PUSH word 20
    ; PUSH word 0x8
    ; PUSH word 0x1
    ; CALL drawCircle

    ; PUSH word 0
    ; PUSH word 0
    ; PUSH word 120
    ; PUSH word 70
    ; PUSH word fill
    ; PUSH word [box_size]
    ; PUSH word 0x7
    ; CALL clearGridBox

    PUSH word 1
    PUSH word 7
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    CALL printNotes

    PUSH word 3
    PUSH word 1
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    CALL printNotes

    PUSH word 8
    PUSH word 4
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    CALL printNotes

    PUSH word 5
    PUSH word 8
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    CALL printNotes

    PUSH word 2
    PUSH word 4
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    CALL printNotes

    PUSH word 6
    PUSH word 0
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    CALL printNotes

    MOV BX, 0
    MOV byte [grid_values], 1
    MOV byte [grid_values + 10], 2
    MOV byte [grid_values + 20], 3
    MOV byte [grid_values + 30], 4
    MOV byte [grid_values + 40], 5
    MOV byte [grid_values + 50], 6
    MOV byte [grid_values + 60], 7
    MOV byte [grid_values + 70], 8
    MOV byte [grid_values + 80], 9

fill_fazool_numbers:
    PUSH word BX
    PUSH word BX
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    PUSH word 0x2
    CALL clearGridBox

    PUSH BX
    PUSH BX
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    PUSH word 0x4
    CALL printNumbers

    INC BX
    CMP BX, 9
    JNE fill_fazool_numbers

    PUSH word 15
    PUSH word 100
    PUSH word 40
    PUSH word 60
    PUSH word 10
    PUSH word 10
    PUSH word 0x1
    PUSH word 0xF
    call drawCards

    MOV AX, 0
    INT 0x16

    CALL unhookTimer

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
    MOV BP, score
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

    POP ES
    POPA

    RET