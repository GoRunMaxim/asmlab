.model small
.stack 100h
.data      
size equ 30
msg db "Enter matrix...$"  
massiv dw size dup(?)
buffer db 7,7 dup('$')  
error db 10,13,"Error! You entered unacceptable symbols", 10, 13," or number was overflowed, start AGAIN", 10, 13, '$'
error_amount_less db 10,13, "amount should more than 0", 10,13,'$' 
error_amount_more db 10,13, "amount should less than 31", 10,13,'$'   
new_line db 10,13,'$'  
new_element db 10,13,"Enter new element:$"
base dw 10
sizeCh db 3, ?, 3 dup (?), '$'
sizeInt db ?
NumberCh db 7, ?, 7 dup (?), '$'
massInt dw 61, ?, 61 dup (?), '$'
MinNumb dw 7FFFh  
MaxNumb dw 8000h
Amount dw ?  
MinBorder dw ?
MaxBorder dw ?
OldRange dw ? 
NewRange dw ?
Divide dw ?
dexs dw 10 
double dw 2h
CountMessage db "******Entering amount of array:******", 0Ah, 0Dh, '$'
NumbersMessage db 0Ah, 0Dh, "******Entering your old array:******", 0Ah, 0Dh, '$'
MinBorderMess db 0Ah, 0Dh, "Enter Minimal border", 0Ah, 0Dh, '$'
MaxBorderMess db 0Ah, 0Dh, "Enter Maximal border", 0Ah, 0Dh, '$'
MaxLessMin db 0Ah, 0Dh, "Max Border Cannot be less then Min Border" , 0Ah, 0Dh, '$' 
OutPuting db 0Ah, 0Dh, "That is a result" , 0Ah, 0Dh, '$' 
NewString db 0Ah, 0Dh, '$'

.code
    
print_string macro str
    mov dx,offset str
    mov ah, 09h
    int 21h   
    endm

get_number proc  
input: 
    mov dx, offset buffer
    mov ah,0ah
    int 21h 
    
    mov si,1
    
    mov di,2
    xor ax,ax ;number in ax 
    xor cx,cx
    xor bx,bx
    mov cl, buffer+1  

buffer_cycle:    
    cmp cl, buffer+1
    jne get_digit
     
check_minus:
    mov bl, buffer+2
    cmp bl, '-'
    jne get_digit
    mov si,-1
    inc di
    loop buffer_cycle
    
get_digit: 
    mov bl, buffer[di]
    inc di
    sub bl, '0'
    jl error_input
    add bl,'0'
    sub bl,'9' 
    jg error_input
    add bl,'9'
       
create_number:
    mul base
    cmp ax, 8000h
    ja error_input   
    sub bx,'0'
    add ax, bx
    cmp ax, 8000h
    ja error_input
    loop buffer_cycle
    imul si
    cmp si, 1
    je is_positive
    ret    
     
is_positive: 
    or ax,ax
    js error_input
    ret
       
error_input: 
    print_string error
    jmp Main            
    ret
get_number endp  

get_numbers proc
    mov cx,Amount
    xor si,si
matloop:
    push cx
    push si
    print_string new_element
    call get_number
    pop si
    pop cx
    mov massiv[si],ax
    cmp ax, MinNumb
    jg MinFinding:
    mov MinNumb, ax
    MinFinding:
    cmp ax, MaxNumb
    jl MaxFinding:
    mov MaxNumb, ax
    MaxFinding:
    inc si
    inc si
    loop matloop
    ret
get_numbers endp

get_min proc
    mov ax, 0900h                   
    mov dx, offset MinBorderMess
    int 21h
    call get_number
    mov MinBorder, ax
    ret
get_min endp 

get_max proc
    mov ax, 0900h                   
    mov dx, offset MaxBorderMess
    int 21h
    call get_number
    mov MaxBorder, ax
    cmp ax, MinBorder
    jge MaxNotLess:
        mov ax, 0900h
        mov dx, offset MaxLessMin
        int 21h
        mov ax, 4C00h
        int 21h
    MaxNotLess:
    mov ax, MaxBorder	;ax = 400
    sub ax, MinBorder	;ax = 400-200 = 200
    mov NewRange, ax	;NewRange = 200
    mov Divide, ax	    ;Divide = 200
    mov ax, MaxNumb	    ;ax = 5
    sub ax, MinNumb	    ;ax = 5-1 = 4
    mov OldRange, ax    ;OldRange = 4     
    mov ax, NewRange
    mov dx, 0
    idiv OldRange
    mov Divide, ax
    xor bp, bp		
    mov ch, 00h		
    mov cl, sizeInt
    mov ax, Amount
    mov ax, 0
    mov si, ax
    mov cx, 0	
    NewNumbersInt:
    mov ax, 0	
    mov ax, massiv[si]	
    sub ax, MinNumb 
    imul Divide
    add ax, MinBorder
    cmp cx, Amount		
    jg Arrounding:
        mov massiv[si], ax		
        inc si
        inc si
        inc cx
        cmp cx, Amount
    jne NewNumbersInt: 		   
    Arrounding:					
	ret  
get_max endp


get_amount proc
    xor si,si
    call get_number
    mov Amount, ax
    cmp ax, 0    
    jg Min:
    mov ax, 0900h
    mov dx, offset error_amount_less
    int 21h
    mov ax, 4c00h 
    int 21h
    Min:
    cmp ax, 31
    jl Max: 
    mov ax, 0900h
    mov dx, offset error_amount_more
    int 21h
    mov ax, 4c00h 
    int 21h
    Max:
    mov MaxNumb, ax 
    
    ret
get_amount endp



print_number proc
    pusha
    xor di, di
    or ax, ax
    jns Convert
    push ax
    mov dx, '-'
    mov ah, 02h
    int 21h
    pop ax
    neg ax
convert:
    xor dx, dx
    div base; ostatok v dl
    add dl, '0'
    inc di
    push dx
    or ax, ax
    jnz convert

print:
    pop dx
    mov ah, 02h
    int 21h
    dec di
    jnz print
    popa
    ret
print_number endp

print_massiv proc
    mov ax, 0900h                   
    mov dx, offset OutPuting    ;Results
	int 21h
    pusha
    mov si, 0
    mov di, 0
    mov bx, dx
    mov cx, 0

print_el:
    mov ax, massiv[si]
    call print_number
    mov ah, 02h
    mov dl, ' '
    int 21h
    mov di, 0
    inc si
    inc si
    inc cx
    cmp cx, Amount
    jb print_el
    popa
    ret
print_massiv endp

Main:
    mov ax, @data
    mov ds, ax
    mov dx, offset CountMessage
    mov ah,9
    int 21h  
    call get_amount  
    mov ax, 0900h
    mov dx, offset NumbersMessage  ;elements of array
    int 21h
    call get_numbers
    call get_min
    call get_max
    
         
    call print_massiv
    mov ax, 4c00h 
    int 21h    
ends

end Main
