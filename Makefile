ASM := uxnasm
EMU := uxncli

all: test

disassembler.rom: disassembler.tal
	$(ASM) disassembler.tal disassembler.rom

.PHONY: test
test: tests.sh disassembler.rom uxn_disassembler.py
	./tests.sh

.PHONY: lint
lint: tests.sh uxn_disassembler.py
	shellcheck tests.sh
	mypy uxn_disassembler.py
	pylint uxn_disassembler.py

.PHONY: clean
clean:
	rm -f *.rom
