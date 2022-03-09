%macro make_buffer 2
    dq %1,%2
    times %1*%2*2 db 0x20
%endmacro
; Enum ID
;   null -> 0
;   person  -> 1
;   Label -> 2
;   Position -> 3
;   Item -> 4
;   Hand -> 5

struc Component
    .id: resq 1
    .size: resq 1
endstruc

struc Position
    .id: resq 1
    .size: resq 1
    .x: resq 1
    .y: resq 1
endstruc

struc Person
    ;should be the same as Component
    .id: resq 1
    .size: resq 1
    .health: resq 1
    .char: resq 1
    .color: resq 1
endstruc

struc Label
    .id: resq 1
    .size: resq 1
    .string: resq 1
    .free_str: resq 1
    .can_rise: resq 1
endstruc

struc Item
    .id: resq 1
    .size: resq 1
    .char: resq 1
    .color: resq 1
    .parent: resq 1 ; entity that is holding me
endstruc

struc Hand
    .id: resq 1
    .size: resq 1
    .item: resq 1
endstruc

%macro make_person 5
    mov rdi, 1
    call MakeEntity
    je %%fail ; Wow!
    mov rdx, qword[rax]
    mov qword[rdx+Person.health], %3
    mov qword[rdx+Person.char], %4
    mov qword[rdx+Person.color], %5

    mov rdi, rdx
    push rax
    mov rsi, 3
    call AddComponent
    mov qword[rax+Position.x], %1
    mov qword[rax+Position.y], %2

    mov rax, [rsp]
    mov rdi, [rax]
    mov rsi, 5
    call AddComponent
    pop rax
    mov rax,[rax]
    %%fail:
%endmacro

%macro move_char 3
    push r11
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    mov rcx, r11
    call Move_Char
    pop r11
%endmacro

%macro reset_tick 0
    movsd xmm0, [zero_double]
    movsd [tick_acc],xmm0
    mov byte[time_check], 0
%endmacro

%macro stacker 0
    mov r15, rsp
    push 0
    and r15, 15
    cmp r15,0
    jne %%not_16
        ; is 16 bit aligned
        push 1
    %%not_16:
%endmacro
%macro unstacker 0
    cmp qword[rsp], 1
    jne %%was_8
        add rsp,8
    %%was_8:
    add rsp,8
%endmacro

%include "inspector.asm"
%include "ecs.asm"
%include "draw.asm"
%include "label.asm"
%include "hand.asm"

segment .data
    winName: db "Rogueish 64",0
    font_file: db "font.ttf",0
    measure_text: db "#",0
    print_num: db "%.6f",10,0
    sprint_msg: db "--==Rogueish 64==--",0
    number_fmt: db "%d",0
    window_x: dq 1200
    window_y: dq 1072
    pallete: dd 0xff96ccda, 0xff678bbf,0xff311d18,0xff4821d8
    sixteen: dd 16.0
    tick_wait: dq 0.1
    tick_acc: dq 0.0
    zero_double: dq 0.0
    time_check: db 0

    char_spacing: dd 12
    game_buffer: make_buffer 75,67
    entity_list: times 256 dq 0

segment .bss
    font: resb 48
    hero_data: resq 1

    ent_list_end: resq 1
segment .text



global main
extern InitWindow
extern printf
extern RealLoadFontEx
extern DrawTextEx
extern WindowShouldClose
extern BeginDrawing
extern ClearBackground
extern EndDrawing
extern CloseWindow
extern DrawTextCodepoint
extern MeasureTextEx
extern IsKeyDown
extern GetFrameTime
extern malloc
extern free
extern asprintf

;arguments -> rdi,rsi,rdx,rcx,r8,r9,stack
main:
    push rbp
    mov rbp, rsp

    ; calculate window size
    ; w = size / 2
    xor rax,rax
    mov eax, [char_spacing]
    cqo
    mul dword [game_buffer + 0]
    mov rcx, rax

    xor eax,eax
    mov eax, [char_spacing]
    cqo
    mul dword [game_buffer + 8]
    sub eax,4
    sub ecx,4
    add rax, 6
    mov [window_x], rax
    mov [window_y], rcx
    
    mov rdi, rcx
    mov rsi, rax
    mov rdx,winName
    call InitWindow

    ; load font
    mov rdi, font_file
    mov rsi, 16
    mov rdx, 0
    mov rcx, 0
    mov r8, font
    call RealLoadFontEx ; "Real"
    
    mov rdi, game_buffer
    call DrawRoom

    mov qword[ent_list_end], entity_list

