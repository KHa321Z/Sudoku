drawRect:
    ; [BP + 14] POS_X
    ; [BP + 12] POS_Y
    ; [BP + 10] WIDTH
    ; [BP + 08] HEIGHT
    ; [BP + 06] COLOR
    ; [BP + 04] FILL
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV CX, [BP + 14]
    ADD CX, [BP + 10]
    MOV DX, [BP + 12]
    ADD DX, [BP + 08]

    PUSH word [BP + 14]
    PUSH CX
    PUSH word [BP + 12]
    PUSH word [BP + 6]
    CALL draw_hLine

    PUSH word [BP + 12]
    PUSH DX
    PUSH word [BP + 14]
    PUSH word [BP + 6]
    CALL draw_vLine

    DEC DX

    PUSH word [BP + 14]
    PUSH CX
    PUSH DX
    PUSH word [BP + 6]
    CALL draw_hLine

    DEC CX
    INC DX

    PUSH word [BP + 12]
    PUSH DX
    PUSH CX
    PUSH word [BP + 6]
    CALL draw_vLine

    CMP word [BP + 4], 1
    JNE skip_fill_rect

    MOV AX, [BP + 12]

fill_rect:
    PUSH word [BP + 14]
    PUSH CX
    PUSH AX
    PUSH word [BP + 6]
    CALL draw_hLine

    INC AX
    CMP AX, DX
    JL fill_rect

skip_fill_rect:
    POPA

    MOV SP, BP
    POP BP

    RET 12