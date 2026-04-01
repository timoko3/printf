default rel
section .text

global _start

global myPrintfWrap

extern printf 
extern sprintf

SPECIFIER_SYMBOL          equ '%'

BUFFER_SIZE               equ 100d
FLOAT_BUFFER_SIZE         equ 100d

DIFFERENCE_NUM_ASCII_L9   equ 48d
DIFFERENCE_NUM_ASCII_G9   equ 55d
NEW_LINE_SYM              equ 0x0a
END_STR_SYM               equ 0x0

MAX_DEC_NUM_LEN           equ 20d

FLOAT_BIAS                equ 127d
FLOAT_AFTER_DOT_LEN	      equ 6d

; _start:
;     push 0123
;     push 33
;     push 31
;     push 100
;     push 3802
;     push fillStr

;     ; sub rsp, 8
;     ; movss xmm0, [testFloat]
;     ; movss [rsp], xmm0

;     push -1

;     push Msg
;     call newPrintf
;     add rsp, 8

;     mov rax, 0x3C
;     xor rdi, rdi
;     syscall


myPrintfWrap:
    push rbp 
    mov rbp, rsp 

    lea r11, [xmmAmount]
    mov byte [r11], al

    mov r14, rdx 
    mov r13, rdi
    mov r15, rsi
    mov r11, rcx

    mov rsi, rdi
    call strlen

    ; empty str case
    cmp rcx, 0d
    je .emptyStr

    mov rax, r13
    mov rbx, rcx 

    xor rdi, rdi        
    call countSpecifiers
    mov r12, rdi

    mov rcx, r11
    mov rsi, r15
    mov rdi, r13
    mov rdx, r14

    mov rax, r12
    imul rax, 8
    sub rsp, rax 

    xor r13, r13   ; index default args = 0
    xor r14, r14   ; non float     args = 0
    xor r15, r15   ; index float   args = 0

    .passArgsLoop:
        cmp r13, r12
        jge .argFillDone
        
        lea r11, [floatPosBuffer]

        cmp byte [r11 + r13], 1d
        je  .floatCase

    .intCase:
        cmp r14, 0d 
        je .useRsi
        cmp r14, 1d    
        je .useRdx
        cmp r14, 2d    
        je .useRcx
        cmp r14, 3d    
        je .useR8
        cmp r14, 4d    
        je .useR9
        jmp .intFromStack

    .useRsi:
        mov rax, rsi
        jmp .storeInt
    .useRdx:
        mov rax, rdx
        jmp .storeInt
    .useRcx:
        mov rax, rcx
        jmp .storeInt
    .useR8:
        mov rax, r8
        jmp .storeInt
    .useR9:
        mov rax, r9
        jmp .storeInt

    .intFromStack:
        mov rax, [rbp + 16 + (r14 - 5) * 8]
    
    .storeInt:
        mov [rsp + r13 * 8], rax
        inc r14
        inc r13 
        jmp .passArgsLoop

    .floatCase:
        cmp r15, 0d 
        je .useXMM0
        cmp r15, 1d 
        je .useXMM1
        cmp r15, 2d 
        je .useXMM2
        cmp r15, 3d 
        je .useXMM3
        cmp r15, 4d
        je .useXMM4
        cmp r15, 5d
        je .useXMM5
        cmp r15, 6d
        je .useXMM6
        cmp r15, 7d
        je .useXMM7

        jmp .nextFloat
        
    .useXMM0:
        movsd [rsp + r13 * 8], xmm0
        jmp .nextFloat
    .useXMM1:
        movsd [rsp + r13 * 8], xmm1
        jmp .nextFloat
    .useXMM2:
        movsd [rsp + r13 * 8], xmm2
        jmp .nextFloat
    .useXMM3:
        movsd [rsp + r13 * 8], xmm3
        jmp .nextFloat
    .useXMM4:
        movsd [rsp + r13 * 8], xmm4
        jmp .nextFloat
    .useXMM5:
        movsd [rsp + r13 * 8], xmm5
        jmp .nextFloat
    .useXMM6:
        movsd [rsp + r13 * 8], xmm6
        jmp .nextFloat
    .useXMM7:
        movsd [rsp + r13 * 8], xmm7
        jmp .nextFloat

    .floatFromStack:
        mov rax, [rsp + 16 + (r15 - 8) * 8]
        mov [rsp + r13 * 8], rax

    .nextFloat: 
        inc r15     
        inc r13         
        jmp .passArgsLoop

    .argFillDone:

    push rdi
    call newPrintf
    pop rdi

    cmp r12, 5d
    jg .clearOnlyRegArgs

        mov  rax, r12
        imul rax, 8
        add  rsp, rax
        
        xor r12, r12


        jmp .callStdPrintf
    .clearOnlyRegArgs:
    ; call of std printf
        sub  r12, 5d 

        mov  rax, 5d
        imul rax, 8
        add  rsp, rax

    .callStdPrintf:

    mov rax, rsp
    and rax, 15
    jz .aligned
        sub rsp, 8
        mov rbx, 1 
    .aligned:
    mov al, [xmmAmount]
    call printf wrt ..plt

    cmp rbx, 1d
    je .restoreStack

    jmp .doneCallStdPrintf

    .restoreStack:
        add rsp, 8

    .doneCallStdPrintf:

    mov  rax, r12
    imul rax, 8
    add  rsp, rax



    .emptyStr:

    pop rbp
    ret 

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

    push r12

    ; to saveArgs for new printf
    push rsi
    push rdx
    push rcx
    push r8
    push r9

    lea rax, [printBuffer]
    mov rbx, BUFFER_SIZE
    call clearBuffer

    mov rsi, [rbp + 16]
    call strlen

    mov rbx, rcx
    mov rax, [rbp + 16]
    call countSpecifiers 
    
    mov rsi, [rbp + 16]
    call strlen
    mov rbx, rcx
    mov rax, [rbp + 16]
    
    call handleStrParts

    lea rsi, [printBuffer]
    call strlen

    mov rax, 0x01
    mov rdi, 1d
    lea rsi, [printBuffer]
    mov rdx, rcx
    syscall

    pop r9
    pop r8
    pop rcx
    pop rdx
    pop rsi

    pop r12

    pop rbp
    ret

