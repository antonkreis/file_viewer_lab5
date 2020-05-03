.model small
.stack 100h 
.data
    eof_counter dw 0
    exit_flag db 0  
    prev_button_flag db 0 
    file_id dw ? 
    no_more_back_flag db 0
    greeting db 10, 13, "Lab 5: File viewer (in 16-bit format)", 10, 13, '$'
    commandline_not_found_message db "Please, enter the path of file in the command line", 10, 13, '$' 
    test_string db "c:/users/lenovo/desktop/big.txt", '$'
    ;test_string db 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19, 20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40, 41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,'$'   
    file_not_found_message db "Error! File not found.", 10, 13, '$'   
    path_not_found_message db "Error! Path not found.", 10, 13, '$'
    too_many_opened_files_message db "Error! To many files are opened.", 10, 13, '$'
    access_forbidden_message db "Error! Access is forbidden.", 10, 13, '$'
    wrong_access_mode_message db "Error! Wrong access mode.", 10, 13, '$' 
    read_access_forbidden_message db "Error! Read access is forbidden.", 10, 13, '$'
    wrong_id_message db "Error! Wrong file ID.", 10, 13, '$'
    unexpected_open_error_message db "Unexpected open error!", 10, 13, '$'  
    unexpected_read_error_message db "Unexpected read error!", 10, 13, '$' 
    unexpected_close_error_message db "Unexpected close error!", 10, 13, '$'
    offset_wrong_id_message db "Offset error! Wrong file ID.", 10, 13, '$'
    frame db 10, 13, "================================================================================", 10, 13, '$'
    buffer db 289 dup (0) 
    file_path db 126 dup ('$')
.code

print_string macro string
    mov ah, 9
    mov dx, offset string 
    int 21h 
print_string endm



open_file proc near    
    mov ah, 3Dh
    mov al, 0 ;mode: 11000001 - 7: not inherited, 100: no restrictions for other proc, 00: reserved, 0 - cannot write, 1 can read
    mov dx, offset file_path  
    ;mov dx, offset test_string
    mov cl, 0
    int 21h
    jc open_error 
    mov file_id, ax
    jmp end_open_file_proc:
open_error: 
    mov bl, 1
    mov exit_flag, bl
file_not_found:
    cmp ax, 02h
    jne path_not_found
    print_string file_not_found_message
    jmp end_open_file_proc  
path_not_found:
    cmp ax, 03h 
    jne too_many_opened_files
    print_string path_not_found_message 
    jmp end_open_file_proc
too_many_opened_files:  
    cmp ax, 04h  
    jne access_forbidden 
    print_string access_forbidden_message 
    jmp end_open_file_proc
access_forbidden:  
    cmp ax, 05h 
    jne wrong_access_mode
    print_string wrong_access_mode_message 
    jmp end_open_file_proc  
wrong_access_mode:
    cmp ax, 0Ch
    jmp unexpected_open_error
    print_string wrong_access_mode_message  
    jmp end_open_file_proc 
unexpected_open_error:
    print_string unexpected_open_error_message    
end_open_file_proc: 
    ret        
open_file endp 


close_file proc near   
    mov ah, 3Eh
    int 21h
    jc close_error
    jmp end_close_file_proc 
close_error:
    cmp ax, 06h
    jne unexpected_close_error
    print_string wrong_id
    jmp end_close_file_proc
unexpected_close_error:
    print_string unexpected_close_error_message    
end_close_file_proc:    
    ret
close_file endp
 
 
read_file proc near    
begin_read_file: 

    mov ax, @data
    mov es, ax   
cld
    mov al, 0
    lea di, buffer
    mov cx, 288
    rep stosb   
    xor ax, ax 
    mov ah, 3fh
    mov bx, file_id
    mov cx, 288
    mov dx, offset buffer
    int 21h 
    jc read_error 
    cmp ax, 288
    jne eof 
    mov al, 0
    mov prev_button_flag, al 
    jmp read
