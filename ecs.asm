segment .data
    new_ent_fail: db "The component %d doesn't exist!",10,0
	default_item_name: db "Null Item",0
segment .text
extern realloc
extern malloc
extern printf

; returns the address to a place in the entity_list.
; The value there is where the entity *actually* is at.
;Entity** MakeEntity(int comp_id)
MakeEntity:
    push rbp
    mov rbp, rsp

    cmp rdi, 1
    je .person
    cmp rdi, 2
    je .label
    cmp rdi,3
    je .position
    cmp rdi, 4
    je .item
    cmp rdi, 5
    je .hand
    
    jmp .none
    .person:
        mov rdi, Person_size
        add rdi, 0x8 ; for the null pointer
        call malloc
        mov qword[rax+Component.id], 1
        ; set the size
        mov rbx, Person_size

        jmp .all
    .label:
        mov rdi, Label_size
        add rdi, 0x8
        call malloc
        mov qword[rax+Component.id],2
        mov qword[rax+Label.string], sprint_msg
        mov qword[rax+Label.can_rise], 0
        mov qword[rax+Label.free_str], 0
        mov rbx, Label_size
        jmp .all
    .position:
        mov rdi, Position_size
        add rdi, 0x8
        call malloc
        mov qword[rax+Component.id],3
        ; mov qword[rax+Position.x],0
        mov rbx, Position_size
        jmp .all
    .item:
        mov rdi, Item_size
        add rdi, 0x8
        call malloc
        mov qword[rax+Component.id],4
        mov qword[rax+Item.char], '/'
        mov qword[rax+Item.color],3
        mov qword[rax+Item.parent], 0
        mov qword[rax+Item.damage], 15
		mov qword[rax+Item.name], default_item_name
        mov rbx, Item_size
        jmp .all
    .hand:
        mov rdi, Hand_size
        add rdi, 0x8
        call malloc
        mov qword[rax+Component.id],5
        mov qword[rax+Hand.item], 0
        mov rbx, Hand_size
        jmp .all
    .none:
        ;that component doesn't exist!
        mov rsi, rdi
        mov rdi, new_ent_fail
        mov rax, 0
        call printf
        mov rax,0
        jmp .end
    .all:
        ; rbx MUST be struct_size.
        ; writes to null integer

        mov qword[rax+Component.size], rbx
        mov qword[rax+rbx], 0
        ; add entity to entity list
        ;TODO: fill in any holes in the list
        mov rbx, qword[ent_list_end]
        mov qword[rbx], rax
        mov rax, rbx
        add qword[ent_list_end],0x8

    .end:
    mov rsp,rbp
    pop rbp
    ret

; ent is a pointer to the first component
; Component* AddComponent(Entity* ent, int comp_id)
AddComponent:
    push rbp
    mov rbp, rsp

    ;find end of entity
    mov rbx, rdi
    .top:
        cmp qword[rbx+Component.id], 0
        je .search_end
        
        add rbx, qword[rbx+Component.size]
        jmp .top
    .search_end:
    ;rbx is the end
    ;get the size of the memory
    sub rbx, rdi
    add rbx, 0x8

    ;find where the component is in the entity list
    mov r8, entity_list
    .find_top:
        cmp r8, qword[ent_list_end] 
        je .find_nope
        cmp qword[r8], rdi
        je .find_end

        add r8, 0x8
        jmp .find_top

        .find_nope_msg: db "Entity is not in entity list! Something is horribly wrong.",10,0
    .find_nope:
        mov rdi, .find_nope_msg
        mov rax, 0
        call printf
        jmp .end
    .find_end:

	;sub rsp, 8; align:1
    push rsi
    cmp rsi, 1
    je .person
    cmp rsi, 2
    je .label
    cmp rsi, 3
    je .position
    cmp rsi, 4
    je .item
    cmp rsi, 5
    je .hand
    jmp .none

    .pre:
        add rsi, rbx ; realloc(ptr, Person_size + old_size)
        push rbx
        push r8
        call realloc
        pop r8
        mov qword[r8], rax
        pop rbx ; old_size

        ;write to the person.
        mov rcx, rbx
        sub rcx, 0x8
        ret
        
    .person:
        mov rsi, Person_size
        call .pre
        mov qword[rax+rcx+Component.id], 1
        ;write to size.
        mov qword[rax+rcx+Component.size], Person_size
        mov qword[rax+rcx+Person.health],0
        mov byte[rax+ rcx+Person.char], 0
        mov byte[rax+ rcx+Person.color], 0

        mov qword[rax+rcx+Person_size], 0
        add rax, rcx
        jmp .end
    .label:
        mov rsi, Label_size
        call .pre
        mov qword[rax+rcx+Component.id], 2
        ;write to size.
        mov qword[rax+rcx+Component.size], Label_size
        mov qword[rax+rcx+Label.string], sprint_msg
        mov qword[rax+rcx+Label.can_rise], 0
        mov qword[rax+rcx+Label.free_str], 0
        mov qword[rax+rcx+Label_size], 0
        add rax, rcx
        jmp .end

    .position:
        mov rsi, Person_size
        call .pre
        mov qword[rax+rcx+Component.id],3
        mov qword[rax+rcx+Component.size], Position_size
        mov qword[rax+rcx+Position.x],0
        mov qword[rax+rcx+Position.y],0
        mov qword[rax+rcx+Position_size],0
        add rax, rcx
        jmp .end

    .item:
        mov rsi, Item_size
        call .pre
        mov qword[rax+rcx+Component.id],4
        mov qword[rax+rcx+Component.size],Item_size
        mov qword[rax+rcx+Item.char], '/'
        mov qword[rax+rcx+Item.color],3
        mov qword[rax+rcx+Item.parent],0
		mov qword[rax+rcx+Item.name], default_item_name
        mov qword[rax+rcx+Item_size],0
        add rax,rcx
        jmp .end
    .hand:
        mov rsi, Hand_size
        call .pre
        mov qword[rax+rcx+Component.id],5
        mov qword[rax+rcx+Component.size],Hand_size
        mov qword[rax+rcx+Hand.item], 0
        ;mov qword[rax+rcx+Item.damage], 15
        mov qword[rax+rcx+Hand_size],0
        add rax,rcx
        jmp .end
    .none:
        mov rdi, AddComponent_no_match
        mov rsi, qword[rsp]
        mov rax, 0
        call printf
    .end:
    ;pop rsi
    mov rsp,rbp
    pop rbp
    ret
