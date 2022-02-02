
%macro make_buffer 2
    dq %1,%2
    times %1*%2*2 db 0x20
%endmacro
; Enum ID
;   null -> 0
;   person  -> 1
;   hero -> 2

struc Person
    .id: resq 1
    .jump: resq 1
    .x: resq 1
    .y: resq 1
    .health: resq 1
    .char: resb 1
    .color: resb 1
endstruc

%macro make_person 5
    mov rdi, Person_size
    call malloc
    mov qword[rax+Person.id], 1
    mov rbx, Person_size

    sub rbx, Person.jump
    mov qword[rax+Person.jump], rbx
    mov qword[rax+Person.x], %1
    mov qword[rax+Person.y], %2
    mov qword[rax+Person.health], %3
    mov byte[rax+Person.char], %4
    mov byte[rax+Person.color], %5
%endmacro

segment .data
    winName: db "Rogueish 64",0
    format: db "Howdy",10,0
    font_file: db "font.ttf",0
    measure_text: db "#",0
    print_num: db "%.6f",10,0
    sprint_msg: db "--==Rogueish 64==--",0
    window_x: dq 1200
    window_y: dq 1072
    background: dd 0xff311d18
    pallete: dd 0xff96ccda, 0xff678bbf
    sixteen: dd 16.0
    move_wait: dq 0.1
    move_time_acc: dq 0.0
    zero_double: dq 0.0
    move_check: db 0

    char_spacing: dd 12
    game_buffer: make_buffer 75,67
    entity_list: times 256 dq 0

segment .bss
    font: resb 48
    hero_data: resq 1

    ent_list_end: resq 1
segment .text


%macro push_font 1
    push qword [%1+0x28]
    push qword [%1+0x20]
    push qword [%1+0x18]
    push qword [%1+0x10]
    push qword [%1+0x8]
    push qword [%1]
%endmacro


%macro move_char 4
    push r11
    mov rdi, %2
    call IsKeyDown
    cmp al, 0
    je .%1_done
        mov rdx, qword[hero_data]
        mov rsi, [rdx+Person.x]
        mov rdx, [rdx+Person.y]

        ; update the buffer
        mov rdi, game_buffer
        ; mov rcx, rsi
        ; mov r8, rdx
        cmp qword[rsp],1
        jne .%1_not_shifting
            push rdx
            ; is pressing shift
            mov rax,9
            cqo
            mov rbx,%3
            mul rbx
            add rsi,rax
            mov rax,9
            cqo
            mov rbx,%4
            mul rbx
            pop rdx
            add rdx,rax
        .%1_not_shifting:
        add rsi, %3
        add rdx, %4
        push rsi
        push rdx
        sub rsp, 8 ;|-> Just to give CanMove a
        mov rcx,rsp;| valid address.
        call CanMove
        add rsp,8

        cmp rax, 0
        jne  .%1_succ ; if failed
            ; fail!
            mov rdi, move_char_fail_msg
            call printf
            jmp .%1_clean_done
        .%1_succ: ; not failed
            cmp rax, 2
            je .%1_clean_done ; if did something
            mov rax, [hero_data]
            ; add qword[rax+0x10], %3
            ; add qword[rax+0x18], %4
            mov rbx, [rsp+8]
            mov rcx, [rsp]
            mov qword[rax+Person.x],rbx
            mov qword[rax+Person.y],rcx
        .%1_clean_done:
            movsd xmm0, [zero_double]
            movsd [move_time_acc],xmm0
            mov byte[move_check], 0
            add rsp, 0x10
    .%1_done:
    pop r11
