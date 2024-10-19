create_grid:
    ; [BP + 14] POS_X
    ; [BP + 12] POS_Y
    ; [BP + 10] COLOR
    ; [BP + 08] FILL_ARRAY
    ; [BP + 06] GRID_LENGTH
    ; [BP + 04] BOX_SIZE
    PUSH BP
    MOV BP, SP
    SUB SP, 2
    ; [BP - 2] CURR_FILL

    PUSHA

    MOV CX, 0
    MOV DX, [BP + 6]
    MOV SI, 0

    MOV BX, [BP + 8]
    PUSH word [BX + SI]
    POP word [BP - 2]

fill_loop:
    ; POS_X1
    MOV BX, [BP + 14]
    PUSH BX
    ; POS_X2
    ADD BX, DX
    PUSH BX
    ; POS_Y
    MOV BX, [BP + 12]
    ADD BX, CX
    PUSH BX
    ; COLOR
    PUSH word [BP + 10]
    CALL draw_hLine

    ; POS_Y1
    MOV BX, [BP + 12]
    PUSH BX
    ; POS_Y2
    ADD BX, DX
    PUSH BX
    ; POS_X
    MOV BX, [BP + 14]
    ADD BX, CX
    PUSH BX
    ; COLOR
    PUSH word [BP + 10]
    CALL draw_vLine

    INC CX
    DEC word [BP - 2]
    JNZ fill_loop

    ADD CX, [BP + 4]
    ADD SI, 2
    MOV BX, [BP + 8]
    PUSH word [BX + SI]
    POP word [BP - 2]

    CMP SI, 20
    JNZ fill_loop

    POPA
    
    MOV SP, BP
    POP BP

    RET 12


traverseGrid:
    ; [BP + 14] POS_X (RETURN)
    ; [BP + 12] POS_Y (RETURN)
    ; [BP + 10] IND_X
    ; [BP + 08] IND_Y
    ; [BP + 06] FILL_ARRAY
    ; [BP + 04] BOX_SIZE
    PUSH BP
    MOV BP, SP

    PUSH CX
    PUSH DX
    PUSH SI

    MOV SI, [BP + 6]
    MOV CX, [SI]
    MOV DX, [SI]
    ADD SI, 2

traverse_rows:
    CMP word [BP + 10], 0
    JZ set_cols

    ADD CX, [BP + 4]
    ADD CX, [SI]
    ADD SI, 2
    DEC word [BP + 10]

    JMP traverse_rows

set_cols:
    MOV SI, [BP + 6]
    ADD SI, 2

traverse_cols:
    CMP word [BP + 8], 0
    JZ set_rows_cols

    ADD DX, [BP + 4]
    ADD DX, [SI]
    ADD SI, 2
    DEC word [BP + 8]

    JMP traverse_cols

set_rows_cols:
    MOV [BP + 14], CX
    MOV [BP + 12], DX

    POP SI
    POP DX
    POP CX

    MOV SP, BP
    POP BP

    RET 8

clearGridBox:
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

    SUB SP, 4
    PUSH word [BP + 16]
    PUSH word [BP + 14]
    PUSH word [BP + 8]
    PUSH word [BP + 6]
    CALL traverseGrid
    POP DX
    POP CX

    MOV SI, [BP + 8]
    ADD CX, [BP + 12]
    ADD DX, [BP + 10]

    MOV SI, CX
    ADD SI, [BP + 6]
    MOV DI, DX
    ADD DI, [BP + 6]
    PUSH CX

    MOV AH, 0x0C
    MOV AL, [BP + 4]
    MOV BX, 0

clear_box:
    INT 0x10

    INC CX
    CMP CX, SI
    JL clear_box

    POP CX
    PUSH CX
    INC DX

    CMP DX, DI
    JL clear_box

    POP CX
    POPA

    MOV SP, BP
    POP BP

    RET 14