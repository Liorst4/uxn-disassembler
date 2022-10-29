ASM := uxnasm
EMU := uxncli

all: test

disassembler.rom: disassembler.tal
	$(ASM) disassembler.tal disassembler.rom

control_disassembled_rom: disassembler.rom uxn_disassembler.py
	cat disassembler.rom | ./uxn_disassembler.py > control_disassembled_rom

test_disassembled_rom: disassembler.rom
	$(EMU) disassembler.rom disassembler.rom > test_disassembled_rom

.PHONY: test
test: control_disassembled_rom test_disassembled_rom
	diff control_disassembled_rom test_disassembled_rom

.PHONY: clean
clean:
	rm -f *.rom
	rm -f *_disassembled_rom
