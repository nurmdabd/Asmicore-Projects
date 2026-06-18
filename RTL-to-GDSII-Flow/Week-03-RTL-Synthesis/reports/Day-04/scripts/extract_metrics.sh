#!/bin/bash

# ===========================================================================
# TITLE: OpenLane Day-04 Metric Extraction & Comparison Wizard
# AUTHOR: Nur Mohammad Abdullah (nurmdabd)
# DATE: 2026.06.06
# ===========================================================================


BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_NAME=$(basename "$0")
OUTPUT_MD="$BASE_DIR/comparison_table.md"

# ---------------------------------------------------------------------------
# CORE FUNCTION: extract_run
# Purpose: Scans logs once and outputs a sanitized markdown table row
# ---------------------------------------------------------------------------
extract_run() {
    local RUN=$1
    local LABEL=$2

    local SYNLOG="$BASE_DIR/$RUN/logs/1-synthesis.log"
    local STALOG="$BASE_DIR/$RUN/logs/2-sta.log"
    local NETLIST="$BASE_DIR/$RUN/outputs/tpu.v"

    # File Existence Isolation Check (For Secure Debugging)
    if [ ! -f "$SYNLOG" ] || [ ! -f "$STALOG" ] || [ ! -f "$NETLIST" ]; then
        echo "| $LABEL | N/A (Log Missing) | N/A | N/A | N/A | N/A | N/A |"
        return
    fi

    # 1. Pure Data Extraction Pipeline
    local CELLS=$(grep 'Number of cells' "$SYNLOG" | tail -1 | grep -o '[0-9]*' | tail -1)
    local AREA=$(grep 'Chip area' "$SYNLOG" | grep -o '[0-9.]*' | tail -1)
    local WNS=$(grep '^wns ' "$STALOG" | tail -1 | awk '{print $2}')
    local TNS=$(grep '^tns ' "$STALOG" | tail -1 | awk '{print $2}')
    local FFS=$(grep -c 'sky130_fd_sc_hd__df' "$NETLIST")

    # Fail-Safe Check: If variables are empty, set defaults
    CELLS=${CELLS:-0}
    AREA=${AREA:-0}
    WNS=${WNS:-0.00}
    TNS=${TNS:-0.00}

    # 2. Timing Conditional Logic (Mathematical Truth Check)
    local TIMING="No ❌"
    if awk "BEGIN {exit !($WNS >= 0)}"; then
        TIMING="Yes 🟢"
    fi

    # Final Output Format
    echo "| $LABEL | $CELLS | $AREA | $WNS | $TNS | $FFS | $TIMING |"
}

# ---------------------------------------------------------------------------
# MAIN EXECUTION BLOCK (The Multi-Run Pipeline)
# ---------------------------------------------------------------------------
echo "==========================================================================="
echo " Wizard Tool  : $SCRIPT_NAME"
echo " Project Root : $BASE_DIR"
echo "==========================================================================="
echo "=== Generating Day-04 Metrics Comparison ==="
echo

# Writing the initial header of the Markdown file
cat > "$OUTPUT_MD" << EOF
# Day-04 Configuration Comparison

| Configuration | Cell Count | Area (um²) | WNS (ns) | TNS (ns) | Flip-Flops | Timing Met? |
|--------------|------------|------------|----------|----------|------------|-------------|
EOF

# Pro-Tips Tricks: We will run the function only once. With 'tee -a', it will be printed 
# to the terminal simultaneously and saved by appending to the bottom of the Markdown file!
extract_run "run1" "Run 1: AREA 0, 20ns" | tee -a "$OUTPUT_MD"
extract_run "run2" "Run 2: AREA 0, 10ns" | tee -a "$OUTPUT_MD"
extract_run "run3" "Run 3: DELAY 0, 20ns" | tee -a "$OUTPUT_MD"

echo
echo "---------------------------------------------------------------------------"
echo "Done! Comparison report successfully compiled."
echo "Output MD File locked at: $OUTPUT_MD"
echo "==========================================================================="