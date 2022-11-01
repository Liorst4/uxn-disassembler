#!/bin/sh

set -ex

if [ -z "$ASM" ]; then
    ASM=uxnasm
fi

if [ -z "$EMU" ]; then
    EMU=uxncli
fi

if [ -z "$ROMS_DIRECTORY" ]; then
    ROMS_DIRECTORY=./roms
fi

py_dis() {
    INPUT="$1"
    OUTPUT="$2"
    ./uxn_disassembler.py > "$OUTPUT" < "$INPUT"
}

tal_dis() {
    INPUT="$1"
    OUTPUT="$2"
    $EMU ./disassembler.rom "$INPUT" > "$OUTPUT"
}

test_tal_vs_py() {
    INPUT="$1"
    TAL_OUTPUT=$(mktemp --suffix=".$(basename "$INPUT").tal_output.tal")
    PY_OUTPUT=$(mktemp --suffix=".$(basename "$INPUT").py_output.tal")

    py_dis "$INPUT" "$PY_OUTPUT"
    tal_dis "$INPUT" "$TAL_OUTPUT"
    diff "$PY_OUTPUT" "$TAL_OUTPUT"

    rm "$TAL_OUTPUT" "$PY_OUTPUT"
}

hash_file() {
    sha512sum "$1" | cut -f1 -d ' '
}

test_tal_correctnes() {
    ORIGINAL_ROM="$1"
    DISASSEMBLED_ROM=$(mktemp --suffix=".$(basename "$ORIGINAL_ROM").disassembled.tal")
    REASSEMBLED_ROM=$(mktemp --suffix=".$(basename "$ORIGINAL_ROM").reassembled.rom")

    tal_dis "$ORIGINAL_ROM" "$DISASSEMBLED_ROM"
    $ASM "$DISASSEMBLED_ROM" "$REASSEMBLED_ROM"

    ORIGINAL_HASH=$(hash_file "$ORIGINAL_ROM")
    REASSEMBLED_HASH=$(hash_file "$REASSEMBLED_ROM")
    if test "$ORIGINAL_HASH" != "$REASSEMBLED_HASH"; then
	false
    fi

    rm "$DISASSEMBLED_ROM" "$REASSEMBLED_ROM"
}

test_tal_vs_py ./disassembler.rom
test_tal_correctnes ./disassembler.rom

if test -d "$ROMS_DIRECTORY"; then
    for rom in "$ROMS_DIRECTORY"/*; do
	test_tal_vs_py "$rom"
	test_tal_correctnes "$rom"
    done
fi
