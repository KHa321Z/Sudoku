printfont:
    ; [BP + 14] POS_X
    ; [BP + 12] POS_Y
    ; [BP + 10] WIDTH
    ; [BP + 08] HEIGHT
    ; [BP + 06] COLOR
    ; [BP + 04] ADDRESS
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    ; [BP - 02] PIXEL_COUNT
    ; [BP - 04] CURR_FONT_BYTE

    PUSHA

    MOV AL, [BP + 10]
    MUL byte [BP + 8]
    MOV [BP - 2], AX

    MOV SI, [BP + 4]
    MOV BL, [SI]
    MOV [BP - 4], BL

    MOV DI, 0

    MOV AH, 0x0C
    MOV AL, [BP + 6]
    MOV BX, 0
    MOV CX, [BP + 14]
    MOV DX, [BP + 12]

drawfont:
    SHL byte [BP - 4], 1
    JNC skip_pixel

    INT 0x10

skip_pixel:
    INC DI
    TEST DI, 7
    JNZ skip_load

    INC SI
    MOV BL, [SI]
    MOV [BP - 4], BL

    XOR BX, BX

skip_load:
    INC CX

    CMP DI, [BP + 10]
    JNE same_row

    MOV CX, [BP + 14]
    INC DX
    XOR DI, DI

same_row:
    DEC word [BP - 2]
    JNZ drawfont

    POPA
    
    MOV SP, BP
    POP BP

    RET 12


printNotes:
    ; [BP + 14] IND_X
    ; [BP + 12] IND_Y
    ; [BP + 10] GRID_X
    ; [BP + 08] GRID_Y
    ; [BP + 06] FILL_ARRAY
    ; [BP + 04] BOX_SIZE
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV SI, notes_values

    ; TRAVERSING COL INDICES IN NOTES
    MOV AX, 18
    MUL byte [BP + 12]
    ADD SI, AX
    ; TRAVERSING ROW INDICES IN NOTES
    MOV AX, [BP + 14]
    SHL AX, 1
    ADD SI, AX

    SUB SP, 4
    PUSH word [BP + 14]
    PUSH word [BP + 12]
    PUSH word [BP + 6]
    PUSH word [BP + 4]
    CALL traverseGrid
    POP DX
    POP CX

    ADD CX, [BP + 10]
    ADD CX, 5
    ADD DX, [BP + 8]
    ADD DX, 5
    MOV AX, [SI]
    MOV DI, smol + 8
    MOV BH, 9
    MOV BL, 3
    PUSH CX

draw_note:
    SHL AX, 1
    JNC skip_note

    PUSH CX
    PUSH DX
    PUSH word 8
    PUSH word 8
    PUSH word 0x4
    PUSH DI
    CALL printfont

skip_note:
    ADD CX, 12
    ADD DI, 8

    DEC BH
    JZ terminate_printNotes

same_note:
    DEC BL
    JNZ draw_note

    POP CX
    PUSH CX
    ADD DX, 12
    MOV BL, 3

    JMP draw_note

terminate_printNotes:
    POP CX
    POPA

    MOV SP, BP
    POP BP

    RET 12


printNumbers:
    ; [BP + 16] IND_X
    ; [BP + 14] IND_Y
    ; [BP + 12] GRID_X
    ; [BP + 10] GRID_Y
    ; [BP + 08] FILL_ARRAY
    ; [BP + 06] BOX_SIZE
    ; [BP + 04] COLOR
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV SI, grid_values
    MOV DI, big

    MOV AX, 9
    MUL byte [BP + 14]
    ADD SI, AX
    ADD SI, [BP + 16]

    SUB SP, 4
    PUSH word [BP + 16]
    PUSH word [BP + 14]
    PUSH word [BP + 8]
    PUSH word [BP + 6]
    CALL traverseGrid
    POP DX
    POP CX

    ADD CX, [BP + 12]
    ADD CX, 9
    ADD DX, [BP + 10]
    ADD DX, 5

    XOR AX, AX
    MOV AL, [SI]
    MOV BX, 96
    MUL BL
    ADD DI, AX

    PUSH CX
    PUSH DX
    PUSH word 24
    PUSH word 32
    PUSH word [BP + 4]
    PUSH DI
    CALL printfont

    POPA

    MOV SP, BP
    POP BP

    RET 14


drawCards:
    ; [BP + 18] POS_X
    ; [BP + 16] POS_Y
    ; [BP + 14] CARD_WIDTH
    ; [BP + 12] CARD_HEIGHT
    ; [BP + 10] SPACING_X
    ; [BP + 08] SPACING_Y
    ; [BP + 06] CARD_COLOR
    ; [BP + 04] NUMBER_COLOR
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV AX, 4
    MOV BX, 2
    MOV CX, [BP + 18]
    MOV DX, [BP + 16]
    MOV SI, big + 96
    MOV DI, SP

draw_card:
    PUSH CX
    PUSH DX
    PUSH word [BP + 14]
    PUSH word [BP + 12]
    PUSH word [BP + 6]
    PUSH word 1
    CALL drawRect

    PUSH CX
    PUSH DX
    PUSH word 24
    PUSH word 32
    PUSH word [BP + 4]
    PUSH SI
    ADD word [DI - 2], 8
    ADD word [DI - 4], 5
    CALL printfont

    PUSH CX
    PUSH DX
    PUSH word 8
    PUSH word 8
    PUSH word [BP + 4]
    PUSH word smol + 72
    ADD word [DI - 2], 16
    ADD word [DI - 4], 47
    CALL printfont

    ADD CX, [BP + 14]
    ADD CX, [BP + 10]
    ADD SI, 96

    DEC BX
    JNZ draw_card

    MOV BX, 2
    MOV CX, [BP + 18]
    ADD DX, [BP + 12]
    ADD DX, [BP + 8]

    DEC AX
    JNZ draw_card

    MOV AX, [BP + 14]
    ADD AX, [BP + 10]
    SHR AX, 1
    ADD CX, AX

    PUSH CX
    PUSH DX
    PUSH word [BP + 14]
    PUSH word [BP + 12]
    PUSH word [BP + 6]
    PUSH word 1
    CALL drawRect

    PUSH CX
    PUSH DX
    PUSH word 24
    PUSH word 32
    PUSH word [BP + 4]
    PUSH SI
    ADD word [DI - 2], 8
    ADD word [DI - 4], 5
    CALL printfont

    PUSH CX
    PUSH DX
    PUSH word 8
    PUSH word 8
    PUSH word [BP + 4]
    PUSH word smol + 72
    ADD word [DI - 2], 16
    ADD word [DI - 4], 47
    CALL printfont

    POPA

    MOV SP, BP
    POP BP

    RET 16