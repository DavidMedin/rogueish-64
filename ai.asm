segment .text
extern printf
extern GetRandomValue

AIMove:
	push rbp
	mov rbp, rsp

	; Get all ai driven things
	mov rcx, entity_list
	push rcx ; 0x0x8
	sub rsp, 0x8
	.top:
		cmp qword[rcx], 0
		je .bot
		
		mov rdi, [rcx]
		mov rsi, AI
		call GetComponent
		cmp rax, 0
		je .skip
			; is AI! check for position now
			mov rdi, [rbp-0x8]
			mov rdi, [rdi]
			mov rsi, POSITION
			call GetComponent
			cmp rax, 0
			jne .has_position
				; doesn't have position, report
				mov rsi, rdi
				mov rdi, .no_person_msg
				mov rax, 0 ; pointless
				call printf
				jmp .skip
			.has_position:
				; move the zombie, I guess
				; Get relative distance to player
				; use sign to move max of 1 in x or y
				mov [rsp], rax ; 0x10
				push 0; x - 0x18
				push 0; y - 0x20
				;push rax ; 0x18 -> zombie's position
				mov rdi, [hero_data]
				mov rsi, POSITION
				call GetComponent
				; I'm so sure it works, I'm not going to check
				mov rbx, [rax+Position.x]
				mov rcx, [rbp-0x10]
				cmp [rcx+Position.x], rbx
				jg .left
				jl .right
				jmp .hor

				.left:
					mov qword[rbp-0x18],-1
					jmp .hor
				.right:
					mov qword[rbp-0x18], 1
				.hor:

				mov rbx, [rax+Position.y]
				mov rcx, [rbp-0x10]
				cmp [rcx+Position.y], rbx
				jg .up
				jl .down
				jmp .vert
				.up:
					mov qword[rbp-0x20], -1
					jmp .vert
				.down:
					mov qword[rbp-0x20], 1
				.vert:
				; move!

				mov rdi, game_buffer
				mov rsi, [rbp-0x10]
				mov rsi, [rsi+Position.x]
				add rsi, [rbp-0x18]
				mov rdx, [rbp-0x10]
				mov rdx, [rdx+Position.y]
				add rdx, [rbp-0x20]
				sub rsp, 0x10; 0x28 & 0x30
				lea rcx, [rbp-0x28]
				call CanMove
				cmp rax, 0
				jne .good
					int03
				.good:
				cmp rax, 1
				je .miss
				; Hit!
					cmp qword[rbp-0x28], 0
					je .skip ; what we hit was a wall or something
					mov rsi, [rbp-0x8]
					mov rsi,[rsi]
					mov rdi, [rbp-0x28]
					call Attack
					jmp .skip
				.miss:
					; move!
					mov rdi, 0
					mov rsi, 10
					call GetRandomValue
					cmp rax, 5
					jl .skip

					mov rbx, [rbp-0x10] ; position
					mov rcx, [rbp-0x18]
					add [rbx+Position.x], rcx
					mov rcx, [rbp-0x20]
					add [rbx+Position.y], rcx
		.skip:
		lea rsp, [rbp-0x10]
		
		mov rcx, [rbp-0x8]
		add rcx, 0x8
		mov [rbp-0x8], rcx
		jmp .top
	.bot:
	.fail:
	.end:
	mov rsp, rbp
	pop rbp
	ret
segment .data
	.no_person_msg: db "This [AI] holder doesn't have a [POSITION] component! (%p)",10,0

segment .text
