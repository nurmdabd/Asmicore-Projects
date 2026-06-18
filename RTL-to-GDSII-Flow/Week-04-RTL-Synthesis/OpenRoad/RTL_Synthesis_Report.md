# RTL Synthesis Report
## 1. Report Metadata

| Property | Value |
|----------|----------|
| Generated On | 2026-06-16 11:25:57 |
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

