section .text

global _start

SPECIFIER_SYMBOL equ '%'

DIFFERENCE_NUM_ASCII_L9   equ 48d
DIFFERENCE_NUM_ASCII_G9   equ 55d
END_STR_SYM      equ 0x0a

_start:
    push 35
    push 33
    push Msg
    call newPrintf
    
    mov rax, 0x3C
    xor rdi, rdi
    syscall

;-----------------------------------------------------------------------
; printf function from c
; Entry: [rbp + 16] = Msg 
;        [rbp + 16 + i * 8] = first arg
;        ....
; Exit:  no
; Exp:   nop
; Destr: rax, rdi, rsi, rdx
;-----------------------------------------------------------------------
newPrintf:
    push rbp 
    mov rbp, rsp 

    mov rbx, MsgLen
    mov rax, [rbp + 16]
    call countSpecifiers 
    
    mov rbx, MsgLen
    mov rax, [rbp + 16]
    
    
    call handleStrParts

    mov rax, 0x01
    mov rdi, 1d
    mov rsi, printBuffer
    mov rdx, printBufferLen
    syscall

    pop rbp
    ret

;-----------------------------------------------------------------------
; count amount of specifiers in string
; Entry: rax = Msg 
;        rbx = MsgLen
; Exit:  rdx = amount str parts
;        rdi = amount specifiers
; Exp:   nop
; Destr: rax, rbx, rcx, rdx, rsi, rdi, r8b 
;-----------------------------------------------------------------------
countSpecifiers:
    xor rdx, rdx
    xor rdi, rdi
    xor rcx, rcx 
    
    ??startCycle:
    cmp rcx, rbx
    jge ??endCycle
        cmp byte [rax + rcx], SPECIFIER_SYMBOL
        jne ??notSpecifier
            inc rdi
            mov rsi, partStrIndexes
            
            call saveStartStrPart

            ;skip specifier part
            add rcx, 2
            call saveStartStrPart

            jmp ??startCycle
        ??notSpecifier:
        cmp byte [rax + rcx], END_STR_SYM
        jne ??notEndStr
            mov rsi, partStrIndexes
            
            call saveStartStrPart

        ??notEndStr:
        inc rcx 
    jmp ??startCycle
    ??endCycle:
    ret 

;-----------------------------------------------------------------------
; saves begins of string parts
; Entry: rax = prevStrPartStart 
;        rbx = MsgLen
; Exit:  rdx = amount specifiers
; Exp:   nop
; Destr: rax, rbx, rcx, rdx, r8b
;-----------------------------------------------------------------------
saveStartStrPart:
    inc rdx
    mov r8b, byte [rsi + rdx - 1d] 
    add r8b, cl
    mov byte [rsi + rdx], r8b

    sub rbx, rcx
    add rax, rcx

    xor rcx, rcx

    ret 

;-----------------------------------------------------------------------
; handles str parts
; Entry: rax = Msg 
;        rbx = MsgLen
;        rdx = strPartsAmount
;        rdi = specifiersAmount
;        [rbp + 16 + i * 8] = first arg
;        ....
; Exit:  no
; Exp:   nop
; Destr: rax, rbx, rcx, rsi, rdi, r8, r9, r10, r11
;-----------------------------------------------------------------------
handleStrParts:
    xor rax, rax
    xor rcx, rcx
    mov rsi, Msg

    xor r8, r8  ; r8 contains cur printBuffer position 
    xor r9, r9  ; r9b is used to transfer specifier type in its handler  
    xor r10, r10
    mov r10, 1

    ; handle all str parts
    mov rcx, rdx
    ??handleStr:
        mov r11, rdx 
        sub r11, rcx
        mov al, byte [partStrIndexes + r11]
        cmp byte [rsi + rax], SPECIFIER_SYMBOL
        je ??specifierCase
            push rcx 
            push rsi 
            push rdi

            ; put in cl length current part str
            mov cl, byte [partStrIndexes + r11 + 1d]
            sub cl, byte [partStrIndexes + r11]

            ; count current printBuffer position
            mov rdi, printBuffer
            add rdi, r8

            ; count current str position            
            add rsi, rax

            add r8, rcx
            call handleStrPart

            pop rdi
            pop rsi 
            pop rcx

            jmp ??strCase

        ??specifierCase:
        ; r10 contains number of specifier to handle
        ; put in rax argument for specifier from stack
            push rcx 
            push rsi 
            push rdi

            mov r9b, [rsi + rax + 1]

            mov r13, [rbp + 16 + 8 * r10]

            call handleSpecifier
            inc r10

            ; count current printBuffer position
            mov rdi, printBuffer
            add rdi, r8

            ; count current str position            
            mov rsi, saveBuffer

            mov rcx, r14
            rep movsb

            add r8, r14

            pop rdi
            pop rsi     
            pop rcx    
        ??strCase:
    loop ??handleStr

    ret

