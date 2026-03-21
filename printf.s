section .text

global _start

SPECIFIER_SYMBOL          equ '%'

DIFFERENCE_NUM_ASCII_L9   equ 48d
DIFFERENCE_NUM_ASCII_G9   equ 55d
NEW_LINE_SYM              equ 0x0a
END_STR_SYM               equ 0x0

MAX_DEC_NUM_LEN           equ 20d


_start:
    push fillStr
    push -34655

    ; sub rsp, 8
    ; movss xmm0, [testFloat]
    ; movss [rsp], xmm0

    push 6516

    push Msg
    call newPrintf
    ; add rsp, 8

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
        cmp byte [rax + rcx], NEW_LINE_SYM
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

            ; count current str position            
            mov rsi, saveBuffer

            call handleSpecifier
            inc r10

            ; count current printBuffer position
            mov rdi, printBuffer
            add rdi, r8

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
;        cl  = length of str
; Exit:  no
; Exp:   nop
; Destr: rsi, rdi
;-----------------------------------------------------------------------
handleStrPart:  
    
    ??handleByte:
        movsb
    loop ??handleByte

    mov byte [rdi], NEW_LINE_SYM

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

caseFloat:
    push rax
    push rcx
    push rsi
    push rdi


    


    pop rdi 
    pop rsi 
    pop rcx 
    pop rax 
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

    mov byte [rdi], NEW_LINE_SYM

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

;-----------------------------------------------------------------------
; handles specifiers
; Entry: r9b = specifierTypeSym
;        rax = argument specifier
; Exit:  no
; Exp:   nop
; Destr: r9b
;----------------------------------------------------------------------- 
caseDec:
    push rax
    push rcx
    push rsi
    push rdi    

    xor r14, r14

    mov rdi, saveBuffer + MAX_DEC_NUM_LEN - 1d

    mov rcx, MAX_DEC_NUM_LEN    
    .prepareSaveBuffer: 
        not rcx
        add rcx, 1d
        mov byte [rdi + rcx + 1], DIFFERENCE_NUM_ASCII_L9
        sub rcx, 1d
        not rcx
    loop .prepareSaveBuffer

    mov rcx, 31d
    mov r12, 40000000h ; mask for reg nibble

    xor r15b, r15b

    test r13d, 80000000h
    jns .notNegativeNum
        not r13
        inc r13
        mov r15b, 1d  ; flag to start print digits
    .notNegativeNum:

    .hexToASCII:
        mov rax, r13
        and rax, r12
        
        call subTenPows

        shr r12, 1

    loop .hexToASCII

    mov rsi, saveBuffer

    mov rcx, 19d    
    .fixOverfilledDigits: 

        mov al, byte [rsi + rcx]
        sub al, DIFFERENCE_NUM_ASCII_L9
        mov byte [rsi + rcx], DIFFERENCE_NUM_ASCII_L9
        call subTenPows

        dec rdi 
    loop .fixOverfilledDigits

    mov rcx, 19d
    .startFindFirstSignificantDigit:
        cmp byte [rsi], DIFFERENCE_NUM_ASCII_L9
        jne .endFindFirstSignificantDigit

        inc rsi
    loop .startFindFirstSignificantDigit
    .endFindFirstSignificantDigit:

    test r15b, 1d
    jz .notNegativeNum2
        dec rsi
        mov byte [rsi], '-'
    .notNegativeNum2:
    mov r14, rsi


    pop rdi
    pop rsi
    pop rcx
    pop rax

    mov rsi, r14 
    mov r14, saveBuffer + MAX_DEC_NUM_LEN
    sub r14, rsi

    ret 

subTenPows:
    push rbx
    push rcx 
    push rdx 


    ; prepare data rbx = curNumber to handle 
    mov rbx, rax
    mov rax, 1

    ; cycle 
    mov r9, 10
    
    xor rcx, rcx

    .startFindMaxPowTenInNum:   
    cmp rbx, rax  
    jl .endFindMaxPowTenInNum
        mul r9 
        inc rcx 
    jmp .startFindMaxPowTenInNum
    .endFindMaxPowTenInNum:

    ;division by 10 rax 
    mov rdx, 0xCCCCCCCCCCCCCCCD
    mul rdx
    shr rdx, 3
    mov rax, rdx
    
    dec rcx

    mov rdx, rcx
    ;divide in digits cycle 

    cmp r14, rdx
    jg  .notGreaterDigit
        mov r14, rdx
        add r14, 1d
    .notGreaterDigit:

    .divideNumInDigits:
    cmp rbx, 0d 
    jle .endDivideNumInDigits  

        .startOfCurPowTen:
        cmp rbx, rax
        jl .endOfCurPowTen 
            sub rbx, rax

            not rdx 
            add rdx, 1d
            add byte [rdi + rdx], 1
            sub rdx, 1d
            not rdx

        jmp .startOfCurPowTen  
        .endOfCurPowTen:

        dec rdx

        ;prepare next pow ten
        mov rcx, rdx
        mov rax, 1d

        .startGetNewPowTen:
        cmp rcx, 0d
        jle .endGetNewPowTen     
        .getNewPowTen:
            push rdx
            mul r9
            dec rcx
            pop rdx
        jmp .startGetNewPowTen 
        .endGetNewPowTen:

    jmp .divideNumInDigits

    .endDivideNumInDigits:

    pop rdx
    pop rcx 
    pop rbx
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

    mov byte [rdi], NEW_LINE_SYM

    pop rdi
    pop rsi
    pop rcx
    pop rax
    ret 
caseString:
    push rdi
    push rsi
    
    xor r14, r14

    mov rsi, r13
    mov rdi, saveBuffer
    .handleByte:
        cmp byte [rsi], 0h
        je .end 

        movsb

        inc r14
    jmp .handleByte
    .end:

    pop rsi
    pop rdi
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

    mov byte [rdi], NEW_LINE_SYM

    pop rdi
    pop rsi
    pop rcx
    pop rax
    ret

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

    dq caseWrong

    dq caseFloat

    ; 101..110
    times (111 - 103) dq caseWrong

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

Msg:    db "testStr %d and %d %s fdsa", 0x0a
MsgLen    equ $ - Msg

fillStr db "filled", 0x0

testFloat dd 3.14

partStrIndexes  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NEW_LINE_SYM

saveBuffer:     db 100 dup(0), NEW_LINE_SYM
printBuffer:    db 100 dup(0), NEW_LINE_SYM

printBufferLen equ $ - printBuffer

wrongSpecifier:    db "ERROR: wrongSpecifier", 0x0a
wrongSpecifierLen    equ $ - wrongSpecifier
