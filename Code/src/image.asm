%define transparentPaletteColor 8

section .bss
    palette: resb 16*3
    buffer: resb 320
    buffer2: resb 320

section .data
    paletteLoaded: db 0

section .text
%include "Code/src/file.asm"
%include "Code/src/pixel.asm"

; Takes File Handle [BP+4] as Input
; Returns Success or Failure Boolean [BP+6]
; Requires Cursor to Be At 0
; Sets Cursor to 118
checkBitmapFile:
    push bp
    mov  bp, sp
    push ax
    push bx

    readfile 118, [bp+4], buffer, bx, ax
    cmp bx,                0   ; Close If Failed To Read from File
    jz  .fail
    cmp ax,                118 ; Close If Size Read < 119
    jnz .fail
    cmp word [buffer+0xE], 40  ; Close If Header is Not Windows BITMAPINFOHEADER
    jnz .fail

    ; Close if Not in 16 Color Mode
    cmp word [buffer+28], 4
    jnz .fail

    ; Close If Compression is Used
    cmp word [buffer+30], 0
    jnz .fail
    cmp word [buffer+32], 0
    jnz .fail

    mov word [bp+6], 0xFFFF
    jmp .nofail
    .fail:
        mov word [bp+6], 0
    .nofail:
    pop bx
    pop ax
    pop bp
    ret 2

; Takes File Handle [BP+4] as Input
; Returns Success or Failure Boolean [BP+6]
; Requires First 118 Bits of File to Be Loaded in Buffer
; https://stackoverflow.com/a/64427761
handlePalette:
    push bp
    mov  bp, sp
    push ax
    push bx

    cmp byte [paletteLoaded], 0
    jnz .checkPalette

        mov si, buffer+54
        mov di, palette
        mov cx, 16
        .loadPaletteLoop:
            mov al, [si+2]
            mov [di], al
            mov al, [si+1]
            mov [di+1], al
            mov al, [si]
            mov [di+2], al
            add si, 4
            add di, 3
            loop .loadPaletteLoop

        setpallete 0x00, [palette+00*3], [palette+00*3+1], [palette+00*3+2]; Set Color 0
        setpallete 0x01, [palette+01*3], [palette+01*3+1], [palette+01*3+2]; Set Color 1
        setpallete 0x02, [palette+02*3], [palette+02*3+1], [palette+02*3+2]; Set Color 2
        setpallete 0x03, [palette+03*3], [palette+03*3+1], [palette+03*3+2]; Set Color 3
        setpallete 0x04, [palette+04*3], [palette+04*3+1], [palette+04*3+2]; Set Color 4
        setpallete 0x05, [palette+05*3], [palette+05*3+1], [palette+05*3+2]; Set Color 5
        setpallete 0x14, [palette+06*3], [palette+06*3+1], [palette+06*3+2]; Set Color 6
        setpallete 0x07, [palette+07*3], [palette+07*3+1], [palette+07*3+2]; Set Color 7
        setpallete 0x38, [palette+08*3], [palette+08*3+1], [palette+08*3+2]; Set Color 8
        setpallete 0x39, [palette+09*3], [palette+09*3+1], [palette+09*3+2]; Set Color 9
        setpallete 0x3A, [palette+10*3], [palette+10*3+1], [palette+10*3+2]; Set Color A
        setpallete 0x3B, [palette+11*3], [palette+11*3+1], [palette+11*3+2]; Set Color B
        setpallete 0x3C, [palette+12*3], [palette+12*3+1], [palette+12*3+2]; Set Color C
        setpallete 0x3D, [palette+13*3], [palette+13*3+1], [palette+13*3+2]; Set Color D
        setpallete 0x3E, [palette+14*3], [palette+14*3+1], [palette+14*3+2]; Set Color E
        setpallete 0x3F, [palette+15*3], [palette+15*3+1], [palette+15*3+2]; Set Color F
        
        mov byte [paletteLoaded], 0xFF
        jmp .after

    .checkPalette:

        mov si, buffer+54
        mov di, palette
        mov cx, 16
        .checkPaletteLoop:
            mov al, [si+2]
            cmp [di], al
            jne .fail
            mov al, [si+1]
            cmp [di+1], al
            jne .fail
            mov al, [si]
            cmp [di+2], al
            jne .fail
            add si, 4
            add di, 3
            loop .checkPaletteLoop

    .after:
    mov word [bp+6], 0xFFFF
    jmp .nofail
    .fail:
        mov word [bp+6], 0
    .nofail:
    pop bx
    pop ax
    pop bp
    ret 2

