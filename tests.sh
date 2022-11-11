#!/bin/sh

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

test_edge_case_rom() {
    TEMP_TAL=$(mktemp --suffix=".$1.edge-case.tal")
    TEMP_ROM="$TEMP_TAL".rom
    cat > "$TEMP_TAL"
    $ASM "$TEMP_TAL" "$TEMP_ROM"
    test_tal_vs_py "$TEMP_ROM"
    test_tal_correctnes "$TEMP_ROM"
    rm "$TEMP_TAL" "$TEMP_ROM"
}

test_truncated_lit() {
    cat <<EOF | test_edge_case_rom truncated_lit
|100
80
EOF
}

test_truncated_litr() {
    cat <<EOF | test_edge_case_rom truncated_litr
|100
c0
EOF
}

test_truncated_lit2_0() {
    cat <<EOF | test_edge_case_rom truncated_lit2_0
|100
a0
EOF
}

test_truncated_lit2_1() {
    cat <<EOF | test_edge_case_rom truncated_lit2_1
|100
a0 00
EOF
}

test_truncated_lit2r_0() {
    cat <<EOF | test_edge_case_rom truncated_lit2r_0
|100
e0
EOF
}

test_truncated_lit2r_1() {
    cat <<EOF | test_edge_case_rom truncated_lit2r_1
|100
e0 00
EOF
}

test_tal_vs_py ./disassembler.rom
test_tal_correctnes ./disassembler.rom

if test -d "$ROMS_DIRECTORY"; then
    for rom in "$ROMS_DIRECTORY"/*; do
	test_tal_vs_py "$rom"
	test_tal_correctnes "$rom"
    done
fi

test_truncated_lit
test_truncated_litr
test_truncated_lit2_0
test_truncated_lit2_1
test_truncated_lit2r_0
test_truncated_lit2r_1