;-----------------------------------------------------------------------
; count amount of specifiers in string
; Entry: rax = Msg 
;        rbx = MsgLen
; Exit:  rdx = amount str parts
;        rdi = amount specifiers
; Exp:   nop
; Destr: rax, rbx, rcx, rdx, rsi, rdi, r8
;-----------------------------------------------------------------------
countSpecifiers:
    push r8

    xor rdx, rdx
    xor rdi, rdi
    xor rcx, rcx 
    
    ; inc rdx

    ??startCycle:
    cmp rcx, rbx
    jge ??endCycle
        cmp byte [rax + rcx], SPECIFIER_SYMBOL
        jne ??notSpecifier
            ; saveFloatArgNum
            cmp byte [rax + rcx + 1], 'f'
            jne .notFloat
                lea r8, [floatPosBuffer]
                mov byte [r8 + rdi], 1d
                jmp .float
            .notFloat:
                lea r8, [floatPosBuffer]
                mov byte [r8 + rdi], 0d
            .float: 
            

            inc rdi
            lea rsi, [partStrIndexes]

            cmp rdi, 1d
            je .notSave

            call saveStartStrPart

            .notSave:

            add rcx, 2

            cmp byte [rax + rcx], SPECIFIER_SYMBOL
            je .nextSpecifier

            call saveStartStrPart

            .nextSpecifier:

            jmp ??startCycle
        ??notSpecifier:
        cmp byte [rax + rcx], NEW_LINE_SYM
        jne ??notEndStr
            lea rsi, [partStrIndexes]
            
            call saveStartStrPart

        ??notEndStr:
        inc rcx 
    jmp ??startCycle
    ??endCycle:

    pop r8
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
    mov rsi, rax
    xor rax, rax
    xor rcx, rcx

    xor r8, r8  ; r8 contains cur printBuffer position 
    xor r9, r9  ; r9b is used to transfer specifier type in its handler  
    xor r10, r10
    mov r10, 1

    ; handle all str parts
    mov rcx, rdx
    ??handleStr:
        mov r11, rdx 
        sub r11, rcx

        lea rbx, [partStrIndexes]

        mov al, byte [rbx + r11]
        cmp byte [rsi + rax], SPECIFIER_SYMBOL
        je ??specifierCase
            push rcx 
            push rsi 
            push rdi

            ; put in cl length current part str
            
            mov cl, byte [rbx + r11 + 1d]
            sub cl, byte [rbx + r11]

            ; count current printBuffer position
            lea rdi, [printBuffer]
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
            lea rsi, [saveBuffer]

            call handleSpecifier
            inc r10

            ; count current printBuffer position
            lea rdi, [printBuffer]
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
    
    cmp rcx, 0d 
    je .notCopyStr 

    .handleByte:
        movsb
    loop .handleByte

    .notCopyStr:

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
    lea r15, [specifierHandlersJmpTable]
    jmp [r15 + r9 * 8]

    ret 

