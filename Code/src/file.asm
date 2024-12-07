; 1 Input Value
; Address of ASCIZ filename
; 2 Return Values
; First Return Value is 0xFFFF if success, 0x0000 if failure
; Second Return Value is File Handle if success, Error Code if Failure
; https://www.minuszerodegrees.net/websitecopies/Linux.old/docs/interrupts/int-html/rb-2779.htm
OpenFile:
    push bp
    mov bp, sp
    pusha

    mov dx, [bp+4]; File Name
    mov ah, 0x3D
    mov al, 00100000b; Open For Read, Allow Others to Access The File But Not Write to It
    int 0x21
    mov [bp+8], ax;
    mov word [bp+6], 0;
    jc .Failure
    mov word [bp+6], 0xFFFF;
    .Failure:

    popa
    mov sp, bp
    pop bp
    ret 2

; 1 Input Value
; File Handle Returned from OpenFile
; 1 Return Value
; Return Value is 0xFFFF if success, 0x0000 if failure
; https://www.minuszerodegrees.net/websitecopies/Linux.old/docs/interrupts/int-html/rb-2782.htm
CloseFile:
    push bp
    mov bp, sp
    pusha

    mov ah, 0x3E
    mov bx, [bp+4]; File Handle
    int 0x21
    mov word [bp+6], 0;
    jc .Failure
    mov word [bp+6], 0xFFFF;
    .Failure:

    popa
    mov sp, bp
    pop bp
    ret 2

; 3 Input Values
; Input 1 [bp+8] => Number of Bytes to Read
; Input 2 [bp+6] => File Handle
; Input 3 [bp+4] => Address Where to Store Bytes
; 2 Return Value
; 1st Return Value is 0xFFFF if success, 0x0000 if failure
; 2nd Return Value is Number of Bytes Read (If Success), Error Code (If Failure)
; https://www.minuszerodegrees.net/websitecopies/Linux.old/docs/interrupts/int-html/rb-2783.htm
ReadFile:
    push bp
    mov bp, sp
    pusha

    mov dx, [bp+4]; Address Where Data to Store DS:DX
    mov bx, [bp+6]; File Handle
    mov cx, [bp+8]; Number of Bytes to Read
    mov ah, 0x3F
    int 0x21
    mov [bp+12], ax;
    mov word [bp+10], 0;
    jc .Failure
    mov word [bp+10], 0xFFFF;
    .Failure:

    popa
    mov sp, bp
    pop bp
    ret 6

; 3 Input Values
; Input 1 [bp+8] => File Handle
; Input 2 [bp+6] => Most Significant 2 Bytes of Position
; Input 3 [bp+4] => Least Significant 2 Bytes of Position
; 1 Return Value
; 1st Return Value is 0xFFFF if success, 0x0000 if failure
; https://www.minuszerodegrees.net/websitecopies/Linux.old/docs/interrupts/int-html/rb-2783.htm
MoveFileCursor:
    push bp
    mov bp, sp
    pusha

    mov dx, [bp+4]; Address Where Data to Store DS:DX
    mov cx, [bp+6]; Number of Bytes to Read
    mov bx, [bp+8]; File Handle
    mov ah, 0x42
    mov al, 0x00
    int 0x21
    mov word [bp+10], 0;
    jc .Failure
    mov word [bp+10], 0xFFFF;
    .Failure:

    popa
    mov sp, bp
    pop bp
    ret 6


%macro openfile 3
    sub sp, 4
    push word %1; File Name
    call OpenFile
    pop %2; Boolean Success
    pop %3; File Handle or Error Code
%endmacro

%macro closefile 2
    sub sp, 2
    push word %1; File Handle
    call CloseFile
    pop %2; Boolean Success
%endmacro

%macro readfile 5
    sub sp, 4
    push word %1; Number Of Bytes
    push word %2; File Handle
    push word %3; Offset Where Bytes are Stored
    call ReadFile
    pop %4; Boolean Success
    pop %5; File Handle or Error Code
%endmacro

%macro movefilecursor 4
    sub sp, 2
    push word %1; File Handle
    push word %2; Most Significant 2 Bytes of Position
    push word %3; Least Significant 2 Bytes of Position
    call MoveFileCursor
    pop %4; Boolean Success
%endmacro