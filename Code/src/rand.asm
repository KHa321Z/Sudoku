seed:   dw 0

; Function to generate a random number in the range [LOWER_BOUND, UPPERBOUND)
rand:
    ; [BP + 8] RANDOM_NUMBER (RETURN)
    ; [BP + 6] LOWER_BOUND
    ; [BP + 4] UPPER_BOUND
    PUSH BP
    MOV BP, SP

    PUSH AX
    PUSH BX
    PUSH DX

    MOV BX, [BP + 4]
    SUB BX, [BP + 6]

    OR BX, BX
    JNZ read_tsc
    
    INC BX

read_tsc:
    RDTSC

    ADD AX, [seed]
    ADD [seed], AX

    XOR DX, DX
    DIV BX

    ADD DX, [BP + 6]
    MOV [BP + 8], DX

    POP DX
    POP BX
    POP AX

    MOV SP, BP
    POP BP

    RET 4