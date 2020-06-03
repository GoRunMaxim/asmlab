.MODEL small
.STACK 100h
.386
.DATA
	instructionsMessage db "W - rotate, A - move left, D - move right, S - speed up falling", 0Ah, 0Dh, "ENTER ANY KEY$"
	lostMessage db "YOU LOST$"
	scoreMessage db "SCORE: $"

    FIELD_WIDTH equ 10
	FIELD_HEIGHT equ 20

	FIGURE_ASCII equ '*'
	FIGURE_ATTRIBUTE equ 5Bh

	FIELD_BG equ 61h
	FIELD_ASCII_BG equ 'O'
	FIELD_ASCII_FIGURE equ  '*'
	FIELD_BG_FIGURE equ 00101001b

	BASIC_DELAY equ 0010h
	SHORT_DELAY equ 0003h

	lastTimer dw 0
	delay dw BASIC_DELAY
	score dw 0
	numberBuffer db 8 DUP('$')

	figure	db 0, 0 
			db 0, 0
			db 0, 0
			db 0, 0
	figure_buffer	db 0, 0 
					db 0, 0
					db 0, 0
					db 0, 0
	rotate db 0 ;BOOL rotate
	xOffset dw 0 ;Offset on X axis

	buffer db 0
	field db 200 DUP(0)

	L_SHAPE_RIGHT db 2, 3, 5, 7
	L_SHAPE_LEFT  db 3, 5, 7, 6
	Z_SHAPE db 2, 4, 5, 7
	S_SHAPE db 3, 5, 4, 6
	T_SHAPE db 3, 5, 4, 7
	I_SHAPE db 1, 3, 5, 7	
	BOX_SHAPE   db 2, 3, 4, 5

.CODE
check macro
    local figureLoop, returnZero, finish
    push cx
    push si
    push ax
    mov cx, 4
    xor si, si
    figureLoop:
        cmp figure[si], 0
        jl returnZero
        cmp figure[si], FIELD_WIDTH
        jge returnZero
		cmp figure[si + 1], FIELD_HEIGHT
		jge returnZero

		;Collistion detection
		xor ax, ax
		mov al, figure[si + 1]
		push cx
		mov cx, FIELD_WIDTH
		mul cx
		pop cx     
		add al, figure[si]
		mov di, ax     
        cmp field[di], 0
		jne returnZero

        add si, 2
    loop figureLoop
    mov di, 1
    jmp finish
    returnZero:
        mov di, 0
    finish:
    pop ax
    pop si
    pop cx
    endm
generateFigure macro
    local figureLoop
    push cx
    push ax
    push dx
    push si
    push di

    mov ah, 00h
    int 1Ah ;
    mov ax, dx
    xor dx, dx
    mov cx, 7
    div cx
    mov di, dx ;Figure index
   
    mov cx, 4
    xor si, si

    mov ax, di
    mul cx
    mov di, ax
    add di, offset L_SHAPE_RIGHT ;DI now contains figure's address

    figureLoop:
        mov al, [di]
        push cx
        mov cx, 2
        div cx
        pop cx

        mov figure[si], dl ;DL is % 2
        mov figure[si + 1], al ; AL is (int) / 2

        add si, 2
        inc di
    loop figureLoop

    pop di
    pop si
    pop dx
    pop ax
    pop cx
    endm
toString proc ;SI points to number
    push ax
    push cx
    push di
    push dx

    xor di, di
    mov ax, [si]
    mov cx, 10
    toSLoop:
        xor dx, dx
        div cx
        add dx, '0'
        mov numberBuffer[di], dl
        inc di
    cmp ax, 0
    jne toSLoop
    mov numberBuffer[di], '$'

    call reverse

    pop dx
    pop di
    pop cx
    pop ax
    ret
    toString endp
reverse proc
    push ax
    push di
    push si

    xor di, di
    mov si, di
    siLoop:
        cmp numberBuffer[si], '$'
        je loopFin
        inc si
    jmp siLoop
    loopFin:
    dec si

    reverseLoop:
        mov al, numberBuffer[si]
        mov ah, numberBuffer[di]
        mov numberBuffer[si], ah
        mov numberBuffer[di], al
        inc di
        dec si
    cmp di, si
    jl reverseLoop
    pop si
    pop di
    pop ax
    ret
    reverse endp
