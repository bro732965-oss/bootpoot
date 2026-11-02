org 0x7E00
bits 16

start:
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000

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
    jc .no_files_disk
    
    mov ax, [file_table]
    cmp ax, 0
    je .no_files_disk
    mov [file_count], ax
    jmp main_loop

.no_files_disk:
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
    mov ax, di
    add dh, al
    mov dl, 2
    call set_cursor
    cmp di, [cursor_pos]
    jne .no_arrow
    mov al, '>'
    mov ah, 0x0E
    int 0x10
    jmp .print_name
.no_arrow:
    mov al, ' '
    mov ah, 0x0E
    int 0x10
.print_name:
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
    je shutdown
    cmp al, 0x0D
    je show_file_menu
    cmp ah, 0x48
    je move_up
    cmp ah, 0x50
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

show_file_menu:
    mov ax, 0x0600
    mov bh, 0x70
    mov cx, 0x0514
    mov dx, 0x0E32
    int 0x10
    mov dh, 5
    mov dl, 22
    call set_cursor
    mov si, m1
    call print_string
    mov dh, 6
    mov dl, 22
    call set_cursor
    mov si, m2
    call print_string
    mov dh, 7
    mov dl, 22
    call set_cursor
    mov si, m3
    call print_string
    mov dh, 8
    mov dl, 22
    call set_cursor
    mov si, m4
    call print_string
    mov dh, 9
    mov dl, 22
    call set_cursor
    mov si, m5
    call print_string
    mov dh, 10
    mov dl, 22
    call set_cursor
    mov si, m6
    call print_string
    mov dh, 11
    mov dl, 22
    call set_cursor
    mov si, m7
    call print_string

.menu_wait:
    mov ah, 0x00
    int 0x16
    cmp al, '1'
    je act_read
    cmp al, '2'
    je act_write
    cmp al, '3'
    je act_create
    cmp al, '4'
    je act_delete
    cmp al, '5'
    je act_console
    cmp al, '6'
    je shutdown
    cmp al, 0x1B
    je main_loop
    jmp .menu_wait

act_create:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    mov si, txt_create
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
    
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, 10
    mov dh, 0
    mov dl, 0x00
    mov bx, file_table
    int 0x13
    
    mov si, msg_created
    call print_string
    mov ah, 0x00
    int 0x16
    jmp main_loop

act_write:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    mov si, txt_write
    call print_string
    
    mov di, buffer
    call read_string
    
    mov ax, [cursor_pos]
    add ax, 11
    
    mov ah, 0x03
    mov al, 1
    mov ch, 0
    mov cl, al
    mov dh, 0
    mov dl, 0x00
    mov bx, buffer
    int 0x13
    
    mov si, msg_saved
    call print_string
    mov ah, 0x00
    int 0x16
    jmp main_loop

act_read:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10
    
    mov ax, [cursor_pos]
    add ax, 11
    
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, al
    mov dh, 0
    mov dl, 0x00
    mov bx, buffer
    int 0x13
    
    mov si, txt_read
    call print_string
    mov si, buffer
    call print_string
    
    mov ah, 0x00
    int 0x16
    jmp main_loop

act_delete:
    mov si, txt_delete
    call print_string
    mov ah, 0x00
    int 0x16
    jmp main_loop

act_console:
    mov si, txt_console
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
    mov si, txt_error
    call print_string
    mov ah, 0x00
    int 0x16
    jmp main_loop

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

read_string:
    xor cx, cx
.loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .done
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
.done:
    mov byte [di], 0
    ret

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
buffer times 512 db 0

file_table:
    dw 0
    times 512-2 db 0

header db '--- home pc (16-bit) ---', 0x0D, 0x0A, 0
no_files_msg db 'No files found. Press Enter to create.', 0x0D, 0x0A, 0
footer db 'Arrows: Move | Enter: Menu | Esc: Shutdown', 0
m1 db '1. Read File', 0
m2 db '2. Write to File', 0
m3 db '3. Create File', 0
m4 db '4. Delete File', 0
m5 db '5. Console (16-bit)', 0
m6 db '6. Shutdown PC', 0
m7 db 'Esc - Back', 0
txt_read db 'File content: ', 0x0D, 0x0A, 0
txt_write db 'Enter text (Press Enter to save): ', 0
txt_create db 'Enter name (Press Enter): ', 0
txt_delete db 'Deleting file... (Press any key)', 0x0D, 0x0A, 0
txt_console db 'Loading console.img...', 0x0D, 0x0A, 0
txt_error db 'Disk read error!', 0x0D, 0x0A, 0
shut_msg db 0x0D, 0x0A, 'Shutting down...', 0x0D, 0x0A, 0
msg_created db 0x0D, 0x0A, 'File Created! (Saved to disk)', 0x0D, 0x0A, 0
msg_saved db 0x0D, 0x0A, 'Text Saved! (Press any key)', 0x0D, 0x0A, 0
nl db 0x0D, 0x0A, 0