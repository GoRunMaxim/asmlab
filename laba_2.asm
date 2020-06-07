.model small         ;in main string delete string
.stack 100h          ;after inputing string  
.data 
messageString    db           "Enter string: $"
messageSubstring    db 0Ah, 0Dh, "Enter substring: $"
messageResult    db 0Ah, 0Dh, "Result string: $"
enter       db 0Ah, 0Dh, "$"
lengt      equ 200 
 
Strb db lengt
Strl db '$'
Str  db lengt dup('$')
 
SubStrb db lengt
SubStrl db '$'
SubStr  db lengt dup('$')
 
.code
start:
    mov ax, @data
    mov ds, ax
    
    lea dx, messageString      ;Enter string         
    call outputString
    lea dx, Strb               ;...
    call inputString
    
    lea dx, enter               ;output  /n
    call outputString
    lea dx,messageSubstring     ;Enter substring      
    call outputString           ;...
    
    lea dx, SubStrb       
    call inputString
    lea dx, enter               ;output /n
    call outputString
    
    lea dx, messageResult   
    call outputString
    
    ;mov al, [Strl]              
    ;cmp al, [SubStrl]           
    ;jg exit
    
    xor cx, cx
    lea si, Str             ;beginning of Str
    dec si
    jmp start_find
    
    find:
    inc si
    cmp [si], ' '         
    je start_find           
    cmp [si], '$'          
    jne find
    jmp exit
    
                    
    start_find:
    inc si
    cmp [si],' '
    je start_find
    lea di, SubStr          ;beginning of SubString
    call searchSubString
    jmp find 
    
    
    
searchSubString proc
    push ax
    push cx
    push di
    push si
 
    xor cx,cx
    mov cl, [SubStrl]           ;cl=SubString.length() 
    compareString: 
    mov ah,[si] 
    dec cx
    cmp ah,[di]                ;if(sub[i]==substr[i])
    je  compare        
    jne NotEqual
    compare:   
    inc si
    inc di
    cmp cx,0                  
    je check
    jne compareString
 
check:
    cmp [si], ' '
    je Equal
    jne NotEqual
 
Equal:
    call length              
    call shift               
    call searchSubString
    
NotEqual:
    pop si
    pop di
    pop cx
    pop ax
    ret
    
searchSubString endp        
  
length proc
    push ax
    skip:  
    inc si  
    cmp [si], ' '       
    je skip
    mov ax,si            
    
    word:    
    mov dh,[si]
    inc si
    cmp [si], ' '           ;if equal to " "
    je continue
    cmp [si], '$'           ;if equal to END
    je continue
    jmp word
    continue:
    push si
    sub si,ax
    mov bx,si
    
    pop si  
    pop ax  
    ret
length endp      

shift proc
    push cx
    push di
    push bx
     
    lea ax, Str
    add al, [Strl]
    sub ax,si
    mov cx,ax
    add cx,2 
    
    ;sdvig
    sdvigg_vlevo:              
        mov ah,[si]         ;save element
        sub si, bx          ;move to the left  
        mov [si],ah 
        add si, bx
        inc si  
    loop sdvigg_vlevo  

  
    pop bx
    pop di
    pop cx
    ret     
shift endp
 

 
inputString proc
push ax 
mov ah, 0Ah
int 21h
pop ax   
ret 
inputString endp
 
outputString proc
push ax
mov ah, 09h
int 21h
pop ax
ret
outputString endp
 
exit:       
lea dx, Str
call outputString
mov ax,4c00h
int 21h
 
end start