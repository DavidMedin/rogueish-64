segment .data
    inspect_format: db "%x",0

segment .text
extern sprintf


;                   rdi         rsi  rdx     rcx           r8          r9
;void CopyText(buffer* buffer,int x,int y,char* string,int width, int height)
;                                                 TODO:|    For word wrap   |
CopyText:
    push rbp
    mov rbp, rsp
    mov rbx, rcx
    push r8 ; width -> -0x8
    push r9; height -> -0x10
    push rcx ; string -> -0x18
    call IndexBuffer ; it just works
    mov r8, [rbp - 0x8]
    mov r9, [rbp - 0x10]
    mov rbx,[rbp - 0x18]

    push 0; x ->  -0x20
    push 0; y -> -0x28
    
    ; mov rbx, qword[rbp-0x18] ok wtf
    push 0
    cmp rax,0
    jne .top
        .fail:
        push rdi
        mov rdi, copy_text_err
        call printf
        pop rdi
        jmp .end
    .top:
        cmp byte[rbx], 0
        je .end
        cmp r8, 0
        je .no_skip
        cmp qword[rbp-0x20],r8
        jnge .no_skip
            ; greater than or equal to width
            mov qword[rbp-0x20], 0 ; reset x
            inc qword[rbp-0x28] ; move cursor y down 1
            inc rdx ;| input args. x is already in rsi
                    ;|, and we just need to add 1 to y.
            push rbx
            call IndexBuffer ; get new place to write to -> rax
            mov r8, [rbp - 0x8] ; restore r8 and r9
            mov r9, [rbp - 0x10]
            pop rbx ; restore pointer into input string
            cmp rax, 0 ; potentially fail
            je .fail

        .no_skip:
        
        mov cl, byte[rbx]
        mov [rax], cl
        
        ; increment
        add rax,2
        inc rbx
        inc qword[rbp-0x20] ; x
        inc qword[rsp]
        jmp .top
    .end:
    add rsp, 0x18
    pop rcx
    pop r9
    pop r8
    mov rsp, rbp
    pop rbp
    ret
copy_text_err: db "Attepted to write text into invalid space! (%d, %d)",10,0



;void DrawInspector(buffer* buffer)
DrawInspector:
    push rbp
    mov rbp, rsp
    push rdi ; save buffer
    sub rsp, 0x18 ; only need ~0x10, but stack
                ; must be 16 byte aligned
                ; for "complex" functions

    mov rbx, entity_list
    mov rcx, 0
    .top:
        cmp rbx, [ent_list_end]
        je .end

        push rbx
        push rcx
        
        lea rdi, [rbp-0x20]
        mov rsi, inspect_format
        mov rdx, rbx
        mov rax, 0; no floating points args for 
        ;               variadic function
        call sprintf

        mov rdi, [rbp-8]; recall buffer
        mov rsi, 1
        ; pop rcx
        mov rdx, 1
        add rdx, [rsp]
        lea rcx, [rbp-0x20]
        mov r8, 0
        call CopyText

        pop rcx;|-> inc y direction
        inc rcx;|
        pop rbx
        add rbx, 8
        jmp .top
    .end:

    add rsp, 0x18
    pop rdi
    mov rsp, rbp
    pop rbp
    ret