eof:
    mov eof_counter, ax 
    mov al, prev_button_flag
    
;    mov bx, ax  
;    mov si, offset buffer
;    mov ds:[si+bx], '$'
    jmp read
     
read_error:
    push ax
    call close_file
    pop ax
    mov bl, 1
    mov exit_flag, bl
read_access_forbidden:
    cmp ax, 05h
    jne wrong_id
    print_string read_access_forbidden_message
    jmp end_read_file_proc
wrong_id:
    cmp ax, 06h
    jne unexpected_read_error    
    print_string wrong_id_message 
    jmp end_read_file_proc
unexpected_read_error:
    print_string unexpected_read_error_message  
    jmp end_read_file_proc 
read: 
    mov di, offset buffer
    cmp ds:[di], 0
    je begin_of_file_error 
    cmp al, 0
    jne user_input 
    print_string frame
    call convert 
    jmp user_input  
    ;print_string buffer 
begin_of_file_error:
   mov ah, 42h
   mov al, 0
   mov bx, file_id
   mov cx, 0 
   ;mov cx, -1
   mov dx, 288
   int 21h 
   jc offset_error
   mov al, 1
   mov no_more_back_flag, al
user_input:   
   mov ah, 8
   int 21h
   cmp al, 1Bh ; ESC
   jne check_next_page
   mov bl, 2
   mov exit_flag, bl 
   jmp end_read_file_proc
check_next_page: 
   
   cmp al, 0Dh ; Enter 
   jne check_prev_page
    
   mov al, 0
   mov no_more_back_flag, al
   mov ax, eof_counter
   cmp ax, 0
   jne user_input
   jmp begin_read_file
   
check_prev_page:
   cmp al, 08h ; Backspace 
   jne user_input 
   mov al, no_more_back_flag 
   cmp al, 0
   jne user_input
   ;je user_input
   mov ax, eof_counter
   cmp ax, 0 
   jne sub_eof_counter
   mov ah, 42h
   mov al, 1
   mov bx, file_id
   mov cx, 0ffffh 
   mov dx, -288
   int 21h 
   jc offset_error
   jmp sub_prev_page 
offset_error:   
    call close_file
    mov bl, 1
    mov exit_flag, bl  
    print_string wrong_id_message
    jmp end_read_file_proc
   
sub_eof_counter:
   mov ah, 42h
   mov al, 1
   mov bx, file_id
   
   mov cx, 0ffffh 
   mov dx, eof_counter 
   neg dx 
   int 21h 
   jc offset_error
sub_prev_page:   
   mov ah, 42h
   mov al, 1
   mov bx, file_id
   mov cx, 0ffffh  
   mov dx, -288
   int 21h 
   jc offset_error
   mov al, 1
   mov prev_button_flag, al    
   mov ax, 0
   mov eof_counter, ax
    
   jmp begin_read_file
end_read_file_proc:    
    ret
read_file endp     
 
 
 
convert proc near  
    mov di, offset buffer
    mov bx, 0 
buffer_cycle:
    push bx   
   ; cmp bx, 288
;    je end_buffer_cycle
    xor ax, ax 
    mov al, ds:[di]
    cmp al, 0
    je end_buffer_cycle
 
    mov bx, ax
    cmp bx, 0 
    jne not_zero
    
    mov ah, 2
    mov dl, '0'    
    int 21h  

    jmp end_print_array
not_zero:       
    mov si, 0       
    xor dx, dx 
    push bx 
    mov bx, 16
    mov cx, 5
size:
    cmp ax, 16
    jl incr
    div bx 
    xor dx, dx
    inc si
    loop size 
    
incr:
    cmp si, 0
    jne not_print_zero 
    push ax
    push dx    
    mov ah, 2
    mov dl, '0'    
    int 21h 
    pop dx
    pop ax
not_print_zero:    
    pop bx      
    inc si         