caseFloat:
; start main part of a function 
    push rax
    push rbx
    push rcx
    push rdx 
    push rsi
    push rdi
    push r8
    push r9
    push r10

    mov r12, 0x7ff0000000000000
    mov rax, r13
    and rax, r12

    cmp rax, r12
    jne .notSpecial

    mov r12, 0x000fffffffffffff
    mov rax, r13
    and rax, r12

    test rax, rax
    jz .isInf

    ; иначе NaN
    ; === NaN case ===
    lea r15, [saveBuffer]
    mov byte [r15],   'N'
    mov byte [r15+1], 'A'
    mov byte [r15+2], 'N'
    mov r14, 3

    pop r10
    pop r9
    pop r8
    pop rdi 
    pop rsi 
    pop rdx
    pop rcx 
    pop rbx
    pop rax
    ret

    .isInf:
    lea r15, [saveBuffer]
    mov byte [r15 + 1], 'I'
    mov byte [r15 + 2], 'N'
    mov byte [r15 + 3], 'F'
    mov r14, 3

    mov r12, 0x8000000000000000
    test r13, r12
    jz .notNegativeInf
        inc r14 
        mov byte [r15], '-'
    .notNegativeInf:

    pop r10
    pop r9
    pop r8
    pop rdi 
    pop rsi 
    pop rdx
    pop rcx 
    pop rbx
    pop rax
    ret

    .notSpecial:
        
    xor r14, r14

    lea rdi, [saveBuffer  + MAX_DEC_NUM_LEN - 1d]
    lea rsi, [floatBuffer + MAX_DEC_NUM_LEN - 1d]

    mov rcx, MAX_DEC_NUM_LEN    
    .prepareSaveBuffer: 
        not rcx
        add rcx, 1d
        mov byte [rdi + rcx + 1], DIFFERENCE_NUM_ASCII_L9
        mov byte [rsi + rcx + 1], DIFFERENCE_NUM_ASCII_L9
        sub rcx, 1d
        not rcx
    loop .prepareSaveBuffer
    
    ; handle exp

    mov r12, 0x7ff0000000000000 ; mask for exp    
    mov rcx, 8d    
    
    mov rax, r13
    and rax, r12

    shr rax, 52d

    mov rdx, rax
    sub rdx, 1023

    ; denormalized case
    cmp rax, 0d
    je .denormalized

    cmp rdx, 20d
    jge .denormalized

    cmp rdx, 0d
    jle .denormalized

    jmp .normalized

    .denormalized:
        movq xmm0, r13
        lea rsi, [deNormFloatCaseStr]
        lea rdi, [saveBuffer]

        mov rax, 1d

        test rsp, 15d
        jz .aligned
            sub rsp, 8d ;aling stack
            mov byte [alignFlag], 1d 
            jmp .sprintfPtr
        .aligned:

        mov byte [alignFlag], 0d
        .sprintfPtr:
        call sprintf wrt ..plt
        cmp byte [alignFlag], 1d
        jne .notBeenAligned
            add rsp, 8d
        .notBeenAligned:

        mov rax, 0d 

        ; test value

        lea rsi, [saveBuffer]
        call strlen

        mov r14, rcx

        pop r10
        pop r9
        pop r8
        pop rdi 
        pop rsi 
        pop rdx
        pop rcx 
        pop rbx
        pop rax
        ret
    .normalized:

    ; normalized case

    ; whole part
    mov rax, r13
    mov  r12, 0x000fffffffffffff
    and rax, r12

    ; zero mantis case

    cmp rax, 0d
    jz .denormalized

    mov  r12, 0x0010000000000000
    or rax, r12

    mov  r12, 0010000000000000h 
    mov rcx, rdx
    mov rbx, r12 
    
    .createMask:
        shr rbx, 1d
        add r12, rbx 
    loop .createMask 

    xor rcx, rcx
    mov rcx, 52
    sub rcx, rdx

    and rax, r12
    shr rax, cl

    mov r15, rax

    ; saveToBuffer
    xor r14, r14

    mov rcx, 53d
    mov r12, 0010000000000000h 

    .hexToASCIIWhlPrt:
        mov rax, r15
        and rax, r12
        
        call subTenPows

        shr r12, 1
    loop .hexToASCIIWhlPrt


    ;fix whole part overfilled digits
    lea rsi, [saveBuffer]
    mov rcx, 19d    
    .fixOverfilledDigits: 

        mov al, byte [rsi + rcx]
        sub al, DIFFERENCE_NUM_ASCII_L9
        mov byte [rsi + rcx], DIFFERENCE_NUM_ASCII_L9
        call subTenPows

        dec rdi 
    loop .fixOverfilledDigits

    ; mantis handle 
    mov r12, 0008000000000000h 
    ; which bits interpret as mantis
    mov rcx, rdx 
    shr r12, cl

    mov rcx, 52d 
    sub rcx, rdx


    mov r15, rcx 
    .hexToASCIIMantisPart:
        xor rax, rax
        mov rax, r13
        and rax, r12
        
        call mantisHandle

        shr r12, 1

    loop .hexToASCIIMantisPart

    lea rdi, [floatBuffer + 22d]
    lea rsi, [floatBuffer]
    mov rcx, 22d    
    .fixOverfilledDigitsMantis: 

        mov al, byte [rsi + rcx]
        sub al, DIFFERENCE_NUM_ASCII_L9
        mov byte [rsi + rcx], DIFFERENCE_NUM_ASCII_L9
        call subTenPows

        dec rdi 
    loop .fixOverfilledDigitsMantis

    ; start find first significant digit of whole part in saveBuffer
    lea rsi, [saveBuffer]
    mov rcx, 19d
    .startFindFirstSignificantDigit:
        cmp byte [rsi], DIFFERENCE_NUM_ASCII_L9
        jne .endFindFirstSignificantDigit

        inc rsi
    loop .startFindFirstSignificantDigit
    .endFindFirstSignificantDigit:
    mov r14, rsi

    ; copy mantissa part 
    lea r15, [saveBuffer]
    mov byte [r15 + MAX_DEC_NUM_LEN], '.'
    lea rsi, [floatBuffer]
    lea rdi, [r15 + MAX_DEC_NUM_LEN + 1]
    mov rcx, 6d ; 6 - threshold of unary accuracy
    rep movsb 
    

    mov r12, 0x8000000000000000
    test r13, r12
    jz .notNegative 
        dec r14
        mov byte [r14], '-'
    .notNegative:

    pop r10
    pop r9
    pop r8
    pop rdi 
    pop rsi 
    pop rdx
    pop rcx 
    pop rbx
    pop rax

    mov rsi, r14 
    lea r14, [saveBuffer + MAX_DEC_NUM_LEN + 7d]
    sub r14, rsi

    ret

