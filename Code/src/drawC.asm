drawCircle:
    ; [BP + 12] POS_X
    ; [BP + 10] POS_Y
    ; [BP + 08] RADIUS
    ; [BP + 06] COLOR
    ; [BP + 04] FILL
    PUSH BP
    MOV BP, SP
    SUB SP, 6
    ; [BP - 02] CIRCLE_X
    ; [BP - 04] CIRCLE_Y
    ; [BP - 06] DEC_PARAM

    PUSHA

    MOV word [BP - 2], 0

    MOV AX, [BP + 8]
    NOT AX
    INC AX

    MOV [BP - 4], AX
    MOV [BP - 6], AX

    MOV AH, 0Ch
    MOV AL, [BP + 6]
    MOV BH, 0

draw_octants:
    XOR SI, SI
    XOR DI, DI

    CMP word [BP - 6], 0
    JNG addDecParam

    INC word [BP - 4]
    ADD SI, [BP - 4]

addDecParam:
    ADD SI, [BP - 2]
    SHL SI, 1
    INC SI
    ADD [BP - 6], SI

    ; (1) cx + x, cy + y
    ; (2) cx + x, cy - y
    ; (3) cx - x, cy + y
    ; (4) cx - x, cy - y
    ; (5) cx + y, cy + x
    ; (6) cx + y, cy - x
    ; (7) cx - y, cy + x
    ; (8) cx - y, cy - x

draw_arcs:
    ; (1), (5)
    MOV CX, [BP + 12]
    ADD CX, [BP - 2]
    MOV DX, [BP + 10]
    ADD DX, [BP - 4]
    INT 0x10

    CMP word [BP + 4], 0
    JE skip_fill1

    PUSH CX

skip_fill1:
    ; (3), (7)
    MOV CX, [BP + 12]
    SUB CX, [BP - 2]
    INT 0x10

    CMP word [BP + 4], 0
    JE skip_fill2

    PUSH CX
    PUSH DX
    PUSH word [BP + 6]
    CALL draw_hLine
    ; Line b/w (1, 3) & (5, 7)

skip_fill2:
    ; (4), (8)
    MOV DX, [BP + 10]
    SUB DX, [BP - 4]
    INT 0x10

    CMP word [BP + 4], 0
    JE skip_fill3

    PUSH CX

skip_fill3:
    ; (2), (6)
    MOV CX, [BP + 12]
    ADD CX, [BP - 2]
    INT 0x10

    CMP word [BP + 4], 0
    JE skip_fill4

    PUSH CX
    PUSH DX
    PUSH word [BP + 6]
    CALL draw_hLine
    ; Line b/w (2, 4) & (6, 8)

skip_fill4:
    ; INVERTING CIRCLE_X AND CIRCLE_Y FOR REUSABILITY
    MOV SI, [BP - 2]
    XCHG SI, [BP - 4]
    MOV [BP - 2], SI

    ; REUSES THE 4 ARC INSTRUCTIONS TO DRAW THE INVERTED 4 ARCS
    INC DI
    TEST DI, 2
    JZ draw_arcs

    INC word [BP - 2]
    MOV SI, [BP - 4]
    NOT SI
    INC SI

    CMP [BP - 2], SI
    JL draw_octants

    POPA

    MOV SP, BP
    POP BP

    RET 10