;   ===============Create Entities====================
    ;allocate the character
    make_person 20,40,100,'@',0
    mov qword[hero_data], rax

    ;allocate the enemy
    make_person 40,20,100,'Z',1

    mov rdi, 4
    call MakeEntity
    mov rdi, [rax]
    mov rsi, 3
    call AddComponent
    mov qword[rax+Position.x], 10
    mov qword[rax+Position.y], 10


;====================================================
    while_top:
    call WindowShouldClose

    cmp rax,1
    je while_end

        ; logic update
        ;get time
        ;accumulate time
        ;if it is greater set ready var to 1
        ;if ready var is 1, get key down
        ;   if key is down, set ready var to 0
        call GetFrameTime
        cvtps2pd xmm0,xmm0 ;convert the float to double
        addsd xmm0,[tick_acc]
        movsd qword[tick_acc], xmm0
        movsd xmm0,[tick_acc]

        comisd xmm0,[tick_wait]
        ;greater than -> zf,pf,cf == 0
        jz .set_end_compare
        jp .set_end_compare
        jb .set_end_compare

        .set_move_byte:
            mov byte[time_check], 1
        .set_end_compare:
        
        cmp byte[time_check],0
        je .done_tick
            ;key input stuff
            mov r11,0
            mov rdi, 340 ; Left Shift
            call IsKeyDown
            cmp al,0
            je .shift_not_down
                mov r11,1; signifies shift is down
            .shift_not_down:            
            ;     |label name|key num|direction|
            push 0
            move_char       87,      0,-1
            add [rsp],rax
            move_char       83,      0,1
            add [rsp],rax
            move_char       65,      -1,0
            add [rsp],rax
            move_char       68,      1,0
            add [rsp],rax

            cmp qword[rsp],0
            jg .done_activity
                ; haven't moved, can do actions 
                mov rdi, 69 ; KEY_E is 69, nice
                call IsKeyDown
                cmp al, 0
                je .done_activity
                    ; try to pick up item
                    call PickUp
                    reset_tick
            .done_activity:
            add rsp, 8
            cmp byte[time_check], 0
            jne .done_tick
                call OnTick
            ; ;update damage indicator
            ; call Label_Move_Up
        .done_tick:


        call BeginDrawing

        mov edi, dword[pallete+2*0x4]
        call ClearBackground

        ;clear buffer
        mov rdi, game_buffer
        call ClearBuffer
        ;draw  room
        call DrawRoom
        
        ;draw entities
        call DrawEntities

        ; draw the Hero over everything
        mov rsi, [entity_list]
        call DrawEntity

        mov rdi, game_buffer
        call DrawInspector

        call DrawBuffer
        call EndDrawing

        jmp while_top
    while_end:

    call CloseWindow

    mov rax, 0
    mov rsp,rbp
    pop rbp
    ret
move_char_fail_msg: db "Attempted to move character out of bounds!",10,0


OnTick:
    push rbp
    mov rbp, rsp
        call Label_Move_Up
    mov rsp, rbp
    pop rbp
    ret

;rax                 rdi   rsi  rdx
;entity* FindEntity(int x,int y,start)
FindEntity:
    push rbp
    mov rbp,rsp
        ;iterate through entities to find an entity at a particular place.
        mov rbx, rdx
        .top:
            cmp rbx,[ent_list_end]
            je  .no_find
            mov rcx, qword[rbx]
            cmp rcx, 0; this is null
            je .nope

            push rdi
            push rsi
            push rbx
            mov rdi, rcx
            mov rsi, 3
            call GetComponent
            pop rbx
            pop rsi
            pop rdi
            cmp rax, 0
            je .nope
            
            cmp [rax+Position.x], rdi
            jne .nope
            cmp [rax+Position.y], rsi
            jne .nope
            jmp .found
            .nope:

            add rbx, 8
            jmp .top

        .no_find:
        mov rax, 0
        jmp .end
        .found:
        mov rax, rbx
        .end:
    mov rsp,rbp
    pop rbp
    ret