mantisHandle:
    push rbx
    push rcx 
    push rdx 
    push r15

    lea rdi, [floatBuffer]

    sub rcx, r15 
    not rcx
    add rcx, 1d 

    add rdi, rcx

    ; put rax appropriate pow 5
    test rax, rax
    jz .zeroDigit
    mov rax, 1
    mov rbx, 5d
    inc rcx 
    .getAppropriatePowFive:
        mul rbx
    loop .getAppropriatePowFive
    

    call subTenPows

    .zeroDigit:

    pop r15 
    pop rdx
    pop rcx 
    pop rbx
    ret 

caseWrong:
    mov rax, 0x01
    mov rdi, 1d
    lea rsi, [wrongSpecifier]
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

    lea rdi, [saveBuffer]
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

    lea rdi, [saveBuffer]
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

    test r14, r14
    jnz .notInc
        mov rax, DIFFERENCE_NUM_ASCII_L9 
        stosb
        inc r14
    .notInc:

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

    lea rdi, [saveBuffer]
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

    lea rdi, [saveBuffer + MAX_DEC_NUM_LEN - 1d]

    mov rcx, MAX_DEC_NUM_LEN    
    .prepareSaveBuffer: 
        not rcx
        add rcx, 1d
        mov byte [rdi + rcx + 1], DIFFERENCE_NUM_ASCII_L9
        sub rcx, 1d
        not rcx
    loop .prepareSaveBuffer

    mov rcx, 32d
    mov r12, 80000000h

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

    lea rsi, [saveBuffer]

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
    lea r14, [saveBuffer + MAX_DEC_NUM_LEN]
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

    lea rdi, [saveBuffer]
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

    test r14, r14
    jnz .notInc
        mov rax, DIFFERENCE_NUM_ASCII_L9 
        stosb
        inc r14
    .notInc:

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
    lea rdi, [saveBuffer]
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

    lea rdi, [saveBuffer]
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

    test r14, r14
    jnz .notInc
        mov rax, DIFFERENCE_NUM_ASCII_L9 
        stosb
        inc r14
    .notInc:

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
    or rax, 20h
    ??end:
    ret 

