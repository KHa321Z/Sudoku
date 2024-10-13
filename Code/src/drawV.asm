draw_vLine:
    ; [BP + 10] POS_Y1
    ; [BP + 08] POS_Y2
    ; [BP + 06] POS_X
    ; [BP + 04] COLOR
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV AH, 0x0C
    MOV AL, [BP + 4]
    MOV BX, 0
    MOV CX, [BP + 6]
    MOV DX, [BP + 10]
    MOV DI, [BP + 8]

    ; STORING SMALLER POS_Y IN DX
    ; STORING GREATER POS_Y IN DI
    CMP DX, DI
    JL vLine
    XCHG DX, DI

vLine:
    INT 0x10
    INC DX
    
    CMP DX, DI
    JLE vLine

    POPA
    
    MOV SP, BP
    POP BP

    RET 8