AddComponent_no_match: db "There is no implemented component %d",10,0

;bool HasComponent(Entity* ent, int comp_id)
HasComponent:
    push rbp
    mov rbp, rsp

    mov rbx, rdi
    .top:
        cmp qword[rbx], rsi
        je .succ
        cmp qword[rbx], 0
        je .fail

        add rbx, qword[rbx+Component.size]
        jmp .top
    .succ:
        mov rax, 1
        jmp .end
    .fail:
        mov rax, 0
        jmp .end
    .end:

    mov rsp,rbp
    pop rbp
    ret

;Component*  GetComponent(Entity* ent, int comp_id)
GetComponent:
    push rbp
    mov rbp, rsp
    mov rbx, rdi
    .top:
        cmp qword[rbx+Component.id],0
        je .fail

        cmp qword[rbx+Component.id],rsi
        je .found

        add rbx, qword[rbx+Component.size]
        jmp .top
    .fail:
        mov rax, 0
        jmp .end
    .found:
        mov rax,rbx
    .end:

    mov rsp,rbp
    pop rbp
    ret

;This function goes though the components of the given
;entity and apropriatly cleans the components up.
;void Deconstruct(Entity* ent)
Deconstruct:
    push rbp
    mov rbp, rsp

    mov rbx, rdi
    push rbx
	sub rsp, 8 ; align:1
    .top:
        cmp qword[rbx], 0
        je .end
        mov qword[rbp-0x8], rbx

        cmp qword[rbx], 1
        je .person
        cmp qword[rbx], 2
        je .label
        cmp qword[rbx],3
        je .position
        .person:
            jmp .cont
        .label:
            cmp qword[rbx+Label.free_str], 0
            je .no_free
            
                PushAll
                mov rdi, TEST_MSG
                mov rsi, qword[rbx+Label.string]
                mov rax, 0
                call printf
                PopAll
                mov rdi, qword[rbx+Label.string]
                call free
            .no_free:
            jmp .cont
        .position:
            jmp .cont
        .cont:
        mov rbx, [rbp-0x8]
        add rbx, [rbx+Component.size]
        jmp .top
    .end:
	add rsp, 8
    pop rbx
    mov rsp,rbp
    pop rbp
    ret
TEST_MSG: db "Freed the string %s",10,0

;ent is a pointer into the entity list (should be entity_list+something)
;void DestroyEntity(Entity** ent)
DestroyEntity:
    push rbp
    mov rbp, rsp


	sub rsp, 8 ; align:1
    push rdi
    mov rdi, [rdi]
    call Deconstruct
    mov rdi, qword[rsp]
    mov rdi, [rdi]
    call free
    
    pop rdi
    mov qword[rdi], 0
    add rdi, 0x8
    cmp qword[ent_list_end], rdi
    jne .done
        ;is the last in the list
        .while:
            sub qword[ent_list_end], 0x8
            mov rsi, [ent_list_end]
            cmp qword[rsi-0x8],0
            je .while
    .done:
    mov rsp, rbp
    pop rbp
    ret

;void RemoveComponent(Entity* ent,int CompID)
RemoveComponent:
