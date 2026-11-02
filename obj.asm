org 0x7E00
bits 16

start:
    mov ax, 0x0003
    int 0x10
    mov dl, 0
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 10
    mov dh, 0
    mov bx, file_table
    int 0x13
    jc .disk_err
    mov ax, [file_table]
    mov [file_count], ax
    jmp main_loop
.disk_err:
    mov word [file_count], 0
main_loop:
    call draw_screen
    call wait_input
    jmp main_loop

draw_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0100
    mov dx, 0x184F
    int 0x10
    mov dh, 1
    mov dl, 2
    call set_cursor
    mov si, header
    call print_string
    
    mov cx, [file_count]
    cmp cx, 0
    je .no_files
    mov bx, file_table + 2
    mov di, 0
.print_loop:
    push cx
    mov dh, 3
    add dh, di
    mov dl, 2
    call set_cursor
    mov si, bx
    call print_string
    add bx, 32
    inc di
    pop cx
    loop .print_loop
    jmp .done
.no_files:
    mov dh, 3
    mov dl, 2
    call set_cursor
    mov si, no_files_msg
    call print_string
.done:
    mov dh, 22
    mov dl, 0
    call set_cursor
    mov si, footer
    call print_string
    ret

wait_input:
    mov ah, 0x00
    int 0x16
    cmp al, 0x1B
    je show_menu
    jmp wait_input

show_menu:
    mov ax, 0x0600
    mov bh, 0x70
    mov cx, 0x0514
    mov dx, 0x0C32
    int 0x10

    mov dh, 5
    mov dl, 22
    call set_cursor
    mov si, menu_item1
    call print_string
    mov dh, 6
    mov dl, 22
    call set_cursor
    mov si, menu_item2
    call print_string
    mov dh, 7
    mov dl, 22
    call set_cursor
    mov si, menu_item3
    call print_string
    mov dh, 8
    mov dl, 22
    call set_cursor
    mov si, menu_item4
    call print_string
    mov dh, 9
    mov dl, 22
    call set_cursor
    mov si, menu_item5
    call print_string
    mov dh, 10
    mov dl, 22
    call set_cursor
    mov si, menu_item6
    call print_string
    mov dh, 11
    mov dl, 22
    call set_cursor
    mov si, menu_item7
    call print_string

.menu_wait:
    mov ah, 0x00
    int 0x16
    cmp al, '1'
    je create_file
    cmp al, '2'
    je write_file
    cmp al, '4'
    je read_file
    cmp al, '5'
    je load_console
    cmp al, '6'
    je shutdown
    cmp al, 0x1B
    je draw_screen
    jmp .menu_wait

create_file:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    mov si, prompt_create
    call print_string
    
    mov ax, [file_count]
    mov bx, 32
    mul bx
    mov di, file_table + 2
    add di, ax
    
    call read_string
    inc word [file_count]
    mov ax, [file_count]
    mov [file_table], ax
    
    mov si, msg_created
    call print_string
    mov ah, 0x00
    int 0x16
    jmp draw_screen

write_file:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    mov si, prompt_name
    call print_string
    
    mov di, search_buffer
    call read_string
    
    call find_file
    jc .not_found

    mov ax, bx
    mov bx, 256
    mul bx
    mov di, ax
    add di, 0x9000

    mov si, prompt_write
    call print_string
    call read_text
    mov si, msg_saved
    call print_string
    jmp .end
.not_found:
    mov si, msg_notfound
    call print_string
.end:
    mov ah, 0x00
    int 0x16
    jmp draw_screen


.find_end:
    cmp byte [di], 0
    je .found_end
    inc di
    jmp .find_end


read_file:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    mov si, prompt_name
    call print_string
    
    mov di, search_buffer
    call read_string
    
    call find_file
    jc .not_found
    
    mov ax, bx
    mov bx, 256
    mul bx
    mov si, ax
    add si, 0x9000
    
    mov si, prompt_read
    call print_string
    mov si, ax
    add si, 0x9000
    call print_string
    jmp .end
.not_found:
    mov si, msg_notfound
    call print_string
.end:
    mov si, msg_press
    call print_string
    mov ah, 0x00
    int 0x16
    jmp draw_screen

find_file:
    mov cx, [file_count]
    mov bx, file_table + 2
    cmp cx, 0
    je .not_found

