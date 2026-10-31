teapotOS — Documentation

Build

```bash
nasm -f bin teapotOS.asm -o teapotOS.bin
```

Run in emulator

```bash
qemu-system-i386 -fda teapotOS.bin
```

Run on real hardware

What you need:

· x86 PC (any);
· Legacy BIOS, or UEFI with CSM/Legacy Boot enabled;
· Secure Boot disabled;
· 640 KB RAM (any PC has it);
· USB drive.

Steps:

1. Write the image to a USB drive in DD mode (Rufus → "DD Image"). Everything on the drive will be overwritten.
2. Enter BIOS/UEFI setup: enable Legacy / CSM, disable Secure Boot.
3. Set boot order to the USB drive in Legacy mode (not "UEFI: ...").
4. Boot. You will see =.

Will not boot: on UEFI without CSM, with Secure Boot enabled, or on a GPT disk without a Legacy boot entry.

How to use

Type exactly 6 characters:

```
[command][drive][head][cylinder][sector][number]
```

Each digit is a single one, 0–9. Enter is not needed. = is just the prompt — you don't type it.

Commands

Key What it does
d read a sector from disk into the buffer
w write the buffer to a disk sector (overwrites old data)
t show 512 bytes from the buffer in hex
b load a sector and jump into it
f find non-empty sectors on disk
m write 1 byte to memory
q power off the computer

Computer replies

· + — success
· - — error