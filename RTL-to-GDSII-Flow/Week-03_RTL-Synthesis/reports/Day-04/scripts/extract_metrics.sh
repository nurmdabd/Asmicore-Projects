#!/bin/bash

# Day-04 Metric Extraction Script

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

extract_run() {

    RUN=$1

    SYNLOG="$BASE_DIR/logs/$RUN/1-synthesis.log"
    STALOG="$BASE_DIR/logs/$RUN/2-sta.log"
    NETLIST="$BASE_DIR/outputs/$RUN/tpu.v"

    CELLS=$(grep 'Number of cells' "$SYNLOG" | tail -1 | grep -o '[0-9]*' | tail -1)

    AREA=$(grep 'Chip area' "$SYNLOG" | grep -o '[0-9.]*' | tail -1)

    WNS=$(grep '^wns ' "$STALOG" | tail -1 | awk '{print $2}')

    TNS=$(grep '^tns ' "$STALOG" | tail -1 | awk '{print $2}')

    FFS=$(grep -c 'sky130_fd_sc_hd__df' "$NETLIST")

    if awk "BEGIN {exit !($WNS >= 0)}"; then
        TIMING="Yes"
    else
        TIMING="No"
    fi

    echo "| $RUN | $CELLS | $AREA | $WNS | $TNS | $FFS | $TIMING |"
}

echo "=== Day-04 Metrics ==="
echo

extract_run run1
extract_run run2
extract_run run3

echo
echo "Generating comparison_table.md ..."

cat > "$BASE_DIR/comparison_table.md" << EOF
# Day-04 Configuration Comparison

| Configuration | Cell Count | Area (um²) | WNS (ns) | TNS (ns) | Flip-Flops | Timing Met? |
|--------------|------------|------------|----------|----------|------------|-------------|
$(extract_run run1 | sed 's/run1/Run 1: AREA 0, 20ns/')
$(extract_run run2 | sed 's/run2/Run 2: AREA 0, 10ns/')
$(extract_run run3 | sed 's/run3/Run 3: DELAY 0, 20ns/')
EOF

echo "Done."
echo
echo "Output:"
echo "$BASE_DIR/comparison_table.md"