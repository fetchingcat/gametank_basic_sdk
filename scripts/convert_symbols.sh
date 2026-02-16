#!/bin/sh
# Convert DASM symbol file to cc65 map file format for GameTank Emulator
# Usage: ./convert_symbols.sh input.sym [output.map]

INPUT="$1"
OUTPUT="${2:-${INPUT%.sym}.map}"

if [ -z "$INPUT" ]; then
    echo "Usage: convert_symbols.sh input.sym [output.map]"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    echo "Error: Input file not found: $INPUT"
    exit 1
fi

# Parse DASM symbol file and convert to cc65 map format
# DASM format: "symbolname    address    (R )"
# cc65 format: "symbolname                       ADDRESS   LAB"

awk '
BEGIN {
    in_symbols = 0
    count = 0
}
/^---.*Symbol List/ {
    in_symbols = 1
    next
}
!in_symbols { next }
/^[[:space:]]*$/ { next }
/^-+$/ { next }
/^[[:space:]]*[^[:space:]]+[[:space:]]+[0-9a-fA-F]+/ {
    name = $1
    addr = toupper($2)
    # Skip dash-only names
    if (name ~ /^-+$/) next
    # Skip internal/temporary symbols
    if (name ~ /^[0-9]+\./ || name ~ /^_[A-Z][A-Z]_[0-9]+/) next
    # Store for sorting
    symbols[count] = sprintf("%-32s %s   LAB", name, addr)
    addrs[count] = strtonum("0x" addr)
    count++
}
END {
    # Simple insertion sort by address
    for (i = 1; i < count; i++) {
        tmp_sym = symbols[i]
        tmp_addr = addrs[i]
        j = i - 1
        while (j >= 0 && addrs[j] > tmp_addr) {
            symbols[j+1] = symbols[j]
            addrs[j+1] = addrs[j]
            j--
        }
        symbols[j+1] = tmp_sym
        addrs[j+1] = tmp_addr
    }
    print ""
    print "Exports list by value:"
    print "------------------------------"
    for (i = 0; i < count; i++) {
        print symbols[i]
    }
    print ""
    printf "Converted %d symbols\n", count > "/dev/stderr"
}
' "$INPUT" > "$OUTPUT"

echo "Output: $OUTPUT" >&2
