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


; Function for checking whether the given number is a valid entry in a row
isRowValid:
    ; [BP + 12] IS_VALID (RETURN)
    ; [BP + 10] BOARD
    ; [BP + 08] NUMBER
    ; [BP + 06] IND_X
    ; [BP + 04] IND_Y
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV word [BP + 12], 0
    MOV BX, [BP + 10]
    MOV DX, [BP + 8]
    MOV CX, 9

    MOV AX, [BP + 4]
    MUL CL
    MOV SI, AX

check_valid_row:
    CMP [BX + SI], DL
    JE is_not_valid_row

    INC SI
    LOOP check_valid_row

    MOV word [BP + 12], 1

is_not_valid_row:
    POPA

    POP BP

    RET 8


; Function for checking whether the given number is a valid entry in a col
isColValid:
    ; [BP + 12] IS_VALID (RETURN)
    ; [BP + 10] BOARD
    ; [BP + 08] NUMBER
    ; [BP + 06] IND_X
    ; [BP + 04] IND_Y
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV word [BP + 12], 0
    MOV BX, [BP + 10]
    MOV DX, [BP + 8]
    MOV CX, 9
    MOV SI, [BP + 6]

check_valid_col:
    CMP [BX + SI], DL
    JE is_not_valid_col

    ADD SI, 9
    LOOP check_valid_col

    MOV word [BP + 12], 1

is_not_valid_col:
    POPA

    POP BP

    RET 8


; Function for checking whether the given number is a valid entry in a subgrid
isSubgridValid:
    ; [BP + 12] IS_VALID (RETURN)
    ; [BP + 10] BOARD
    ; [BP + 08] NUMBER
    ; [BP + 06] IND_X
    ; [BP + 04] IND_Y
    PUSH BP
    MOV BP, SP

    PUSHA

    MOV word [BP + 12], 0
    MOV BX, [BP + 10]
    MOV DX, [BP + 8]

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
    JE is_not_valid_subGrid

    DEC AX
    JNZ next_index_subGrid

    MOV AX, 3
    ADD SI, 6

next_index_subGrid:
    INC SI
    LOOP check_valid_subGrid

    MOV word [BP + 12], 1

is_not_valid_subGrid:
    POPA

    POP BP

    RET 8


; Function for checking whether the given number is a valid entry in the board
insertIsValid:
    ; [BP + 12] IS_VALID (RETURN)
    ; [BP + 10] BOARD
    ; [BP + 08] NUMBER
    ; [BP + 06] IND_X
    ; [BP + 04] IND_Y
    PUSH BP
    MOV BP, SP

    MOV word [BP + 12], 0

    PUSH word 0
    PUSH word [BP + 10]
    PUSH word [BP + 8]
    PUSH word [BP + 6]
    PUSH word [BP + 4]
    CALL isRowValid
    POP word [BP + 12]

    CMP word [BP + 12], 0
    JE is_not_valid

    PUSH word 0
    PUSH word [BP + 10]
    PUSH word [BP + 8]
    PUSH word [BP + 6]
    PUSH word [BP + 4]
    CALL isColValid
    POP word [BP + 12]

    CMP word [BP + 12], 0
    JE is_not_valid

    PUSH word 0
    PUSH word [BP + 10]
    PUSH word [BP + 8]
    PUSH word [BP + 6]
    PUSH word [BP + 4]
    CALL isSubgridValid
    POP word [BP + 12]

    CMP word [BP + 12], 0
    JE is_not_valid

is_not_valid:
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


; Function for checking all possible solutions of a partially filled board
checkSolutions:
    ; [BP + 10] NO_OF_SOLUTION (RETURN)
    ; [BP + 08] REQ_SOLUTIONS
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
    PUSH word [BP + 10]
    PUSH word [BP + 8]
    PUSH BX
    PUSH DI
    CALL checkSolutions
    POP SI

    ; Check whether solution is found
    MOV [BP + 10], SI
    ; If number of solutions match required number of solutions
    ; Then terminate
    CMP [BP + 8], SI
    JE term_checkSolutions

    ; Removes Value to check for another combination
    MOV byte [BX + DI - 1], 0

insert_next:
    LOOP inserting_value

    JMP term_checkSolutions

fully_traversed:
    ; Found a Solution
    INC word [BP + 10]

term_checkSolutions:
    POP ES
    POPA

    POP BP

    RET 6