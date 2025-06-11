#!/bin/bash

# === Default Values ===
MIN_LEN=0
MAX_LEN=0
CHARSET=""
WORDLIST_IN="rockyou.txt"
OUT_DIR="."
RULE_LEVEL="med"

usage() {
    cat <<EOF
Usage: $0 -mi <min_len> [-ma <max_len>] -c <aA1!> [-w wordlist.txt] [-o output_dir] [-r low|med|high]

Options:
  -mi <num>     Minimum password length (required)
  -ma <num>     Maximum password length (optional; default: same as min)
  -c  <chars>   Character classes (required):
                  a = lowercase
                  A = uppercase
                  1 = digits
                  ! = special characters
  -w <file>     Input wordlist (default: rockyou.txt)
  -o <dir>      Output directory (default: current directory)
  -r <level>    Rule strength: low | med | high (default: med)
  -h, --help    Show this help message
EOF
    exit 1
}

# === Parse Arguments ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        -mi) MIN_LEN="$2"; shift 2 ;;
        -ma) MAX_LEN="$2"; shift 2 ;;
        -c)  CHARSET="$2"; shift 2 ;;
        -w)  WORDLIST_IN="$2"; shift 2 ;;
        -o)  OUT_DIR="$2"; shift 2 ;;
        -r)  RULE_LEVEL="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# === Validate Required Inputs ===
[[ -z "$MIN_LEN" || -z "$CHARSET" ]] && { echo "[!] -mi and -c are required"; usage; }
[[ "$MAX_LEN" -eq 0 ]] && MAX_LEN="$MIN_LEN"

# === Output Paths ===
mkdir -p "$OUT_DIR"
WORDLIST_OUT="$OUT_DIR/filtered_wordlist.txt"
RULE_OUT="$OUT_DIR/policy.rule"
MASK_OUT="$OUT_DIR/policy.mask"

# === Mask Charset Build ===
MASK_CHARS=""
[[ "$CHARSET" == *"a"* ]] && MASK_CHARS+="?l"
[[ "$CHARSET" == *"A"* ]] && MASK_CHARS+="?u"
[[ "$CHARSET" == *"1"* ]] && MASK_CHARS+="?d"
[[ "$CHARSET" == *"!"* ]] && MASK_CHARS+="?s"
[[ -z "$MASK_CHARS" ]] && { echo "Error: Invalid character class."; exit 1; }

# === Generate Mask File ===
echo "[*] Generating masks..."
> "$MASK_OUT"
for ((L=MIN_LEN; L<=MAX_LEN; L++)); do
    MASK=""
    for ((i=0; i<L; i++)); do
        MASK+="${MASK_CHARS:0:3}"  # Use first 3 types max
    done
    echo "$MASK" >> "$MASK_OUT"
done
echo "[+] Mask written to $MASK_OUT"

# === Rule Generation ===
echo "[*] Generating Hashcat rules (level: $RULE_LEVEL)..."
> "$RULE_OUT"

case "$RULE_LEVEL" in
    low)
        echo "$" >> "$RULE_OUT"
        echo "u" >> "$RULE_OUT"
        echo "l" >> "$RULE_OUT"
        ;;
    med)
        echo "$" >> "$RULE_OUT"
        echo "c" >> "$RULE_OUT"
        echo "u" >> "$RULE_OUT"
        echo "l" >> "$RULE_OUT"
        echo "$1" >> "$RULE_OUT"
        echo "$!" >> "$RULE_OUT"
        echo "^1" >> "$RULE_OUT"
        echo "^!" >> "$RULE_OUT"
        ;;
    high)
        for d in {0..9}; do echo "$d" >> "$RULE_OUT"; done
        for s in '!' '@' '#' '$' '%'; do echo "$s" >> "$RULE_OUT"; done
        echo "c" >> "$RULE_OUT"
        echo "u" >> "$RULE_OUT"
        echo "l" >> "$RULE_OUT"
        echo "$1" >> "$RULE_OUT"
        echo "$!" >> "$RULE_OUT"
        echo "^1" >> "$RULE_OUT"
        echo "^!" >> "$RULE_OUT"
        echo "d" >> "$RULE_OUT"
        echo "D" >> "$RULE_OUT"
        ;;
    *)
        echo "[!] Invalid rule level: $RULE_LEVEL"; usage ;;
esac
echo "[+] Rules written to $RULE_OUT"

# === Wordlist Filtering (optional) ===
if [[ -n "$WORDLIST_IN" && "$WORDLIST_IN" != "rockyou.txt" ]]; then
    echo "[*] Filtering $WORDLIST_IN..."
    [[ ! -f "$WORDLIST_IN" ]] && { echo "[!] Wordlist not found: $WORDLIST_IN"; exit 1; }

    GREP_CMD="grep -E '^.{$MIN_LEN,$MAX_LEN}$'"
    [[ "$CHARSET" == *"a"* ]] && GREP_CMD+=" | grep '[a-z]'"
    [[ "$CHARSET" == *"A"* ]] && GREP_CMD+=" | grep '[A-Z]'"
    [[ "$CHARSET" == *"1"* ]] && GREP_CMD+=" | grep '[0-9]'"
    [[ "$CHARSET" == *"!"* ]] && GREP_CMD+=" | grep '[[:punct:]]'"

    TOTAL_BEFORE=$(wc -l < "$WORDLIST_IN")
    eval "$GREP_CMD" "$WORDLIST_IN" > "$WORDLIST_OUT"
    TOTAL_AFTER=$(wc -l < "$WORDLIST_OUT")
    PERCENT=$(awk "BEGIN {printf \"%.2f\", ($TOTAL_AFTER/$TOTAL_BEFORE)*100}")

    echo "[+] Filtered wordlist saved to $WORDLIST_OUT"
    SHOW_FILTER_STATS=1
else
    SHOW_FILTER_STATS=0
fi


echo ""
echo "====== Summary ======"
[[ "$SHOW_FILTER_STATS" == 1 ]] && {
    echo "Wordlist in:         $WORDLIST_IN"
    echo "Filtered wordlist:   $WORDLIST_OUT"
    echo "Total lines before:  $TOTAL_BEFORE"
    echo "Total lines after:   $TOTAL_AFTER"
    echo "Reduction:           $PERCENT%"
}
echo "Mask file:           $MASK_OUT"
echo "Rule file:           $RULE_OUT"
echo "====================="
