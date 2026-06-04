#!/bin/bash

echo "=== Day 2 Acceptance Check ==="

NETLIST="../outputs/tpu.v"
SYNLOG="../logs/1-synthesis.log"

# Check 1: No errors in synthesis log
ERRORS=$(grep -c 'ERROR' "$SYNLOG" 2>/dev/null || echo 0)

if [ "$ERRORS" -eq 0 ]; then
    echo "[PASS] Error count: 0"
else
    echo "[FAIL] Error count: $ERRORS"
fi

# Check 2: Netlist exists and is non-empty
if [ -s "$NETLIST" ]; then
    echo "[PASS] Netlist exists and non-empty"
else
    echo "[FAIL] Netlist missing or empty"
fi

# Check 3: Standard-cell count
CELLS=$(grep -c 'sky130_fd_sc_hd' "$NETLIST" 2>/dev/null || echo 0)

if [ "$CELLS" -gt 100 ]; then
    echo "[PASS] Cell count: $CELLS"
else
    echo "[FAIL] Cell count only $CELLS"
fi

# Check 4: Flip-flops present
FFS=$(grep -c 'sky130_fd_sc_hd__df' "$NETLIST" 2>/dev/null || echo 0)

if [ "$FFS" -gt 0 ]; then
    echo "[PASS] Flip-flops mapped: $FFS"
else
    echo "[FAIL] No flip-flops detected"
fi

echo "=============================="
