printfont:
    PUSH BP
    ; POS_X
    ; POS_Y
    ; WIDTH
    ; HEIGHT
    ; COLOR
    ; ADDRESS
    MOV BP, SP
    ; PIXEL_COUNT
    ; CURR_FONT_BYTE
    SUB SP, 4
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
    POP BP
    MOV SP, BP

    RET 12