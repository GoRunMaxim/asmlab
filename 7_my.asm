.model tiny
	.code
	.186
	org 100h	;com-program
start:          
	mov		ch, 0
	mov		cl, es:[0080h]
	mov		si, 81h
	lea		di, programPath    
	mov		bx, maxCmdSize
	call	readParam	
	lea		di, [commandText + 1]
	mov		bx, 126
	call	readParamWithSpaces    
	
	cmp		programPath[0], 0
	je		invalidCommandLineArgs		
	
	call	calcCommandLineSize	           	             
	             
    mov		ah, 09h
    mov		dx, offset message
    int		21h

    mov		ah, 0Ah
    mov		dx, offset userInput
    int		21h  

    mov		si, offset string      
    call	atoi  
    cmp		error, 1
    jne		loadProgram
    mov		ah, 09h
    mov		dx, offset invalidNumberMessage
    int		21h
    jmp		start    
    
loadProgram:              
	mov 	ah, 09h
    mov 	dx, offset newLine
    int 	21h                              
	mov 	sp, programLength + 100h + 200h	 ; перемещение стека на 200h после конца программы
	mov 	ah, 4Ah							 ;освободить всю память после конца программы и стека
	stackShift = programLength + 100h + 200h ;размер в параграфах +1
	mov 	bx, stackShift shr 4 + 1
	int 	21h 
	; exec parameter block ( load and run )
	mov 	ax, cs
	mov 	word ptr EPB + 4, ax		; cmd segment
	mov 	word ptr EPB + 8, ax		; fcb1 segment
	mov 	word ptr EPB + 0Ch, ax		; fcb2 segment
	xor 	cx, cx
	mov 	cl, N_times
runProgram:
	mov 	ssSeg, ss
	mov 	spSeg, sp
	mov		ax, 4B00h
	mov 	dx, offset programPath ;путь к файлу
	mov 	bx, offset EPB		   ;блок epb
	int 	21h					   ;запуск программы
	jc 		errorDuringLoadingProgram
	loop 	runProgram
	mov 	ss, cs:ssSeg
	mov 	sp, cs:spSeg
    jmp 	exitStart
errorDuringLoadingProgram:
    mov 	ah, 09h
    mov 	dx, offset error4Bh
    int 	21h
    jmp 	exitStart 
invalidCommandLineArgs:
    mov 	ah, 09h
    mov 	dx, offset invalidCmdArgs
    int 	21h
exitStart:
	int 	20h						;ret нельзя- стек перемещен
proc	calcCommandLineSize
		mov		cx, maxCmdSize
		mov		al, 0Dh   
		lea		di, commandText
		repnz	scasb    
		neg		cx        
		dec		cx
		add		cx, maxCmdSize
		cmp		cx, 1
		jne		cmdNotEmpty		                              
		mov		cx, 0		   
cmdNotEmpty:		                               
		mov		commandLine, cl	                                     
endp	calcCommandLineSize	                    
               
               
proc	readParam		
		push	ax	  
		push	bx     	          	    
		cmp		cx, 0	           
	 	jle		exitReadParam 	      	                  	                  
skipSpaces:
		push	di
		mov		di, si
		mov		al, ' '
		repz	scasb	   
		dec		di   
		inc		cx
		mov		si, di  
		pop		di   
findParamEnd:
		movsb     
		dec		bx
		dec		cx
		cmp		bx, 0
		je		paramEnded
		cmp		byte ptr es:[di - 1], 0Dh
		je		paramEnded
		cmp		byte ptr es:[di - 1], ' '
		jne		findParamEnd
paramEnded:	   		
		dec		di    
		mov		byte ptr es:[di], 0
		inc		di
exitReadParam:	  
		pop		bx   
		pop		ax	     		        	
		ret	            	
endp	readParam  
		                
proc	readParamWithSpaces	
		push	ax	
		push	bx       	          	
		cmp		cx, 0	      
	 	jle		exitReadParam2	        	      	                  	                
		        
findParamEnd2:
		movsb    
		dec		cx    
		dec		bx
		cmp		bx, 0
		je		paramEnded2
		cmp		byte ptr es:[di - 1], 0Dh
		je		paramEnded2
		jmp		findParamEnd2
		
paramEnded2:	   		
		dec		di    
		mov		byte ptr es:[di], 0Dh
		inc		di

exitReadParam2:	      
		pop		bx
		pop		ax	     		        	
		ret	            	
endp	readParamWithSpaces



	                
atoi	proc
;==== ds:si - string address ===  
    	push bx
    	push cx
    	push dx
    	push si  
 
    	xor bx, bx
    	xor dx, dx 
    	mov error, 0
    	
getNumberLength:
        xor cx, cx
        mov di, offset length
        mov cl, [di] 
        cmp cl, 0
        je invalidInput      	
convert:	
        xor ax, ax
    	lodsb
        cmp al, '-'	
    	je invalidInput	
        cmp al, '9'
    	jnbe invalidInput    
    	cmp al, '0'    
    	jb invalidInput   
    	sub ax, '0'	
    	shl dx, 1	
    	add ax, dx
    	shl dx, 2	
    	add dx, ax  
    	cmp dx, MAX_NUMBER
    	jg invalidInput 
    	cmp dx, 0
    	je invalidInput
loop convert
        jmp exit

invalidInput:
        mov error, 1
exit:   
        mov ax, dx 
        mov N_times, al             
    	pop si
    	pop dx 
    	pop cx
    	pop bx
	    
	    ret 
atoi	endp 
	
	
maxCmdSize		EQU		126

message			db		'Emount of start?', 10, 13, ': $'     
newLine         db      10, 13, '$' 
invalidNumberMessage    db      'Invalid input: number should contain only digits in the following range [1, 255]', 10, 13, '$' 
invalidCmdArgs          db      'Invalid command line input. Try again.', 10, 13, '$' 
error4Bh                db      'Error has happened during loading/running program.', 10, 13, 'Check your program path and try again', '$'        
error           db      0
ssSeg			dw		0			; stack register keepers
spSeg			dw		0
userInput    	EQU $               ; Buffer for string
				maxLength db 4      ; Maximum characters buffer can hold
				length 	  db 0      ; Number of characters actually read,
				string    db 4 dup ('$')          ; Actual characters read, including the final carriage return (0Dh)
N_times			db		0	
programPath		db		128 dup(0)			;asciz string
				
EPB				dw		0000				;текущее окружение
				dw 		offset commandLine, 0	;адрес командной строки
				dw 		005Ch, 0, 006Ch, 0	;Адреса FCB (File control block) программы
				
commandLine		db		maxCmdSize			;длина командной строки
commandText		db 		' ', maxCmdSize dup(0Dh)	;командная строка
MAX_NUMBER		equ		255
programLength	equ		$ - start 

end start