; BP+4 File Name
; BP+6 Address of Bitmap Handle
; Format Of Resulting Bitmap Handle:
; 0xFFFFFFFFFFFF if File Open Failed
; First 2 Bytes = OS File Handle
; Next 2 Bytes = Width
; Next 2 Bytes = Height
; If Success
OpenBitmap:
    push bp
    mov  bp, sp
    pusha

    mov di, [bp+6];

    openfile [bp+4], bx, ax
    cmp bx,   0
    jz  .failedToOpen
    ; Put OS File Handle in Bitmap Handle
    mov [di], ax

    sub  sp, 2
    push ax
    call checkBitmapFile
    pop  bx

    cmp bx, 0
    jz .BMPCheckFailed

    ; Close If Width > 640
    cmp word [buffer+18], 640
    ja .BMPCheckFailed
    cmp word [buffer+20], 0
    jnz .BMPCheckFailed

    ; Close If Height > 480
    cmp word [buffer+22], 480
    ja .BMPCheckFailed
    cmp word [buffer+24], 0
    jnz .BMPCheckFailed

    ; Put Width in Bitmap Handle+2
    mov ax, [buffer+18];
    mov [di+2], ax;

    ; Put Height in Bitmap Handle+4
    mov ax, [buffer+22];
    mov [di+4], ax;

    sub  sp, 2
    push word [di]
    call handlePalette
    pop  bx

    cmp bx, 0
    jz .BMPCheckFailed

    jmp .return



    .BMPCheckFailed:
        closefile [di], bx
    .failedToOpen:
        mov word [di], -1
        mov word [di+2], -1
        mov word [di+4], -1

    .return:
    popa
    mov sp, bp
    pop bp
    ret 4

CloseBitmap:
    push bp
    mov bp, sp
    push di
    push bx

    mov di, [bp+4]

    closefile [di], bx
    mov word [di], -1
    mov word [di+2], -1
    mov word [di+4], -1

    pop bx
    pop di
    mov sp, bp
    pop bp
    ret 2

