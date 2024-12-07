; PCB Layout:
; AX, BX, CX, DX, SI, DI, BP, SP, IP, CS, DS, SS, ES, Fl, Nx, Du
; 00, 02, 04, 06, 08, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30

pcb:        times 2 * 16 dw 0
stacks:     times 2 * 512 dw 0
current:    dw 0
load_str:   db "Loading"
load_s:     dw $ - load_str
load_ticks: dw 0

loadTimer:
    PUSH DS
    PUSH BX

    PUSH CS
    POP DS

    ; Decrease Loading Screen Time Task
;     CMP word [current], 1
;     JNE swap_task

;     CMP word [load_ticks], 8
;     JE reload_ticks

;     INC word [load_ticks]
;     JMP terminate_loadTimer

; reload_ticks:
;     MOV word [load_ticks], 0

swap_task:
    MOV BX, [current]
    SHL BX, 5

    MOV [pcb + BX + 00], AX
    MOV [pcb + BX + 04], CX
    MOV [pcb + BX + 06], DX
    MOV [pcb + BX + 08], SI
    MOV [pcb + BX + 10], DI
    MOV [pcb + BX + 12], BP
    MOV [pcb + BX + 24], ES

    POP AX
    MOV [pcb + BX + 02], AX
    POP AX
    MOV [pcb + BX + 20], AX
    POP AX
    MOV [pcb + BX + 16], AX
    POP AX
    MOV [pcb + BX + 18], AX
    POP AX
    MOV [pcb + BX + 26], AX
    MOV [pcb + BX + 22], SS
    MOV [pcb + BX + 14], SP

    MOV BX, [pcb + BX + 28]
    MOV [current], BX
    SHL BX, 5

    MOV CX, [pcb + BX + 04]
    MOV DX, [pcb + BX + 06]
    MOV SI, [pcb + BX + 08]
    MOV DI, [pcb + BX + 10]
    MOV BP, [pcb + BX + 12]
    MOV ES, [pcb + BX + 24]
    MOV SS, [pcb + BX + 22]
    MOV SP, [pcb + BX + 14]

    PUSH word [pcb + BX + 26]
    PUSH word [pcb + BX + 18]
    PUSH word [pcb + BX + 16]
    PUSH word [pcb + BX + 20]

terminate_loadTimer:
    MOV AL, 0x20
    OUT 0x20, AL

    MOV AX, [pcb + BX + 00]
    MOV BX, [pcb + BX + 02]
    POP DS

    IRET

setLoadingTask:
    PUSHA

    MOV BX, 32

    MOV [pcb + BX + 18], CS
    MOV word [pcb + BX + 16], loadingAnimation
    MOV [pcb + BX + 22], DS
    
    MOV word [pcb + BX + 14], stacks + 2048 - 2

    MOV word [pcb + BX + 26], 0x0200
    MOV word [pcb + BX + 28], 0
    MOV word [pcb + 28], 1

    POPA

    RET

loadingAnimation:
    PUSH DS
    POP ES

    MOV CX, 0

shit:
    PUSH word 0
    PUSH CX
    PUSH word 0x1
    CALL printTeleNum
    INC CX
    JMP shit

    MOV AH, 0x13
    MOV AL, 0
    MOV BH, 0
    MOV BL, 0x1
    MOV CX, [load_s]
    MOV DX, 0x0F23
    MOV BP, load_str
    INT 0x10

    MOV AH, 0x02
    ADD DX, [load_s]
    INT 0x10

    MOV AH, 0x09
    MOV CX, 0

print_dots:
    PUSH CX
    MOV AL, ' '
    MOV CX, 3
    INT 0x10
    POP CX

    MOV AL, '.'
    INT 0x10

    INC CX
    AND CX, 3
    JMP print_dots