# Day-02 Fixes

## Overview

The objective of Day-02 was to eliminate synthesis errors, obtain a valid gate-level netlist, verify successful technology mapping, and satisfy all synthesis acceptance criteria.

---

## Fix 1: Yosys Assertion Failure During RTL Elaboration

### Error Message

```text
ERROR: Assert `arg->is_signed == sig.as_wire()->is_signed'
failed in frontends/ast/genrtlil.cc:1985.
```

### Location

```text
fixedpoint.sv
```

### Root Cause

The original Tiny TPU RTL implementation used a complex fixed-point arithmetic library (`fixedpoint.sv`) containing parameterized signed arithmetic constructs. During RTL elaboration, Yosys encountered a signedness mismatch that triggered an internal assertion failure.

As a result, synthesis terminated before technology mapping and no gate-level netlist could be generated.

### Investigation

The issue was isolated by directly invoking Yosys on the arithmetic library:

```bash
yosys -p "read_verilog -sv fixedpoint.sv"
```

The failure was reproduced outside OpenLane, confirming that the root cause was located in the RTL implementation rather than the OpenLane flow itself.

### Fix Applied

Repository analysis identified an ASIC-oriented implementation located in:

```text
tiny-tpu-hardened/
```

This version replaced the original arithmetic package with:

```text
fixedpoint_simple.v
```

The hardened implementation was adopted as the synthesis target, and the OpenLane configuration was updated accordingly.

### Confirmation

After switching to the hardened implementation:

* RTL elaboration completed successfully.
* Technology mapping completed successfully.
* Gate-level netlist generation succeeded.
* Timing annotation file was generated.

Generated outputs:

```text
tpu.v
tpu.sdf
```

---

## Day-02 Acceptance Results

| Check               | Result |
| ------------------- | ------ |
| Error Count         | 0      |
| Netlist Exists      | Yes    |
| Netlist Non-Empty   | Yes    |
| Standard Cell Count | 93781  |
| Flip-Flops Present  | Yes    |
| DFF Count           | 3040   |
| Synthesis Status    | PASS   |

---

## Final Verification

### Error Count

```text
0
```

### Netlist Size

```text
12 MB
```

### Standard Cell Count

```text
93781
```

### Flip-Flop Statistics

```text
sky130_fd_sc_hd__dfrtp : 2944
sky130_fd_sc_hd__dfxtp : 96
Total DFFs            : 3040
```

### Conclusion

All Day-02 synthesis acceptance requirements were satisfied. The Tiny TPU design successfully produced a non-empty gate-level netlist with valid standard-cell mapping and sequential logic implementation. The design is ready to proceed to Day-03 activities.

```
```
