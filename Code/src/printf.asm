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
    PUSH word 0xF
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
    ; [BP + 14] IND_X
    ; [BP + 12] IND_Y
    ; [BP + 10] GRID_X
    ; [BP + 08] GRID_Y
    ; [BP + 06] FILL_ARRAY
    ; [BP + 04] BOX_SIZE
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV SI, grid_values
    MOV DI, big

    MOV AX, 9
    MUL byte [BP + 12]
    ADD SI, AX
    ADD SI, [BP + 14]

    SUB SP, 4
    PUSH word [BP + 14]
    PUSH word [BP + 12]
    PUSH word [BP + 6]
    PUSH word [BP + 4]
    CALL traverseGrid
    POP DX
    POP CX

    ADD CX, [BP + 10]
    ADD CX, 9
    ADD DX, [BP + 8]
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
    PUSH word 0x0
    PUSH DI
    CALL printfont

    POPA

    MOV SP, BP
    POP BP

    RET 12