;-----------------------------------------------------------------------
; handles str part case
; Entry: rsi = curStrBufferPtr
;        rdi = curPrintBufferPtr
; Exit:  no
; Exp:   nop
; Destr: rsi, rdi
;-----------------------------------------------------------------------
handleStrPart:  
    
    ??handleByte:
        movsb
    loop ??handleByte

    mov byte [rdi], END_STR_SYM

    ret

;-----------------------------------------------------------------------
; handles specifiers
; Entry: r9b = specifierTypeSym
;        rax = argument specifier
; Exit:  no
; Exp:   nop
; Destr: r9b
;-----------------------------------------------------------------------
handleSpecifier:
    jmp [specifierHandlersJmpTable + r9 * 8]

    ret 

caseWrong:
    mov rax, 0x01
    mov rdi, 1d
    mov rsi, wrongSpecifier
    mov rdx, wrongSpecifierLen
    syscall

    mov rax, 0x3C
    xor rdi, rdi
    syscall
casePercent:
    push rax
    push rsi
    xor r14, r14
    inc r14
    dec r10 

    mov rdi, saveBuffer
    mov rax, '%'
    stosb


    pop rsi 
    pop rax
    ret 
caseBin:
    push rax
    push rcx
    push rsi
    push rdi

    xor r14, r14
    mov r15b, 0d  ; flag to start print digits

    mov rdi, saveBuffer
    mov rcx, 64d

    mov r12, 8000000000000000h ; mask for reg nibble

    ; msb handle 
    mov rax, r13
    and rax, r12
    shl rax, 63

    cmp al, 0d
    je .skipChangeFlagHighDig
        mov r15b, 1d
    .skipChangeFlagHighDig:

    cmp r15b, 0d
    je .notSignNumHighDig
        add rax, DIFFERENCE_NUM_ASCII_L9 
        stosb
        inc r14
    .notSignNumHighDig:

    .hexToASCII:
        mov rax, r13
        and rax, r12

        mov rsi, rcx
        sub rsi, 1d

        push rcx 
        mov rcx, rsi
        shr rax, cl
        pop rcx 

        
        ; block exist for printing only significant digits(don't print numbers till first non zero)
        cmp al, 0d
        je .skipChangeFlag
            mov r15b, 1d
        .skipChangeFlag:

        call convertNibbleToASCII   

        shr r12, 1

        cmp r15b, 0d
        je .notSignNum
            stosb
            inc r14
        .notSignNum:
    loop .hexToASCII

    mov byte [rdi], END_STR_SYM

    pop rdi
    pop rsi
    pop rcx
    pop rax

    ret 
caseChar:
    push rax
    push rsi
    xor r14, r14
    inc r14 

    mov rdi, saveBuffer
    mov rax, r13
    stosb


    pop rsi 
    pop rax

    ret 
caseDec:
    ret 
caseOct:
    push rax
    push rcx
    push rsi
    push rdi

    xor r14, r14
    mov r15b, 0d  ; flag to start print digits

    mov rdi, saveBuffer
    mov rcx, 21d

    mov r12, 07000000000000000h ; mask for reg nibble

    ; msb handle 
    mov rax, r13
    and rax, r12
    shl rax, 63

    cmp al, 0d
    je .skipChangeFlagHighDig
        mov r15b, 1d
    .skipChangeFlagHighDig:

    cmp r15b, 0d
    je .notSignNumHighDig
        add rax, DIFFERENCE_NUM_ASCII_L9 
        stosb
        inc r14
    .notSignNumHighDig:

    .hexToASCII:
        mov rax, r13
        and rax, r12

        mov rsi, rcx
        sub rsi, 1d
        lea rsi, [rsi + rsi * 2]

        push rcx 
        mov rcx, rsi
        shr rax, cl
        pop rcx 

        
        ; block exist for printing only significant digits(don't print numbers till first non zero)
        cmp al, 0d
        je .skipChangeFlag
            mov r15b, 1d
        .skipChangeFlag:

        call convertNibbleToASCII   

        shr r12, 3

        cmp r15b, 0d
        je .notSignNum
            stosb
            inc r14
        .notSignNum:
    loop .hexToASCII

    mov byte [rdi], END_STR_SYM

    pop rdi
    pop rsi
    pop rcx
    pop rax
    ret 
caseString:
    ret 

;-----------------------------------------------------------------------
; converts reg value to showable hex
; Entry: r13 = argument specifier
; Exit:  r14 = amount of symbols drawn 
; Exp:   nop
; Destr: r12, r13, r14, r15
;-----------------------------------------------------------------------

caseHex:
    push rax
    push rcx
    push rsi
    push rdi

    xor r14, r14
    mov r15b, 0d  ; flag to start print digits

    mov rdi, saveBuffer
    mov rcx, 16d

    mov r12, 0f000000000000000h ; mask for reg nibble

    .hexToASCII:
        mov rax, r13
        and rax, r12

        mov rsi, rcx
        sub rsi, 1d
        shl rsi, 2

        push rcx 
        mov rcx, rsi
        shr rax, cl
        pop rcx 

        
        ; block exist for printing only significant digits(don't print numbers till first non zero)
        cmp al, 0d
        je .skipChangeFlag
            mov r15b, 1d
        .skipChangeFlag:

        call convertNibbleToASCII   

        shr r12, 4

        cmp r15b, 0d
        je .notSignNum
            stosb
            inc r14
        .notSignNum:
    loop .hexToASCII

    mov byte [rdi], END_STR_SYM

    pop rdi
    pop rsi
    pop rcx
    pop rax
    ret

; ;-----------------------------------------------------------------------
; ; prepares number pow2 for show
; ; Entry: r13 = argument specifier
; ;        r8  = mask
; ;        r9  = amount digits masks
; ; Exit:  r14 = amount of symbols drawn 
; ; Exp:   nop
; ; Destr: r12, r13, r14, r15
; ;-----------------------------------------------------------------------
; makePow2NumReadyShow:
;     push rax
;     push rcx
;     push rsi
;     push rdi

;     xor r14, r14
;     mov r15b, 0d  ; flag to start print digits

;     mov rdi, saveBuffer
;     mov rcx, 16d

;     mov r12, r8 ; mask for reg nibble

;     hexToASCII:
;         mov rax, r13
;         and rax, r12

;         mov rsi, rcx
;         sub rsi, 1d
;         shl rsi, 2

;         push rcx 
;         mov rcx, rsi
;         shr rax, cl
;         pop rcx 

        
;         ; block exist for printing only significant digits(don't print numbers till first non zero)
;         cmp al, 0d
;         je ??skipChangeFlag
;             mov r15b, 1d
;         ??skipChangeFlag:

;         call convertNibbleToASCII   

;         shr r12, 4

;         cmp r15b, 0d
;         je ??notSignNum
;             stosb
;             inc r14
;         ??notSignNum:
;     loop hexToASCII

;     mov byte [rdi], END_STR_SYM

;     pop rdi
;     pop rsi
;     pop rcx
;     pop rax
;     ret


;-----------------------------------------------------------------------
; converts number in nibble to ASCII
; Entry: rax = nibble
;         
; Exit:  rax = ASCII code
; Exp:   no
; Destr: ax
;-----------------------------------------------------------------------
convertNibbleToASCII:
    ; case <= 9

    cmp rax, 9d
    jg ??G9
        add rax, DIFFERENCE_NUM_ASCII_L9
        jmp ??end

    ??G9:

    ; case > 9
    
    add rax, DIFFERENCE_NUM_ASCII_G9

    ??end:
    ret 

section .rodata
align 8
specifierHandlersJmpTable:
    ; 0..36
    times 37 dq caseWrong

    ; 37 = '%'
    dq casePercent

    ; 38..97
    times (98 - 38) dq caseWrong

    ; 98 = 'b'
    dq caseBin

    ; 99 = 'c'
    dq caseChar

    ; 100 = 'd'
    dq caseDec

    ; 101..110
    times (111 - 101) dq caseWrong

    ; 111 = 'o'
    dq caseOct

    ; 112..114
    times (115 - 112) dq caseWrong

    ; 115 = 's'
    dq caseString

    ; 116..119
    times (120 - 116) dq caseWrong

    ; 120 = 'x'
    dq caseHex

    ; till 256
    times (256 - 121) dq caseWrong


section .data

Msg:    db "testStr %c and %c %% fdsa", 0x0a
MsgLen    equ $ - Msg

partStrIndexes  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, END_STR_SYM

saveBuffer:     db 100 dup(0), END_STR_SYM
printBuffer:    db 100 dup(0), END_STR_SYM

printBufferLen equ $ - printBuffer

wrongSpecifier:    db "ERROR: wrongSpecifier", 0x0a
wrongSpecifierLen    equ $ - wrongSpecifier
