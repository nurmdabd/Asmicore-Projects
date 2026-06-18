# RTL Synthesis Comparative Study
## Tiny TPU vs Kronos RISC-V Core using ORFS and ASAP7

![Flow](https://img.shields.io/badge/Flow-ORFS-blue)
![PDK](https://img.shields.io/badge/PDK-ASAP7-green)
![Node](https://img.shields.io/badge/Node-7nm-orange)
![RTL](https://img.shields.io/badge/RTL-Verilog%2FSV-red)
![Frequency](https://img.shields.io/badge/Frequency-500%2F600%2F700MHz-purple)
![Status](https://img.shields.io/badge/Status-Completed-success)

This repository presents a comparative RTL synthesis study of two fundamentally different digital architectures:

- **Tiny TPU** – a machine-learning accelerator based on a **4×4 systolic array**
- **Kronos** – a lightweight **RV32I RISC-V processor**

The study was conducted using **OpenROAD Flow Scripts (ORFS)** and the **ASAP7 7nm Predictive PDK**. Both designs were synthesized at multiple target frequencies and analyzed from timing, area, power, and architectural perspectives.

The primary objective was not only to obtain synthesis results, but also to investigate:

- How architectural differences influence synthesis behavior
- Which logic structures dominate timing closure
- How frequency scaling affects timing margins and power consumption
- What design modifications could further improve performance

# Quick Results Snapshot

| Metric              | Tiny TPU    | Kronos      |
| ------------------- | ----------- | ----------- |
| RTL Files           | 17          | 13          |
| Total Cells         | 86102       | 13971       |
| DFF Count           | 3040        | 1933        |
| Area                | 9793.11 μm² | 1745.85 μm² |
| Logic Depth         | 43          | 19          |
| Fmax                | 1059.99 MHz | 1885.85 MHz |
| Total Power @500MHz | 29.3 mW     | 4.35 mW     |
| Critical Path       | PE→GD       | IF→ID       |

# Table of Contents
- [Objectives](#objectives)
- [Environment and Toolchain](#environment-and-toolchain)
- [Design Overview](#design-overview)
- [Methodology](#methodology)
- [Repository Organization](#repository-organization)
- [Important Commands](#important-commands)
- [Synthesis Results](#synthesis-results)
- [Critical Path Analysis](#critical-path-analysis)
- [Challenges Encountered](#challenges-encountered)
- [Engineering Journey Summary](#engineering-journey-summary)
- [Key Findings](#key-findings)
- [Recommended Optimization](#recommended-optimization)
- [Master Metrics Tables](#master-metrics-tables)
- [Lessons Learned](#lessons-learned)
- [Additional Resources](#additional-resources)


---
# Objectives

The goals of this work were:

- Perform RTL synthesis using ORFS and ASAP7
- Compare accelerator and processor architectures
- Evaluate synthesis behavior at multiple frequencies
- Analyze timing closure capability
- Identify worst-case critical paths
- Estimate maximum achievable operating frequencies
- Study power consumption trends
- Investigate architectural bottlenecks
- Recommend potential optimization strategies

---
# Environment and Toolchain

| Item | Value |
|------|-------|
| RTL-to-GDSII Flow | ORFS (OpenROAD Flow Scripts) |
| Technology Node | ASAP7 Predictive PDK |
| Process Node | 7 nm |
| Logic Synthesizer | Yosys |
| Static Timing Analysis | OpenROAD |
| SystemVerilog Frontend | Slang |
| Operating System | Ubuntu 22.04 (WSL2) |
| Frequency Targets | 500 MHz, 600 MHz, 700 MHz |

---
# Design Overview

## Tiny TPU

Tiny TPU is a compact machine-learning accelerator designed around a systolic-array architecture. The design performs matrix multiplication, activation computation, and gradient-update operations.

Major architectural blocks include:

- Processing Elements (PEs)
- Systolic Array
- Gradient Descent Engine
- Activation Functions
- Unified Buffer
- Vector Processing Unit (VPU)

### Architectural Characteristics

- 4×4 systolic array
- Arithmetic-intensive datapath
- Regular replicated structure
- Dataflow-oriented execution model
- MAC dominated computation

---
## Kronos RISC-V Core

Kronos is a lightweight RV32I-compatible processor implementing a three-stage pipeline.

The processor contains logic for:

- Instruction Fetch (IF)
- Instruction Decode (ID)
- Execute (EX)
- Branch Handling
- Hazard Control
- Register File Access
- CSR Operations

### Architectural Characteristics

- Three-stage pipeline
- Control-oriented design
- Sequentially partitioned datapath
- Hazard and branch management
- Instruction-centric execution

---
## Design Summary

| Property | Tiny TPU | Kronos |
|---------|----------|---------|
| Design Type | Tensor Processing Unit | RV32I Processor |
| Top Module | `tpu` | `kronos_core` |
| RTL Files | 17 | 13 |
| Architecture | 4×4 Systolic Array | Three-stage Pipeline |
| Dominant Logic | Arithmetic Datapath | Control Logic |
| Primary Function | Matrix Multiplication and Gradient Update | Instruction Execution and Control |
| Technology | ASAP7 | ASAP7 |
| Frequency Targets | 500 / 600 / 700 MHz | 500 / 600 / 700 MHz |

---
# Methodology

The overall workflow followed during this study is illustrated below.

```text
RTL Design
    │
    ▼
Constraint Generation
    │
    ▼
ORFS Configuration
    │
    ▼
Yosys Logic Synthesis
    │
    ▼
Technology Mapping
    │
    ▼
OpenROAD Static Timing Analysis
    │
    ▼
Metric Extraction
    │
    ▼
Comparative Evaluation
```

The investigation consisted of five major stages.

### Day-01 — Environment Setup and Initial Synthesis

- ORFS environment preparation
- Tiny TPU migration from OpenLane to ORFS
- Kronos SystemVerilog support setup
- Frequency sweep preparation
- Initial synthesis execution

### Day-02 — Architectural Investigation

- Hierarchy analysis
- Arithmetic structure identification
- Cell utilization study
- Systolic array regularity investigation

### Day-03 — Static Timing Analysis

- Critical path extraction
- Logic depth measurement
- Timing slack analysis
- Maximum frequency estimation

### Day-04 — Frequency Behavior Analysis

- Frequency scaling study
- Timing margin comparison
- System-level bottleneck identification
- Optimization recommendations

### Day-05 — Comparative Summary

- Master metric generation
- Power analysis
- Sequential/combinational contribution study
- Automation of report extraction

---
## Frequency Sweep

Three operating points were evaluated throughout the study.

| Target Frequency | Clock Period |
|-----------------|--------------|
| 500 MHz | 2000 ps |
| 600 MHz | 1667 ps |
| 700 MHz | 1429 ps |

Both designs successfully achieved timing closure at all three target frequencies.

# Repository Organization

The project contains two synthesized designs, each evaluated at three target frequencies.

```text
OpenRoad/
├── tiny-tpu/
│   ├── rtl/
│   ├── run_500mhz/
│   ├── run_600mhz/
│   └── run_700mhz/
│
├── kronos/
│   ├── rtl/
│   ├── run_500mhz/
│   ├── run_600mhz/
│   └── run_700mhz/
│
├── generate_report_v1.sh
└── generate_metrics..sh
```

Each synthesis run contains:

```text
configs/
logs/
reports/
results/
```

Important reports used throughout the analysis:

```text
reports/1_Post_synthesis.rpt
reports/synth_stat.txt
results/1_synth.sdc
results/1_2_yosys.v
```
---
# Important Commands
The following commands were frequently used during the study.

## Design Inspection
### Discover available modules

```bash
grep -R "^module " rtl
```

### Count RTL source files

```bash
find rtl \
\( -name "*.v" -o -name "*.sv" \) \
| wc -l
```
---
## ORFS Execution

### Generate ORFS variables

```bash
make DESIGN_CONFIG=config.mk vars
```
### Run synthesis

```bash
make \
DESIGN_CONFIG=config_700mhz.mk \
FLOW_VARIANT=700mhz \
synth
```

### Generate timing reports

```bash
make \
DESIGN_CONFIG=config_700mhz.mk \
FLOW_VARIANT=700mhz \
synth-report
```
---
## Timing Analysis

### Extract worst timing path

```bash
grep -B5 -A300 "Path Type: max" \
reports/1_Post_synthesis.rpt
```

### Extract slack

```bash
grep "slack (MET)" \
reports/1_Post_synthesis.rpt
```

### Extract Fmax

```bash
grep "clk period_min" \
reports/1_Post_synthesis.rpt
```

---
## Power Analysis

```bash
grep -A15 "report_power" \
reports/1_Post_synthesis.rpt
```

---
## Sequential Cell Count

```bash
grep -E "DFF|SDFF|LATCH" \
reports/synth_stat.txt
```

---
# Synthesis Results

## Design Comparison Summary

| Metric | Tiny TPU | Kronos |
|-------|---------|---------|
| RTL Files | 17 | 13 |
| Total Cells | 86102 | 13971 |
| DFF Count | 3040 | 1933 |
| Chip Area | 9793.11 μm² | 1745.85 μm² |
| Logic Depth | 43 | 19 |
| Data Arrival Time | 927.96 ps | 515.19 ps |
| Critical Period | 943.41 ps | 530.27 ps |
| Estimated Fmax | 1059.99 MHz | 1885.85 MHz |
| Total Power @500MHz | 29.3 mW | 4.35 mW |
| Dominant Logic | Arithmetic Datapath | Control Logic |

---
## Frequency Scaling Analysis

| Frequency | TPU Slack | Kronos Slack |
|-----------|-----------|--------------|
| 500 MHz | 1056.59 ps | 1469.73 ps |
| 600 MHz | 723.59 ps | 1136.73 ps |
| 700 MHz | 485.59 ps | 898.73 ps |

### Observation

Both designs successfully satisfy timing requirements at all evaluated frequencies.

Timing slack decreases as frequency increases, but neither design required:

- additional buffers
- logic duplication
- area expansion

Cell count and area remained unchanged from **500 MHz → 700 MHz**.

---
## Power Comparison

| Metric | Tiny TPU | Kronos |
|--------|---------|---------|
| Internal Power | 16.8 mW | 3.14 mW |
| Switching Power | 12.5 mW | 1.21 mW |
| Leakage Power | 7.25 μW | 1.25 μW |
| Total Power | 29.3 mW | 4.35 mW |

### Observation

Tiny TPU consumes approximately

```text
6.7×
```

more power than Kronos.

Power increases almost linearly with frequency while:

- Cell count remains constant
- Chip area remains constant

which matches the expected behavior:

```text
Pdynamic ∝ Frequency
```

---
# Critical Path Analysis

## Tiny TPU

Critical Path

```text
systolic_inst.pe21.pe_psum_out[8]
        ↓
Accumulation Logic
        ↓
Gradient Descent Logic
        ↓
ub_inst.gradient_descent_inst_0
.value_updated_out[10]
```

Characteristics

| Metric | Value |
|--------|-------|
| Logic Depth | 43 Cells |
| Data Arrival Time | 927.96 ps |
| Largest Cell Delay | 67.65 ps |
| Largest Delay Cell | HAxp5_ASAP7_75t_R |
| Minimum Period | 943.41 ps |
| Estimated Fmax | 1059.99 MHz |

Dominant logic cells

```text
FAx1
HAxp5
AO21x1
OA21x2
OA211x2
AO22x1
XNOR2x2
```

---
## Kronos

Critical Path

```text
u_if.fetch[2]
      ↓
Instruction Fetch
      ↓
Decode Logic
      ↓
Control Generation
      ↓
u_id.decode[50]
```

Characteristics

| Metric | Value |
|--------|-------|
| Logic Depth | 19 Cells |
| Data Arrival Time | 515.19 ps |
| Minimum Period | 530.27 ps |
| Estimated Fmax | 1885.85 MHz |
| Worst Slack @700MHz | 898.73 ps |

Dominant cells

```text
INVx1
NOR2x1
AO221x1
OA211x2
OR3x1
XOR2x2
```

---
# Timing Bottleneck Discussion

Several observations can be made from the STA reports.

### Observation-01

Tiny TPU critical path depth

```text
43 cells
```

Kronos critical path depth

```text
19 cells
```

Therefore

```text
TPU critical path is approximately

2.26×

deeper than Kronos
```

---
### Observation-02

Kronos maximum frequency

```text
1885.85 MHz
```

Tiny TPU maximum frequency

```text
1059.99 MHz
```

Thus Kronos can theoretically operate

```text
1.78×

faster
```

than Tiny TPU.

---
### Observation-03

The critical path of Tiny TPU is dominated by

```text
Arithmetic Accumulation
```

whereas Kronos is limited by

```text
Instruction Decode
```

---
### Observation-04

The integrated system frequency is ultimately constrained by

```text
Tiny TPU

Fmax ≈ 1.06 GHz
```

rather than

```text
Kronos

Fmax ≈ 1.89 GHz
```

Consequently, the TPU arithmetic datapath becomes the dominant timing bottleneck of the complete accelerator system.

---
# Challenges Encountered

Throughout this study, several engineering and toolchain issues were encountered. This section documents the most important challenges, their causes, and the corresponding solutions.

## A. Environment and Toolchain Issues

<details>
<summary><b>Problem-01 : ORFS Docker Flow Fails During CTS with Illegal Instruction</b></summary>

### Severity

```text
Critical-Level High
```

### Symptoms

```text
Error: cts.tcl, 83 child killed: illegal instruction
```

### Affected Designs

```text
Nangate45/gcd
ASAP7/gcd
```

### Root Cause

The exact reason could not be isolated.

Evidence suggested either

```text
Docker runtime incompatibility
```

or

```text
Host CPU instruction mismatch
```

inside the OpenROAD executable.

### Resolution

Docker-based ORFS was abandoned.

Moved to

```text
Native OpenROAD Build

Native Yosys Build

Native KLayout Installation
```

### Validation

Successfully generated

```text
results/asap7/gcd/base/6_final.gds

results/nangate45/gcd/base/6_final.gds
```

</details>

---
<details>
<summary><b>Problem-02 : ASAP7 Smoke Test Failure</b></summary>

### Severity

```text
Critical-Level High
```

### Symptoms

```text
Could not resolve PDK 'asap7'
```

### Cause

ASAP7 is not distributed through Volare and must be installed separately.

### Resolution

Clone ASAP7 manually

```bash
git clone \
https://github.com/The-OpenROAD-Project/asap7.git
```

### Validation

ASAP7 reference designs executed successfully.

</details>

---
## B. Design Migration Issues

<details>
<summary><b>Problem-03 : Converting OpenLane TPU Project into an ORFS Design</b></summary>

### Background

Tiny TPU was originally prepared for

```text
OpenLane

OpenLane2
```

using

```text
config.json
```

ORFS expects

```text
config.mk

constraint.sdc
```

### Investigation

Inspect OpenLane configuration

```bash
cat config.json
```

Important fields

```json
"DESIGN_NAME": "tpu"

"CLOCK_PORT": "clk"

"CLOCK_PERIOD": 50.0
```

### Solution

Create ORFS configuration

```makefile
export PLATFORM=asap7

export DESIGN_NAME=tpu

export VERILOG_FILES=...

export SDC_FILE=...
```

Generate variables

```bash
make DESIGN_CONFIG=config.mk vars
```

### Validation

Generated

```text
vars.sh

vars.tcl

vars.gdb
```

TPU became a valid ORFS design.

</details>

---
<details>
<summary><b>Problem-04 : Kronos Top Module Ambiguity</b></summary>

### Candidate Modules

```text
krz_top

snowflake_top

kronos_core
```

### Selected Top Module

```makefile
DESIGN_NAME=kronos_core
```

### Validation

Kronos synthesized successfully.

</details>

---
## C. Timing and Constraint Issues

<details>
<summary><b>Problem-05 : Missing WNS/TNS Reports After Synthesis</b></summary>

### Symptoms

Searching reports

```bash
grep -R "wns" reports
```

returned

```text
(no output)
```

### Root Cause

Timing reports are not generated by

```bash
make synth
```

Timing reports require

```bash
make synth-report
```

### Solution

```bash
make \
DESIGN_CONFIG=config.mk \
FLOW_VARIANT=500mhz \
synth-report
```

Generated

```text
1_Post_synthesis.rpt
```

### Validation

```bash
grep -i "wns" \
1_Post_synthesis.rpt

grep -i "tns" \
1_Post_synthesis.rpt
```

</details>

---
<details>
<summary><b>Problem-06 : Timing Unit Misinterpretation in ASAP7</b></summary>

### Severity

```text
Critical-Level High
```

### Symptoms

Observed

```text
WNS = -941.41

TNS = -1292424.50
```

### Initial Constraint

```tcl
create_clock [get_ports clk] \
-period 2.000
```

### Investigation

Inspect liberty files

```bash
zgrep "time_unit" \
platforms/asap7/lib/NLDM/*.lib.gz
```

Output

```text
time_unit : "1ps";
```

### Root Cause

ASAP7 internally uses

```text
1 ps
```

Therefore

```tcl
-period 2.000
```

means

```text
2 ps
```

instead of

```text
2 ns
```

Actual requested frequency

```text
500 GHz
```

### Correct Constraints

500 MHz

```tcl
-period 2000
```

600 MHz

```tcl
-period 1666.667
```

700 MHz

```tcl
-period 1428.571
```

### Validation

Positive slack observed for all runs.

</details>

---
## D. HDL Frontend Issues

<details>
<summary><b>Problem-07 : SystemVerilog Package Parsing Error</b></summary>

### Symptoms

```text
ERROR:

syntax error

unexpected TOK_IMPORT
```

### Cause

Default frontend

```text
read_verilog
```

cannot fully parse package imports.

### Resolution

Use Slang frontend

```makefile
export SYNTH_HDL_FRONTEND=slang
```

### Validation

Logs show

```text
Executing SLANG frontend
```

</details>

---
## E. Data Collection Issues

<details>
<summary><b>Problem-08 : Metrics Distributed Across Multiple Reports</b></summary>

Metrics were scattered across

```text
synth_stat.txt

1_Post_synthesis.rpt

1_synth.sdc

1_2_yosys.v
```

### Solution

Develop

```text
generate_report_v1.sh
```

to automate extraction.

</details>

---
<details>
<summary><b>Problem-09 : Incorrect Flip-Flop Counting</b></summary>

Initially reported

```text
TPU

6080

Kronos

3864
```

After verification

```text
TPU

3040

Kronos

1933
```

### Root Cause

Double counting during cell extraction.

</details>

---
# Engineering Journey Summary

```text
Docker ORFS
      │
      ├── CTS Illegal Instruction
      ▼

Native ORFS
      │
      ├── ASAP7 Smoke Test Failure
      ▼

TPU Migration
(OpenLane → ORFS)
      │
      ├── Missing WNS/TNS
      ├── Timing Unit Investigation
      ├── Slang Frontend Issue
      ▼

Frequency Sweep
      │
      ├── Critical Path Analysis
      ├── Power Analysis
      ▼

Comparative Evaluation
```

---
# Key Findings

- Tiny TPU contains approximately **6.16× more cells** than Kronos.

- Kronos achieves approximately **1.78× higher maximum operating frequency**.

- Tiny TPU critical path is approximately **2.26× deeper**.

- Tiny TPU consumes approximately **6.7× more total power**.

- Both designs successfully close timing at **700 MHz**.

- Tiny TPU arithmetic datapath limits overall system frequency.

- Dynamic power increases nearly linearly with frequency.

- No additional cells were required from **500 MHz → 700 MHz**.

---
# Recommended Optimization

Current implementation

```text
Register
↓
43 combinational stages
↓
Register
```

Suggested implementation

```text
Register
↓
≈21 stages
↓
Pipeline Register
↓
≈22 stages
↓
Register
```

Expected benefits

- Higher achievable frequency
- Improved timing margin
- Better scalability
- Reduced critical path delay

Trade-offs
- Additional flip-flops
- Increased clock power
- One extra pipeline stage

---

# Master Metrics Tables
## Tiny TPU Master Metrics Table

| Count | Metric                         | 500 MHz                                                   | 600 MHz                                                   | 700 MHz                                                   |
| :---: | ------------------------------ | --------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------- |
|   1   | Clock Period (ps)              | 2000                                                      | 1667                                                      | 1429                                                      |
|   2   | Top Module                     | `tpu`                                                     | `tpu`                                                     | `tpu`                                                     |
|   3   | RTL Files                      | 17                                                        | 17                                                        | 17                                                        |
|   4   | Total Cells                    | 86102                                                     | 86102                                                     | 86102                                                     |
|   5   | Combinational Cells            | 83062                                                     | 83062                                                     | 83062                                                     |
|   6   | Sequential Cells               | 3040                                                      | 3040                                                      | 3040                                                      |
|   7   | DFF Count                      | 3040                                                      | 3040                                                      | 3040                                                      |
|   8   | Sequential Cell %              | 3.53 %                                                    | 3.53 %                                                    | 3.53 %                                                    |
|   9   | Sequential Area (%)            | 11.68 %                                                   | 11.68 %                                                   | 11.68 %                                                   |
|  10   | Chip Area (μm²)                | 9793.109                                                  | 9793.109                                                  | 9793.109                                                  |
|  11   | Worst Slack                    | 1056.59                                                   | 723.59                                                    | 485.59                                                    |
|  12   | WNS (ps)                       | 0.00                                                      | 0.00                                                      | 0.00                                                      |
|  13   | TNS (ps)                       | 0.00                                                      | 0.00                                                      | 0.00                                                      |
|  14   | FEP                            | 0                                                         | 0                                                         | 0                                                         |
|  15   | Minimum Period (ps)            | 943.41                                                    | 943.41                                                    | 943.41                                                    |
|  16   | Estimated Fmax (MHz)           | 1059.99                                                   | 1059.99                                                   | 1059.99                                                   |
|  17   | Path Groups                    | clk                                                       | clk                                                       | clk                                                       |
|  18   | Number of Path Groups          | 1                                                         | 1                                                         | 1                                                         |
|  19   | Most Critical Path Group       | clk                                                       | clk                                                       | clk                                                       |
|  20   | Number of Max Paths            | 2                                                         | 2                                                         | 2                                                         |
|  21   | Start Point of Critical Path   | `systolic_inst.pe21.`<br>`pe_psum_out[8]`                 | `systolic_inst.pe21.`<br>`pe_psum_out[8]`                 | `systolic_inst.pe21.`<br>`pe_psum_out[8]`                 |
|  22   | End Point of Critical Path     | ub_inst.gradient_descent_inst_0.<br>value_updated_out[10] | ub_inst.gradient_descent_inst_0.<br>value_updated_out[10] | ub_inst.gradient_descent_inst_0.<br>value_updated_out[10] |
|  23   | Critical Path Logic Depth      | 43                                                        | 43                                                        | 43                                                        |
|  24   | Largest Cell Type              | `HAxp5_ASAP7_75t_R`                                       | `HAxp5_ASAP7_75t_R`                                       | `HAxp5_ASAP7_75t_R`                                       |
|  25   | Largest Single Cell Delay (ps) | 67.65                                                     | 67.65                                                     | 67.65                                                     |
|  26   | Data Arrival Time (ps)         | 927.96                                                    | 927.96                                                    | 927.96                                                    |
|  27   | Setup Time (ps)                | 15.44                                                     | 15.44                                                     | 15.44                                                     |
|  28   | VT Type                        | RVT                                                       | RVT                                                       | RVT                                                       |
|  29   | RVT Percentage                 | 100%                                                      | 100%                                                      | 100%                                                      |
|  30   | Internal Power (W)             | 1.68e-02 W                                                | 2.02e-02                                                  | 2.35e-02 W                                                |
|  31   | Switching Power (W)            | 1.25e-02                                                  | 1.49e-02                                                  | 1.74e-02 W                                                |
|  32   | Leakage Power (W)              | 7.25e-06                                                  | 7.25e-06                                                  | 7.25e-06 W                                                |
|  33   | Total Power (W)                | 2.93e-02                                                  | 3.51e-02                                                  | 4.10e-02 W                                                |
|  34   | Sequential Contribution (%)    | 13.7 %                                                    | 13.7 %                                                    | 13.7 %                                                    |
|  35   | Combinational Contribution (%) | 86.3 %                                                    | 86.3 %                                                    | 86.3 %                                                    |
|  36   | Buffer Count                   | 12781                                                     | 12781                                                     | 12781                                                     |
|  37   | Inverter Count                 | 6937                                                      | 6937                                                      | 6937                                                      |
|  38   | Arithmetic Cell Count          | 3864                                                      | 3864                                                      | 3864                                                      |
|  39   | Average Cell Area (μm²/cell)   | 0.1137                                                    | 0.1137                                                    | 0.1137                                                    |
|  40   | Power Density (W/μm²)          | 2.99189972e-06                                            | 3.58415291e-06                                            | 4.18661735e-06                                            |

- WNS-Worst Negative Slack
- TNS-Total Negative Slack
- DFF-D Flip Flop
- FEP-Failing Endpoints
---

## Kronos Master Metrics Table

| Count | Metric                         | 500 MHz                     | 600 MHz                     | 700 MHz                     |
| :---: | ------------------------------ | --------------------------- | --------------------------- | --------------------------- |
|   1   | Clock Period (ps)              | 2000                        | 1667                        | 1429                        |
|   2   | Top Module                     | `kronos_core`               | `kronos_core`               | `kronos_core`               |
|   3   | RTL Files                      | 13                          | 13                          | 13                          |
|   4   | Total Cells                    | 13971                       | 13971                       | 13971                       |
|   5   | Combinational Cells            | 12038                       | 12038                       | 12038                       |
|   6   | Sequential Cells               | 1933                        | 1933                        | 1933                        |
|   7   | DFF Count                      | 1933                        | 1933                        | 1933                        |
|   8   | Sequential Cell %              | 13.84 %                     | 13.84 %                     | 13.84 %                     |
|   9   | Sequential Area (%)            | 33.58 %                     | 33.58 %                     | 33.58 %                     |
|  10   | Chip Area (μm²)                | 1745.853                    | 1745.853                    | 1745.853                    |
|  11   | Worst Slack                    | 1469.73                     | 1136.73                     | 898.73                      |
|  12   | WNS (ps)                       | 0.00                        | 0.00                        | 0.00                        |
|  13   | TNS (ps)                       | 0.00                        | 0.00                        | 0.00                        |
|  14   | FEP                            | 0                           | 0                           | 0                           |
|  15   | Minimum Period (ps)            | 530.27                      | 530.27                      | 530.27                      |
|  16   | Estimated Fmax (MHz)           | 1885.85                     | 1885.85                     | 1885.85                     |
|  17   | Path Groups                    | clk                         | clk                         | clk                         |
|  18   | Number of Path Groups          | 1                           | 1                           | 1                           |
|  19   | Most Critical Path Group       | clk                         | clk                         | clk                         |
|  20   | Number of Max Paths            | 2                           | 2                           | 2                           |
|  21   | Start Point of Critical Path   | `u_if.fetch[2]$_DFFE_PP_`   | `u_if.fetch[2]$_DFFE_PP_`   | `u_if.fetch[2]$_DFFE_PP_`   |
|  22   | End Point of Critical Path     | `u_id.decode[50]$_DFFE_PP_` | `u_id.decode[50]$_DFFE_PP_` | `u_id.decode[50]$_DFFE_PP_` |
|  23   | Critical Path Logic Depth      | 19                          | 19                          | 19                          |
|  24   | Largest Cell Type              | `HAxp5_ASAP7_75t_R`         | `HAxp5_ASAP7_75t_R`         | `HAxp5_ASAP7_75t_R`         |
|  25   | Largest Single Cell Delay (ps) | 62.46                       | 62.46                       | 62.46                       |
|  26   | Data Arrival Time (ps)         | 515.19                      | 515.19                      | 515.19                      |
|  27   | Setup Time (ps)                | 15.08                       | 15.08                       | 15.08                       |
|  28   | VT Type                        | RVT                         | RVT                         | RVT                         |
|  29   | RVT Percentage                 | 100%                        | 100%                        | 100%                        |
|  30   | Internal Power (W)             | 3.14e-03                    | 3.77e-03                    | 4.40e-03                    |
|  31   | Switching Power (W)            | 1.21e-03                    | 1.45e-03                    | 1.70e-03                    |
|  32   | Leakage Power (W)              | 1.25e-06                    | 1.25e-06                    | 1.25e-06                    |
|  33   | Total Power (W)                | 4.35e-03                    | 5.22e-03                    | 6.09e-03                    |
|  34   | Sequential Contribution (%)    | 47.3%                       | 47.3%                       | 47.3%                       |
|  35   | Combinational Contribution (%) | 52.7%                       | 52.7%                       | 52.7%                       |
|  36   | Buffer Count                   | 1420                        | 1420                        | 1420                        |
|  37   | Inverter Count                 | 779                         | 779                         | 779                         |
|  38   | Arithmetic Cell Count          | 171                         | 171                         | 171                         |
|  39   | Average Cell Area (μm²/cell)   | 0.1250                      | 0.1250                      | 0.1250                      |
|  40   | Power Density (W/μm²)          | 2.49161880e-06              | 2.98994255e-06              | 2.98994255e-06              |

- WNS-Worst Negative Slack
- TNS-Total Negative Slack
- DFF-D Flip Flop
- FEP-Failing Endpoints

# Lessons Learned

- ORFS and OpenLane use different design configuration formats.

- Timing units should always be verified from Liberty files.

- `make synth` and `make synth-report` generate different artifacts.

- SystemVerilog package support requires the Slang frontend.

- Automation scripts significantly reduce manual extraction effort.

- Architecture strongly influences timing behavior.

- Static Timing Analysis provides much deeper insight than area and cell counts alone.


---


# Additional Resources


### Week-04 Assignment Directory

Repository containing all synthesis runs, reports, scripts, and documentation.

📁 **Week-04_RTL-Synthesis**

<https://github.com/nurmdabd/Asmicore-Projects/tree/master/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis>


### Metric Extraction Scripts

Automation scripts used to extract timing, area, power, and cell statistics from ORFS reports.

📄 **generate_metrics..sh**

<https://github.com/nurmdabd/Asmicore-Projects/tree/master/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis/scripts>


### Individual Metric Extraction Methodology

Detailed commands used to extract each reported metric individually.

📄 **Appendix-B_Markdown.md**

<https://github.com/nurmdabd/Asmicore-Projects/blob/master/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis/OpenRoad/Appendix-B_Markdown.md>


---