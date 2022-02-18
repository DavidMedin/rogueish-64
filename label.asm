segment .text

Label_Move_Up:
    push rbp
    mov rbp, rsp
    ; Iterate through all entities
    ; Dec the y value of the position component
        ;of whom have both position and label
    mov rbx, entity_list
    .each_top:
        cmp ebx, qword[ent_list_end]
        je .end
        push rbx
        mov rdi, rbx
        mov rsi, 2
        call GetComponent
        cmp rax, 0
        
        add ebx, 0x8
        jmp .each_top
    .end:
    mov rsp, rbp
    pop rbp
    ret