; ------------------------------ MISC. FUNCTIONS ------------------------------


; Function for filling stack array with [1, ARRAY_SIZE] values
; Starts inserting from end using CX register's values
populateArray:
    ; [BP + 06] ARRAY_END_IN_STACK
    ; [BP + 04] ARRAY_SIZE
    PUSH BP
    MOV BP, SP

    PUSH BX
    PUSH CX 
    PUSH DI

    MOV BX, 1
    MOV CX, [BP + 4]
    MOV DI, [BP + 6]

fill_array:
    MOV [DI + BX - 1], BX
    INC BX

    LOOP fill_array

    POP DI
    POP CX
    POP BX

    POP BP

    RET 4


; Function for returning a random number from an array
; Removes the number from the array and shrinks it by shifting
extractRandomNum:
    ; [BP + 08] EXTRACTED_NUMBER (RETURN)
    ; [BP + 06] ARRAY_END_IN_STACK
    ; [BP + 04] ARRAY_SIZE
    PUSH BP
    MOV BP, SP

    PUSH AX
    PUSH BX
    PUSH DI

    PUSH word 0
    PUSH word 0
    PUSH word [BP + 4]
    CALL rand
    POP BX

    DEC word [BP + 4]
    MOV DI, [BP + 6]

    ; Extract Number
    XOR AX, AX
    MOV AL, [DI + BX]
    MOV [BP + 8], AX

    ; Compress Array
shift_array:
    MOV AL, [DI + BX + 1]
    MOV [DI + BX], AX
    
    INC BX
    CMP BX, [BP + 4]
    JL shift_array

    POP DI
    POP BX
    POP AX

    POP BP

    RET 4


; ------------------------------ BOARD FUNCTIONS ------------------------------


; Function for checking whether the given number is a valid entry
insertIsValid:
    ; [BP + 12] IS_VALID (RETURN)
    ; [BP + 10] BOARD
    ; [BP + 08] NUMBER
    ; [BP + 06] IND_X
    ; [BP + 04] IND_Y
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV word [BP + 12], 1
    MOV BX, [BP + 10]
    MOV DX, [BP + 8]

    ; Checks same row
    MOV CX, 9

    MOV AX, [BP + 4]
    MUL CL
    MOV SI, AX

check_valid_row:
    CMP [BX + SI], DL
    JE is_not_valid

    INC SI
    LOOP check_valid_row

    ; Checks same col
    MOV CX, 9
    MOV SI, [BP + 6]

check_valid_col:
    CMP [BX + SI], DL
    JE is_not_valid

    ADD SI, 9
    LOOP check_valid_col

    ; Checks same subgrid
    MOV AX, [BP + 4]
    MOV CX, 3
    DIV CL
    
    XOR AH, AH
    MOV CL, 3 * 9
    MUL CL
    MOV SI, AX

    MOV AX, [BP + 6]
    MOV CL, 3
    DIV CL

    XOR AH, AH
    MOV CL, 3
    MUL CL
    ADD SI, AX

    MOV AX, 3
    MOV CX, 9

check_valid_subGrid:
    CMP [BX + SI], DL
    JE is_not_valid

    DEC AX
    JNZ next_index_subGrid

    MOV AX, 3
    ADD SI, 6

next_index_subGrid:
    INC SI
    LOOP check_valid_subGrid

    JMP terminate_is_valid

is_not_valid:
    MOV word [BP + 12], 0

terminate_is_valid:
    POPA

    POP BP

    RET 8


; Function for randomly filling the diagonal subgrids of the board
fillDiagonalSubGrids:
    ; [BP + 04] BOARD
    PUSH BP
    MOV BP, SP
    SUB SP, 10
    ; [BP - 02] NUMBER_ARRAY_START
    ; [BP - 10] NUMBER_ARRAY_END

    PUSHA

    MOV BX, BP
    SUB BX, 10

    MOV SI, 3
    MOV DI, [BP + 4]

    ; Loop for moving from subgrid to subgrid
diagonal_subGrid:
    PUSH word BX
    PUSH word 9
    CALL populateArray

    MOV AX, 3
    MOV CX, 9

    ; Loop for filling subgrid
fill_subGrid:
    PUSH word 0
    PUSH word BX
    PUSH CX
    CALL extractRandomNum
    POP DX

    MOV [DI], DL

    DEC AX
    JNZ next_index

    MOV AX, 3
    ADD DI, 6

next_index:
    INC DI
    LOOP fill_subGrid

    ADD DI, 3
    DEC SI
    JNZ diagonal_subGrid

    POPA

    MOV SP, BP
    POP BP

    RET 2


