oldTimerISR:    dd 0
time:           dd 0
tick:           dw 0

printTimer:
    PUSHA

    MOV AX, [CS:time]
    MOV BX, 10
    MOV CX, 0

nextdigit:
    ; Extracts LSB
    MOV DX, 0
    DIV BX
    ADD DL, 0x30
    PUSH DX
    ; Extracts MSB
    MOV DX, 0
    DIV BX
    ADD DL, 0x30
    PUSH DX

    ADD CX, 2
    CMP CX, 5
    JE move_cursor

    PUSH word ':'
    MOV AX, [CS:time + 2]
    INC CX

    JMP nextdigit

move_cursor:
    ; Set Cursor
    MOV AX, 0x0200
    MOV BX, 0
    MOV DX, 0x033C
    INT 0x10

print_clock:
    POP AX

    ; CALL Teletype Output
    MOV AH, 0x0E
    MOV BL, 0xF
    INT 0x10

    LOOP print_clock

    POPA
    RET

timerISR:
    PUSH AX

    INC word [CS:tick]

    CMP word [CS:tick], 18
    JNE skip_print_timer

    MOV word [CS:tick], 0
    INC word [CS:time]

    CMP word [CS:time], 60
    JNE call_print_timer

    MOV word [CS:time], 0
    INC word [CS:time + 2]

call_print_timer:
    CALL printTimer

skip_print_timer:
    POP AX
    
    JMP FAR [CS:oldTimerISR]

hookTimer:
    PUSH AX
    PUSH ES

    XOR AX, AX
    MOV ES, AX

    MOV AX, [ES:8 * 4]
    MOV [oldTimerISR], AX
    MOV AX, [ES:8 * 4 + 2]
    MOV [oldTimerISR + 2], AX

    CLI
    MOV word [ES:8 * 4], timerISR
    MOV word [ES:8 * 4 + 2], CS
    STI

    POP ES
    POP AX

    RET

unhookTimer:
    PUSH AX
    PUSH ES

    XOR AX, AX
    MOV ES, AX

    STI
    MOV AX, [oldTimerISR]
    MOV [ES:8 * 4], AX
    MOV AX, [oldTimerISR + 2]
    MOV [ES:8 * 4 + 2], AX
    CLI

    POP ES
    POP AX

    RET