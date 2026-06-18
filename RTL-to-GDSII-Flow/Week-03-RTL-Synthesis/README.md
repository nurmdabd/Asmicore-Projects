# Week-03 RTL Synthesis Workflow
## Tiny TPU ASIC Synthesis Using OpenLane and SKY130

---

## Overview

This repository documents the complete RTL synthesis workflow performed as part of the RTL-to-GDSII implementation flow using the OpenLane ASIC toolchain and the SKY130 open-source Process Design Kit (PDK).

The project focuses on synthesizing a Tiny Tensor Processing Unit (Tiny TPU) accelerator architecture into a technology-mapped gate-level implementation while investigating synthesis behavior, debugging methodology, timing analysis, optimization tradeoffs, and architectural implementation characteristics.

Unlike a simple synthesis exercise, this workflow emphasizes engineering investigation, synthesis debugging, report interpretation, design-space exploration, and implementation-quality evaluation.

---

## Project Objectives

The primary goals of this work are:

- Establish a production-ready OpenLane synthesis environment.
- Analyze and understand a hierarchical TPU accelerator RTL design.
- Generate a technology-mapped gate-level netlist.
- Perform synthesis debugging and error resolution.
- Validate synthesis correctness through acceptance testing.
- Interpret synthesis statistics and timing reports.
- Evaluate timing-versus-area tradeoffs.
- Compare synthesis characteristics across multiple processor architectures.
- Develop practical understanding of ASIC synthesis methodology.

---

# Design Information

| Item | Value |
|--------|--------|
| Design | Tiny TPU |
| Top Module | `tpu` |
| RTL Language | SystemVerilog / Verilog |
| Flow | OpenLane |
| Synthesizer | Yosys |
| STA Tool | OpenSTA |
| PDK | SKY130A |
| Standard Cell Library | `sky130_fd_sc_hd` |
| Target Platform | ASIC |

---

# Design Architecture

The Tiny TPU implements a machine-learning accelerator architecture composed of multiple computational subsystems.

```text
tpu
├── systolic
│   └── pe
│
├── unified_buffer
│   └── gradient_descent
│
└── vpu
    ├── bias_parent
    │   └── bias_child
    │
    ├── leaky_relu_parent
    │   └── leaky_relu_child
    │
    ├── leaky_relu_derivative_parent
    │   └── leaky_relu_derivative_child
    │
    └── loss_parent
        └── loss_child
```

The architecture combines:

- Matrix multiplication hardware
- Processing elements
- Vector processing units
- Activation functions
- Gradient descent logic
- Unified memory buffering
- Control logic

This creates a highly interconnected accelerator-oriented RTL design suitable for synthesis exploration.

---

# Workflow Overview

The synthesis workflow was organized into six engineering phases.

```text
Day-00
Environment Setup
        │
        ▼
Day-01
Initial Synthesis
        │
        ▼
Day-02
Debugging & Validation
        │
        ▼
Day-03
Report Analysis
        │
        ▼
Day-04
Optimization Study
        │
        ▼
Day-05
Cross-Architecture Comparison
```

---

# Day-00 — Environment Preparation

## Objective

Establish a reproducible ASIC synthesis environment.

## Activities

### OpenLane Setup

OpenLane was installed using the official Docker-based workflow.

```bash
git clone https://github.com/The-OpenROAD-Project/OpenLane.git
cd OpenLane
make mount
```

### SKY130 PDK Verification

Environment validation included:

```bash
echo $PDK
echo $PDK_ROOT
```

Verification of:

- OpenLane installation
- Docker functionality
- PDK accessibility
- Liberty timing libraries
- Standard cell libraries

### Repository Investigation

The Tiny TPU repository was analyzed to identify:

- Synthesizable RTL sources
- Top-level hierarchy
- Clock ports
- Reset ports

### Critical Design Parameters

| Parameter | Value |
|------------|---------|
| Top Module | `tpu` |
| Clock Port | `clk` |
| Reset Port | `rst` |
| RTL Sources | `src/*.sv` |

---

# Day-01 — First Synthesis Attempt

## Objective

Perform the first RTL synthesis execution using OpenLane.

---

## Configuration Development

Initial configuration:

