bits 16

section .entry

extern __bss_start
extern __end

extern start 
global entry

entry:
    cli

    ; Save boot drive
    mov [boot_drive_], dl

    ; Set up stack
    mov ax, ds
    mov ss, ax
    mov sp, 0xFFF0
    mov bp, sp

    ; Switch to protected mode
    call EnableA20
    call LoadGDT

    ; 4 - Set protection enable flag in CR0
    mov eax, cr0 
    or al, 1
    mov cr0, eax

    ; 5 - Far jump into protected mode
    jmp dword 08h:.pmode

.pmode:
    ; Now running in protected mode
    [bits 32]

    ; 6 - Set up segment registers
    mov ax, 0x10
    mov ds, ax
    mov ss, ax

    ; Clear bss
    mov edi, __bss_start
    mov ecx, __end
    sub ecx, edi
    mov al, 0
    cld
    rep stosb

    ; Expect boot drive in dl, send it as argument to cstart function
    xor edx, edx 
    mov dl, [boot_drive_]
    push edx
    call start

    cli
    hlt

EnableA20:
    [bits 16]

    ; Disable keyboard
    call A20WaitInput
    mov al, KbdControllerDisableKeyboard
    out KbdControllerCommandPort, al

    ; Read control output port
    call A20WaitInput
    mov al, KbdControllerReadCtrlOutputPort
    out KbdControllerCommandPort, al

    call A20WaitInput
    in al, KbdControllerDataPort
    push eax

    ; Write control output port
    call A20WaitInput
    mov al, KbdControllerWriteCtrlOutputPort
    out KbdControllerCommandPort, al

    call A20WaitInput
    pop eax
    or al, 2
    out KbdControllerDataPort, al

    ; Enable keyboard
    call A20WaitInput
    mov al, KbdControllerEnableKeyboard
    out KbdControllerCommandPort, al

    call A20WaitInput
    ret 

A20WaitInput:
    [bits 16]

    ; Wait until status bit 2 is 0
    in al, KbdControllerCommandPort
    test al, 2
    jnz A20WaitInput
    ret

A20WaitOutput:
    [bits 16]

    ; Wait until status bit 1 is 1 so it can be read
    in al, KbdControllerCommandPort
    test al, 1
    jz A20WaitOutput
    ret

LoadGDT:
    [bits 16]
    lgdt [gdt_desc_]
    ret

KbdControllerDataPort               equ 0x60
KbdControllerCommandPort            equ 0x64
KbdControllerDisableKeyboard        equ 0xAD
KbdControllerEnableKeyboard         equ 0xAE
KbdControllerReadCtrlOutputPort     equ 0xD0
KbdControllerWriteCtrlOutputPort    equ 0xD1

ScreenBuffer                        equ 0xB80000

gdt_:
                dq 0

                ; 32-bit code segment
                dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
                dw 0                        ; base (bits 0-15) = 0x0
                db 0                        ; base (bits 16-23)
                db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
                db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
                db 0                        ; base high

                ; 32-bit data segment
                dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF for full 32-bit range
                dw 0                        ; base (bits 0-15) = 0x0
                db 0                        ; base (bits 16-23)
                db 10010010b                ; access (present, ring 0, data segment, executable, direction 0, writable)
                db 11001111b                ; granularity (4k pages, 32-bit pmode) + limit (bits 16-19)
                db 0                        ; base high

                ; 16-bit code segment
                dw 0FFFFh                   ; limit (bits 0-15) = 0xFFFFF
                dw 0                        ; base (bits 0-15) = 0x0
                db 0                        ; base (bits 16-23)
                db 10011010b                ; access (present, ring 0, code segment, executable, direction 0, readable)
                db 00001111b                ; granularity (1b pages, 16-bit pmode) + limit (bits 16-19)
                db 0                        ; base high

                ; 16-bit data segment
                dw 0FFFFh
                dw 0
                db 0
                db 10010010b
                db 00001111b
                db 0

gdt_desc_:      dw gdt_desc_ - gdt_ - 1
                dd gdt_

boot_drive_:    db 0

