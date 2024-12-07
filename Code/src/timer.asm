oldTimerISR:    dd 0
tick:           dw 0

timerISR:
    PUSH AX

    INC word [CS:tick]

    CMP word [CS:tick], 18
    JNE skip_print_timer

    MOV word [CS:tick], 0
    INC word [CS:time]
    ; Decrement Score Multiplier Ticks
    DEC word [score_sec]
    JNZ skip_dec_score_mult

    ; Reset Tick Count for Multiplier
    MOV word [score_sec], 18
    
    CMP word [score_mult], 1
    JE skip_dec_score_mult

    DEC word [score_mult]

skip_dec_score_mult:
    CMP word [CS:time], 60
    JNE call_print_timer

    MOV word [CS:time], 0
    INC word [CS:time + 2]

call_print_timer:
    PUSH word 0x033C
    CALL printTimer

skip_print_timer:
    POP AX
    
    JMP FAR [CS:oldTimerISR]

hookTimer:
    ; [BP + 04] TIMER_FUNCTION
    PUSH BP
    MOV BP, SP

    PUSH AX
    PUSH ES

    XOR AX, AX
    MOV ES, AX

    MOV AX, [ES:8 * 4]
    MOV [oldTimerISR], AX
    MOV AX, [ES:8 * 4 + 2]
    MOV [oldTimerISR + 2], AX

    CLI
    MOV AX, [BP + 4]
    MOV [ES:8 * 4], AX
    MOV [ES:8 * 4 + 2], CS
    STI

    POP ES
    POP AX

    POP BP

    RET 2

unhookTimer:
    PUSH AX
    PUSH ES

    XOR AX, AX
    MOV ES, AX

    CLI
    MOV AX, [oldTimerISR]
    MOV [ES:8 * 4], AX
    MOV AX, [oldTimerISR + 2]
    MOV [ES:8 * 4 + 2], AX
    STI

    POP ES
    POP AX

    RET