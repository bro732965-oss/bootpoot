org 0x7C00
bits 16

run_os:
    mov ax, 0x0003
    int 0x10

    mov si, msg
    call print_string

input1:
    call read_char
    mov [cur], al
    call read_char
    mov [cur1], al
    call read_char
    mov [sim], al
    
    mov cx, 4
.read_params:
    push cx
    call read_char
    pop cx
    loop .read_params

    mov si, newline
    call print_string

crt_tbl:
    cmp byte [cur], 'd'
    je disk
    cmp byte [cur], 't'
    je text
    cmp byte [cur], 'q'
    je qei
    cmp byte [cur], 'b'
    je bin
    cmp byte [cur], 'f'
    je dir
    cmp byte [cur], 'w'
    je write_disk
    cmp byte [cur], 'm'
    je ozy
    cmp byte [cur], 'l'
    je read_ozy   
    cmp byte [cur], 'p'
    je scan_mem
    cmp byte [cur], 's'
    je bin1
    cmp byte [cur], 'x'
    je kill_console
    jmp error
    
kill_console:

    cli
.wait:
    mov al, 0x02
    out 0x64, al     
    in al, 0x64
    test al, 0x02   
    jnz .wait

    
    mov al, 0xFE
    out 0x64, al

    
    hlt
    jmp error 
read_char:
    mov ah, 0x00
    int 0x16
    mov ah, 0x0E
    int 0x10
    ret

read_ozy:
    mov ah, 0x02        
    mov al, [sim2]
    mov es, ax
    mov bx, buffer       
    mov ax, 0x0000
    mov es, ax           
    int 0x13             
    jc error
    mov si, ok_msg
    call print_string
    jmp input1

ozy:
    mov al, [sim2]
    mov ah, [sim2+1]
    mov es, ax
    mov bx, buffer
    mov al, [sim]
    mov [es:bx], al
    mov si, ok_msg
    call print_string
    jmp input1

disk:
    mov ah, 0x02
    mov al, [sim4]
    sub al, '0'
    mov ch, [sim]
    sub ch, '0'
    mov cl, [sim3]
    sub cl, '0'
    mov dh, [sim2]
    sub dh, '0'
    mov dl, [cur1]
    sub dl, '0'
    mov bx, buffer
    mov ax, 0x0000
    mov es, ax
    int 0x13
    jc error
    mov si, ok_msg
    call print_string
    jmp input1

write_disk:
    mov ah, 0x03       
    mov al, [sim4]
    sub al, '0'
    mov ch, [sim]
    sub ch, '0'
    mov cl, [sim3]
    sub cl, '0'
    mov dh, [sim2]
    sub dh, '0'
    mov dl, [cur1]
    sub dl, '0'
    mov bx, buffer
    mov ax, 0x0000
    mov es, ax
    int 0x13
    jc error
    mov si, ok_msg
    call print_string
    jmp input1

scan_mem:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov word [scan_seg], 0x0000
    mov word [scan_line], 0

.scan_loop:
    mov ax, [scan_seg]
    mov es, ax
    xor bx, bx
    xor dl, dl

.byte_loop:
    mov al, [es:bx]
    test al, al
    jnz .nonzero
    xor dl, dl
    jmp .next
.nonzero:
    test dl, dl
    jnz .skip
    call print_addr

    inc word [scan_line]
    cmp word [scan_line], 20
    jl .skip
    mov word [scan_line], 0
    call read_char

    mov ax, [scan_seg]
    mov es, ax

.skip:
    mov dl, 1
.next:
    inc bx
    jnz .byte_loop

    mov ax, [scan_seg]
    add ax, 0x1000
    mov [scan_seg], ax
    cmp ax, 0x1000
    jne .scan_loop

    mov si, done_msg
    call print_string
    jmp input1

print_addr:
    mov ax, es
    call print_hex
    mov al, ':'
    call print_char
    mov ax, bx
    call print_hex
    mov si, newline
    call print_string
    ret

print_hex:
    push ax
    mov al, ah
    call print_hex_byte
    pop ax
    call print_hex_byte
    ret

