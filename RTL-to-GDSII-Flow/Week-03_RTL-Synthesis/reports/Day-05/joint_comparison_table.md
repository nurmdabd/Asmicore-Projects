# Joint 4-Design Comparison

## Overview

This document summarizes the synthesis characteristics of four different accelerator and processor architectures implemented using the SKY130 HD standard-cell library. The objective is to compare resource utilization, timing behavior, and architectural implications across the designs.

At the time of writing, synthesis results for the ibex (S4) design are not yet available. Therefore, the comparison currently includes GPU (S1), TPU (S2), and NPU (S3) results, with ibex values marked as TBD.

---

# Joint 4-Design Comparison Table

| Metric                      |                 GPU (S1) |               TPU (S2) |                 NPU (S3) | ibex (S4) |
| --------------------------- | -----------------------: | ---------------------: | -----------------------: | --------: |
| Total Cell Count            |                   13,515 |                 93,781 |                  787,924 |       TBD |
| Chip Area (µm²)             |               150,688.27 |             804,275.11 |             1,969,810.00 |       TBD |
| Flip-Flop Count             |                    2,284 |                  3,040 |                  131,328 |       TBD |
| Most Common Cell Type       | sky130_fd_sc_hd__dfxtp_2 | sky130_fd_sc_hd__buf_1 | sky130_fd_sc_hd__nand2_1 |       TBD |
| WNS at Baseline Clock       |                  0.00 ns |                0.00 ns |               -81,798 ns |       TBD |
| Timing Met?                 |                      Yes |                    Yes |                       No |       TBD |
| Latches Inferred            |                        0 |                      0 |                        0 |       TBD |
| Unique Cell Types Used      |                       73 |                     73 |                       63 |       TBD |
| Run-1 → Run-2 Cell Increase |                       0% |                     0% |                       0% |       TBD |
| Estimated RTL Modules       |                       12 |                     28 |                       36 |       TBD |

---

# Preliminary Architectural Observations

## GPU (S1)

The GPU implementation produced the smallest synthesized design among the currently available results.

Key observations:

* Lowest cell count.
* Lowest silicon area.
* Timing closure achieved.
* Moderate flip-flop utilization.
* Dominant cell type is a flip-flop cell (`dfxtp_2`), indicating significant sequential logic usage.

The relatively small implementation size suggests that the tiny-GPU design focuses on lightweight parallel processing rather than large-scale matrix computation.

---

## TPU (S2)

The TPU implementation occupies a middle position between the GPU and NPU.

Key observations:

* Approximately seven times larger than the GPU in cell count.
* More than 800,000 µm² estimated area.
* Timing closure achieved.
* Large number of buffer cells inserted during synthesis.
* Systolic-array architecture creates highly regular datapath structures.

The TPU demonstrates a balance between computational throughput and implementation complexity.

---

## NPU (S3)

The NPU implementation is significantly larger than both GPU and TPU.

Key observations:

* Highest cell count.
* Highest silicon area.
* Largest flip-flop count.
* Timing violation observed.
* Dominant use of NAND cells.

The extremely large flip-flop count indicates that behavioral memory structures were synthesized into register-based implementations rather than dedicated SRAM macros.

As a result, the design experiences substantial area growth and severe timing degradation.

---

# Cross-Design Comparison

Based on currently available data:

### Area Ranking

1. GPU
2. TPU
3. NPU

### Cell Count Ranking

1. GPU
2. TPU
3. NPU

### Flip-Flop Ranking

1. GPU
2. TPU
3. NPU

### Timing Performance

* GPU meets timing.
* TPU meets timing.
* NPU fails timing.

---

# Sections Pending Completion

The following sections require ibex synthesis results before final analysis can be completed:

* Finalized Joint Comparison Table
* Q1–Q6 Discussion Questions
* CPU versus Accelerator Comparison
* Timing Closure Difficulty Assessment
* Recommended Design for Week-02 Physical Implementation

These sections will be updated after receiving the ibex (S4) synthesis metrics.

---

# Current Conclusion

The currently available synthesis results demonstrate substantial variation in implementation complexity across the three accelerator architectures.

The GPU represents the smallest implementation with successful timing closure. The TPU occupies a middle ground, providing increased computational capability while maintaining acceptable area and timing characteristics. The NPU exhibits the largest implementation footprint and fails timing due to the synthesis of behavioral memory structures into large numbers of standard-cell registers.

A complete architectural comparison will be performed after integrating the ibex synthesis results.
