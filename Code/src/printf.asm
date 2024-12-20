printfont:
    ; [BP + 14] POS_X
    ; [BP + 12] POS_Y
    ; [BP + 10] WIDTH
    ; [BP + 08] HEIGHT
    ; [BP + 06] COLOR
    ; [BP + 04] ADDRESS
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    ; [BP - 02] PIXEL_COUNT
    ; [BP - 04] CURR_FONT_BYTE

    PUSHA

    MOV AL, [BP + 10]
    MUL byte [BP + 8]
    MOV [BP - 2], AX

    MOV SI, [BP + 4]
    MOV BL, [SI]
    MOV [BP - 4], BL

    MOV DI, 0

    MOV AH, 0x0C
    MOV AL, [BP + 6]
    MOV BX, 0
    MOV CX, [BP + 14]
    MOV DX, [BP + 12]

drawfont:
    SHL byte [BP - 4], 1
    JNC skip_pixel

    INT 0x10

skip_pixel:
    INC DI
    TEST DI, 7
    JNZ skip_load

    INC SI
    MOV BL, [SI]
    MOV [BP - 4], BL

    XOR BX, BX

skip_load:
    INC CX

    CMP DI, [BP + 10]
    JNE same_row

    MOV CX, [BP + 14]
    INC DX
    XOR DI, DI

same_row:
    DEC word [BP - 2]
    JNZ drawfont

    POPA
    
    MOV SP, BP
    POP BP

    RET 12


printNotes:
    ; [BP + 14] IND_X
    ; [BP + 12] IND_Y
    ; [BP + 10] GRID_X
    ; [BP + 08] GRID_Y
    ; [BP + 06] FILL_ARRAY
    ; [BP + 04] BOX_SIZE
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV SI, notes

    ; TRAVERSING COL INDICES IN NOTES
    MOV AX, 18
    MUL byte [BP + 12]
    ADD SI, AX
    ; TRAVERSING ROW INDICES IN NOTES
    MOV AX, [BP + 14]
    SHL AX, 1
    ADD SI, AX

    SUB SP, 4
    PUSH word [BP + 14]
    PUSH word [BP + 12]
    PUSH word [BP + 6]
    PUSH word [BP + 4]
    CALL traverseGrid
    POP DX
    POP CX

    ADD CX, [BP + 10]
    ADD CX, 5
    ADD DX, [BP + 8]
    ADD DX, 5
    MOV AX, [SI]
    MOV DI, smol + 8
    MOV BH, 9
    MOV BL, 3
    PUSH CX

draw_note:
    SHL AX, 1
    JNC skip_note

    PUSH CX
    PUSH DX
    PUSH word 8
    PUSH word 8
    PUSH word 0x4
    PUSH DI
    CALL printfont

skip_note:
    ADD CX, 12
    ADD DI, 8

    DEC BH
    JZ terminate_printNotes

same_note:
    DEC BL
    JNZ draw_note

    POP CX
    PUSH CX
    ADD DX, 12
    MOV BL, 3

    JMP draw_note

terminate_printNotes:
    POP CX
    POPA

    MOV SP, BP
    POP BP

    RET 12


printNumbers:
    ; [BP + 16] IND_X
    ; [BP + 14] IND_Y
    ; [BP + 12] GRID_X
    ; [BP + 10] GRID_Y
    ; [BP + 08] FILL_ARRAY
    ; [BP + 06] BOX_SIZE
    ; [BP + 04] COLOR
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV SI, board
    MOV DI, big

    MOV AX, 9
    MUL byte [BP + 14]
    ADD SI, AX
    ADD SI, [BP + 16]

    SUB SP, 4
    PUSH word [BP + 16]
    PUSH word [BP + 14]
    PUSH word [BP + 8]
    PUSH word [BP + 6]
    CALL traverseGrid
    POP DX
    POP CX

    ADD CX, [BP + 12]
    ADD CX, 9
    ADD DX, [BP + 10]
    ADD DX, 5

    XOR AX, AX
    MOV AL, [SI]
    MOV BX, 96
    MUL BL
    ADD DI, AX

    PUSH CX
    PUSH DX
    PUSH word 24
    PUSH word 32
    PUSH word [BP + 4]
    PUSH DI
    CALL printfont

    POPA

    MOV SP, BP
    POP BP

    RET 14


printString:
    ; [BP + 10] POS_X
    ; [BP + 08] POS_Y
    ; [BP + 06] NULL_TERM_STRING
    ; [BP + 04] COLOR
    PUSH BP
    MOV BP, SP

    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    XOR AX, AX
    MOV CX, 0xFFFF
    MOV DI, [BP + 6]
    REPNE SCASB

    MOV AX, 0xFFFF
    SUB AX, CX
    DEC AX
    MOV CX, AX

    MOV DX, [BP + 10]
    MOV DI, [BP + 6]

draw_char:
    XOR BX, BX
    MOV BL, [DI]

    CMP BL, 0x20
    JE skip_space

    SUB BL, 65
    CMP BL, 26
    JL is_uppercase

    SUB BL, 5

is_uppercase:
    SHL BX, 4
    ADD BX, chars

    PUSH DX
    PUSH word [BP + 8]
    PUSH word 8
    PUSH word 16
    PUSH word [BP + 4]
    PUSH BX
    CALL printfont

skip_space:
    ADD DX, 8
    INC DI
    LOOP draw_char

    POP ES
    POPA

    POP BP

    RET 8


