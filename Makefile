ASM := uxnasm
EMU := uxncli

all: test

disassembler.rom: disassembler.tal
	$(ASM) disassembler.tal disassembler.rom

.PHONY: test
test: tests.sh disassembler.rom uxn_disassembler.py
	./tests.sh

.PHONY: clean
clean:
	rm -f *.rom
