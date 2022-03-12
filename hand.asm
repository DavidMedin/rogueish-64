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
; Attack:
;     push rbp
;     mov rbp, rsp
;     push rdi    ; rbp -0x8
;     ; mov rax, qword[rdi] ; rax = place in ent_list
;     mov rdi, qword[rdi]
;     push rax
;     mov rsi, 1
;     call GetComponent
;     ; pop rbx
;     mov rbx,[rbp-0x8];  rbp-0x8 = first arg
;     pop rcx
;     cmp rax, 0
;     je .end
;     push rcx

;     ;Is a person
;     mov rcx, rax

;     ;Attack!
;     ;Figure out the dmaage to deal
;     ;Find if the human has a hand
;     mov rdi, qword[rbp-0x8]
;     mov rdi, [rdi]
;     mov rsi, HAND
;     call GetComponent
;     cmp rax, 0
;     je .end ; will clean the stack

;     cmp qword[rax+Hand.item], 0
;     je .no_item
;         ;has an item
;         mov rdx, qword[rax+Hand.item]
;         mov rdi, [rdx]
;         mov rsi, ITEM
;         call GetComponent
;         cmp rax, 0
;         je .end

;         ; mov rdx, qword[rdx+Item.damage]
;         push qword[rax+Item.damage]
;     .no_item:
;         ;doesn't have an item
;         ; mov rdx, 10
;         push 10
;     .done_damage:

;     mov rdx, qword[rsp]
;     sub qword[rcx+Person.health], rdx
    
;     push rbx
;     push rax
;     push rcx
;     ;create damage label
;     mov rdi, 2
;     call MakeEntity
;     mov rdi, [rax]
;     mov qword[rdi+Label.can_rise], 1

;     push rdi

;     ;generate damage string
;     sub rsp, 0x8
;     mov rdi, rsp
;     stacker
;     ;use sprintf
;     mov rsi, number_fmt
;     mov rdx, qword[rbp-0x18] ; was 10
;     mov rax, 0
;     call asprintf
;     unstacker
;     ;write string
;     mov rbx, qword[rsp+8]
;     mov rax, [rsp]
;     mov qword[rbx+Label.string], rax

;     add rsp, 0x8; remove the string
;     mov qword[rbx+Label.free_str], 1

;     pop rdi
;     mov rsi, 3
;     call AddComponent
;     ; mov rbx, [rsp+0x20]
;     mov rbx, [rbp-0x8]
;     mov rbx, [rbx]
;     push rax
;     mov rdi, rbx
;     mov rsi, 3
;     call GetComponent
;     pop rbx
;     mov rcx, [rax+Position.x]
;     mov [rbx+Position.x],  rcx
;     mov rcx, [rax+Position.y]
;     mov [rbx+Position.y], rcx


;     ;===========================
;     ;try to kill
;     pop rcx
;     pop rax
;     pop rbx
;     add rsp, 8
;     mov rdi, qword[rax]
;     cmp qword[rcx+Person.health], 0
;     jg .not_dead
;         mov rdi, rbx
;         call DestroyEntity
;     .not_dead:
;     .end:
;     mov rsp, rbp
;     pop rbp
;     ret

;void Attack(Entity** attackee)
Attack:
    push rbp
    mov rbp, rsp

    push rdi ; attackee Entity** -> rbp-0x8

    ;Get hero's damage delt===============
    mov rdi, [hero_data]
    mov rsi, HAND
    call GetComponent
    cmp rax, 0
    je .end ; No hands, no attack!

    mov rdi, [rax]
    mov rdi, ITEM
    call GetComponent
    cmp rax,0
    je .no_item
        ; there is an item
        push qword[rax+Item.damage]; damage -> rbp-0x10
        jmp .end_item
    .no_item:    
        push 10; damage -> rbp-0x10
    .end_item:
    ;======================================
    ;Deal Damage===========================
    mov rdi, [rbp-0x8]
    mov rdi, [rdi]
    mov rsi, PERSON
    call GetComponent
    cmp rax, 0
    je .end
    
    mov rbx, [rsp-0x10]
    sub qword[rax+Person.health], rbx
    ;======================================

    ;Potentially kill attackee=============
    cmp qword[rax+Person.health], 0
    jg .not_dead
        ;is dead
        push 1
        jmp .done_dead
    .not_dead:
    push 0
    .done_dead:
    ;======================================

    ;Create Damage Label===================
        ;Create Entity with Label=====
    mov rdi, LABEL
    call MakeEntity
    mov rbx, [rax]
    mov qword[rbx+Label.can_rise], 1
    push rax ; Entity** new label -> rbp-0x20
        ;Add Position to Label========
    mov rdi, rbx
    mov rsi, POSITION
    call AddComponent
        push rax;=======
    mov rbx, [rbp-0x8];#
    mov rdi,[rbx]     ;#
    mov rsi, POSITION ;#
    call GetComponent ;#
        pop rbx;========
    mov rcx, [rbx+Position.x]
    mov [rax+Position.x], rcx
    mov rcx, [rbx+Position.y]
    mov [rax+Position.y], rcx

        ;Create string for Label======
    sub rsp, 8  ;0x28
    mov rdi, rsp
    mov rsi, number_fmt
    mov rdx, qword[rbp-0x10]
    mov rax, 0
    stacker
    call sprintf
    unstacker

    pop rcx; Removes text from 0x20
    pop rbx ; removes Entity** new label at rbp-0x20
    mov rbx,[rbx]
    mov qword[rbx+Label.string], rcx
    ;======================================
    pop rbx ; should be -0x18, which is whether player is dead
    mov rdi, [rbp-0x8]
    call DestroyEntity
    ;======================================
    ; 16 bytes implicitly cleaned up
    .end:
    mov rsp, rbp
    pop rbp
    ret

;
;get hero's damage delt
;get attackee's person
;deal damage
;create damage label
;potentially delete attackee