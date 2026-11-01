org 0x7E00
bits 16

start:
    mov ax, 0x0003
    int 0x10
    
    ; Загружаем таблицу файлов с дискеты (10-й сектор)
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
    
    ; Выделяем выбранный файл (если нужно, можно добавить цвет)
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
    
    cmp al, '1'       ; Нажата кнопка 1 - меню действий
    je file_actions_menu
    
    cmp ah, 0x48      ; Стрелка вверх
    je move_up
    cmp ah, 0x50      ; Стрелка вниз
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

; --- МЕНЮ ДЕЙСТВИЙ С ФАЙЛОМ (Вызывается по кнопке '1') ---
file_actions_menu:
    mov ax, 0x0600
    mov bh, 0x70
    mov cx, 0x0514
    mov dx, 0x0B32
    int 0x10

    mov dh, 5
    mov dl, 22
    call set_cursor
    mov si, act_menu1
    call print_string

    mov dh, 6
    mov dl, 22
    call set_cursor
    mov si, act_menu2
    call print_string

    mov dh, 7
    mov dl, 22
    call set_cursor
    mov si, act_menu3
    call print_string

    mov dh, 8
    mov dl, 22
    call set_cursor
    mov si, act_menu4
    call print_string

.act_wait:
    mov ah, 0x00
    int 0x16
    cmp al, '1'      ; Создать файл
    je create_new_file
    cmp al, '2'      ; Редактировать выбранный
    je edit_selected_file
    cmp al, '3'      ; Прочитать выбранный
    je read_selected_file
    cmp al, 0x1B     ; Esc - назад
    je draw_screen
    jmp .act_wait

; --- 1. СОЗДАТЬ НОВЫЙ ФАЙЛ ---
create_new_file:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10

    mov si, prompt_name
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
    
    mov si, msg_created
    call print_string
    mov ah, 0x00
    int 0x16
    jmp draw_screen

; --- 2. РЕДАКТИРОВАТЬ ФАЙЛ ---
edit_selected_file:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10

    mov si, prompt_edit
    call print_string
    
    ; Вычисляем адрес памяти для текста выбранного файла
    ; Например: 0x9000 + (cursor_pos * 256)
    mov ax, [cursor_pos]
    mov bx, 256
    mul bx
    mov di, ax
    add di, 0x9000
    
    xor cx, cx
.read_text:
    mov ah, 0x00
    int 0x16
    mov ah, 0x0E
    int 0x10
    mov [di], al
    inc di
    inc cx

    ; Проверка на 4 Enter подряд
    cmp al, 0x0D
    jne .reset_count
    inc byte [enter_count]
    cmp byte [enter_count], 4
    je .done_edit
    jmp .read_text

.reset_count:
    mov byte [enter_count], 0
    jmp .read_text

.done_edit:
    mov byte [di], 0
    mov si, msg_saved
    call print_string
    mov ah, 0x00
    int 0x16
    jmp draw_screen

; --- 3. ПРОЧИТАТЬ ФАЙЛ ---
read_selected_file:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0
    mov dx, 0x184F
    int 0x10

    mov si, prompt_read
    call print_string

    ; Вычисляем адрес памяти
    mov ax, [cursor_pos]
    mov bx, 256
    mul bx
    mov si, ax
    add si, 0x9000
    
    call print_string
    mov si, nl
    call print_string
    
    mov si, msg_press_key
    call print_string
    mov ah, 0x00
    int 0x16
    jmp draw_screen

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

file_table:
    dw 0
    times 512-2 db 0

header db 'teapoot', 0x0D, 0x0A, 0
no_files_msg db 'No files found. Press 1 to open Actions.', 0x0D, 0x0A, 0
footer db 'Arrows: Move | 1: Actions Menu', 0

act_menu1 db '1. Create New File', 0
act_menu2 db '2. Edit Selected File', 0
act_menu3 db '3. Read Selected File', 0
act_menu4 db 'Esc - Back', 0

prompt_name db 0x0D, 0x0A, 'Enter file name (8 chars): ', 0
prompt_edit db 0x0D, 0x0A, 'Enter text (4x Enter to save): ', 0
prompt_read db 0x0D, 0x0A, '--- File Content ---', 0x0D, 0x0A, 0

msg_created db 0x0D, 0x0A, 'File Created! Press any key...', 0
msg_saved db 0x0D, 0x0A, 'Text Saved! Press any key...', 0
msg_press_key db 0x0D, 0x0A, 'Press any key to return...', 0
nl db 0x0D, 0x0A, 0