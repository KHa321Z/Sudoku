draw_vLine:
    ; POS_Y1
    ; POS_Y2
    ; POS_X
    ; COLOR
    PUSH BP
    MOV BP, SP
    PUSHA

    MOV AH, 0x0C
    MOV AL, [BP + 4]
    MOV BX, 0
    MOV CX, [BP + 6]
    MOV DX, [BP + 10]
    MOV DI, [BP + 8]

vLine:
    INT 0x10
    INC DX
    
    CMP DI, DX
    JNE vLine

    POPA
    MOV SP, BP
    POP BP

    RET 8