; BP+4 Drawing Start Offset Height
; BP+6 Drawing Start Offset Width
; BP+8 Drawing Height
; BP+10 Drawing Width
; BP+12 Starting Column
; BP+14 Starting Row
; BP+16 Address of Bitmap File Handle
; BP+18 Use Transparency 0xFFFF or 0x0000 (0xFFFF for use transparency)
; BP-2 is the Bitmap File Handle
; BP-4 is the Width of Bitmap
; Returns Success or Failure Boolean [BP+20]
DrawImage:
    jmp .afterInitialExit
    .initialExit:
        popa
        mov sp, bp
        pop bp
        ret 16
    .afterInitialExit:
    push bp
    mov bp, sp
    sub sp, 4
    pusha

    mov word [bp+20], 0

    mov si, [bp+16]

    ; Check Width
    mov ax, [bp+10]
    cmp ax, 0
    jna .initialExit
    add ax, [bp+6]
    cmp [si+2], ax;
    jb .initialExit

    mov ax, [bp+10]
    add ax, [bp+12]
    cmp ax, 640
    ja .initialExit

    ; Check Height
    mov ax, [bp+8]
    cmp ax, 0
    jna .initialExit
    add ax, [bp+4]
    cmp [si+4], ax;
    jb .initialExit

    mov ax, [bp+8]
    add ax, [bp+14]
    cmp ax, 480
    ja .initialExit

    ; Store File Handle Location in BP-2
    mov ax, [si]
    mov [bp-2], ax

    ; Store Image Width in Bytes in BP-4
    mov ax, [si+2]
    shr ax, 1
    add ax, 3
    shr ax, 2
    shl ax, 2
    mov [bp-4], ax

    ; Calculate Initial Offset
    
    mov ax, [si+4]
    sub ax, [bp+8]
    sub ax, [bp+4]
    mov bx, [bp-4]
    mul bx
    mov bx, [bp+6]
    shr bx, 1
    add ax, bx
    adc dx, 0
    add ax, 118
    adc dx, 0

    movefilecursor [bp-2], dx, ax, dx
    cmp dx, 0
    jz .exit

    mov cx, [bp+8]
    mov ax, [bp+14]
    add ax, cx
    .drawLoopRow:
        push cx

        readfile [bp-4], [bp-2], buffer, bx, dx
        cmp bx, 0      ; Close If Failed To Read from File
        jz  .exit
        cmp dx, [bp-4] ; Close If Size Read < Width
        jnz .exit
        mov cx, [bp+10]
        mov bx, [bp+12]
        mov si, 0
        .drawLoopCol:
            ; Put 1st 4 Bits in DH
            ; Put 2nd 4 Bits in DL
            mov dh, [buffer+si]
            shr dx, 4
            shr dl, 4

            cmp word [bp+18], 0
            jz .write1
            cmp dh, transparentPaletteColor
            jz .afterwrite1
            .write1:
                writepixel dh, bx, ax
            .afterwrite1:
            
            dec cx
            jz .stopLoop
            inc bx
            
            cmp word [bp+18], 0
            jz .write2
            cmp dl, transparentPaletteColor
            jz .afterwrite2
            .write2:
                writepixel dl, bx, ax
            .afterwrite2:
            
            inc bx
            inc si
            loop .drawLoopCol
        .stopLoop:
        dec ax

        pop cx
        loop .drawLoopRow

    mov word [bp+20], 0xFFFF
    .exit:
    popa
    mov sp, bp
    pop bp
    ret 16