;int Move_Char(key,x,  y,fast?)
Move_Char:
    push rbp
    mov rbp, rsp
    push rsi
    push rdx
    push rcx
    ; mov rdi, %2
    call IsKeyDown
    cmp al, 0
    mov rax, 0
    je .done
        mov rdx, qword[hero_data]
        ;conserve ---
        push rdx ; hero's data
        ; args ---
        mov rdi, rdx
        mov rsi, 3
        call GetComponent
        pop rdx
        cmp rax, 0
        je .clean_done

        mov rsi, [rax+Position.x]
        mov rdx, [rax+Position.y]

        ; update the buffer
        mov rdi, game_buffer
        cmp qword[rbp-0x18],1
        jne .not_shifting
            push rdx
            ; is pressing shift
            mov rax,9
            cqo
            mov rbx,[rbp-0x8]
            mul rbx
            add rsi,rax
            mov rax,9
            cqo
            mov rbx,[rbp-0x10]
            mul rbx
            pop rdx
            add rdx,rax
        .not_shifting:
        add rsi, [rbp-0x8]
        add rdx, [rbp-0x10]
        push rsi
        push rdx
        ; sub rsp, 8 ;| -> Just to give CanMove a
        push 69
        mov rcx,rsp;| valid address.
        call CanMove
        ; add rsp,8

        cmp rax, 0
        jne  .succ ; if failed
            ; fail!
            mov rdi, move_char_fail_msg
            call printf
            jmp .clean_done
        .succ: ; not failed
            cmp rax, 2
            je .hit ; if did something
            ; mov rax, [hero_data]
            mov rdi, qword[hero_data]
            mov rsi, 3
            call GetComponent
            mov rbx, [rsp+0x10]
            mov rcx, [rsp+0x8]
            mov qword[rax+Position.x],rbx
            mov qword[rax+Position.y],rcx
            jmp .clean_done
        .hit:
            cmp qword[rsp], 0
            je .clean_done
            ; attack I guess
            mov rdi, qword[rsp]
            call Attack
            ; mov rax, qword[rsp] ; rax = place in ent_list
            ; mov rdi, qword[rax]
            ; push rax
            ; mov rsi, 1
            ; call GetComponent
            ; ; pop rbx
            ; mov rbx,[rsp]
            ; pop rcx
            ; cmp rax, 0
            ; je .clean_done
            ; push rcx

            ; ;Is a person
            ; mov rcx, rax
            ; sub qword[rcx+Person.health], 10
            
            ; push rbx
            ; push rax
            ; push rcx
            ; ;create damage label
            ; mov rdi, 2
            ; call MakeEntity
            ; mov rdi, [rax]
            ; mov qword[rdi+Label.can_rise], 1

            ; push rdi

            ; sub rsp, 0x8
            ; mov rdi, rsp
            ; stacker
            ; ; sub rsp, 0x10; asprintf wants 16-byte aligned
            ; ;use sprintf
            ; mov rsi, number_fmt
            ; mov rdx, 10
            ; mov rax, 0
            ; call asprintf
            ; unstacker
            ; ;write string
            ; mov rbx, qword[rsp+8] ; was +10
            ; mov rax, [rsp]
            ; mov qword[rbx+Label.string], rax
            ; ; add rsp, 0x10
            ; add rsp, 0x8; remove the string
            ; mov qword[rbx+Label.free_str], 1

            ; pop rdi
            ; mov rsi, 3
            ; call AddComponent
            ; mov rbx, [rsp+0x20]
            ; mov rbx, [rbx]
            ; push rax
            ; mov rdi, rbx
            ; mov rsi, 3
            ; call GetComponent
            ; pop rbx
            ; mov rcx, [rax+Position.x]
            ; mov [rbx+Position.x],  rcx
            ; mov rcx, [rax+Position.y]
            ; mov [rbx+Position.y], rcx


            ; ;===========================
            ; pop rcx
            ; pop rax
            ; pop rbx
            ; add rsp, 8
            ; mov rdi, qword[rax]
            ; cmp qword[rcx+Person.health], 0
            ; jg .not_dead
            ;     ;dead
            ;     ; .kill:
            ;     ; mov rdi, qword[rbx]
            ;     ; call free
            ;     ; mov qword[rbx], 0
                
            ;     ; add rbx, 0x8
            ;     ; cmp qword[ent_list_end], rax
            ;     ; jne .clean_done
            ;     ;     ;is the last in the list
                    
            ;     ;     sub qword[ent_list_end], 0x8
            ;     mov rdi, rbx
            ;     call DestroyEntity
            ; .not_dead:
        .clean_done:
            ; clean up timer
            add rsp, 8 ; clean up pointer given to CanMove
            ; movsd xmm0, [zero_double]
            ; movsd [tick_acc],xmm0
            ; mov byte[time_check], 0
            reset_tick
            add rsp, 0x28 ;+0x10
            mov rax, 1
    .done:
    mov rsp, rbp
    pop rbp
    ret


