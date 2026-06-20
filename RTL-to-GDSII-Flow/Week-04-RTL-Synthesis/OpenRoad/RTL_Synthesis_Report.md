# RTL Synthesis Report
## 1. Report Metadata

| Property | Value |
|----------|----------|
| Generated On | 2026-06-18 23:34:16 |
| Technology | ASAP7 |
| Flow | OpenROAD Flow Scripts (ORFS) |
| Analysis Type | RTL Synthesis |
| Design Count | 2 |
| Frequency Points | 500 MHz, 600 MHz, 700 MHz |

## 2. Design Characteristics

| Metric | TPU | Kronos Core |
|----------|----------|----------|
| Design Name | TPU | Kronos Core |
| Top Module | tpu | kronos_core |
| Technology Node | ASAP7 | ASAP7 |
| Standard Cell Library | ASAP7 Standard Cell Family | ASAP7 Standard Cell Family |
| Target Frequencies | 500/600/700 MHz | 500/600/700 MHz |
| Flip-Flop Count | 3040 | 1933 |
| Most Common Cell Type | BUFx2_ASAP7_75t_R | DFFHQNx1_ASAP7_75t_R |
| Most Common Cell Count | 12683 | 1675 |
| Total Cell Count | 86102 | 13971 |
| Chip Area (µm²) | 9793.11 | 1745.85 |


---

## 3. Metrics Collection Sources

| Metric | Source File | Extraction Method |
|----------|----------|----------|
| Top Module | config_*.mk | DESIGN_NAME |
| Cell Count | synth_stat.txt | grep "cells$" |
| Chip Area | synth_stat.txt | grep "Chip area" |
| Flip-Flop Count | 1_2_yosys.v | DFF cell counting |
| Most Common Cell | 1_2_yosys.v | histogram analysis |
| WNS | 1_Post_synthesis.rpt | grep "^wns" |
| TNS | 1_Post_synthesis.rpt | grep "^tns" |
| Worst Slack | 1_Post_synthesis.rpt | grep "worst slack" |
| Critical Path Period | 1_Post_synthesis.rpt | grep "period_min" |
| Fmax | 1_Post_synthesis.rpt | grep "fmax" |
| Timing Status | Derived from WNS | PASS |


## 4. Day-01 Synthesis Results

### TPU

| Metric | 500 MHz | 600 MHz | 700 MHz | 500→700 Change | Timing Met All 3? |
|----------|----------|----------|----------|----------|----------|
| Cell Count | 86102 | 86102 | 86102 | 0.00% | Yes |
| Chip Area (µm²) | 9793.11 | 9793.11 | 9793.11 | 0.00% | Yes |
| Flip-Flop Count | 3040 | 3040 | 3040 | 0.00% | Yes |
| WNS (ns) | 0.00 | 0.00 | 0.00 | N/A | Yes |
| TNS (ns) | 0.00 | 0.00 | 0.00 | N/A | Yes |
| Worst Slack (ps) | 1056.59 | 723.59 | 485.59 | -54.04% | Yes |

### Kronos Core

| Metric | 500 MHz | 600 MHz | 700 MHz | 500→700 Change | Timing Met All 3? |
|----------|----------|----------|----------|----------|----------|
| Cell Count | 13971 | 13971 | 13971 | 0.00% | Yes |
| Chip Area (µm²) | 1745.85 | 1745.85 | 1745.85 | 0.00% | Yes |
| Flip-Flop Count | 1933 | 1933 | 1933 | 0.00% | Yes |
| WNS (ns) | 0.00 | 0.00 | 0.00 | N/A | Yes |
| TNS (ns) | 0.00 | 0.00 | 0.00 | N/A | Yes |
| Worst Slack (ps) | 1469.73 | 1136.73 | 898.73 | -38.85% | Yes |


---

## 5. Frequency Scaling Analysis

| Metric | TPU-500 | TPU-600 | TPU-700 | Kronos-500 | Kronos-600 | Kronos-700 |
|----------|----------|----------|----------|----------|----------|----------|
| Target Period (ps) | 2000.0000 | 1667.0000 | 1429.0000 | 2000.0000 | 1667.0000 | 1429.0000 |
| Critical Path (ps) | 943.41 | 943.41 | 943.41 | 530.26 | 530.27 | 530.27 |
| Fmax (MHz) | 1059.99 | 1059.99 | 1059.99 | 1885.85 | 1885.85 | 1885.85 |
| Worst Slack (ps) | 1056.59 | 723.59 | 485.59 | 1469.73 | 1136.73 | 898.73 |
| Frequency Margin (MHz) | 359.99 | 359.99 | 359.99 | 1185.85 | 1185.85 | 1185.85 |


---

## 6. Cross-Design Comparison

| Metric | TPU | Kronos |
|----------|----------|----------|
| Total Cells | 86102 | 13971 |
| Chip Area (µm²) | 9793.11 | 1745.85 |
| Flip-Flops | 3040 | 1933 |
| Most Common Cell | BUFx2_ASAP7_75t_R | DFFHQNx1_ASAP7_75t_R |
| Most Common Cell Count | 12683 | 1675 |
| Fmax (MHz) | 1059.99 | 1885.85 |
| FF Percentage (%) | 3.53 | 13.84 |
| Cells per µm² | 8.79 | 8.00 |
| Area per Cell (µm²/cell) | 0.11 | 0.12 |

### Derived Ratios

| Metric | Value |
|----------|----------|
| TPU/Kronos Area Ratio | 5.61 |
| TPU/Kronos Cell Ratio | 6.16 |
| TPU/Kronos FF Ratio | 1.57 |
| TPU/Kronos Fmax Ratio | 0.56 |
| TPU/Kronos Cell Density Ratio | 1.10 |

---

## 7. Design Ranking

| Category | Winner | Reason |
|----------|----------|----------|
| Smallest Area | Kronos | Lower silicon footprint |
| Lowest Cell Count | Kronos | Smaller implementation |
| Highest Fmax | Kronos | Better timing capability |
| Highest FF Ratio | Kronos | More sequential logic |
| Highest Cell Density | TPU | Better packing efficiency |
| Lowest Area per Cell | TPU | Better area utilization |
### Overall Assessment

---

Kronos wins in 4 categories.

TPU wins in 2 categories.

Overall winner: Kronos.

Kronos demonstrates superior timing performance and implementation efficiency.

TPU demonstrates higher computational complexity and logic capacity.
---

## 8. Frequency Scaling Behavior

| Design | Slack Loss (ps) | Slack Reduction (%) |
|----------|----------|----------|
| TPU | 571.00 | -54.04% |
| Kronos | 571.00 | -38.85% |

---

## 9. Key Observations

1. TPU occupies 5.61× more silicon area than Kronos.

2. TPU contains 6.16× more standard cells than Kronos.

3. Kronos achieves the highest maximum operating frequency (1885.85 MHz).

4. Both designs successfully meet timing at 500 MHz, 600 MHz and 700 MHz.

5. TPU retains a frequency margin of 359.99 MHz above the 700 MHz target.

6. Kronos retains a frequency margin of 1185.85 MHz above the 700 MHz target.

7. TPU contains 3.53% sequential cells.

8. Kronos contains 13.84% sequential cells.

9. Kronos is more sequentially dominated, while TPU is more combinationally dominated.

10. Kronos contains nearly 4× higher sequential-cell ratio than TPU (13.84% vs 3.53%).