; BP+4 Drawing Start Offset Height
; BP+6 Drawing Start Offset Width
; BP+8 Drawing Height
; BP+10 Drawing Width
; BP+12 Starting Column
; BP+14 Starting Row
; BP+16 Address of Bitmap File Handle
; BP+18 Background Offset Height
; BP+20 Background Offset Width
; BP+22 Address of Background Bitmap File Handle
; BP-2 is the Bitmap File Handle
; BP-4 is the Width of Bitmap
; BP-6 is the Bitmap File Handle of Background
; BP-8 is the Width of Background
; Returns Success or Failure Boolean [BP+24]
DrawImageWithBackground:
    jmp .afterInitialExit
    .initialExit:
        popa
        mov sp, bp
        pop bp
        ret 20
    .afterInitialExit:
    push bp
    mov bp, sp
    sub sp, 4
    pusha

    mov word [bp+24], 0

    mov si, [bp+16]
    mov di, [bp+22]

    ; Check Width
    mov ax, [bp+10]
    cmp ax, 0
    jna .initialExit
    add ax, [bp+6]
    cmp [si+2], ax;
    jb .initialExit

    mov ax, [bp+10]
    add ax, [bp+12]
    cmp ax, 640
    ja .initialExit

    ; Check Height
    mov ax, [bp+8]
    cmp ax, 0
    jna .initialExit
    add ax, [bp+4]
    cmp [si+4], ax;
    jb .initialExit

    mov ax, [bp+8]
    add ax, [bp+14]
    cmp ax, 480
    ja .initialExit

    ; Check Background Width
    mov ax, [bp+10]
    add ax, [bp+20]
    cmp [di+2], ax;
    jb .initialExit

    ; Check Background Height
    mov ax, [bp+8]
    add ax, [bp+18]
    cmp [di+4], ax;
    jb .initialExit

    ; Store File Handle Location in BP-2
    mov ax, [si]
    mov [bp-2], ax

    ; Store Background File Handle Location in BP-6
    mov ax, [di]
    mov [bp-6], ax

    ; Store Image Width in Bytes in BP-4
    mov ax, [si+2]
    shr ax, 1
    add ax, 3
    shr ax, 2
    shl ax, 2
    mov [bp-4], ax

    ; Store Background Width in Bytes in BP-8
    mov ax, [di+2]
    shr ax, 1
    add ax, 3
    shr ax, 2
    shl ax, 2
    mov [bp-8], ax

    ; Calculate Initial Offset of Main Image
    mov ax, [si+4]
    sub ax, [bp+8]
    sub ax, [bp+4]
    mov bx, [bp-4]
    mul bx
    mov bx, [bp+6]
    shr bx, 1
    add ax, bx
    adc dx, 0
    add ax, 118
    adc dx, 0

    movefilecursor [bp-2], dx, ax, dx
    cmp dx, 0
    jz .exit

    ; Calculate Initial Offset of Background Image
    mov ax, [di+4]
    sub ax, [bp+8]
    sub ax, [bp+18]
    mov bx, [bp-8]
    mul bx
    mov bx, [bp+20]
    shr bx, 1
    add ax, bx
    adc dx, 0
    add ax, 118
    adc dx, 0

    movefilecursor [bp-6], dx, ax, dx
    cmp dx, 0
    jz .exit

    mov cx, [bp+8]
    mov ax, [bp+14]
    add ax, cx
    .drawLoopRow:
        push cx
        readfile [bp-4], [bp-2], buffer, bx, dx
        cmp bx, 0      ; Close If Failed To Read from File
        jz  .exit
        cmp dx, [bp-4] ; Close If Size Read < Width
        jnz .exit
        readfile [bp-8], [bp-6], buffer2, bx, dx
        cmp bx, 0      ; Close If Failed To Read from File
        jz  .exit
        cmp dx, [bp-8] ; Close If Size Read < Width
        jnz .exit
        mov cx, [bp+10]
        mov bx, [bp+12]
        mov si, 0
        .drawLoopCol:
            ; Put 1st 4 Bits in DH
            ; Put 2nd 4 Bits in DL
            mov dh, [buffer+si]
            shr dx, 4
            shr dl, 4

            mov di, ax;

            mov ah, [buffer2+si]
            shr ax, 4
            shr al, 4

            cmp word [bp+18], 0
            jz .write1
            cmp dh, transparentPaletteColor
            jz .writeBackground1
            .write1:
                writepixel dh, bx, di
                jmp .afterwrite1
            .writeBackground1:
                writepixel ah, bx, di
            .afterwrite1:
            
            dec cx
            jz .stopLoop
            inc bx
            
            cmp word [bp+18], 0
            jz .write2
            cmp dl, transparentPaletteColor
            jz .writeBackground2
            .write2:
                writepixel dl, bx, di
                jmp .afterwrite2
            .writeBackground2:
                writepixel al, bx, di
            .afterwrite2:
            
            inc bx
            inc si
            mov ax, di
            loop .drawLoopCol
        .stopLoop:
        dec ax

        pop cx
        dec cx
        jz .exitLoop
        jmp .drawLoopRow

    .exitLoop:

    mov word [bp+24], 0xFFFF
    .exit:
    popa
    mov sp, bp
    pop bp
    ret 20

%MACRO openbitmap 2
    push %2; Address of File Handle (6 Bytes)
    push %1; File Name
    call OpenBitmap
%ENDMACRO

%MACRO closebitmap 1
    push word %1; Address of File Handle
    call CloseBitmap
%ENDMACRO

%MACRO drawimage 9
    sub sp, 2
    push word %8; Use Transparency
    push word %1; Address of File Handle
    push word %3; Starting Column
    push word %2; Starting Row
    push word %4; Drawing Width
    push word %5; Drawing Height
    push word %6; Width Offset
    push word %7; Height Offset
    call DrawImage
    pop word %9; Return Value
%ENDMACRO

%MACRO drawimagewithbackground 11
    sub sp, 2
    push word %8; Address of Background File Handle
    push word %9; Background Width Offset
    push word %10; Background Height Offset
    push word %1; Address of File Handle
    push word %3; Starting Column
    push word %2; Starting Row
    push word %4; Drawing Width
    push word %5; Drawing Height
    push word %6; Width Offset
    push word %7; Height Offset
    call DrawImageWithBackground
    pop word %11; Return Value
%ENDMACRO