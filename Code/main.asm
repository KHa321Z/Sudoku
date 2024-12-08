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
%include "Code/src/image.asm"

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

    CALL loadingscreen

    CALL gamescreen

    CALL endingscreen
    
    JMP start

end_game:
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

difficulties:   db 40, 35, 30
difficulty:     dw 0
easy_s:         db 'Easy'
medium_s:       db 'Medium'
hard_s:         db 'Hard'
all_modes:      dw easy_s, medium_s, hard_s
all_mode_size:  dw 4, 6, 4
gamemode:       db 'Mode:'
mode:           dw 0
mode_size:      dw 0

time:           dd 0
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

game_palette:   db 62, 54, 46               ; 0x0 Background
                db 58, 35, 09               ; 0x1 Grid Border
                db 59, 47, 35               ; 0x2 Highlighted Grid Boxes
                db 63, 55, 47               ; 0x3 Not Filled Grid Boxes
                db 47, 26, 00               ; 0x4 Pre Filled Numbers
                db 63, 28, 00               ; 0x5 Custom Filled Numbers
                db 63, 00, 00               ; 0x6 Highlighted Grid Boxes Border
                db 59, 37, 37               ; 0x7 Mistake Grid Box Background
game_pal_size:  dw $ - game_palette

screen_img:     db "Code/assets/menu.bmp", 0
img_handle:     dw -1, -1, -1

; Send Palette Data to DAC
setPalette:
    ; [BP + 06] PALETTE
    ; [BP + 04] PALETTE_SIZE
    PUSH BP
    MOV BP, SP

    PUSHA

    ; DAC Pallete Write Port
    MOV DX, 0x3C8
    ; Pallete Color Index 0
    XOR AL, AL
    OUT DX, AL

    MOV SI, [BP + 6]
    MOV CX, [BP + 4]
    ; DAC Port for RGB Values
    MOV DX, 0x3C9

palette_loop:
    MOV AL, [SI]
    OUT DX, AL
    
    INC SI
    LOOP palette_loop

    POPA

    POP BP

    RET 4

btn_pos:        dw 168, 220, 272, 360
point_colors:   dw 0x3, 0xF

startscreen:

    PUSHA

    openbitmap screen_img, img_handle
    drawimage img_handle, 0, 0, 640, 480, 0, 0, 0, CX
    closebitmap img_handle

    MOV SI, 0

main_nav:
    MOV BX, 0
    CMP SI, 3
    JNE chk_main_key

    XOR BX, 2

chk_main_key:
    ; Draw Pointer
    SHL SI, 1
    PUSH word 65
    PUSH word [btn_pos + SI]
    PUSH word 32
    PUSH word 32
    PUSH word [point_colors + BX]
    PUSH word pointer
    CALL printfont
    SHR SI, 1

    XOR BX, 2

    MOV AX, 0
    INT 0x16

    ; up
    CMP AH, 0x48
    JNE chk_main_down

    ; Clear Pointer
    SHL SI, 1
    PUSH word 65
    PUSH word [btn_pos + SI]
    PUSH word 32
    PUSH word 32
    PUSH word [point_colors + BX]
    PUSH word pointer
    CALL printfont
    SHR SI, 1

    DEC SI
    AND SI, 3

    JMP main_nav

chk_main_down:
    ; down
    CMP AH, 0x50
    JNE chk_main_enter

    ; Clear Pointer
    SHL SI, 1
    PUSH word 65
    PUSH word [btn_pos + SI]
    PUSH word 32
    PUSH word 32
    PUSH word [point_colors + BX]
    PUSH word pointer
    CALL printfont
    SHR SI, 1

    INC SI
    AND SI, 3

    JMP main_nav

chk_main_enter:
    ; Play Button Sound
    CALL buttonSound

    ; Enter Key
    CMP AH, 0x1C
    JNE main_nav

    CMP SI, 3
    JE end_game

    XOR BH, BH
    MOV BL, [difficulties + SI]
    MOV [difficulty], BX

    SHL SI, 1
    MOV BX, [all_modes + SI]
    MOV [mode], BX
    MOV BX, [all_mode_size + SI]
    MOV [mode_size], BX
    SHR SI, 1

    POPA

    RET

; Multitask with Loading Screen
loadingscreen:

    PUSHA
    PUSH ES

    ; ; Set Task for Loading Animation
    ; CALL setLoadingTask

    ; PUSH word loadTimer
    ; CALL hookTimer

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

    ; ; Board Generation Complete
    ; CALL unhookTimer

    POP ES
    POPA

    RET

gamescreen:

    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    MOV AX, 0x0012
    INT 0x10

    PUSH word game_palette
    PUSH word [game_pal_size]
    CALL setPalette

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
    PUSH word 0x4
    CALL printScore

    ; Print Mistakes
    PUSH word 0x030F
    CALL printMistakes

    ; Print Game Mode
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, [mode_size]
    MOV DX, 0x0326

    CMP CX, 6
    JNE adjust_mode_length
    DEC DX