addOnField macro 
	local figureLoop
	push cx
	push ax
	push dx
	push si
	push di

	mov cx, 4
	xor si, si
	figureLoop:
		xor ax, ax
		mov al, figure_buffer[si + 1]

		push cx
		mov cx, FIELD_WIDTH
		mul cx
		pop cx
		add al, figure_buffer[si]
		mov di, ax

		mov field[di], 1
		add si, 2
	loop figureLoop

	pop di
	pop si
	pop dx
	pop ax
	pop cx
	endm
checkLines macro 
	local rowLoop, colLoop, rowLoopEnd, rowElimLoop, pointLoop
	push bx
	push ax
	push si
	push cx

	mov ax, FIELD_HEIGHT - 1
	mov cx, FIELD_WIDTH
	mul cx
	mov si, ax

	mov cx, FIELD_HEIGHT - 2

	rowLoop:
		push cx

		mov bx, si
		add bx, FIELD_WIDTH - 1
		mov cx, FIELD_WIDTH
		colLoop:
			mov al, field[bx]
			cmp al, 0
			je rowLoopEnd
			dec bx
		loop colLoop
		
		mov cx, FIELD_HEIGHT - 2
		rowElimLoop:
			push cx
			mov cx, FIELD_WIDTH
			pointLoop:
				inc bx
				mov al, field[bx - FIELD_WIDTH]
				mov field[bx], al
			loop pointLoop

			sub bx, FIELD_WIDTH
			sub bx, FIELD_WIDTH
			pop cx
		loop rowElimLoop
		add si, FIELD_WIDTH
		mov ax, score
		add ax, 1
		mov score, ax

		rowLoopEnd:
		sub si, FIELD_WIDTH
		pop cx
	loop rowLoop

	pop cx
	pop si
	pop ax
	pop bx
	endm
clearScreen macro
    push ax
    mov ax, 03h
    int 10h
    pop ax
    endm
drawFigure macro
	local figureLoop
	push cx
	push ax
	push dx
	push si
	push es
	push di

	mov cx, 4
	xor si, si
	figureLoop:
		xor ax, ax
		mov al, figure[si + 1]

		push cx
		mov cx, 160
		mul cx
		mov di, ax
		xor ax, ax
		mov al, figure[si]
		mov cx, 2
		mul cx
		add di, ax
		pop cx

		mov al, FIGURE_ASCII
		mov ah, FIGURE_ATTRIBUTE
		stosw
		add si, 2
	loop figureLoop

	pop di
	pop es
	pop si
	pop dx
	pop ax
	pop cx
	endm
drawField macro
	local fieldLoopH, fieldLoopW, next, nothing
	push cx
	push ax
	push si
	push di
	push es

	mov ax, 0B800h
	mov es, ax

	mov cx, FIELD_HEIGHT
	xor si, si
	xor di, di
	fieldLoopH:
		push cx
		mov cx, FIELD_WIDTH
		fieldLoopW:
			mov al, field[si]
		
			cmp al, 1
			jne nothing

			mov ah, FIELD_BG_FIGURE
			mov al, FIELD_ASCII_FIGURE
			jmp next
		
			nothing:
			mov ah, FIELD_BG
			mov al, FIELD_ASCII_BG
		
			next:
			stosw
			inc si
		loop fieldLoopW
		add di, 160 - FIELD_WIDTH
		sub di, FIELD_WIDTH
		pop cx
	loop fieldLoopH
	drawFigure

	pop es
	pop di
	pop si
	pop ax
	pop cx
	endm
isLost macro
	local isLostLoop, lost, finish
	push cx
	push ax
	push si

	mov cx, FIELD_WIDTH
	mov si, FIELD_WIDTH
	isLostLoop:
		xor ax, ax
		mov al, field[si]
		cmp ax, 1
		je lost
		inc si
	loop isLostLoop
	mov di, 0
	jmp finish
	lost:
	mov di, 1
	
	finish:
	pop si
	pop ax
	pop cx
	endm
