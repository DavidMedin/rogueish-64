segment .text
extern asprintf
extern free
extern printf

; void DrawInv( Buffer* buff, Entity* ent)
DrawInv:
	push rbp
	mov rbp, rsp

	push rdi; -0x8
	push rsi; -0x10
	
	;write to (1,1) of buffer
	; make a string from format and item name
	; get hand -> item -> item name
	mov rdi, rsi
	mov rsi, HAND
	call GetComponent
	cmp rax, 0
	jne .has_hand
		mov rdi, .no_comp
		mov rax, 0
		call printf
		jmp .fail
	.has_hand:
	
	cmp qword[rax+Hand.item], 0
	je .no_msg; no item, diffent message!
		jmp .has_item
	.no_msg:
		push 0 ; 0x18
		push rsp ; 0x20
		jmp .print
	.has_item:
	;has an item in hand
	mov rdi, [rax+Hand.item] ; assuming rdi is Entity**
	mov rdi, [rdi]
	mov rsi, ITEM
	call GetComponent
	cmp rax, 0
	jne .good_item
		; doesn't have an item component
		mov rdi, .no_comp
		mov rax, 0
		call printf
		jmp .fail
	.good_item:
	push 0
	push qword[rax+Item.name]; 0x20
	.print:
	sub rsp, 0x10; -0x28 & -0x30
	lea rdi, [rbp-0x28]
	mov rsi, .hand_msg
	mov rdx, [rbp-0x20];[rax + Item.name]
	mov rax, 0
	call asprintf
	;mov [rbp-0x20], rax

	mov rdi, [rbp-0x8]
	;mov rdi, [rdi]
	mov rsi, 1
	mov rdx, 1
	; write to rcx a string
	mov rcx, [rbp-0x28]
	mov r8, 18
	mov r9, 1
	push 0x3
	push 0x3
	call CopyText

	mov rdi, [rbp-0x28]
	call free

	.fail:
	.end:
	mov rsp, rbp
	pop rbp
	ret
	.no_comp: db "DrawInv: Entity doesn't have any hands!",10,0
	.no_item_comp: db "DrawInv: 'Item' doesn't have an [Item] entity!",10,0
	.hand_msg: db "Hand: %s",0
