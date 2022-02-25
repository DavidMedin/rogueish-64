segment .text

Label_Move_Up:
    push rbp
    mov rbp, rsp
    ; Iterate through all entities
    ; Dec the y value of the position component
        ;of whom have both position and label
    mov rbx, entity_list
    push rbx
    .each_top:
        cmp rbx, qword[ent_list_end]
        jge .end
        mov qword[rbp-0x8], rbx
        cmp qword[rbx], 0
        je .cont
        mov rdi, qword[rbx]
        mov rsi, 2
        call GetComponent
        cmp rax, 0
        je .cont
        cmp qword[rax+Label.can_rise], 0
        je .cont
        ; push rax
        mov rdi, qword[rbp-0x8]
        mov rdi, [rdi]
        mov rsi, 3
        call GetComponent
        cmp rax, 0
        je .cont
            ; more code here
            dec qword[rax+Position.y]
            cmp qword[rax+Position.y], 0
            jge .cont
                ;out of bounds! kill me
                mov rdi, [rbp-0x8]
                call DestroyEntity
        .cont:
        ; pop rbx
        mov rbx, [rbp-0x8]
        add rbx, 0x8
        jmp .each_top
    .end:
    add rsp, 0x8
    mov rsp, rbp
    pop rbp
    ret