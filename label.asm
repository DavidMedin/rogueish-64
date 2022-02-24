segment .text

Label_Move_Up:
    push rbp
    mov rbp, rsp
    ; Iterate through all entities
    ; Dec the y value of the position component
        ;of whom have both position and label
    mov rbx, entity_list
    .each_top:
        cmp rbx, qword[ent_list_end]
        je .end
        push rbx
        cmp qword[rbx], 0
        je .cont
        mov rdi, qword[rbx]
        mov rsi, 2
        call GetComponent
        cmp rax, 0
        je .cont
        cmp qword[rax+Label.can_rise], 0
        je .cont
        push rax
        mov rdi, qword[rbp-0x8]
        mov rdi, [rdi]
        mov rsi, 3
        call GetComponent
        cmp rax, 0
        je .cont
            ; more code here
            dec qword[rax+Position.y]
        .cont:
        pop rbx
        add rbx, 0x8
        jmp .each_top
    .end:
    mov rsp, rbp
    pop rbp
    ret