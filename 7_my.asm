.286
.model      small
.stack      100h

.data
    startMessage      db "CONSOLE PARAMETERS: ", '$'
    applicationError  db "APPLICATION START ERROR!", '$'
    negativeExit      db "ENTER CORRECT NUMBER!", '$'
    allocatingError   db "ALLOCATING MEMORY ERROR!", '$'
    badArguments      db "BAD ARGUMENTS ERROR!", 0dh, 0ah, '$'
    fileError         db "ERROR OPENING FILE!", '$'
    badFileName       db "BAD FILE NAME!", '$'

    partSize          equ 256
    wasPreviousLetter dw 0
    path              db 256 dup('$')
    tempVariable      dw 0
    isEndl            db 0
    spacePos          dw 0
    base              dw 10
    iterations        dw 0
    stringNumber      dw 0
    parsingStep       dw 1
    endl              db 13, 10, '$'

    tempString        db 256 dup('$')
    applicationName   db 256 dup(0)                 ;name of l5.exe
    part              db partSize dup('$')
    
    ;Exec Parameter Block (EPB) for funcion 4Bh
    env               dw 0

    dsize=$-startMessage          ;size of data segment 
.code

;printing string
printString proc  
    push    bp
    mov     bp, sp   
    pusha 
    mov     dx, [ss:bp+4+0]     
    mov     ax, 0900h
    int     21h 
    mov     dx, offset endl
    mov     ax, 0900h
    int     21h  
    popa
    pop     bp      
    ret 
endp

;output string
puts proc
    mov     ah, 9
    int     21h
    ret
endp

exit proc
    mov     ax, 4c00h
    int     21h
endp

;bad range
badRange:
    lea     dx, negativeExit
    call    puts
    call    exit
ret

;convert to int
toInteger proc
    pusha        
    xor     di, di
    lea     di, path 
    xor     bx, bx     
    xor     ax, ax   
    xor     cx, cx
    xor     dx, dx
    mov     bx, spacePos
    
    skipSpacesInteger:
        cmp     [di + bx], byte ptr ' '
        jne     unskippingInteger
        inc     bx
        jmp     skipSpacesInteger
    
    unskippingInteger:
        cmp     [di + bx], byte ptr '-'
        jne     atoiLoop
        jmp     atoiError

    atoiLoop:        
        cmp     [di + bx], byte ptr '0'    
        jb      atoiError  
        cmp     [di + bx], byte ptr '9'    
        ja      atoiError                     
        mul     base            ;mul 10
        mov     dl, [di + bx] 
        jo      atoiError 
        sub     ax, '0'  
        jo      atoiError
        add     ax, dx 
        inc     bx 
        cmp     [di + bx], byte ptr ' '
        jne     atoiLoop  
        jmp     atoiEnd 
    
    atoiError:
        jmp     badRange

    atoiEnd: 
        mov     tempVariable, ax 
        mov     spacePos, bx
        inc     parsingStep
        cmp     tempVariable, 255
        jg      badRange
        cmp     tempVariable, 0
        je      badRange
        popa
        ret
endp

;app error
applicationStartError:
    lea     dx, applicationError
    call    puts
    call    exit
ret

;memory allocating
allocateMemory proc
    push    ax
    push    bx 
    mov     bx, ((csize/16)+1)+256/16+((dsize/16)+1)+256/16
    mov     ah, 4Ah
    int     21h 
    jc      allocateMemoryError
    jmp     allocateMemoryEnd 
    allocateMemoryError:
        lea     dx, allocatingError
        call    puts
        call    exit    
    allocateMemoryEnd:
        pop     bx
        pop     ax
        ret
endp

;get iterations
getIterations proc
    pusha
    xor     ax, ax
    call    toInteger
    mov     ax, tempVariable
    mov     iterations, ax
    popa
    ret
endp

;load and run application
loadAndRun proc
    mov     ax, 4B00h      ;load and execute
    lea     dx, applicationName
    lea     bx, env
    int     21h
    jb      applicationStartError
    ret
endp

;get file name
getFilename proc
    pusha
    lea     di, path 
    xor     bx, bx     
    xor     ax, ax   
    mov     bx, spacePos
    skipSpacesString:
        cmp     [di + bx], byte ptr ' '
        jne     unskippingString
        inc     bx
        jmp     skipSpacesString
    unskippingString:
        lea si, applicationName
    copyFilename:
        xor     ax, ax
        mov     al, [di + bx] 
        mov     [si], al
        inc     bx
        inc     si
        cmp     [di + bx], byte ptr '$'
        jne     copyFilename
        mov     spacePos, bx
        popa
        ret
endp

;bad arguments call
badArgumentsCall:
    lea     dx, badArguments
    call    puts
    call    exit
ret

;start
start proc
    call    allocateMemory
    mov     ax, @data        ;move data segment address in DS
    mov     ds, ax
    mov     bl, es:[80h]     ;length of com line
    add     bx, 80h          ;args line last (call kernel)   
    mov     si, 82h          ;args line start
    mov     di, offset path
    cmp     si, bx
    ja      badArgumentsCall
    getPath:
        mov     al, es:[si]
        mov     [di], al
        cmp     BYTE PTR es:[si], byte ptr ' '
        jne     getNextCharacter
        cmp     wasPreviousLetter, 0
        je      skipCurrentSymbol
        mov     wasPreviousLetter, 0
        cmp     parsingStep, 1
        jne     stepThree
        call    getIterations
        jmp     skipCurrentSymbol
        ;stepTwo:
        ;    call    getStringNumber
        ;    jmp     skipCurrentSymbol
        stepThree:
            call    getFilename
            jmp     main
        getNextCharacter:
            mov     wasPreviousLetter, 1
        skipCurrentSymbol:
            inc     di
            inc     si
            cmp     si, bx
            jg      stepThree
    jbe getPath
    
    main:
        lea     dx, startMessage
        call    puts
        lea     ax, path 
        push    ax
        call    printString  
        pop     ax
        xor cx, cx
        mov cx, iterations
        startApps:
            call    loadAndRun
            loop    startApps
            call exit
endp

csize = $ - printString

end start