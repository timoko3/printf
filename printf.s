section .text

global _start

SPECIFIER_SYMBOL equ '%'
END_STR_SYM      equ 0x0a

_start:
    push 3
    push 2
    push 1
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
    mov rdx, MsgLen
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
; Exit:  no
; Exp:   nop
; Destr: rax, rbx, rcx, rsi, rdi, r8
;-----------------------------------------------------------------------
handleStrParts:
    xor rax, rax
    xor rcx, rcx
    mov rsi, Msg

    xor r8, r8

    ; handle all str parts
    mov rcx, rdx
    ??handleStr:
        mov rdi, rdx 
        sub rdi, rcx
        mov al, byte [partStrIndexes + rdi]
        cmp byte [rsi + rax], SPECIFIER_SYMBOL
        je ??specifierCase
            push rcx 
            push rsi 
            push rdi

            ; put in cl length current part str
            mov cl, byte [partStrIndexes + rdi + 1d]
            sub cl, byte [partStrIndexes + rdi]

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

        ; call handleSpecifier
        ??strCase:
    loop ??handleStr

    ret

;-----------------------------------------------------------------------
; handles str part case
; Entry: rax = Msg 
;        rbx = MsgLen
;        rdx = strPartsAmount
;        rdi = specifiersAmount
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

; replaceSpecifiers:
;     ret 

section .data

Msg:    db "testStr%dand%dfdsa", 0x0a
MsgLen    equ $ - Msg

partStrIndexes  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, END_STR_SYM

saveBuffer:     db 100 dup(0), END_STR_SYM
printBuffer:    db 100 dup(0), END_STR_SYM