adjust_mode_length:
    MOV BP, [mode]
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


congrats:       db 'Congratulations!'
cong_size:      dw cong_size - congrats
lose:           db 'You Lose'
lose_size:      dw lose_size - lose
quit:           db 'Quit Game', 0
newgame:        db 'Main Menu', 0

btn_pos_end:    dw 216, 344
btn_str_end:    dw newgame, quit

drawEndingBtns:
    ; [BP + 10] POS_X
    ; [BP + 8] POS_Y
    ; [BP + 6] STRING
    ; [BP + 4] HIGHLIGHT
    PUSH BP
    MOV BP, SP

    PUSH AX

    MOV AX, 0x04
    CMP word [BP + 4], 1
    JNE not_highlight

    MOV AX, 0x0F

not_highlight:
    PUSH word [BP + 10]
    PUSH word [BP + 8]
    PUSH word 87
    PUSH word 26
    PUSH word 0x0
    PUSH word 0x1
    CALL drawRect

    PUSH word [BP + 10]
    PUSH word [BP + 8]
    PUSH word 87
    PUSH word 26
    PUSH word 0x1
    PUSH word 0x0
    CALL drawRect

    INC word [BP + 10]
    INC word [BP + 8]

    PUSH word [BP + 10]
    PUSH word [BP + 8]
    PUSH word 85
    PUSH word 24
    PUSH word 0x1
    PUSH word [BP + 4]
    CALL drawRect

    ; (8, 5) Offset from Button
    ADD word [BP + 10], 7
    ADD word [BP + 8], 4

    PUSH word [BP + 10]
    PUSH word [BP + 8]
    PUSH word [BP + 6]
    PUSH AX
    CALL printString

    POP AX

    POP BP

    RET 8

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
    PUSH word 0x4
    PUSH word 0x0
    CALL drawRect

    PUSH word 159
    PUSH word 119
    PUSH word 322
    PUSH word 242
    PUSH word 0x4
    PUSH word 0x0
    CALL drawRect

    MOV CX, [cong_size]
    MOV DX, 0x0A20
    MOV BP, congrats

    CMP word [mistake_count], 0x33
    JNE print_congrats
    
    MOV CX, [lose_size]
    MOV DX, 0x0A24
    MOV BP, lose

print_congrats:
    MOV AX, 0x1300
    MOV BX, 0x0004
    INT 0x10

    PUSH word 0x0D18
    PUSH word 0x1
    CALL printScore
    
    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, [time_size]
    MOV DX, 0x0D2C
    MOV BP, timestr
    INT 0x10

    PUSH word 0x0D32
    CALL printTimer
    
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
    MOV BP, [mode]
    INT 0x10

    PUSH word 0x0F2C
    CALL printMistakes

    PUSH word [btn_pos_end]
    PUSH word 300
    PUSH word [btn_str_end]
    PUSH word 0x1
    CALL drawEndingBtns

    PUSH word [btn_pos_end + 2]
    PUSH word 300
    PUSH word [btn_str_end + 2]
    PUSH word 0x0
    CALL drawEndingBtns

    MOV SI, 0

end_nav:
    MOV AX, 0
    INT 0x16

    ; right key
    CMP AH, 0x4D
    JE change_btn
    ; left key
    CMP AH, 0x4B
    JE change_btn
    ; Enter Key
    CMP AH, 0x1C
    JE end_enter

    JMP end_nav

change_btn:
    SHL SI, 1
    PUSH word [btn_pos_end + SI]
    PUSH word 300
    PUSH word [btn_str_end + SI]
    PUSH word 0
    CALL drawEndingBtns
    SHR SI, 1

    XOR SI, 1

    SHL SI, 1
    PUSH word [btn_pos_end + SI]
    PUSH word 300
    PUSH word [btn_str_end + SI]
    PUSH word 0x1
    CALL drawEndingBtns
    SHR SI, 1

    JMP end_nav

end_enter:
    CMP SI, 1
    JE end_game

    MOV AX, 0
    MOV CX, 326
    MOV DI, solved

    REP STOSB

    MOV AL, 9
    MOV CX, 9

    REP STOSB

    MOV word [empty_values], 0
    MOV word [score], 0
    MOV word [mistake_count], 0x30
    MOV word [time], 0
    MOV word [time + 2], 0
    MOV word [boardInd], 0
    MOV word [boardInd + 2], 0
    MOV byte [notesOn], 0
    MOV byte [eraseOn], 0
    MOV word [undoTop], undoTop
    MOV word [tick], 0

    POP ES
    POPA

    RET