; IND_X | IND_Y | NOTES_H | NOTES_L
undoStack:  times 10 dd 0
undoTop:    dw $

undoPush:
    ; [BP + 06] BOARD_INDEX
    ; [BP + 04] NOTES
    PUSH BP
    MOV BP, SP

    PUSH ES
    PUSH AX
    PUSH BX

    MOV BX, [undoTop]

    CMP BX, undoStack
    JNE not_full

    PUSH DS
    POP ES

    MOV CX, 5 * 2
    MOV SI, undoStack
    MOV DI, undoStack + 5 * 4

    REP MOVSW

    MOV BX, SI

not_full:
    SUB BX, 4

    MOV AX, [BP + 6]
    MOV [BX], AX
    MOV AX, [BP + 4]
    MOV [BX + 2], AX

    MOV [undoTop], BX

    POP BX
    POP AX
    POP ES

    POP BP

    RET 4

undoPop:
    ; [BP + 06] BOARD_INDEX (RETURN)
    ; [BP + 04] NOTES (RETURN)
    PUSH BP
    MOV BP, SP

    PUSH AX
    PUSH BX

    MOV word [BP + 6], -1
    MOV word [BP + 4], -1
    MOV BX, [undoTop]

    CMP BX, undoTop
    JE empty_stack

    MOV AX, [BX]
    MOV [BP + 6], AX
    MOV AX, [BX + 2]
    MOV [BP + 4], AX

    ADD word [undoTop], 4

empty_stack:
    POP BX
    POP AX

    POP BP

    RET