%endmacro

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

    mov rdi, format
    call printf

    ; load font
    mov rdi, font_file
    mov rsi, 16
    mov rdx, 0
    mov rcx, 0
    mov r8, font
    call RealLoadFontEx ; "Real"
    
    mov rdi, game_buffer
    call DrawRoom

    ; call ClearBuffer
    mov qword[ent_list_end], entity_list
    ;allocate the character
    make_person 30,40,100,'@',0
    mov qword[hero_data], rax
    mov qword[entity_list], rax
    add qword[ent_list_end], 8; increment the end of the list thingy

    ;allocate the enemy
    make_person 40,20,100,'Z',1
    mov rbx, qword[ent_list_end]
    mov qword[rbx], rax
    add qword[ent_list_end], 8

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
        addsd xmm0,[move_time_acc]
        movsd qword[move_time_acc], xmm0
        movsd xmm0,[move_time_acc]

        comisd xmm0,[move_wait]
        ;greater than -> zf,pf,cf == 0
        jz .set_end_compare
        jp .set_end_compare
        jb .set_end_compare

        .set_move_byte:
            mov byte[move_check], 1
        .set_end_compare:
        
        cmp byte[move_check],0
        je done_input

            mov r11,0
            mov rdi, 340 ; Left Shift
            call IsKeyDown
            cmp al,0
            je .shift_not_down
                mov r11,1; signifies shift is down
            .shift_not_down:            
            ;     |label name|key num|direction|
            move_char w,      87,      0,-1
            move_char s,      83,      0,1
            move_char a,      65,      -1,0
            move_char d,      68,      1,0
        done_input: ; if not pressed or way is blocked


        call BeginDrawing

        mov edi, dword[background]
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

;void DrawEntity(Buffer* buffer,Entity* entity)
DrawEntity:
    push rbp
    mov rbp,rsp

    push rsi
    mov rcx, rsi
    mov rsi, [rcx+Person.x]
    mov rdx, [rcx+Person.y]
    call IndexBuffer
    pop rsi
    mov bl, [rsi+Person.char]
    mov byte[rax], bl
    mov bl, [rsi+Person.color]
    mov byte[rax+1], bl

    mov rsp,rbp
    pop rbp
    ret

;rax                 rdi   rsi
;entity* FindEntity(int x,int y)
FindEntity:
    push rbp
    mov rbp,rsp
        ;iterate through entities to find an entity at a particular place.
        mov rbx, entity_list
        .top:
            cmp rbx,[ent_list_end]
            je  .no_find
            mov rcx, qword[rbx]
            cmp [rcx+Person.x], rdi
            jne .nope
            cmp [rcx+Person.y], rsi
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

; void DrawEntities(Buffer* buffer)
DrawEntities:
    push rbp
    mov rbp, rsp

    mov rbx, entity_list
    .top_loop:
        cmp rbx, qword[ent_list_end]
        jge .bot_loop

        mov rcx, qword[rbx]
        cmp qword[rcx], 1 ; 1=person
        jne .end_process
            push rbx
            push rcx
            mov rsi, qword[rcx+Person.x]
            mov rdx, qword[rcx+Person.y]
            call IndexBuffer
            pop rcx
            pop rbx
            mov dl, byte[rcx+Person.char]
            mov byte[rax], dl
            mov dl, byte[rcx+Person.color]
            mov byte[rax+1], dl
        jmp .end_process
        .not_person:

        .end_process:

        add rbx, 8
        jmp .top_loop
    .bot_loop:

    mov rsp, rbp
    pop rbp
    ret

; void ClearBuffer(Buffer* buffer)
ClearBuffer:
    push rbp
    mov rbp, rsp

    mov rbx, 0
    .top_y:
        cmp rbx,[rdi+0x8]
        jge .bot_y 
        mov rcx, 0
        .top_x:
            cmp rcx,[rdi+0]
            jge .bot_x

            mov rsi, rcx
            mov rdx, rbx
            call IndexBuffer
            mov byte[rax], 0x20 ; I think 0x20 is ' '

            inc rcx
            jmp .top_x
            .bot_x:
        inc rbx
        jmp .top_y
        .bot_y:

    mov rsp, rbp
    pop rbp
    ret

