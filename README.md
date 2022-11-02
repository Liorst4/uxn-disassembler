# UXN rom disassembler

A simple program to translate [UXN](https://wiki.xxiivv.com/site/uxn.html) roms into the textual
[uxntal language](https://wiki.xxiivv.com/site/uxntal.html).

Disassembled files can be re-assembled into UXN roms using
the [UXN assembler](https://git.sr.ht/~rabbits/uxn/tree/main/item/src/uxnasm.c).

A python version of the disassembler is kept for testing and reference.

## Usage

    $EMU ./disassembler.rom $ROM_TO_DISASSEMBLE > $OUTPUT
    ./uxn_disassembler.py < $ROM_TO_DISASSEMBLE > $OUTPUT

## Notes and limitations

UXN reads roms as a raw binary blob, unlike ELF or PE, there
are no sections to distinguish between code and data, thus
all data given to the disassembler is assumed to be code.


Data that isn't a valid op code, is kept as raw data.
After each disassembled opcode there is a comment containing
the original data that was parsed.


Before each opcode (and raw data) the is absolute padding
(`|0100` for example), remember to update/remove them when
patching a disassembled rom.

## Building

    make EMU=$PATH_TO_UXNEMU ASM=$PATH_TO_UXNASM disassembler.rom
    make EMU=$PATH_TO_UXNEMU ASM=$PATH_TO_UXNASM test

## Example for some disassembled code


    |0100	#0000	( a00000 )
    |0103	#00	( 8000 )
    |0105	STZ2	( 31 )
    |0106	#0000	( a00000 )
    |0109	#03ac	( a003ac )
    |010c	STA2	( 35 )
    |010d	#0114	( a00114 )
    |0110	#10	( 8010 )
    |0112	DEO2	( 37 )
    |0113	BRK	( 00 )
    |0114	#12	( 8012 )
    |0116	DEI	( 16 )
    |0117	DUP	( 06 )
    |0118	#0a	( 800a )
    |011a	EQU	( 08 )

## License

This repository uses the MIT license.
More info in the LICENSE file.
