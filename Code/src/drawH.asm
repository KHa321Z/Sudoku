draw_hLine:
    ; [BP + 10] POS_X1
    ; [BP + 08] POS_X2
    ; [BP + 06] POS_Y
    ; [BP + 04] COLOR
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV AH, 0x0C
    MOV AL, [BP + 4]
    MOV BX, 0
    MOV CX, [BP + 10]
    MOV DX, [BP + 6]
    MOV DI, [BP + 8]

    ; STORING SMALLER POS_X IN CX
    ; STORING GREATER POS_X IN DI
    CMP CX, DI
    JL hLine
    XCHG CX, DI

hLine:
    INT 0x10
    INC CX
    
    CMP CX, DI
    JLE hLine

    POPA
    
    MOV SP, BP
    POP BP

    RET 8