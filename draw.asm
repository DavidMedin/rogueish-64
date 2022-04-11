%macro push_font 1
    push qword [%1+0x28]
    push qword [%1+0x20]
    push qword [%1+0x18]
    push qword [%1+0x10]
    push qword [%1+0x8]
    push qword [%1]
%endmacro

segment .text
extern memcpy
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

;void DrawEntity(Buffer* buffer,Entity* entity)
DrawEntity:
    push rbp
    mov rbp,rsp
    push rdi
    push rsi
    
    mov rdi, rsi
    mov rsi, 1
    call GetComponent
    ; pop rsi
    ; pop rdi
    mov rdi, qword[rbp-0x8 ]
    mov rsi, qword[rbp-0x10]
    cmp rax, 0
    je .label
        ; if this entity has a person component
        mov rcx, rax
		sub rsp, 8;align:1
        push rcx
        mov rdi, qword[rbp-0x10]
        mov rsi, 3
        call GetComponent
        pop rcx
		;add rsp, 8 ;unalign:1
        cmp rax, 0
        je .label
		;sub rsp, 8 ; align:2
		;mov [rsp], rcx ;use align:1
        push rcx
        mov rdi, [rbp-0x8]
        mov rsi, [rax+Position.x]
        mov rdx, [rax+Position.y]
        call IndexBuffer
        pop rcx
		add rsp, 8 ; unalign:1
        mov bl, [rcx+Person.char]
        mov byte[rax], bl
        mov bl, [rcx+Person.color]
        mov byte[rax+1], bl

    .label:
    mov rsi, qword[rbp-0x10]
    mov rdi, rsi
    mov rsi, 2
    ; draw labels
    call GetComponent
    cmp rax, 0
    je .item
		mov rcx, qword[rax+Label.string]
        mov rdi, qword[rbp-0x10]
        mov rsi, 3
        call GetComponent
        cmp rax, 0
        je .end
            mov rdi, qword[rbp-0x8]
            mov rsi, qword[rax+Position.x]
            mov rdx, qword[rax+Position.y]
            mov r8, 0
			sub rsp, 8;align:1
            push 0x3
            call CopyText
            add rsp, 0x10;unalign:1 & color push

    .item:
    mov rdi, qword[rbp-0x10]
    mov rsi, 4
    call GetComponent
    cmp rax, 0
    je .end
        mov rcx, rax
        cmp qword[rcx+Item.parent], 0
        jne .end

        mov rdi, qword[rbp-0x10]
        mov rsi, 3 ; position
        call GetComponent
        cmp rax, 0
        je .end
            mov rdi, qword[rbp-0x8]
            mov rsi, qword[rax+Position.x]
            mov rdx, qword[rax+Position.y]
            call IndexBuffer
            mov rdx, [rcx+Item.char]
            mov byte[rax], dl
            mov rdx, [rcx+Item.color]
            mov byte[rax+1],dl
    .end:
    pop rsi
    pop rdi
    mov rsp,rbp
    pop rbp
    ret


; void DrawEntities(Buffer* buffer)
DrawEntities:
    push rbp
    mov rbp, rsp

    mov rbx, entity_list
    mov r8, 0
    .top_loop:
        cmp rbx, qword[ent_list_end]
        jge .bot_loop

        mov rsi, qword[rbx]
        cmp rsi, 0
        je .cont
        push rbx
        push r8
        call DrawEntity
        pop r8
        pop rbx
        .cont:
        add rbx, 8
        inc r8
        jmp .top_loop
    .bot_loop:

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
    ; mov rsi, 1
    ; mov rdx, 1
    ; mov rcx, sprint_msg
    ; mov r8, 5
    ; mov r9, 5
    ; call CopyText
    pop rdi
    mov rsp, rbp
    pop rbp
    ret

