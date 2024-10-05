clear_screen:

    PUSH ES
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH DI

    MOV AX, 0
    MOV DX, 4

    nextplane:
    
        ADD AX, 0xA000
        MOV ES, AX

        MOV DI, 0
        ; 640 x 480 = 307,200 pixels
        ; 307,200 pixels = 38,400 bytes
        ; 38,400 bytes = 19,200 words
        MOV CX, 19200
        MOV AX, 0xFFFF
        REP STOSW

        ADD AX, 0x1000
        DEC DX
        JNZ nextplane

    POP DI
    POP DX
    POP CX
    POP AX
    POP ES

    RET