print_hex_byte:
    push ax
    shr al, 4
    call print_hex_nibble
    pop ax
    and al, 0x0F
    call print_hex_nibble
    ret

print_hex_nibble:
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .out
.digit:
    add al, '0'
.out:
    call print_char
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

scan_seg  dw 0
scan_line dw 0

done_msg db ' done', 0x0D, 0x0A, 0

text:
    mov si, buffer
    mov cx, 512
    xor bx, bx
hex_loop:
    lodsb
    push ax
    shr al, 4
    call print_hex_nibble
    pop ax
    and al, 0x0F
    call print_hex_nibble
    mov al, ' '
    call print_char
    inc bx
    cmp bx, 16
    jne hex_next
    xor bx, bx
    mov si, newline
    call print_string
hex_next:
    loop hex_loop
    jmp input1

qei:
    mov ax, 0x5301    
    xor bx, bx         
    int 0x15       
    jc .error_shutdown 
    mov ax, 0x530E   
    xor bx, bx      
    mov cx, 0x0102 
    int 0x15          
    jc .error_shutdown
    mov ax, 0x5307      
    mov bx, 0x0001      
    mov cx, 0x0003      
    int 0x15           
.error_shutdown:
    cli               
.hang_loop:
    hlt              
    jmp .hang_loop   

bin:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, [sim4]
    sub al, '0'
    mov ch, [sim]
    sub ch, '0'
    mov cl, [sim3]
    sub cl, '0'
    mov dh, [sim2]
    sub dh, '0'
    mov dl, [cur1]
    sub dl, '0'
    int 0x13
    jc error
    jmp 0x1000:0x0000

error:
    mov si, err_msg
    call print_string
    jmp input1

print_string:
    lodsb
    or al, al
    jz .done
    call print_char
    jmp print_string
.done:
    ret

dir:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    mov ah, 0x08
    mov dl, [boot_drive]
    int 0x13
    jc .defaults

    mov [max_cyl], ch
    mov [max_head], dh
    and cl, 0x3F
    mov [max_sect], cl
    jmp .scan_start

.defaults:
    mov byte [max_cyl], 79
    mov byte [max_head], 1
    mov byte [max_sect], 18

.scan_start:
    mov ch, 0
cyl_loop:
    mov dh, 0
head_loop:
    mov cl, 1
sect_loop:
    push cx
    push dx

    mov ah, 0x02
    mov al, 1
    mov dl, [boot_drive]
    mov bx, 0x8000
    mov ax, 0x0000
    mov es, ax
    int 0x13
    jc next_sector

    mov si, 0x8000
    mov cx, 512
check_empty:
    lodsb
    or al, al
    jnz data_found
    loop check_empty
    jmp next_sector

bin1:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, [sim2]
    mov ah, [sim2+1]
    mov es, ax
    mov al, [sim1]
    mov ah, [sim1+1]
    mov bx, ax
    int 0x13
    jc error

data_found:
    pop dx
    pop cx
    push cx
    push dx

    mov al, 'C'
    call print_char
    mov ax, cx
    call print_hex_word
    mov al, 'H'
    call print_char
    mov ax, dx
    call print_hex_word
    mov al, 'S'
    call print_char
    mov ax, cx
    call print_hex_byte
    mov si, newline
    call print_string

next_sector:
    pop dx
    pop cx
    inc cl
    cmp cl, [max_sect]
    jle sect_loop
    inc dh
    cmp dh, [max_head]
    jle head_loop
    inc ch
    cmp ch, [max_cyl]
    jle cyl_loop
hang:
    jmp hang

print_hex_word:
    push ax
    mov al, ah
    call print_hex_byte
    pop ax
    call print_hex_byte
    ret

boot_drive db 0
max_cyl    db 0
max_head   db 0
max_sect   db 0

cur     db 0
cur1    db 0
sim     db 0
sim1    db 0
sim2    db 0
sim3    db 0
sim4    db 0

msg     db '=', 0
newline db 0x0D, 0x0A, 0
ok_msg  db '+', 0x0D, 0x0A, 0
err_msg db '-', 0x0D, 0x0A, 0

buffer equ 0x8000   

