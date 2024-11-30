addDelay:
    PUSH CX
    MOV CX, 0xFFFF

delay_loop:
    LOOP delay_loop

    POP CX
    RET

playSingleNote:
    ; [BP + 06] FREQUENCY
    ; [BP + 04] DURATION
    PUSH BP
    MOV BP, SP

    PUSH AX
    PUSH CX

    MOV AL, 0xB6
    OUT 0x43, AL

    MOV AX, [BP + 6]
    OUT 0x42, AL
    MOV AL, AH
    OUT 0x42, AL

    ; Turn Speaker On
    IN AL, 0x61
    OR AL, 0x3
    OUT 0x61, AL

    MOV CX, [BP + 4]

sound_loop:
    CALL addDelay
    LOOP sound_loop

    ; Turn Speaker Off
    IN AL, 0x61
    AND AL, 0xFC
    OUT 0x61, AL

    POP CX
    POP AX

    POP BP

    RET 4

errorSound:
    PUSH word 0x2000
    PUSH word 6
    CALL playSingleNote

    RET

buttonSound:
    PUSH word 0x05F2
    PUSH word 3
    CALL playSingleNote

    RET

celebratorySound:
    PUSHA

    MOV CX, 3

    MOV AL, 0xB6
    OUT 0x43, AL

    ; 4 Notes with Ascending Frequencies
play_celebratory_notes:
    ; 1st Note
    MOV AX, 0x0F00
    OUT 0x42, AL
    MOV AL, AH
    OUT 0x42, AL

    ; Turn Speaker On
    IN AL, 0x61
    OR AL, 0x3
    OUT 0x61, AL

    CALL addDelay

    ; 2nd Note
    MOV AX, 0x0800
    OUT 0x42, AL
    MOV AL, AH
    OUT 0x42, AL

    CALL addDelay

    ; 3rd Note
    MOV AX, 0x0400
    OUT 0x42, AL
    MOV AL, AH
    OUT 0x42, AL

    CALL addDelay

    ; 4th Note
    MOV AX, 0x0200
    OUT 0x42, AL
    MOV AL, AH
    OUT 0x42, AL

    CALL addDelay

    ; Turn Speaker Off
    IN AL, 0x61
    AND AL, 0xFC
    OUT 0x61, AL

    LOOP play_celebratory_notes

    POPA

    RET