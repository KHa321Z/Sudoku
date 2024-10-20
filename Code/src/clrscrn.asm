; NEEDS RECHECKING WITH COLOR COMBINATIONS
; CAN ADD 266414 COLORS 
; BUT WILL CHECK WHAT TO ADD

clear_screen:
    ; [BP + 4] COLOR
    PUSH BP
    MOV BP, SP

    PUSHA
    PUSH ES

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

    POP ES
    POPA

    MOV SP, BP
    POP BP

    RET