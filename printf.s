section .text

global _start

SPECIFIER_SYMBOL equ '%'

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
; Entry: [bp + 16] = Msg 
;        [bp + 16 + i * 8] = first arg
;        ....
; Exit:  no
; Exp:   nop
; Destr: rax, rdi, rsi, rdx
;-----------------------------------------------------------------------
newPrintf:
    push rbp 
    mov rbp, rsp 

    mov rbx, MsgLen
    mov rax, [rbp + 16d]
    call countSpecifiers 
    
    mov rbx, MsgLen
    mov rax, [rbp + 16d]
    ; call handleStrParts

    mov rax, 0x01
    mov rdi, 1d
    mov rsi, [rbp + 16d]
    mov rdx, MsgLen
    syscall

    pop rbp
    ret

;-----------------------------------------------------------------------
; count amount of specifiers in string
; Entry: rax = Msg 
;        rbx = MsgLen
; Exit:  rdx = amount specifiers
; Exp:   nop
; Destr: rax, rbx, rcx, rdx, rsi, r8b 
;-----------------------------------------------------------------------
countSpecifiers:

    xor rcx, rcx 
    ??startCycle:
    cmp rcx, rbx
    jge ??endCycle
        cmp byte [rax + rcx], SPECIFIER_SYMBOL
        jne ??notSpecifier
            mov rsi, partStrIndexes
            
            call saveStartStrPart

            ;skip specifier part
            add rcx, 2
            call saveStartStrPart

            jmp ??startCycle
        ??notSpecifier:
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
; count amount of specifiers in string
; Entry: rax = Msg 
;        rbx = MsgLen
; Exit:  no
; Exp:   nop
; Destr: rcx, rax, rdx
;-----------------------------------------------------------------------
; handleStrParts:
;     xor rcx, rcx

;     mov rcx, rbx
;     ??handleStr:
;         push 
;         call handleStrPart

;     loop handleStr

;     ret

; handleStrPart:  
;     mov rsi, rax
;     mov rdi, saveBuffer
;     ??handleByte:
;         cmp byte [rax], SPECIFIER_SYMBOL
;         jne ??copy
            
;         ??copy
;         stosb
;     loop handleByte
;     ret

; replaceSpecifiers:
;     ret 
section .data

Msg:    db "testStr%dand%d", 0x0a
MsgLen    equ $ - Msg

partStrIndexes  db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x0a

saveBuffer:     db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0x0a
printBuffer:    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0x0a