.search:
    push cx
    push bx
    push si
    push di
    mov si, bx
    mov di, search_buffer
    mov cx, 32
    repe cmpsb
    pop di
    pop si
    pop bx
    pop cx
    je .found
    add bx, 32
    loop .search

.not_found:
    stc
    ret
.found:
    mov bx, [file_count]
    sub bx, cx
    clc
    ret

read_string:
    xor cx, cx
    mov byte [enter_count], 0
.loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .enter
    cmp al, 0x08
    je .backspace
    mov ah, 0x0E
    int 0x10
    mov [di], al
    inc di
    inc cx
    jmp .loop
.backspace:
    cmp cx, 0
    je .loop
    dec di
    dec cx
    mov al, 0x08
    mov ah, 0x0E
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .loop
.enter:
    mov al, 0x0D
    mov ah, 0x0E
    int 0x10
    mov al, 0x0A
    int 0x10
    inc byte [enter_count]
    cmp byte [enter_count], 4
    je .done
    jmp .loop
.done:
    mov byte [di], 0
    ret

read_text:
    xor cx, cx
    mov byte [enter_count], 0
.loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .enter
    cmp al, 0x08
    je .backspace
    mov ah, 0x0E
    int 0x10
    mov [di], al
    inc di
    inc cx
    jmp .loop
.backspace:
    cmp cx, 0
    je .loop
    dec di
    dec cx
    mov al, 0x08
    mov ah, 0x0E
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .loop
.enter:
    mov al, 0x0D
    mov ah, 0x0E
    int 0x10
    mov al, 0x0A
    int 0x10
    mov byte [di], 0x0D
    inc di
    mov byte [di], 0x0A
    inc di
    inc byte [enter_count]
    cmp byte [enter_count], 4
    je .done
    jmp .loop
.done:
    mov byte [di], 0
    ret

load_console:
    mov si, console_msg
    call print_string
    mov ax, 0x1000
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, 64
    mov ch, 0
    mov cl, 20
    mov dh, 0
    mov dl, 0
    int 0x13
    jc .err
    jmp 0x1000:0x0000
.err:
    mov si, err_msg
    call print_string
    mov ah, 0x00
    int 0x16
    jmp draw_screen

shutdown:
    mov si, shut_msg
    call print_string
    mov ax, 0x5301
    xor bx, bx
    int 0x15
    mov ax, 0x530E
    xor bx, bx
    mov cx, 0x0102
    int 0x15
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    cli
.halt:
    hlt
    jmp .halt

set_cursor:
    mov ah, 0x02
    xor bh, bh
    int 0x10
    ret

print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

file_count dw 0
cursor_pos dw 0
enter_count db 0
search_buffer db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

file_table:
    dw 0
    times 512-2 db 0

header db '--- MyOS File Manager ---', 0x0D, 0x0A, 0
no_files_msg db 'No files found. Press Esc for menu.', 0x0D, 0x0A, 0
footer db 'Esc: Menu', 0

menu_item1 db '1. Create File', 0
menu_item2 db '2. Write to File', 0
menu_item4 db '4. Read File', 0
menu_item5 db '5. Console (16-bit)', 0
menu_item6 db '6. Shutdown PC', 0
menu_item7 db 'Esc - Back', 0

prompt_create db 0x0D, 0x0A, 'Enter name (4x Enter): ', 0
prompt_name db 0x0D, 0x0A, 'Enter existing name (4x Enter): ', 0
prompt_write db 0x0D, 0x0A, 'Enter text (4x Enter): ', 0
prompt_update db 0x0D, 0x0A, 'Append text (4x Enter): ', 0
prompt_read db 0x0D, 0x0A, '--- File Content ---', 0x0D, 0x0A, 0

msg_created db 0x0D, 0x0A, 'File Created! Press any key...', 0
msg_saved db 0x0D, 0x0A, 'Text Saved! Press any key...', 0
msg_notfound db 0x0D, 0x0A, 'File not found!', 0
msg_press db 0x0D, 0x0A, 'Press any key...', 0
console_msg db 'Loading console.img...', 0x0D, 0x0A, 0
shut_msg db 0x0D, 0x0A, 'Shutting down...', 0x0D, 0x0A, 0
err_msg db 0x0D, 0x0A, 'Disk Error!', 0x0D, 0x0A, 0
nl db 0x0D, 0x0A, 0