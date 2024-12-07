; https://www.minuszerodegrees.net/websitecopies/Linux.old/docs/interrupts/int-html/rb-0121.htm
%macro setpallete 4
    pusha
    mov bx, %1; Register Number 1 Word
    mov dh, %2; R 1 byte
    shr dh, 2; 6 Bits per Color
    mov ch, %3; G 1 byte
    shr ch, 2; 6 Bits per Color
    mov cl, %4; B 1 byte
    shr cl, 2; 6 Bits per Color
    mov ax, 0x1010;
    int 0x10;
    popa
%endmacro

; https://www.minuszerodegrees.net/websitecopies/Linux.old/docs/interrupts/int-html/rb-0104.htm
%macro writepixel 3
    pusha
    push %2; Column
    push %3; Row
    mov al, %1; Pixel Color
    mov ah, 0x0C;
    pop dx
    pop cx
    mov bh, 0x00;
    int 0x10;
    popa
%endmacro