;-----------------------------------------------------------------------
; counts amount of symbols in str with endStr symbol '$'
; Entry: rsi = pointer to the begin of str
; Exit:  rcx = length str
; Exp:   dh = ensStr symbol ASCII code
; Destr: ah, cx, di
;-----------------------------------------------------------------------

strlen:
	mov rdi, rsi
	xor rcx, rcx
	
	strlenCycle:
	mov al, byte [rdi]

	cmp al, END_STR_SYM
	je strlenEnd
	inc rdi

	inc rcx    ; increment symbols counter
	jmp strlenCycle
	strlenEnd:
	ret

;-----------------------------------------------------------------------
; fills buffer with 0 values
; Entry: rax = pointer to the begin of buffer
;        rbx = length buffer
;        cl  = symbol to clear with
; Exit:  
; Exp:   dh = ensStr symbol ASCII code
; Destr: ah, cx, di
;-----------------------------------------------------------------------
clearBuffer:
    mov rcx, rbx 
    .clear:
        mov byte [rax + rcx], 0d
    loop .clear 
    ret    

section .data

align 8
specifierHandlersJmpTable:
    
    times ('%'  -  0)     dq caseWrong  
                          dq casePercent ; '%'
    times ('b' - '%' - 1) dq caseWrong
                          dq caseBin     ; 'b'
                          dq caseChar    ; 'c'
                          dq caseDec     ; 'd'
                          dq caseWrong
                          dq caseFloat   ; 'f'
    times ('o' - 'f' - 1) dq caseWrong 
                          dq caseOct     ; 'o'
    times ('s' - 'o' - 1) dq caseWrong   
                          dq caseString  ; 's'
    times ('x' - 's' - 1) dq caseWrong 
                          dq caseHex     ; 'x'
    times (256 - 'x' - 1) dq caseWrong   

; Msg:    db "%d %s  %x %d%%%b%c", 0x0a, 0x0
; MsgLen    equ $ - Msg

; fillStr db "love", 0x0

alignFlag          db 0d
testFloat          dd 07F800f00h

partStrIndexes     db BUFFER_SIZE dup(0), NEW_LINE_SYM

saveBuffer:        db BUFFER_SIZE dup(0), NEW_LINE_SYM
printBuffer:       db BUFFER_SIZE dup(0), NEW_LINE_SYM

printBufferLen     equ $ - printBuffer

floatPosBuffer     db FLOAT_BUFFER_SIZE dup(0),   NEW_LINE_SYM
floatBuffer        db FLOAT_BUFFER_SIZE dup(30h), NEW_LINE_SYM

xmmAmount          db 0

deNormFloatCaseStr db "%g", 0h

wrongSpecifier:    db "ERROR: wrongSpecifier", 0x0a
wrongSpecifierLen  equ $ - wrongSpecifier

section .note.GNU-stack noalloc noexec nowrite progbits
