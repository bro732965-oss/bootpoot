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
    add dh, [cursor_pos]
    mov dl, 2
    call set_cursor
    mov si, bx
    call print_string
    add bx, 16
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
    cmp al, 0x1B   ; Esc - меню
    je show_menu
    cmp al, 0x0D   ; Enter - открыть
    je open_file
    cmp ah, 0x48   ; Стрелка вверх
    je move_up
    cmp ah, 0x50   ; Стрелка вниз
    je move_down
    jmp wait_input

move_up:
    cmp word [cursor_pos], 0
    je wait_input
    dec word [cursor_pos]
    jmp wait_input

move_down:
    mov ax, [file_count]
    dec ax
    cmp [cursor_pos], ax
    jge wait_input
    inc word [cursor_pos]
    jmp wait_input

open_file:
    mov si, bin_msg
    call print_string
    mov ah, 0x00
    int 0x16
    jmp draw_screen

show_menu:
    mov ax, 0x0600
    mov bh, 0x70
    mov cx, 0x0514
    mov dx, 0x0B32
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

.menu_wait:
    mov ah, 0x00
    int 0x16
    cmp al, '1'
    je create_file
    cmp al, '2'
    je load_console
    cmp al, '4'
    je edit_file
    cmp al, '5'
    je shutdown
    cmp al, 0x1B
    je draw_screen
    jmp .menu_wait

create_file:
    mov si, create_prompt
    call print_string
    mov ax, [file_count]
    mov bx, 16
    mul bx
    mov di, file_table + 2
    add di, ax
    mov cx, 8
.read_name:
    mov ah, 0x00
    int 0x16
    mov ah, 0x0E
    int 0x10
    mov [di], al
    inc di
    loop .read_name
    mov byte [di], 0
    inc word [file_count]
    mov ax, [file_count]
    mov [file_table], ax
    jmp draw_screen

edit_file:
    mov si, edit_prompt
    call print_string
    mov di, file_content
    mov cx, 32
.read_text:
    mov ah, 0x00
    int 0x16
    mov ah, 0x0E
    int 0x10
    mov [di], al
    inc di
    loop .read_text
    mov byte [di], 0
    jmp draw_screen

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
file_table:
    dw 0
    times 512-2 db 0
file_content db 0

header db 'teapot', 0x0D, 0x0A, 0
no_files_msg db 'No files found. Press Esc to create.', 0x0D, 0x0A, 0
footer db 'Arrows: Move | Enter: Open | Esc: Menu', 0
menu_item1 db '1. Create File', 0
menu_item2 db '2. Console (16-bit)', 0
menu_item3 db '3. Save & Exit', 0
menu_item4 db '4. Edit File (text)', 0
menu_item5 db '5. Shutdown PC', 0
bin_msg db 'Loading...', 0x0D, 0x0A, 0
create_prompt db 0x0D, 0x0A, 'Name (8 chars): ', 0
edit_prompt db 0x0D, 0x0A, 'Enter text (32 chars): ', 0
console_msg db 'Loading console.img...', 0x0D, 0x0A, 0
shut_msg db 0x0D, 0x0A, 'Shutting down...', 0x0D, 0x0A, 0
err_msg db 0x0D, 0x0A, 'Disk Error!', 0x0D, 0x0A, 0