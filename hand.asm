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
	sub rsp, 8 ; align:1
    mov rsi, 5
    call GetComponent
    cmp rax, 0
    je .no_hands

    ;push rax
	mov [rsp], rax ; use align:1    

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

;void Attack(Entity** attackee,Entity* attacker)
Attack:
    push rbp
    mov rbp, rsp
    push rdi ; attackee Entity** -> rbp-0x8
	sub rsp, 8 ; align:1

    ;Get hero's damage delt===============
    mov rdi, rsi
    mov rsi, HAND
    call GetComponent
    cmp rax, 0
    je .end ; No hands, no attack!

    mov rdi, [rax+Hand.item]
    cmp rdi, 0
    je .no_item
    mov rdi, [rdi]
    mov rsi, ITEM
    call GetComponent
    cmp rax,0
    je .no_item
        ; there is an item
        ;push qword[rax+Item.damage]; damage -> rbp-0x10
		mov rdi, [rax+Item.damage]
		mov [rsp], rdi; Use align:1
        jmp .end_item
    .no_item:    
        ; will be causes if there is no item in hand
        ; or if the entity in hand is not an item (weird)
        ;push 10; damage -> rbp-0x10
		mov qword[rsp], 10
    .end_item:
    ;======================================
    ;Deal Damage===========================
    mov rdi, [rbp-0x8]
    mov rdi, [rdi]
    mov rsi, PERSON
    call GetComponent
    cmp rax, 0
    je .end
    
    mov rbx, [rbp-0x10] ; was rsp?
    ; PushAll
    ; stacker

    ; mov rsi, rbx

    ; unstacker
    ; PopAll
    sub qword[rax+Person.health], rbx
    ;======================================

    ;Potentially kill attackee=============
    cmp qword[rax+Person.health], 0
    jg .not_dead
        ;is dead
        push 1 ; rbp-0x18
        jmp .done_dead
    .not_dead:
    push 0
    .done_dead:
	sub rsp, 8 ; rbp-0x20
    ;======================================

    ;Create Damage Label===================
        ;Create Entity with Label=====
    mov rdi, LABEL
    call MakeEntity
    mov rbx, [rax]
    mov qword[rbx+Label.can_rise], 1
    push rax ; Entity** new label -> rbp-0x28
	sub rsp, 8 ; align:2 -> rbpx30
        ;Add Position to Label========
    mov rdi, rbx
    mov rsi, POSITION
    call AddComponent
        ;push rax;=======
		mov [rsp], rax ; use align:2
    mov rbx, [rbp-0x8];#
    mov rdi,[rbx]     ;#
    mov rsi, POSITION ;#
    call GetComponent ;#
        ;pop rbx;========
		mov rbx, [rsp] ; read from align:2
    mov rcx, [rax+Position.x]
    mov [rbx+Position.x], rcx
    mov rcx, [rax+Position.y]
    mov [rbx+Position.y], rcx

        ;Create string for Label======
    ;sub rsp, 8  ;0x38
    mov rdi, rsp; use rbp-0x30 align:2
    mov rsi, bare_int_fmt
    mov rdx, qword[rbp-0x10]
    mov rax, 0
    ;stacker
    call asprintf
    ;unstacker

    pop rcx; Removes text from 0x30
    pop rbx ; removes Entity** new label at rbp-0x28
    mov rbx,[rbx]
    mov qword[rbx+Label.string], rcx
    ;======================================
	add rsp, 8 ; remove -0x20, align buffer
    pop rbx ; should be -0x18, which is whether player is dead
    cmp rbx, 0
    je .end
    	mov rdi, [rbp-0x8]
        mov rsi, [rdi]
        cmp rsi,[hero_data]
        jne .good_kill
            ; tried to kill hero, kill everything!
            call DestroyAll
            mov qword[dead], 1
            jmp .end
        .good_kill:
    	call DestroyEntity
        add qword[coin], 1
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