```json
{
  "DESIGN_NAME": "tpu",
  "VERILOG_FILES": "dir::src/*.sv",
  "CLOCK_PORT": "clk",
  "CLOCK_PERIOD": 10
}
```

---

## Major Challenge Encountered

The synthesis flow successfully completed:

- RTL Parsing
- Hierarchy Construction
- Verilator Checking

but failed during RTL elaboration.

### Failure

```text
ERROR:
Assert `arg->is_signed == sig.as_wire()->is_signed'
```

Location:

```text
fixedpoint.sv
```

### Difficulty Level

⭐⭐⭐⭐⭐ High

This was not:

- a configuration error
- a missing file
- an OpenLane issue

The failure originated from internal signed-arithmetic handling inside the RTL implementation.

---

# Day-02 — Debugging and Recovery

## Objective

Achieve a clean synthesis result.

---

## Debug Methodology

Rather than modifying random RTL files, a structured debugging workflow was followed.

### Step 1

Identify failure stage.

```text
Yosys Elaboration
```

### Step 2

Isolate failing module.

```text
fixedpoint.sv
```

### Step 3

Reproduce independently.

```bash
yosys -p "read_verilog -sv fixedpoint.sv"
```

### Step 4

Search repository for synthesis-oriented alternatives.

### Step 5

Identify Hardened TPU implementation.

---

## Hardened RTL Migration

A dedicated ASIC-oriented implementation was discovered.

```text
tiny-tpu-hardened/
```

Key improvement:

```text
fixedpoint.sv
    ↓

fixedpoint_simple.v
```

The simplified arithmetic implementation eliminated the Yosys assertion failure.

---

## Corrective Actions

### RTL Migration

Moved to hardened source hierarchy.

### OpenLane Redesign

Created dedicated synthesis workspace.

### Configuration Updates

```json
{
  "DESIGN_NAME": "tpu",
  "VERILOG_FILES": "dir::src/*.v",
  "CLOCK_PORT": "clk",
  "CLOCK_PERIOD": 20.0
}
```

### Source Verification

Verified:

- file accessibility
- hierarchy completeness
- module visibility

---

## Acceptance Validation

### Requirements

| Requirement | Target |
|-------------|---------|
| Errors | 0 |
| Netlist Generated | Yes |
| Cell Count | >100 |
| Flip-Flops Present | Yes |

### Result

PASS

---

# Day-03 — Synthesis Report Analysis

## Objective

Interpret synthesis outputs from an engineering perspective.

---

## Final Synthesis Metrics

| Metric | Value |
|----------|----------:|
| Total Cells | 93,781 |
| Flip-Flops | 3,040 |
| Wires | 93,573 |
| Unique Cell Types | 73 |
| Area | 804,275 µm² |
| WNS | 0.00 |
| TNS | 0.00 |

---

## Engineering Observations

### Large Datapath Presence

The TPU contains:

```text
93,781 Cells
```

indicating substantial arithmetic hardware.

---

### Significant Sequential Logic

```text
3,040 Flip-Flops
```

This confirms:

- pipelining
- state retention
- clocked computation

---

### Dense Connectivity

```text
93,573 Wires
```

Nearly one wire per cell.

Implications:

- routing complexity
- congestion risk
- clock-tree challenges

---

### Timing Closure

```text
WNS = 0.00
TNS = 0.00
```

The synthesized implementation successfully satisfies timing requirements.

---

# Day-04 — Design Space Exploration

## Objective

Study the impact of synthesis constraints on implementation quality.

---

## Experimental Setup

Three independent synthesis runs were performed.

### Run-1

Baseline

```text
AREA 0
20 ns
```

---

### Run-2

Aggressive Timing

```text
AREA 0
10 ns
```

---

### Run-3

Delay-Oriented Optimization

```text
DELAY 0
20 ns
```

---

# Major Investigation

An unexpected result appeared.

Run-2 produced:

```text
Exactly same implementation
```

as Run-1.

---

## Root Cause

OpenLane configuration contained:

```json
"CLOCK_PERIOD": 10
```

and

```json
"scl::sky130_fd_sc_hd": {
  "CLOCK_PERIOD": 20
}
```

The library-specific configuration overrode the global constraint.

---

## Engineering Lesson

OpenLane supports hierarchical configuration precedence.

Technology-specific overrides can silently replace global settings.

This is one of the most common pitfalls during ASIC flow configuration.

---

# Final Comparison

| Metric | Run-1 | Run-2 | Run-3 |
|----------|----------:|----------:|----------:|
| Strategy | AREA 0 | AREA 0 | DELAY 0 |
| Clock | 20ns | 10ns | 20ns |
| Cells | 93,781 | 93,781 | 110,151 |
| Area (µm²) | 804,275 | 804,275 | 942,738 |
| WNS | 0.00 | -1.68 | 0.00 |
| TNS | 0.00 | -52.73 | 0.00 |

---

## Key Observation

### AREA Strategy

Produces smallest implementation.

### DELAY Strategy

Produces fastest implementation.

Tradeoff:

```text
Higher Performance
        ↑
