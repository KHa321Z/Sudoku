create_grid:
    PUSH BP
    ; POS_X
    ; POS_Y
    ; COLOR
    ; FILL_ARRAY
    ; GRID_LENGTH
    ; BOX_SIZE
    MOV BP, SP
    ; CURR_FILL
    SUB SP, 2
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