;void BlitBuffer(Buffer* src, buffer* dest, int dest_x, int dest_y)
BlitBuffer:
	push rbp
	mov rbp, rsp
	push rdi ; -> 0x8
	push rsi ; -> 0x10
	push rdx ; -> 0x18
	push rcx ; -> 0x20
	mov rax, [rdi]
	shl rax, 1 ; width * 2
	push rax ; -> 0x28
	sub rsp, 0x8

	;----Calculate width copyable-----
	mov rax, [rsi]
	sub rax, [rdi] ; dest.width - src.width
	cmp rax, 0
	jl .fail ; if(dest.width - src.width < 0) fail 
	;------------------------
	;-----Calculate Height copyable
	mov rax, [rsi+0x8]
	sub rax, [rdi+0x8]
	cmp rax, 0
	jl .fail ; same as before but height

	cmp rdx, 0;| x and y must be positive
	jl .fail  ;|
	cmp rcx, 0;|
	jl .fail;  |
	
	;mov rdi, .x_msg
	;mov rsi, [rbp-0x18]
	;mov rax, 0
	;call printf
	;mov rdi, .y_msg
	;mov rsi, [rbp-0x20]
	;mov rax, 0
	;call printf
	;mov rdi, [rbp - 0x8]
	;mov rsi, [rdi+0x8]
	;mov rdi, .height_msg
	;mov rax, 0
	;call printf
	;Iterate through src's Y---------
	mov r8, 0 ; was rcx for release
	mov r9, 0
	.top:
		mov rsi, [rbp - 0x10]
		cmp r8, [rsi + 0x8] ; get dests height
		jge .bot
		; ------ Get destination pointer
		;mov rdi, rsi
		;mov rcx, [rdi]
		;add rdi, 0x10; skip dimentions
		;mov rbx, [rbp - 0x20] ; get y
		;cqo; fill rdx with 0 prob
		;mov rax, rbx
		;mul rcx ; y * width
		;add rcx, [rbp - 0x18] ; y * width + x
		;lea rdi, [rdi + rcx] ; buffer[y * width + x]
		mov rdi, rsi
		mov rsi, [rbp-0x18]
		mov rdx, [rbp-0x20]
		add rdx, r8
		push r8
		push r9
		call IndexBuffer
		pop r9
		pop r8
		sub rsp, 8; align : 1
		push rax

		mov rdi, [rbp - 0x8]
		cmp r9, [rdi+0x8]; compare to height
		jge .bot
		mov rsi, 0
		mov rdx, r9
		push r8
		push r9
		call IndexBuffer
		pop r9
		pop r8

		mov rsi, rax
		pop rdi
		add rsp, 8 ; align :1
		mov rdx, [rbp - 0x28]
		push r8
		push r9
		call memcpy
		pop r9
		pop r8
		inc r9
		inc r8
		jmp .top
	.bot:
	;mov rdi, .height_msg
	;mov rsi, r8
	;mov rax, 0
	;call printf
	;mov rdi, .height_msg
	;mov rsi, r9
	;mov rax, 0
	;call printf
	jmp .end
	.fail:
		mov rdi, .fail_msg
		mov rax, 0
		call printf
		int3
	.end:
	mov rsp, rbp
	pop rbp
	ret
	.fail_msg: db "Src buffer tried to blit outside of dest!",10,0
	.width_msg: db "width: %d", 10 ,0
	.height_msg: db "height: %d", 10, 0
	.x_msg: db "x: %d", 10,0
	.y_msg: db "y: %d",10,0

;					rdi
;void DrawBuffer(Buffer* buffer)
DrawBuffer:
    push rbp
    mov rbp, rsp
    sub rsp, 0xc; 12 bytes, save x and y
	push rdi
    push_font font; where is font referenced? ; 0x30 bytes

    mov r8,0
    top_y:
		mov rax, [rbp - 0x14] ; get buffer
        cmp r8d, dword [rax + 8]
        je end_y
        mov r9, 0

        ;for ex
        top_x:
			mov rax, [rbp-0x14]
            cmp r9d, dword[rax + 0]
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
			mov rax, [rbp-0x14]
            mov eax, [rax + 0]
            cdq
            mul r8d ; y * buff_size_x
            shl rax, 1 ; multiply by two to get the number of bytes (char, color index)
			xor rbx,rbx
            mov ebx,eax ; ebx = eax
            ; ebx = 16 * char_count_x * y
            ;-----------

			xor rax,rax
            mov eax, r9d
            push  2
            cdq
            mul dword [rsp]
            add rax, 16 ; becuase of the beginning of the struct
            add rsp, 8
            ; eax = x * 2 + 8 (becuase the second byte is color)
            ;-----------

			; index buffer (get color and character)
            xor rdi,rdi;       buffer  +  y-off + x-off
			mov r10, [rbp-0x14]
			add r10, rbx
            mov dil, byte [r10   +  rax]; get char
            mov bl, byte[r10 + rax + 1]; get color
            xor rax,rax
            mov al, bl
            xor rbx,rbx
            mov bl,al
            mov dword [rbp-0x8], r8d
            mov dword [rbp-0xc], r9d

			;--------- index color pallete
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