More Cells
        ↑
More Area
```

Classic ASIC optimization behavior.

---

# Day-05 — Four-Architecture Comparison

## Objective

Understand how architecture affects synthesis behavior.

---

## Compared Designs

| Design | Type |
|----------|----------|
| tiny-GPU | SIMD Accelerator |
| tiny-TPU | Systolic Accelerator |
| tiny-NPU | Neural Processor |
| ibex | RISC-V CPU |

---

## Comparison Results

| Metric | GPU | TPU | NPU | Ibex |
|----------|----------:|----------:|----------:|----------:|
| Cells | 13,515 | 93,781 | 787,924 | 11,157 |
| Area (µm²) | 150,688 | 804,275 | 1,969,810 | 13,511,277* |
| Flip-Flops | 2,284 | 3,040 | 131,328 | 865 |
| Timing Met | Yes | Yes | No | Yes |

---

## Architectural Insights

### GPU

Smallest accelerator.

Optimized for SIMD execution.

---

### TPU

Balanced architecture.

Good tradeoff between:

- performance
- area
- timing

---

### NPU

Largest implementation.

Memory inference caused:

- cell explosion
- flip-flop explosion
- severe timing failure

---

### Ibex CPU

Smallest design.

Highest control-logic diversity.

Most area-efficient architecture.

---

# Major Technical Challenges

## Challenge 1

RTL hierarchy discovery.

Difficulty:

⭐⭐⭐☆☆

---

## Challenge 2

Yosys assertion failure.

Difficulty:

⭐⭐⭐⭐⭐

---

## Challenge 3

OpenLane configuration debugging.

Difficulty:

⭐⭐⭐⭐☆

---

## Challenge 4

Timing report interpretation.

Difficulty:

⭐⭐⭐☆☆

---

## Challenge 5

Architecture-level comparison.

Difficulty:

⭐⭐⭐⭐☆

---

# Key Engineering Lessons Learned

### Synthesis is not Push-Button

Successful RTL simulation does not guarantee synthesizability.

---

### Arithmetic RTL Matters

Complex signed arithmetic can trigger synthesis-tool limitations.

---

### Timing Constraints Must Be Verified

Never trust configuration files alone.

Always verify generated STA reports.

---

### Optimization Has Tradeoffs

```text
AREA Optimization
        ↓
Smaller Silicon

DELAY Optimization
        ↓
Better Timing
```

---

### Architecture Dominates Results

The largest contributor to:

- area
- timing
- power
- complexity

is the RTL architecture itself.

---

# Final Outcome

The Tiny TPU design was successfully synthesized using OpenLane and SKY130 after identifying and resolving synthesis-blocking RTL issues.

The final implementation achieved:

- Successful technology mapping
- Valid gate-level netlist generation
- Timing closure
- Zero synthesis errors
- Comprehensive report analysis
- Multi-run optimization study
- Cross-architecture comparison

The resulting synthesis package forms the foundation for the next stages of the RTL-to-GDSII flow:

```text
Floorplanning
        ↓
Placement
        ↓
Clock Tree Synthesis
        ↓
Routing
        ↓
Physical Verification
        ↓
GDSII Generation
```

---

## Author

**Nur Mohammad Abdullah**

RTL-to-GDSII Flow Training Program

Week-03 RTL Synthesis Assignment

ASIC Implementation using OpenLane and SKY130