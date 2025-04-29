#pragma once
#include <stdbool.h>
#include <stdint.h>

void __attribute__((cdecl)) x86_outb(uint16_t port, uint8_t value); // NOLINT
uint8_t __attribute__((cdecl)) x86_inb(uint16_t port);              // NOLINT