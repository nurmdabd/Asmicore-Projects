#!/bin/bash

# ===========================================================================
# TITLE: OpenLane ASIC Synthesis Acceptance Wizard
# AUTHOR: Nur Mohammad Abdullah (nurmdabd)
# DATE: 2026.06.05
# ===========================================================================

echo "=== Day 2 Acceptance Check ==="

NETLIST="../outputs/tpu.v"
SYNLOG="../logs/1-synthesis.log"

# ---------------------------------------------------------------------------
# Check 1: No errors in synthesis log (Isolated Safe Check)
# ---------------------------------------------------------------------------
if [ ! -f "$SYNLOG" ]; then
    echo "[CRITICAL] Synthesis log file is missing or not found!"
else
    ERRORS=$(grep -c 'ERROR' "$SYNLOG" 2>/dev/null)
    if [ "$ERRORS" -eq 0 ]; then
        echo "[PASS] Error count: 0"
    else
        echo "[FAIL] Error count: $ERRORS"
    fi
fi

# ---------------------------------------------------------------------------
# Check 1: No errors in synthesis log (Isolated Safe Check)
# ---------------------------------------------------------------------------
if [ ! -f "$SYNLOG" ]; then
    echo "[CRITICAL] Synthesis log file is missing or not found!"
else
    WARNINGS=$(grep -c -i 'WARNING' "$SYNLOG" 2>/dev/null)
    if [ "$WARNINGS" -eq 0 ]; then
        echo "[PASS] Warning count: 0"
    else
        echo "[FAIL] Warning count: $WARNINGS"
    fi
fi

# ---------------------------------------------------------------------------
# Check 2: Netlist exists and is non-empty
# ---------------------------------------------------------------------------
if [ -s "$NETLIST" ]; then
    echo "[PASS] Netlist exists and non-empty"
    
    # -----------------------------------------------------------------------
    # Check 3: Standard-cell count (Only runs if Netlist safely exists)
    # -----------------------------------------------------------------------
    CELLS=$(grep -c 'sky130_fd_sc_hd' "$NETLIST" 2>/dev/null)
    if [ "$CELLS" -gt 100 ]; then
        echo "[PASS] Cell count: $CELLS"
    else
        echo "[FAIL] Cell count only $CELLS"
    fi

    # -----------------------------------------------------------------------
    # Check 4: Flip-flops present (Only runs if Netlist safely exists)
    # -----------------------------------------------------------------------
    FFS=$(grep -c 'sky130_fd_sc_hd__df' "$NETLIST" 2>/dev/null)
    if [ "$FFS" -gt 0 ]; then
        echo "[PASS] Flip-flops mapped: $FFS"
    else
        echo "[FAIL] No flip-flops detected"
    fi

else
    echo "[FAIL] Netlist missing or empty"
    echo "[CRITICAL] Skipping Cell and Flip-Flop count checks due to missing Netlist."
fi

echo "=============================="