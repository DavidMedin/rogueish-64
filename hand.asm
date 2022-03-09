segment .text

PickUp:
    push rbp
    mov rbp, rsp

    ; find entities at location
    ; push qword[hero_data]
    mov rdi, [hero_data]
    mov rsi, 3
    call GetComponent
    cmp rax, 0
    je .no_position
    push rax
    mov rsi, 5
    call GetComponent
    cmp rax, 0
    je .no_hands
    push rax
    
    mov rax, entity_list
    jmp .go
    .try_again:
        add rax, 0x8
    .go:
    mov rcx, [rbp-0x8]
    mov rdi, [rcx+Position.x]
    mov rsi, [rcx+Position.y]
    mov rdx, rax
    call FindEntity
    cmp rax, 0
    je .no_find
        ; found
        mov r8, rax
        mov rcx, [rax]
        cmp rcx, [hero_data]
        je .try_again
        
        ;pick up item now
        mov rdi, rcx
        mov rsi, 4
        call GetComponent ; doens't eat rdi or rsi
        cmp rax, 0
        je .try_again

        ; contains the item component
        ; mov rcx, [rbp-0x10]
        mov rdx, [hero_data]
        mov [rax+Item.parent], rdx
        mov rdx, [rbp-0x10]
        mov [rdx+Hand.item], r8

        jmp .end
    .no_find:
        mov rdi, PickUpMiss
        mov rax, 0
        call printf
        jmp .end
    .no_position:
        mov rdi, PickUpBadProgrammer
        mov rax, 0
        call printf
        jmp .fail
    .no_hands:
        mov rdi, PickUpUnHaneded
        mov rax, 0
        call printf
        add rsp, 0x8
        jmp .fail
    .end:
    add rsp, 0x10
    .fail:
    mov rsp, rbp
    pop rbp
    ret
PickUpUnHaneded: db "You can't pick up items without hands silly!",10,0
PickUpMiss: db "No item is on the floor there!",10,0
PickUpBadProgrammer: db "You dingus, that 'hero' doesn't have a position component!",10,0

;void Attack(Entity** attackee)
Attack:
    push rbp
    mov rbp, rsp
    push rdi    ; rbp -0x8
    ; mov rax, qword[rdi] ; rax = place in ent_list
    mov rdi, qword[rdi]
    push rax
    mov rsi, 1
    call GetComponent
    ; pop rbx
    mov rbx,[rbp-0x8];  rbp-0x8 = first arg
    pop rcx
    cmp rax, 0
    je .end
    push rcx

    ;Is a person
    mov rcx, rax
    sub qword[rcx+Person.health], 10
    
    push rbx
    push rax
    push rcx
    ;create damage label
    mov rdi, 2
    call MakeEntity
    mov rdi, [rax]
    mov qword[rdi+Label.can_rise], 1

    push rdi

    sub rsp, 0x8
    mov rdi, rsp
    stacker
    ; sub rsp, 0x10; asprintf wants 16-byte aligned
    ;use sprintf
    mov rsi, number_fmt
    mov rdx, 10
    mov rax, 0
    call asprintf
    unstacker
    ;write string
    mov rbx, qword[rsp+8] ; was +10
    mov rax, [rsp]
    mov qword[rbx+Label.string], rax
    ; add rsp, 0x10
    add rsp, 0x8; remove the string
    mov qword[rbx+Label.free_str], 1

    pop rdi
    mov rsi, 3
    call AddComponent
    ; mov rbx, [rsp+0x20]
    mov rbx, [rbp-0x8]
    mov rbx, [rbx]
    push rax
    mov rdi, rbx
    mov rsi, 3
    call GetComponent
    pop rbx
    mov rcx, [rax+Position.x]
    mov [rbx+Position.x],  rcx
    mov rcx, [rax+Position.y]
    mov [rbx+Position.y], rcx


    ;===========================
    ;try to kill
    pop rcx
    pop rax
    pop rbx
    add rsp, 8
    mov rdi, qword[rax]
    cmp qword[rcx+Person.health], 0
    jg .not_dead
        mov rdi, rbx
        call DestroyEntity
    .not_dead:
    .end:
    mov rsp, rbp
    pop rbp
    ret