; Function for randomly removing values from the board
removeValues:
    ; [BP + 06] BOARD
    ; [BP + 04] NUMBER_OF_VALUES
    PUSH BP
    MOV BP, SP
    SUB SP, 82
    ; [BP - 02] START_INDEX
    ; [BP - 44] END_INDEX

    PUSHA

    MOV DI, BP
    SUB DI, 82
    MOV AX, 81

    PUSH DI
    PUSH AX
    CALL populateArray

    MOV CX, [BP + 4]
    MOV SI, [BP + 6]

fill_zero:
    PUSH word 0
    PUSH DI
    PUSH AX
    CALL extractRandomNum
    POP BX

    DEC BX
    MOV byte [SI + BX], 0
    DEC AX

    LOOP fill_zero

    POPA

    MOV SP, BP
    POP BP

    RET 4


; Function for generating a solved board
fillBoard:
    ; [BP + 10] IS_FILLED (RETURN)
    ; [BP + 08] BOARD
    ; [BP + 06] IND_X
    ; [BP + 04] IND_Y
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV word [BP + 10], 0

    ; Check if on diagonal subgrid
    MOV AX, [BP + 4]
    MOV CX, 3
    DIV CL
    MOV BL, AL

    MOV AX, [BP + 6]
    MOV CL, 3
    DIV CL

    CMP AL, BL
    JNE not_on_diagonal

    ; Base Case
    ; Reached last row and last diagonal subgrid
    CMP word [BP + 4], 8
    JE board_filled

    ; On diagonal
    MOV AX, [BP + 6]
    ADD AX, 3
    MOV CL, 9
    DIV CL

    ADD [BP + 4], AL
    MOV [BP + 6], AH

    ; Not on diagonal
not_on_diagonal:
    MOV SI, [BP + 8]

    MOV AX, [BP + 4]
    MOV CX, 9
    MUL CL

    ADD SI, AX
    ADD SI, [BP + 6]

    ; Checking every value by brute force
checking_value:
    ; Checking whether value is inserteable
    PUSH word 0
    PUSH word [BP + 8]
    PUSH CX
    PUSH word [BP + 6]
    PUSH word [BP + 4]
    CALL insertIsValid
    POP AX

    CMP AX, 0
    JZ check_next

    ; Inserts Value
    MOV [SI], CL

    ; Recursive Call
    MOV AX, [BP + 6]
    INC AX
    MOV BX, 9
    DIV BL

    MOV BL, AL
    ADD BX, [BP + 4]

    MOV AL, AH
    XOR AH, AH

    PUSH word 0
    PUSH word [BP + 8]
    PUSH AX
    PUSH BX
    CALL fillBoard
    POP AX

    ; Board Filled
    CMP AX, 1
    JE board_filled

    ; Remove Value if board not solved
    MOV byte [SI], 0

check_next:
    LOOP checking_value

    JMP term_fillBoard

board_filled:
    ; Return Value of Filled Board
    MOV word [BP + 10], 1

term_fillBoard:
    POPA

    POP BP

    RET 6


; Function for checking all possible solutions of a partially filled board
checkSolutions:
    ; [BP + 08] NO_OF_SOLUTION (RETURN)
    ; [BP + 06] BOARD
    ; [BP + 04] ARRAY_INDEX
    PUSH BP
    MOV BP, SP

    PUSHA
    PUSH ES

    PUSH DS
    POP ES
    MOV DI, [BP + 4]
    MOV BX, [BP + 6]
    XOR AX, AX
    MOV CX, 81

    ; Check if exceeded last index
    SUB CX, DI
    JLE fully_traversed

    ADD DI, BX

    ; Scan for an empty index in the board
    REPNE SCASB
    JNZ fully_traversed

    DEC DI
    SUB DI, BX

    MOV AX, DI
    MOV CX, 9
    DIV CL

    XOR DH, DH
    MOV DL, AH
    XOR AH, AH

    INC DI

inserting_value:
    ; Checking whether value is inserteable
    PUSH word 0
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH AX
    CALL insertIsValid
    POP SI

    CMP SI, 0
    JZ insert_next

    ; Inserts Value
    MOV [BX + DI - 1], CL

    ; Recursive Call
    PUSH word [BP + 8]
    PUSH BX
    PUSH DI
    CALL checkSolutions
    POP SI

    ; Check whether another solution is found
    MOV [BP + 8], SI
    ; If 2 solutions found then terminate
    CMP word [BP + 8], 1
    JG term_checkSolutions

    ; Removes Value to check for another combination
    MOV byte [BX + DI - 1], 0

insert_next:
    LOOP inserting_value

    JMP term_checkSolutions

fully_traversed:
    ; Found a Solution
    INC word [BP + 8]

term_checkSolutions:
    POP ES
    POPA

    POP BP

    RET 4