saveFigure macro
	push si
	push di
	push cx
	push es
	push ds
	pop es
	lea di, figure_buffer
	lea si, figure
	mov cx, 4
	rep movsw
	pop es
	pop cx
	pop di
	pop si
	endm
loadFigure macro
	push si
	push di
	push cx
	push es
	push ds
	pop es
	lea di, figure
	lea si, figure_buffer
	mov cx, 4
	rep movsw
	pop es
	pop cx
	pop di
	pop si
	endm

rotateFigure macro
	local figureLoop
	push cx
	push ax
	push si
	push di
	push bx
		cmp rotate, 0
		je finish

		saveFigure
		lea di, figure ;Center of rotation
		add di, 2

		mov cx, 4
		xor si, si
		figureLoop:
			mov al, figure[si + 1]	;xOffset
			sub al, [di + 1]
			mov dl, figure[si]	;yOffset
			sub dl, [di]

			mov bl, [di]
			add bl, al
			mov figure[si], bl	;new X

			mov bl, [di + 1]
			sub bl, dl
			mov figure[si + 1], bl	;new Y

			add si, 2
		loop figureLoop

		check
		cmp di, 0
		jne finish
		loadFigure

	finish:
	pop bx
	pop di
	pop si
	pop ax 
	pop cx
	endm
moveDown macro
	local figureLoop, finish
	push cx
	push si
	saveFigure
	mov cx, 4
    mov si, 1
    figureLoop:
		inc figure[si]
        add si, 2
    loop figureLoop
	finish:
	pop si
	pop cx
	endm
moveSide macro
	local figureLoop, finish
	push cx
	push si
	push ax

	cmp xOffset, 0
	je finish

	saveFigure
	mov cx, 4
	xor si, si
	xor ax, ax
	figureLoop:
		mov al, figure[si]
		add ax, xOffset
		mov figure[si], al
		add si, 2
	loop figureLoop

	check
	cmp di, 0
	jne finish
	loadFigure

	finish:
	pop ax
	pop si
	pop cx
	endm
input macro
	local notPressedAnyKey, a, d, s, clearBuffer
	push ax
	push dx
	xor ax, ax

	mov ah, 06h
	mov dl, 0ffh
	int 21h
	jz notPressedAnyKey

	push ax
	clearBuffer:
	int 21h
	jnz clearBuffer
	pop ax
	
	cmp al, 'w'
	jne s
	mov rotate, 1
	jmp notPressedAnyKey

	s:
	cmp al, 's'
	jne a
	mov delay, SHORT_DELAY
	jmp notPressedAnyKey
	
	a:
	cmp al, 'a'
	jne d
	mov xOffset, -1
	jmp notPressedAnyKey

	d:
	cmp al, 'd'
	jne notPressedAnyKey
	mov xOffset, 1

	notPressedAnyKey:
	pop dx
	pop ax
	endm
isDelayPassed macro
	push dx
	push cx
		mov ah, 0
		int 1Ah 
		mov ax, dx 
		sub dx, lastTimer
		cmp dx, delay
	pop cx
	pop dx
	endm
printStr macro string
    push dx
    push ax
    lea dx, string
    mov ah, 09H
    int 21h
    pop ax
    pop dx
    endm
printLn macro
    push dx
    push ax
        mov ah, 02h
        
        mov dl, 0Ah ; \n
        int 21h

        mov dl, 0Dh ; \r
        int 21h
    pop ax
    pop dx
    endm
main:
	mov ax, @DATA
	mov ds, ax
	clearScreen
	printStr instructionsMessage
	printLn
	mov ah, 0Ah
	int 21h
	clearScreen
    generateFigure
	while:
		isDelayPassed
		jb skip

		mov delay, BASIC_DELAY
		input

		moveSide
		rotateFigure
		moveDown
	
		check
		cmp di, 0
		jne notHit

		addOnField
		checkLines
		
		isLost
		cmp di, 1
		je lost
		
		generateFigure

		notHit:
		drawField
		mov lastTimer, ax
		mov xOffset, 0
		mov rotate, 0


		skip:
	jmp while
	lost:
	clearScreen
	printStr lostMessage
	printLn
	printStr scoreMessage
	lea si, score
	call toString
	printStr numberBuffer
	printLn
	
	int 20h
end main