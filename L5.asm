.model small
.stack 100h
.386
.data
sumbl db 1 dup(0)
buffercur db ?
argc dw 0
maxcmdsize equ 125
cmd_length dw ?
cmd_line db maxcmdsize+2,?,maxcmdsize dup(?)
buf db maxcmdsize+2,?,maxcmdsize dup('$')  
filename db 126 dup("$")
localsize dw 0  ;size of string that user entered
number dw 0
stringinfile dw 0
String13 db "karetka ", 13,10, "$"
String10 db "LF found", 13,10, "$"
StringFileOpenMsg db "File was opened ", 13,10, "$"
StringFileCloseMsg db "File was closed ", 13,10, "$"
StringErrorComandLineMsg db "Comand Line Error size",13,10,"$"
StringFileErrorOpenMsg db "File Error Open", 13,10, "$"
StringFileErrorCloseMsg db "File Error Close", 13,10, "$"
StringBeginMsg db "The program has begun ", 13,10, "$"
StringErrorParsMsg db "Error pars params in comand line",13,10,"$" 
StringErrorOwerflowMsg db "Error Owerflow of size:",13,10,"$"
StringEndMsg db "The program has end ", 13,10, "$"
StringinFileMsg db "The number of the matching line in the file: $"
StringAmpleAmountMsg db "Satisfying number of lines: $"
StringNewStr db 13,10,"$"
StringScobka db ") $"
StringSizeMsg db ".   size: $"
StringPlusMsg db " + $"
flag db 0
boolsh db 0
counter db 0
.code


Print_str macro msg
    push ax
    push dx
    mov ah,9
    mov dx,offset msg
    int 21h
    pop dx
    pop ax
endm 


Show_AX proc
    push bx
    push cx
    push dx
    push ax
    mov bx, 10
    xor cx,cx
Convert:
    xor dx,dx
    div bx           
    add dl, 30h
    push dx          
    inc cx           
    or ax, ax
    jnz Convert
Show1:
    pop dx 
    mov ah,2           
    int 21h
    dec cx            
    jnz Show1
    pop ax
    pop dx
    pop cx
    pop bx
    ret
Show_AX endp

IsEnough proc
    inc stringinfile
    push bx
    cmp counter,0
    jg finaly
    cmp si,localsize
    jae EndIsEnough ;jle
finaly:    
    inc number
    push ax
    mov ax,number
    call Show_AX
    pop ax
    Print_str StringScobka
    Print_str StringinFileMsg
    push ax
    mov ax,stringinfile
    call Show_AX
    Print_str StringSizeMsg
    cmp counter,0
    je finaly2
    push ax
    push cx
    xor cx,cx
    mov cl,counter
    mov ax,65535 
IsEnoughCycle:
    call Show_AX
    Print_str StringPlusMsg
    loop IsEnoughCycle
    pop cx
    pop ax
finaly2:        
    mov ax,si
    call Show_AX
    pop ax
    
    Print_str StringNewStr
EndIsEnough:
    pop bx    
    ret
IsEnough endp

Makeparams proc
    push si
    push di
    push dx
    push cx
    xor si,si
    xor di,di   
sravn:    
    cmp cmd_line[si],' '
    jne nextstep
    call SkipSpaces
    inc argc
    cmp argc,2
    je second
    cmp argc,3
    je third
nextstep:
    mov dl,cmd_line[si]
    mov buf[di],dl
    inc di
    inc si
    xor dx,dx
    mov dx,cmd_length
    cmp si,dx
    jne sravn
    jmp third 
second:
    mov cx,di
    xor di,di
secondcycle:
    xor dx,dx
    mov dl,buf[di]
    mov filename[di],dl
    mov buf[di],"$"
    inc di
    loop secondcycle
    mov filename[di],0
    xor di,di
    jmp sravn
third:
    mov cx,di
    xor di,di
thirdcycle:
    cmp buf[di],30h
    jl ErrorEnded2
    cmp buf[di],39h
    jg ErrorEnded2
    push ax
    push bx
    mov bx,10
    mov ax,localsize
    mul bx
    mov localsize,ax
    pop bx
    pop ax
    jc ErrorEnded1
    
    push ax
    xor ax,ax
    mov al,buf[di]
    sub al,30h
    add localsize,ax
    pop ax
    jc ErrorEnded1
    inc di
    loop thirdcycle
    jmp EndMakeparams    
ErrorEnded1:
    pop cx
    Print_str StringErrorOwerflowMsg
    jmp ErrorEnds        
ErrorEnded2:
    Print_str StringErrorParsMsg
ErrorEnds:
    pop cx    
    pop dx    
    pop si
    pop di
    jmp Exit                      
EndMakeparams:
    pop cx    
    pop dx    
    pop si
    pop di
    ret
Makeparams endp        

SkipSpaces proc
SkipCycle:    
    cmp cmd_line[si],' '
    je skip
    jmp EndSkip
skip:
    inc si
    jmp SkipCycle
EndSkip:    
    ret
SkipSpaces endp    


start:
    cmp boolsh, 1
    jne m
    dec stringinfile 
    m:
    mov ax, @data
    mov es, ax
    
    xor cx,cx
    mov cl,ds:[80h]
    mov bx,cx
    mov si,81h
    mov di,offset cmd_line
    rep movsb
    
    mov ds,ax
    Print_str StringBeginMsg    ;the program has begun
    mov cmd_length,bx

    call Makeparams    
    
    mov dx,offset filename
    mov ah,3Dh
    mov al,00h
    int 21h
    jc ErrorExit2 
    Print_str StringFileOpenMsg
    mov bx,ax
    mov di,01
    push si
Cycle:    
    call Read
    jmp Cycle
Close:
    call Ended
    jmp Exit
    
ErrorExit1:    
    Print_str StringErrorComandLineMsg
    jmp Exit
ErrorExit2:
    Print_str StringFileErrorOpenMsg
    jmp Exit
ErrorExit3:
    Print_str StringFileErrorCloseMsg                
Exit:
    Print_str StringEndMsg    
    mov ax, 4c00h
    int 21h

Read proc
    push cx
    push si
    xor si,si
    mov cx,1
ReadCycle:
    mov dx,offset sumbl
    mov al, sumbl
    mov buffercur,al
    mov ah,3Fh  ;read from file
    int 21h
    jc ErrorExit2
    mov cx,ax
    jcxz Close 
    inc si
    cmp si,65535
    je @count
lstep:    
    cmp sumbl,10
    je EndRead13
    cmp sumbl,10
    je EndRead0 
    jmp ReadCycle
@count:
    inc counter
    jmp lstep    
EndRead13:
    mov flag, 1
    jmp EndRead
EndRead0:
    cmp flag,1
    jne EndRead
    mov flag,0
    dec stringinfile         
EndRead:
    cmp buffercur, 13
    jne r
    mov boolsh, 1 
    r:
    dec si     
    call IsEnough   
    pop si
    pop cx
    ret
Read endp



    
Ended proc
    cmp buf,13
    call IsEnough
    mov ah,3Eh
    int 21h
    jc ErrorExit3 
    Print_str StringNewStr
    Print_str StringAmpleAmountMsg
    push ax
    mov ax,number
    call Show_AX
    pop ax
    Print_str StringNewStr
    Print_str StringFileCloseMsg
    jmp endEnded
ErrorExitl:
    Print_str StringFileErrorCloseMsg                
    Print_str StringEndMsg    
    mov ax, 4c00h
    int 21h
endEnded:    
    ret
Ended endp        

end start