number:     
    mov ax, bx 
    mov cx, si 
    dec cx 
    push bx
    mov bx, 16
division:
     cmp cx, 0
     je end_division
     div bx
     xor dx, dx 
     loop division 
end_division:     
     push ax
          
     mov ah, 2
     mov dl, al 
     cmp dl, 10
     jge letters
     add dl, 30h
     jmp print_numbers
letters:
     add dl, 37h
print_numbers:         
     int 21h  
   
     pop ax  
     mov cx, si  
     dec cx
multi:
    cmp cx, 0
    je end_multi
    mul bx
    loop multi  
end_multi:
    pop bx
    sub bx, ax 
    dec si
    cmp si, 0
    jne number    
end_print_array:
    pop bx 
    inc bx 
    test bx, 0Fh
    jnz test_4:
    mov ah, 2    
    mov dl, ' '   
    int 21h    
    mov dl, '|'   
    int 21h     
    mov dl, ' '   
    int 21h     
    push cx
    mov cx, 16  
    sub di, 15
print_text:
    mov dl, ds:[di]
    cmp dl, 0Ah
    je print_point
    cmp dl, 0Dh
    je print_point   
    int 21h 
    jmp not_print_point
print_point: 
    mov dl, '.'
    int 21h
not_print_point:    
    inc di           
    loop print_text
    pop cx
     
    mov dl, 0Ah   
    int 21h
    mov dl, 0Dh   
    int 21h 
    mov bx, 0  
    ;inc di
    jmp buffer_cycle
test_4:    
    test bx, 3
    jnz space
    mov ah, 2
    mov dl, ' '   
    int 21h 
space:    
    mov ah, 2 
    mov dl, ' '   
    int 21h 
    inc di   
    jmp buffer_cycle
end_buffer_cycle:
    pop bx   
    mov ah, 2
    
    ;mov dl, bl   
;    int 21h  
    cmp bx, 0
    je do_not_print_more
    mov ax, 16
    sub ax, bx
    mov cx, 3
    mul cx   


    
    mov dx, 12
    cmp bx, dx
    jge start_space_loop
    inc ax
    mov dx, 8 
    cmp bx, dx
    jge start_space_loop
    inc ax
    mov dx, 4
    cmp bx, dx
    jge start_space_loop
    inc ax   
   
    
start_space_loop:    
    mov cx, ax 
spaces:  
    mov ah, 2
    mov dl, ' '
    int 21h
    loop spaces 
    
    mov dl, '|'
    int 21h
          
    mov dl, ' '
    int 21h    
    mov cx, bx 
    
    sub di, bx

print_text_end:
    mov dl, ds:[di]
    cmp dl, 0Ah
    je print_point_end
    cmp dl, 0Dh
    je print_point_end   
    int 21h 
    jmp not_print_point_end
print_point_end: 
    mov dl, '.'
    int 21h
not_print_point_end:    
    inc di           
    loop print_text_end
    
do_not_print_more:      
      
    ret
convert endp    



 
 
start:
    mov ax, @data
    mov ds, ax    
    print_string greeting     
    mov cl, es:80h 
    cmp cl, 0
    je file_path_not_found
    mov si, offset file_path 
    mov di, 81h
    mov al, ' '
    repe scasb
    dec di

copy_path:
    mov al, es:[di]
    cmp al, 13
    je end_copy_path
    mov ds:[si], al
    inc si
    inc di 
    jmp copy_path 
 
file_path_not_found:    
    print_string commandline_not_found_message
    jmp program_end                                        
end_copy_path: 
           
    print_string file_path 
    mov al, 0
    mov ds:[si], al 
     
    call open_file   
    mov al, exit_flag
    cmp al, 1
    je program_end  
     
    call read_file
    mov al, exit_flag
    cmp al, 1
    je program_end  
finish:    
    call close_file
    jmp program_end

         
program_end:    
    mov ax, 4c00h
    int 21h 

end start