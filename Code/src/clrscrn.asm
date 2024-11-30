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

clearBg:
    ; [BP + 12] POS_X
    ; [BP + 10] POS_Y
    ; [BP + 08] WIDTH
    ; [BP + 06] HEIGHT
    ; [BP + 04] COLOR
    PUSH BP
    MOV BP, SP
    SUB SP, 6
    ; [BP - 02] ENABLE_PLANE_MASK           ; Higher Byte for Pixel On / Lower Byte for Pixel Off
    ; [BP - 04] STARTING_BIT_COUNT
    ; [BP - 06] ENDING_BIT_COUNT

    PUSHA
    PUSH ES

    ; Sets up the Plane Masks in [BP - 02]
    MOV AX, [BP + 4]
    MOV [BP - 1], AL
    MOV [BP - 2], AL
    XOR byte [BP - 2], 0xF

    ; Sets VGA Segment
    MOV AX, 0xA000
    MOV ES, AX

    ; Setting up Initial Bit Masking in Row
    MOV AX, [BP + 12]
    AND AX, 7
    MOV [BP - 4], AX
    ; Reduces Width and Converts Pixel Position into Byte Count
    SHR word [BP + 12], 3
    SUB [BP + 8], AX
    ; Setting up Latter Bit Masking in Row
    MOV AX, [BP + 8]
    AND AX, 7
    MOV [BP - 6], AX

    ; Convert Pixel Width into Byte Count
    MOV CX, [BP + 8]
    SHR CX, 3

    ; Decrement one Count if Width is divisible by 8
    CMP word [BP - 4], 0
    JNZ not_dec_cx
    DEC CX

not_dec_cx:
    ; Sets up Index in DI
    MOV AX, 80
    MUL word [BP + 10]
    MOV DI, AX 
    ADD DI, [BP + 12]

    MOV SI, 0

    ; Enabling VGA Plane register 
    MOV AL, 0x02
    MOV DX, 0x3C4
    OUT DX, AL

    INC DX

enable_plane_loop:
    ; Enabling VGA Planes based on [BP + SI - 2]
    MOV AL, [BP + SI - 2]
    OUT DX, AL

    ; Saving Start and Height of Block
    PUSH DI
    PUSH word [BP + 6]

next_bg_row:
    ; Saving Width of Row
    PUSH CX

    ; Masking Initial Portion of Row
    MOV CX, [BP - 4]
    MOV AX, 0xFFFF
    SHR AL, CL

    ; Masking wrt Planes Enabled
    CMP SI, 0
    JZ and_mask_start

    ; Pixel Set Mask
    OR [ES:DI], AL
    MOV AL, 0xFF

    JMP next_pixel_byte

and_mask_start:
    ; Pixel Reset Mask
    NOT AL
    AND [ES:DI], AL
    XOR AL, AL

next_pixel_byte:
    ; Saving Width of Row
    POP CX
    PUSH CX
    ; Saving Initial Position of Row
    PUSH DI
    INC DI

    ; Storing Color in Row
    REP STOSB

    ; Masking Latter Portion of Row
    MOV AX, 0xFFFF
    MOV CX, 8
    SUB CX, [BP - 6]
    SHL AL, CL

    ; Masking wrt Planes Enabled
    CMP SI, 0
    JZ and_mask_end

    ; Pixel Set Mask
    OR [ES:DI], AL
    JMP next_pixel_row

and_mask_end:
    ; Pixel Reset Mask
    NOT AL
    AND [ES:DI], AL

next_pixel_row:
    ; Going to Next Row
    POP DI
    ADD DI, 80
    
    ; Restoring Width Count
    POP CX

    ; Decrementing Height Count
    DEC word [BP + 6]
    JNZ next_bg_row

    ; Loading Start and Height of Block
    POP word [BP + 6]
    POP DI

    ; Changing to Next Plane Mask
    INC SI
    CMP SI, 2
    JNE enable_plane_loop

    POP ES
    POPA

    MOV SP, BP
    POP BP

    RET 10