;                   rdi
; void DrawRoom(Buffer* buffer)
DrawRoom:
    push rbp
    mov rbp, rsp
    push rdi
    ; write to the buffer
    mov eax,0
    top_write_y:
        cmp eax,[rdi + 8]
        je bot_write_y

        mov ebx,0
        top_write_x:
            cmp ebx,[rdi + 0]
            je bot_write_x

            ; if (eax == 0 || ebx == 0 || eax == (buff_size_x - 1) || ebx == (buff_size_y - 1) )
            cmp eax, 0
            je succ
            cmp ebx,0
            je succ
            mov ecx, [rdi + 8]
            dec ecx
            cmp eax,ecx
            je succ
            mov ecx, [rdi + 0]
            dec ecx
            cmp ebx,ecx
            je succ

            mov r8d,1
            jmp write_fail
            succ:
            mov r8d, 0
            write_fail:

                push rax
                push rbx
                push r8
                mov rdi, rdi
                mov esi, ebx
                mov edx, eax
                call IndexBuffer
                pop r8
                cmp r8d,0
                jne write_end
                mov byte[rax], '#'
                write_end:
                mov byte[rax+1], 1
                pop rbx
                pop rax
        
            inc ebx
            jmp top_write_x
        bot_write_x:

        inc eax
        jmp top_write_y
    bot_write_y:
    mov rsi, 1
    mov rdx, 1
    mov rcx, sprint_msg
    mov r8, 30
    mov r9, 5
    call CopyText
    pop rdi
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
        jmp .end
    .no_fail:
    push rax
    cmp byte[rax], '#'
    je .no
    ;see if something else is there
    mov rdi, rsi
    mov rsi, rdx
    call FindEntity
    cmp rax, 0
    je .success
    ;entity is there
    ;TODO: read member to see if 'walkable' like an item.
    ;defaulting to not 'walkable' for now.
    pop rcx
    mov [rcx], rax
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

    push 0; x ->  -0x20
    push 0; y -> -0x28
    
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
        jmp .top
    .end:
    add rsp, 0x10
    pop rcx
    pop r9
    pop r8
    mov rsp, rbp
    pop rbp
    ret
copy_text_err: db "Attepted to write text into invalid space! (%d, %d)",10,0

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

;void DrawBuffer(Font* font)
DrawBuffer:
    push rbp
    mov rbp, rsp
    sub rsp, 0xc
    push_font font

    mov r8,0
    top_y:
        cmp r8d, dword [game_buffer + 8]
        je end_y
        mov r9, 0

        ;for x
        top_x:
            cmp r9d, dword[game_buffer + 0]
            je end_x

            ;---------------
            sub rsp,8
            mov eax, [char_spacing]
            cdq
            mul r9d
            cvtsi2ss xmm0, eax
            movss [rsp], xmm0
            ; push (x * char_spacing) 
            ;-------------- 
            mov eax,[char_spacing]
            cdq
            mul r8d
            cvtsi2ss xmm0, eax
            movss [rsp+4], xmm0
            ; push (char_spacing * y)
            ;-------------
            movq xmm0, [rsp]
            add rsp,8

            ;-----------
            ;TODO: maybe should be moved closer to function
            movss xmm1, [sixteen]
            ;------------
            mov eax, [game_buffer + 0]
            cdq
            mul r8d ; y * buff_size_x
            shl rax, 1 ; multiply by two to get the number of bytes (char, color index)
            mov ebx,eax ; ebx = eax
            ; ebx = 16 * char_count_x * y
            ;-----------

            mov eax, r9d
            push  2
            cdq
            mul dword [rsp]
            add rax, 16 ; becuase of the beginning of the struct
            add rsp, 8
            ; eax = x * 2 + 8 (becuase the second byte is color)
            ;-----------

            xor rdi,rdi;       buffer  +  y-off + x-off
            mov dil, byte [game_buffer + ebx   +  eax]
            mov bl, byte[game_buffer + ebx + eax + 1]
            xor rax,rax
            mov al, bl
            xor rbx,rbx
            mov bl,al
            mov dword [rbp-0x8], r8d
            mov dword [rbp-0xc], r9d

            xor rsi,rsi
            xor rax,rax
            mov rax, rbx
            cqo
            mov r8, 4
            mul r8
            mov esi, [pallete + rax]

            call DrawTextCodepoint

            mov r8d, dword [rbp-0x8]
            mov r9d, dword [rbp-0xc]

            inc r9d
            jmp top_x
        end_x:
        inc r8d
        jmp top_y
    end_y:
    add rsp,48 ; not really needed

    mov rsp,rbp
    pop rbp
    ret