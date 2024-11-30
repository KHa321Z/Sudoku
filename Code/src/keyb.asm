oldKbISR:   dd 0
onBoard:    db 1
boardInd:   dw 0, 0

notesOn:    db 0
eraseOn:    db 0

kbISR:
    PUSHA
    PUSH DS

    PUSH CS
    POP DS

    IN AL, 0x60

    ; Escape Key
    CMP AL, 1
    JNE chk_nums

    ; Add Pause Menu

chk_nums:
    CMP AL, 10
    JA chk_up

    DEC AX
    MOV CX, AX

    MOV AX, 9
    MUL byte [boardInd + 2]
    ADD AX, [boardInd]
    MOV BX, AX

    ; Check for Already Filled Cell
    CMP byte [board + BX], 0
    JNZ nomatch

    ; Check if Notes Functionality is On
    CMP byte [notesOn], 1
    JE input_note

    ; Input Check
    CMP CL, [solved + BX]
    JE valid_input

    ; Invalid Input

    ; Increase Mistake Count
    INC word [mistake_count]
    ; Print Mistake Count
    PUSH word 0x030F
    CALL printMistakes

    ; Update Score
    MOV AX, [mistake_count]
    SUB AX, 0x30
    MOV BX, 50
    MUL BL

    SUB [score], AX
    CMP word [score], 0
    JNL skip_reset_score

    MOV word [score], 0

skip_reset_score:
    ; Print Score
    PUSH word 0x0124
    CALL printScore

    ; Change Background of Cell to Mistake Color
    PUSH word [boardInd]
    PUSH word [boardInd + 2]
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    PUSH word 0x6
    PUSH word 0x7
    CALL clearGridBox
    ; Temporarily Print the Number
    MOV [board + BX], CL

    PUSH word [boardInd]
    PUSH word [boardInd + 2]
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    PUSH word 0x4
    CALL printNumbers

    MOV byte [board + BX], 0

    ; Play Sound

    JMP nomatch

valid_input:
    ; Insert Number in Board
    MOV [board + BX], CL
    ; Decrement Empty Values
    DEC word [empty_values]
    ; Decrment Count in Card Array
    MOV BL, [board + BX]
    XOR BH, BH
    DEC BL
    DEC byte [remaining_nos + BX]
    
    ; Update Score
    MOV AX, 5
    MUL byte [score_mult]
    ADD [score], AX
    ; Reset Identifiers
    MOV word [score_mult], 10
    MOV word [score_sec], 18
    ; Print Score
    PUSH word 0x0124
    CALL printScore

    ; Update Number Cards
    PUSH word 15
    PUSH word 100
    PUSH word 40
    PUSH word 60
    PUSH word 10
    PUSH word 10
    PUSH word 0x1
    PUSH word 0xF
    CALL drawCards

    JMP highlight_next

input_note:
    ; Shifts and Turns on Notes bit using Masking
    DEC CL
    MOV AX, 0x8000

    SHR AX, CL
    SHL BX, 1
    XOR [notes + BX], AX

    ; Save Move in Undo Stack
    MOV BH, [boardInd]
    MOV BL, [boardInd + 2]
    
    PUSH BX
    PUSH AX
    CALL undoPush

    JMP highlight_next

chk_up:
    ; Up Key
    CMP AL, 0x48
    JNE chk_down

    PUSH word 0x1
    PUSH word 0x0
    CALL redrawCell

    DEC word [boardInd + 2]

    JMP highlight_next
    
chk_down:
    ; Down Key
    CMP AL, 0x50
    JNE chk_left

    PUSH word 0x1
    PUSH word 0x0
    CALL redrawCell

    INC word [boardInd + 2]

    JMP highlight_next
    
chk_left:
    ; Left Key
    CMP AL, 0x4B
    JNE chk_right

    PUSH word 0x1
    PUSH word 0x0
    CALL redrawCell

    DEC word [boardInd]

    JMP highlight_next

chk_right:
    ; Right Key
    CMP AL, 0x4D
    JNE chk_note

    PUSH word 0x1
    PUSH word 0x0
    CALL redrawCell

    INC word [boardInd]

    JMP highlight_next

