#!/usr/bin/env python3

# Copyright © 2022 Lior Stern
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# “Software”), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import argparse
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

def disassemble(rom: bytes) -> typing.Generator[str, None, None]:
    i = 0
    while i < len(rom):
        instruction = rom[i]
        keep_mode = bool(instruction & ModeMask.KEEP_MODE_MASK)
        short_mode = bool(instruction & ModeMask.SHORT_MODE_MASK)
        return_mode = bool(instruction & ModeMask.RETURN_MODE_MASK)
        opcode = OpCode(instruction & ~(ModeMask.KEEP_MODE_MASK |
                                        ModeMask.SHORT_MODE_MASK |
                                        ModeMask.RETURN_MODE_MASK))

        line = f'|{i+0x100:04x}\t'

        if opcode != OpCode.LIT:
            line += opcode.name
            if short_mode:
                line += '2'
            if keep_mode:
                line += 'k'
            if return_mode:
                line += 'r'
            line += f'\t( {instruction:02x} )'
            yield line
            i += 1
            continue

        if not keep_mode and not return_mode and not short_mode:
            line += f'BRK\t( {rom[i]:02x} )'
            i += 1
        elif (
                return_mode
                or instruction in (0x20, 0x40, 0x60)
                or (
                    short_mode and (
                        i + 1 >= len(rom) or
                        i + 2 >= len(rom)
                    )
                )
                or (
                    not short_mode
                    and i + 1 >= len(rom)
                )
        ):
            line += f'{rom[i]:02x}'
            i += 1
        elif short_mode:
            line += f'#{rom[i+1]:02x}'
            line += f'{rom[i+2]:02x}'
            line += '\t( '
            line += f'{instruction:02x}'
            line += f'{rom[i+1]:02x}'
            line += f'{rom[i+2]:02x}'
            line += ' )'
            i += 3
        else:
            line += f'#{rom[i+1]:02x}'
            line += '\t( '
            line += f'{instruction:02x}'
            line += f'{rom[i+1]:02x}'
            line += ' )'
            i += 2

        yield line

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', type=argparse.FileType('rb'), default=sys.stdin.buffer)
    parser.add_argument('--output', type=argparse.FileType('w'), default=sys.stdout)
    args = parser.parse_args()

    rom = args.input.read()
    for line in disassemble(rom):
        args.output.write(line)
        args.output.write('\n')

    sys.exit(0)
