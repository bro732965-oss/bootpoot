# bootpoot
teapotOS — Documentation & Requirements

Below is a concise English documentation for your boot sector, plus the hardware/firmware requirements. I'll base it on the corrected version (teapotOS.as), and note where the older teapot.as differs.

---

teapotOS — README

Overview

teapotOS is a 512-byte Legacy BIOS boot sector (not a full operating system). It provides a minimal interactive command monitor in 16-bit real mode, using BIOS interrupts for video, keyboard, and disk I/O. All code fits in the first sector of a boot device and ends with the 0xAA55 signature.

Build

```bash
nasm -f bin teapotOS.asm -o teapotOS.bin
```

Output: exactly 512 bytes, signature 55 AA at offset 0x1FE.

Run (emulator, recommended)

```bash
qemu-system-i386 -fda teapotOS.bin
# or
qemu-system-x86_64 -drive format=raw,file=teapotOS.bin
```

Run (real hardware)

1. Write the image to a USB drive in DD mode (Rufus: "DD Image"; Linux: sudo dd if=teapotOS.bin of=/dev/sdX bs=512 count=1 conv=fsync). This erases the target device.
2. In firmware setup: enable CSM / Legacy Boot, disable Secure Boot, select the USB device in Legacy (not UEFI) mode.
3. Boot. Expected: = prompt appears.

---

Command Reference

At the = prompt, the monitor reads exactly 6 keystrokes:

Position Meaning
1 Command letter
2 Drive number (digit)
3 Head number (digit)
4 Cylinder number (digit)
5 Sector number (digit)
6 Count / value (digit)

All numeric fields are single decimal digits (0–9). Multi-digit values are not supported. No Enter key is required or read; input is taken character-by-character.

Commands (teapotOS.as)

Key Name Action Status
d disk read INT 13h AH=02h — read count sectors from CHS into 0x0000:0x8000 works for single-digit CHS
w disk write INT 13h AH=03h — write count sectors from 0x0000:0x8000 to CHS works for single-digit CHS; overwrites disk
t text dump hex dump of 512 bytes at buffer (0x8000) works
b boot sector read CHS into 0x1000:0x0000 and JMP 0x1000:0x0000 works if CHS valid
f find/dir scan disk CHS range, print non-empty sectors as C…H…S… works; ends in infinite loop when done
m memory write write one byte (cmd[3]) to segment cmd[4], offset cmd[5] fixed vs teapot.as (no fall-through)
l load memory INT 13h — broken: AH/AL/DL not set, reads garbage unreliable
p scan memory scan segments 0x0000, 0x1000, … for non-zero bytes, print addresses very slow / hangs on real HW (loops until segment wraps)
s run sector broken: same INT 13h issue as l; also placed inside dir loop do not use
q quit ACPI power-off via INT 15h AX=5307h; falls back to hlt loop works on most ACPI machines

teapot.as differences: q = plain hlt only; m falls through into d (bug); command keys are o/r/s/l instead of m/l/p/s.

Output

· = — prompt (printed once at boot in teapotOS.as)
· + — success (followed by CRLF)
· - — error (followed by CRLF)

Memory map used

Address Use
0x7C00 this boot sector (loaded by BIOS)
0x8000 disk I/O buffer (buffer equ 0x8000)
0x1000:0x0000 target for b (boot sector jump)

Known limitations

· Single-digit CHS only; no multi-digit parsing.
· No Enter/Backspace; fixed 6-char input.
· No IDT, no protected mode; relies entirely on BIOS interrupt vectors.
· l and s are non-functional.
· p scans until 16-bit segment wrap — effectively hangs on real hardware.
· f ends in an infinite jmp $ after completion.
· w can destroy the boot device's data.

---

System Requirements

Minimum (emulator)

· QEMU (i386 or x86_64) or any PC emulator with Legacy BIOS (Bochs, VirtualBox with Legacy boot).
· ~1 MB RAM (BIOS + real-mode only).
· No disk image beyond the 512-byte file.
· No OS, no filesystem.

Minimum (real hardware)

Component Requirement
CPU x86, 16-bit real mode capable (any 8086+; effectively any x86 PC)
Firmware Legacy BIOS or UEFI with CSM/Legacy Boot enabled; Secure Boot off
RAM ≥ 640 KB conventional memory (standard on any PC)
Boot device USB drive, floppy, HDD, or CD — any device the BIOS can boot from in Legacy mode
Disk (for d/w/f/b) CHS-addressable via INT 13h; BIOS must provide CHS geometry (INT 13h AH=08h)
Power (for q) ACPI-capable motherboard for graceful shutdown; otherwise falls back to hlt

Not supported

· Pure UEFI without CSM — the sector will not be executed.
· Secure Boot enabled — unsigned boot sector blocked.
· GPT-only disks with no Legacy boot entry.
· Multi-digit CHS / LBA — commands accept one digit per field.
· Any modern OS features (protected mode, paging, multitasking, filesystems).

Recommended for development

· NASM 2.15+ (assembler)
· QEMU 6.0+ (fast iteration)
· A hex editor (xxd, HxD) to verify the 55 AA signature
· Rufus (Windows) or dd (Linux/macOS) for USB writing

---

Notes on the two versions

· teapotOS.as is the recommended version: fixes the ozy→disk fall-through bug and adds ACPI shutdown on q.
· teapot.as is kept for reference; it contains the fall-through bug and only hlts on quit.
· Both share the broken l/s handlers and the unbounded p scan. Fix these before relying on them.