chk_note:
    ; N Key
    CMP AL, 0x31
    JNE chk_erase

    ; Toggle Notes Button
    XOR byte [notesOn], 1

    JMP nomatch

chk_erase:
    ; E Key
    CMP AL, 0x12
    JNE chk_enter

    ; Toggle Erase Button
    XOR byte [eraseOn], 1

    JMP nomatch

chk_enter:
    ; Enter Key
    CMP AL, 0x1C
    JNE chk_undo

    CMP byte [eraseOn], 1
    JNE nomatch

    ; Erase Notes from Selected Cell
    MOV AX, 9
    MUL byte [boardInd + 2]
    ADD AX, [boardInd]
    MOV BX, AX
    SHL BX, 1

    ; Save Move in Undo Stack
    MOV AH, [boardInd]
    MOV AL, [boardInd + 2]

    PUSH AX
    PUSH word [notes + BX]
    CALL undoPush

    ; Erase the Current Cell
    MOV word [notes + BX], 0

    JMP highlight_next

chk_undo:
    ; Z Key
    CMP AL, 0x2C
    JNE nomatch

    SUB SP, 4
    CALL undoPop
    POP BX
    POP AX

    ; Play Error Sound
    CMP AX, -1
    JE nomatch

    PUSH word [boardInd]
    PUSH word [boardInd + 2]

    PUSH BX

    MOV BL, AH
    XOR AH, AH

    MOV [boardInd], BL
    MOV [boardInd + 2], AL

    MOV BH, 9
    MUL byte BH

    XOR BH, BH
    ADD BX, AX

    POP AX
    SHL BX, 1
    XOR [notes + BX], AX

    PUSH word 0x1
    PUSH word 0x0
    CALL redrawCell

    POP word [boardInd + 2]
    POP word [boardInd]

    ; Redraw the Current Cell in the Case Undo was done to Current Cell
    JMP highlight_next

highlight_next:
    PUSH word 0x6
    PUSH word 0x2
    CALL redrawCell

nomatch:
    POP DS
    POPA

    JMP FAR [CS:oldKbISR]

redrawCell:
    ; [BP + 06] CELL_BORDER_COLOR
    ; [BP + 04] CELL_COLOR
    PUSH BP
    MOV BP, SP

    PUSH AX
    PUSH BX

    PUSH word [boardInd]
    PUSH word [boardInd + 2]
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    PUSH word [BP + 6]
    PUSH word [BP + 4]
    CALL clearGridBox

    MOV AX, 9
    MUL byte [boardInd + 2]
    ADD AX, [boardInd]
    MOV BX, AX

    CMP byte [board + BX], 0
    JE draw_notes_instead

    PUSH word [boardInd]
    PUSH word [boardInd + 2]
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]
    PUSH word 0x4
    CALL printNumbers

    JMP terminate_redraw

draw_notes_instead:
    PUSH word [boardInd]
    PUSH word [boardInd + 2]
    PUSH word 120
    PUSH word 70
    PUSH word fill
    PUSH word [box_size]    
    CALL printNotes

terminate_redraw:
    POP BX
    POP AX

    POP BP

    RET 4

hookKb:
    PUSH AX
    PUSH ES

    XOR AX, AX
    MOV ES, AX

    MOV AX, [ES:9 * 4]
    MOV [oldKbISR], AX
    MOV AX, [ES:9 * 4 + 2]
    MOV [oldKbISR + 2], AX

    CLI
    MOV word [ES:9 * 4], kbISR
    MOV word [ES:9 * 4 + 2], CS
    STI

    POP ES
    POP AX

    RET

unhookKb:
    PUSH AX
    PUSH ES

    XOR AX, AX
    MOV ES, AX

    STI
    MOV AX, [oldKbISR]
    MOV [ES:8 * 4], AX
    MOV AX, [oldKbISR + 2]
    MOV [ES:8 * 4 + 2], AX
    CLI

    POP ES
    POP AX

    RET