;(0:error, 1:yes, 2:no) if hit!=0, then we *could* move
;if returns 1 or 0, rcx was not written too.
;rcx can be NULL if returned 2. It will only point
;   to an entity if an entity is in the way.
;rax            rdi       rsi   rdx     rcx
;int CanMove(char*buffer,int x,int y,entity* hit)
CanMove:
    push rbp
    mov rbp,rsp
    push rcx
    call IndexBuffer
    cmp rax, 0
    jne .no_fail
        ; error
        pop rcx
        jmp .end
    .no_fail:
    ; push rax
    mov qword[rcx], 0
    cmp byte[rax], '#'
    je .no
    ;see if something else is there
    mov rdi, rsi
    mov rsi, rdx
    mov rdx, entity_list
    call FindEntity
    cmp rax, 0
    je .success
    ;does it have the correct entity?
    mov rdi, [rax]
    push rax
    mov rsi, 1
    call GetComponent
    pop rbx
    cmp rax, 0
    je .success
    ;entity is there
    ; mov rbx, [rax]
    ; cmp qword[rbx+Person.id], 1
    ; jne .success
    pop rcx
    mov [rcx], rbx
    jmp .no 
    .success:
        mov rax,1
        jmp .end
    .no:
        mov rax,2
        jmp .end
    .end:
    mov rsp,rbp
    pop rbp
    ret

;(0:error, 1:succeed, 2:failed to move (mechanical))
; rax               rdi            rsi     rdx    rcx  r8
;void MoveChar(char* buffer,int old_x,int old_y,new_x,new_y)
MoveChar:
    push rbp
    mov rbp,rsp

    ; args match IndexBuffer
    push rcx
    push r8
    call IndexBuffer ; [rbp-8] = IndexBuffer
    pop r8
    pop rcx

    ;check if the index was out of bounds
    cmp rax,0
    jne move_char_succ_x
        ; fail!
        mov rax, 0
        jmp move_char_end

    move_char_succ_x:
    
    push rax
    mov rsi,rcx
    mov rdx,r8
    call IndexBuffer

    ;check if the index was out of bounds
    cmp rax,0
    jne move_char_succ_y
        ; fail!
        pop rax ; clear stack (not really needed)
        mov rax, 0
        jmp move_char_end

    move_char_succ_y:
    ; check destination block
    cmp byte[rax], '#'
    jne .skip_fail    
        ; is blocked, return 2
        mov rax, 2
        jmp move_char_end
    .skip_fail:

    pop rbx
    mov cx, word[rbx]
    mov word[rax], cx

    mov word[rbx], 0x0020

    .func_suc:
    mov rax, 1
    move_char_end:
    mov rsp, rbp
    pop rbp
    ret


; rax                        rdi        rsi    rdx   
;void*   IndexBuffer(char* buffer,int ,int x,int y)
IndexBuffer:
    push rbp
    mov rbp, rsp
    
    push rdi
    push rsi
    push rdx
    ; push rcx; y
    push rdx

    ; check bounds
    cmp rsi, [rdi]
    jge index_buffer_fail
    cmp rdx, [rdi + 8] ; y
    jge index_buffer_fail
    cmp rsi, 0
    jl index_buffer_fail
    cmp rdx, 0
    jl index_buffer_fail
    jmp index_buffer_succ
    index_buffer_fail:
        add rsp,8 ; handle the last push
        mov rax, 0
        ; .break_oh_no:
        jmp index_buffer_end
    index_buffer_succ:

    mov rax, [rdi + 0]
    cqo
    mul qword [rsp] ; y
    mov r8, 2
    mul r8 
    mov r8, rax ; r8 = size_x * y * 2
    add rsp, 8

    mov rax, rsi ; x
    cqo
    mov r9, 2
    mul r9
    add rax, r8
    add rax, rdi
    add rax, 16 ; skip over the size of the buffer
    index_buffer_end:
    pop rdx
    pop rsi
    pop rdi

    mov rsp, rbp
    pop rbp
    ret