drawCards:
    ; [BP + 18] POS_X
    ; [BP + 16] POS_Y
    ; [BP + 14] CARD_WIDTH
    ; [BP + 12] CARD_HEIGHT
    ; [BP + 10] SPACING_X
    ; [BP + 08] SPACING_Y
    ; [BP + 06] CARD_COLOR
    ; [BP + 04] NUMBER_COLOR
    PUSH BP
    MOV BP, SP
    SUB SP, 4
    ; [BP - 02] COL_COUNTER
    ; [BP - 04] CARD_INDEX

    PUSHA

    MOV word [BP - 2], 2
    MOV AX, 4
    MOV BX, 0
    MOV CX, [BP + 18]
    MOV DX, [BP + 16]
    MOV SI, big + 96
    MOV DI, SP

draw_card:
    PUSH CX
    PUSH DX
    PUSH word [BP + 14]
    PUSH word [BP + 12]
    PUSH word [BP + 6]
    PUSH word 1
    CALL drawRect

    PUSH CX
    PUSH DX
    PUSH word 24
    PUSH word 32
    PUSH word [BP + 4]
    PUSH SI
    ADD word [DI - 2], 8
    ADD word [DI - 4], 5
    CALL printfont

    MOV [BP - 4], BX
    MOV BL, [remaining_nos + BX]
    SHL BX, 3
    ADD BX, smol

    PUSH CX
    PUSH DX
    PUSH word 8
    PUSH word 8
    PUSH word [BP + 4]
    PUSH word BX
    ADD word [DI - 2], 16
    ADD word [DI - 4], 47
    CALL printfont

    MOV BX, [BP - 4]
    INC BX
    ADD CX, [BP + 14]
    ADD CX, [BP + 10]
    ADD SI, 96

    DEC word [BP - 2]
    JNZ draw_card

    MOV word [BP - 2], 2
    MOV CX, [BP + 18]
    ADD DX, [BP + 12]
    ADD DX, [BP + 8]

    DEC AX
    JNZ draw_card

    MOV AX, [BP + 14]
    ADD AX, [BP + 10]
    SHR AX, 1
    ADD CX, AX

    PUSH CX
    PUSH DX
    PUSH word [BP + 14]
    PUSH word [BP + 12]
    PUSH word [BP + 6]
    PUSH word 1
    CALL drawRect

    PUSH CX
    PUSH DX
    PUSH word 24
    PUSH word 32
    PUSH word [BP + 4]
    PUSH SI
    ADD word [DI - 2], 8
    ADD word [DI - 4], 5
    CALL printfont

    MOV BL, [remaining_nos + BX]
    SHL BX, 3
    ADD BX, smol

    PUSH CX
    PUSH DX
    PUSH word 8
    PUSH word 8
    PUSH word [BP + 4]
    PUSH word BX
    ADD word [DI - 2], 16
    ADD word [DI - 4], 47
    CALL printfont

    POPA

    MOV SP, BP
    POP BP

    RET 16

printTeleNum:
    ; [BP + 08] ROW/COL_VALUE
    ; [BP + 06] NUMBER
    ; [BP + 04] COLOR
    PUSH BP
    MOV BP, SP

    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    MOV AX, [BP + 6]
    MOV BX, 10
    MOV CX, 0

next_digit:
    MOV DX, 0
    DIV BX

    ADD DL, 0x30
    PUSH DX

    INC CX
    CMP AX, 0
    JNZ next_digit

    ; Set Cursor Position
    MOV AH, 0x02
    MOV BH, 0
    MOV DX, [BP + 8]
    INT 0x10
    ; Set Color
    MOV BX, [BP + 4]

print_next_digit:
    POP AX
    MOV AH, 0x0E
    INT 0x10

    LOOP print_next_digit

    POP ES
    POPA

    POP BP

    RET 6

printMistakes:
    ; [BP + 04] ROW/COL_VALUE
    PUSH BP
    MOV BP, SP

    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    MOV AX, 0x1300
    MOV BX, 0x0001
    MOV CX, [m_size]
    MOV DX, [BP + 4]

    PUSH BP
    MOV BP, mistakes
    INT 0x10
    POP BP

    PUSH BP
    SUB SP, 3
    MOV BP, SP

    MOV CX, [mistake_count]
    MOV byte [BP], CL
    MOV byte [BP + 1], '/'
    MOV byte [BP + 2], '3'

    MOV CX, 3
    ADD DL, [m_size]
    INT 0x10

    ADD SP, 3
    POP BP

    POP ES
    POPA

    POP BP

    RET 2    

printScore:
    ; [BP + 06] ROW/COL_VALUE
    ; [BP + 04] COLOR
    PUSH BP
    MOV BP, SP

    PUSHA
    PUSH ES

    PUSH DS
    POP ES

    ; Print Score Text
    MOV AX, 0x1300
    MOV BX, [BP + 4]
    MOV CX, [score_size]
    MOV DX, [BP + 6]

    PUSH BP
    MOV BP, score_text
    INT 0x10
    POP BP

    ADD DX, [score_size]
    INC DX

    ; Clear Previous Score
    MOV AH, 0x02
    MOV BH, 0
    INT 0x10

    MOV AH, 0x0A
    MOV AL, ' '
    MOV CX, 4
    INT 0x10

    PUSH DX
    PUSH word [score]
    PUSH word [BP + 4]
    CALL printTeleNum

    POP ES
    POPA

    POP BP

    RET 4

printTimer:
    ; [BP + 04] Row/Col Value
    PUSH BP
    MOV BP, SP

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
    MOV DX, [BP + 4]
    INT 0x10

print_clock:
    POP AX

    ; CALL Teletype Output
    MOV AH, 0x0E
    MOV BL, 0x1
    INT 0x10

    LOOP print_clock

    POPA

    POP BP

    RET 2