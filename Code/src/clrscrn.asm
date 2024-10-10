; NEEDS RECHECKING WITH COLOR COMBINATIONS
; CAN ADD 266414 COLORS 
; BUT WILL CHECK WHAT TO ADD

clear_screen:
    ; COLOR
    PUSH BP
    MOV BP, SP
    PUSH ES
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    MOV AX, 0xA000
    MOV ES, AX

    MOV AL, 0x02
    MOV DX, 0x3C4
    OUT DX, AL

    MOV AL, 0x0F
    MOV DX, 0x3C5
    OUT DX, AL

    XOR DI, DI
    XOR AX, AX
    XOR BX, BX

    ; 640 x 480 = 307,200 pixels
    ; 307,200 pixels = 38,400 bytes
    ; 38,400 bytes = 19,200 words
    MOV CX, 19200
    REP STOSW

    MOV AL, 0xF
    MOV DX, 0x3C8
    OUT DX, AL

    MOV DX, 0x3C9
    MOV AL, 63
    OUT DX, AL
    MOV AL, 63
    OUT DX, AL
    MOV AL, 63
    OUT DX, AL

    MOV AX, 0x0B00
    MOV BL, 0xF
    INT 0x10

    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    POP ES
    MOV SP, BP
    POP BP

    RET 2