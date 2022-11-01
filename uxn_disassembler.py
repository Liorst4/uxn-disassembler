#!/usr/bin/env python3

import enum
import sys
import typing

class ModeMask(enum.IntEnum):
    SHORT_MODE_MASK = 0x20
    RETURN_MODE_MASK = 0x40
    KEEP_MODE_MASK = 0x80

class OpCode(enum.IntEnum):
    LIT = 0x00
    INC = 0x01
    POP = 0x02
    NIP = 0x03
    SWP = 0x04
    ROT = 0x05
    DUP = 0x06
    OVR = 0x07
    EQU = 0x08
    NEQ = 0x09
    GTH = 0x0a
    LTH = 0x0b
    JMP = 0x0c
    JCN = 0x0d
    JSR = 0x0e
    STH = 0x0f
    LDZ = 0x10
    STZ = 0x11
    LDR = 0x12
    STR = 0x13
    LDA = 0x14
    STA = 0x15
    DEI = 0x16
    DEO = 0x17
    ADD = 0x18
    SUB = 0x19
    MUL = 0x1a
    DIV = 0x1b
    AND = 0x1c
    ORA = 0x1d
    EOR = 0x1e
    SFT = 0x1f

def uxn_byte_literal(number: int) -> str:
    text = hex(number)[2:]
    if number < 0x10:
        text = '0' + text
    return text

def uxn_short_literal(number: int) -> str:
    return '{:04x}'.format(number)

def disassemble(rom: bytes) -> typing.Generator[str, None, None]:
    i = 0
    while i < len(rom):
        instruction = rom[i]
        keep_mode = bool(instruction & ModeMask.KEEP_MODE_MASK)
        short_mode = bool(instruction & ModeMask.SHORT_MODE_MASK)
        return_mode = bool(instruction & ModeMask.RETURN_MODE_MASK)
        opcode = OpCode(instruction & ~(ModeMask.KEEP_MODE_MASK | ModeMask.SHORT_MODE_MASK | ModeMask.RETURN_MODE_MASK))

        line = f'|{uxn_short_literal(i+0x100)}\t'

        if opcode == OpCode.LIT:
            if return_mode or instruction in (0x20, 0x40, 0x60):
                line += f'{uxn_byte_literal(rom[i])}'
                i += 1
            elif not keep_mode:
                line += f'BRK\t( {uxn_byte_literal(rom[i])} )'
                i += 1
            elif short_mode:
                if i + 1 >= len(rom):
                    line += f'{uxn_byte_literal(rom[i])}'
                    i += 1
                elif i + 2 >= len(rom):
                    line += f'{uxn_byte_literal(rom[i])}{uxn_byte_literal(rom[i+1])}'
                    i += 2
                else:
                    line += f'#{uxn_byte_literal(rom[i+1])}{uxn_byte_literal(rom[i+2])}\t( {uxn_byte_literal(instruction)}{uxn_byte_literal(rom[i+1])}{uxn_byte_literal(rom[i+2])} )'
                    i += 3
            else:
                if i + 1 >= len(rom):
                    line += f'{uxn_byte_literal(rom[i])}'
                    i += 1
                else:
                    line += f'#{uxn_byte_literal(rom[i+1])}\t( {uxn_byte_literal(instruction)}{uxn_byte_literal(rom[i+1])} )'
                    i += 2

            yield line
            continue

        line += opcode.name

        if short_mode:
            line += '2'

        if keep_mode:
            line += 'k'

        if return_mode:
            line += 'r'

        line += f'\t( {uxn_byte_literal(instruction)} )'

        yield line
        i += 1

if __name__ == '__main__':
    rom = sys.stdin.buffer.read()
    for line in disassemble(rom):
        print(line)
    sys.exit(0)
