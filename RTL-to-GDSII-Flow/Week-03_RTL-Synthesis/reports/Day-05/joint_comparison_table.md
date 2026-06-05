# Joint 4-Design Comparison

## 4-Design Synthesis Comparison Table

| Metric                      |                 GPU (S1) |               TPU (S2) |                 NPU (S3) |                ibex (S4) |
| --------------------------- | -----------------------: | ---------------------: | -----------------------: | -----------------------: |
| Total Cell Count            |                   13,515 |                 93,781 |                  787,924 |                   11,157 |
| Chip Area (µm²)             |              150,688.272 |             804,275.11 |                1,969,810 |              13,511,277* |
| Flip-Flop Count             |                    2,284 |                  3,040 |                  131,328 |                      865 |
| Most Common Cell Type       | sky130_fd_sc_hd__dfxtp_2 | sky130_fd_sc_hd__buf_1 | sky130_fd_sc_hd__nand2_1 | sky130_fd_sc_hd__nand2_1 |
| WNS at Baseline Clock       |                     0.00 |                   0.00 |                  -81,798 |                       >0 |
| Timing Met?                 |                      Yes |                    Yes |                       No |                      Yes |
| Latches Inferred            |                        0 |                      0 |                        0 |                        0 |
| Unique Cell Types           |                       73 |                     73 |                       63 |                       80 |
| Run-1 → Run-2 Cell Increase |                       0% |                     0% |                       0% |                       0% |
| Estimated RTL Modules       |                       12 |                     28 |                       36 |                       25 |

* ibex area was generated using a custom Liberty-based area estimation method and should be interpreted cautiously when compared against OpenLane-reported synthesis areas.

---

# Analysis Questions

## Q1. Which design has the most cells? Does this match your expectation based on the architecture?

The NPU contains the highest cell count (787,924 cells). This matches expectations because neural-network accelerators require substantial arithmetic and memory resources. Memory inference during synthesis further increased implementation size.

---

## Q2. GPU and TPU both do parallel arithmetic. Why might their cell counts differ?

The TPU uses a systolic-array architecture with dedicated dataflow paths, local interconnects, and extensive buffering. The GPU uses a more compact SIMD-style architecture. Consequently, the TPU requires significantly more hardware resources than the GPU.

---

## Q3. ibex is a CPU — why does it have more diverse logic than the GPU or TPU?

The ibex CPU must support instruction fetch, decode, execution, branching, exception handling, and pipeline control. These functions require a broader variety of control-oriented logic structures than accelerator designs, resulting in the highest number of unique cell types.

---

## Q4. Which design has the best WNS? What does that tell you about its critical path?

GPU, TPU, and ibex all achieved timing closure with non-negative WNS values. This indicates that their critical paths satisfy the target timing constraints and are shorter than the available clock period.

---

## Q5. Which design would be hardest to close timing on in a real tapeout? Why?

The NPU would be the most difficult design to close timing on. Its extremely negative WNS (-81,798 ns) indicates severe timing violations caused primarily by behavioral memory structures being synthesized into large amounts of combinational and sequential logic.

---

## Q6. All designs used the same sky130_fd_sc_hd library. Did they use the same cell types?

No. Although all designs used the same standard-cell library, each architecture utilized different subsets of cells. TPU was buffer-dominated, GPU used many flip-flops, NPU was NAND-heavy, and ibex employed the widest variety of cell types due to its control-intensive architecture.

---

# Group Conclusion

The comparison demonstrates that architecture is the primary factor influencing synthesis outcomes. Accelerator designs emphasize arithmetic throughput and datapath resources, while CPU architectures emphasize control complexity and cell diversity. Memory implementation choices can dramatically affect area, cell count, and timing behavior, as demonstrated by the NPU results.
