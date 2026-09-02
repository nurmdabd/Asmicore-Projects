# DV & RTL Fundamentals — 14-Day Assignment

**Asmicore Semiconductor — Internship Program · RTL Design + Design Verification (Week 3)**
Author: **Nur Mohammad Abdullah**
Toolchain: **Icarus Verilog v12.0** (`iverilog -g2012` / `vvp`), run locally. GTKWave for waveform review.

---

## 1. What this repository contains

Three RTL blocks, each designed from scratch, smoke-tested in simulation, specified in a formal
document, and given a written verification plan:

| # | Design | Module | Class | Exercises |
|---|--------|--------|-------|-----------|
| 1 | Sequence Detector (overlapping `1011`) | `seq_detect_1011` | Pure control FSM | Moore FSM, 5 states, 1-bit serial I/O |
| 2 | Traffic Light Controller | `traffic_light` | FSM + datapath | Timed states driven by a down-counter |
| 3 | Synchronous FIFO | `sync_fifo` | Pure datapath | Memory array, r/w pointers, count-based `full`/`empty` |

Alongside the RTL: the combined RTL specification document, a day-by-day Knowledge Base,
verification-planning materials (feature lists, Req-IDs, checker/stimulus/priority tables, coverage
models), an issue log, focused regression tests with archived waveforms, and the Day-14
presentation deck.

---

## 2. Repository layout

```
Week-03/
├── README.md                              ← this file
├── rtl/                                   ← synthesizable SystemVerilog (design)
│   ├── Day-01_01_and_gate.sv                    Day-1 annotated combinational example
│   ├── Day-01_02_annotated_dff_example.sv       Day-1 annotated sequential example
│   ├── Day-04_01_seq_detect_1011.sv             RTL #1
│   ├── Day-05_01_traffic_light.sv               RTL #2
│   └── Day-06_01_sync_fifo.sv                   RTL #3
├── tb/                                    ← testbenches (verification)
│   ├── Day-04_02_seq_detect_1011_smoke_tb.sv        RTL #1 smoke
│   ├── Day-04_04_seq_detect_1011_overlap_tb.sv      RTL #1 self-checking overlap regression
│   ├── Day-05_02_traffic_light_smoke_tb.sv          RTL #2 smoke
│   ├── Day-05_03_traffic_light_min_duration_tb.sv   RTL #2 min-duration regression
│   ├── Day-06_02_sync_fifo_smoke_tb.sv              RTL #3 smoke (+ simultaneous R/W)
│   └── Day-06_03_sync_fifo_multiwrap_tb.sv          RTL #3 self-checking multi-wrap regression
├── docs/                                  ← specification, planning & study documents
│   ├── Day-08_01_RTL_Specifications.docx            combined spec, all 3 designs
│   ├── Knowledge_Base.docx                          daily entries, issue log, reflection
│   ├── ISSU_LOG.docx                                issue log, standalone — 13 entries  (see §6.3)
│   ├── Learning Notes.pdf                           study reference, Days 1–12 learning topics
│   ├── Day-02_01_seq_detect_state_diagram.docx      state diagram + transition/output tables
│   ├── Day-03_01_testbench_anatomy_diagram.docx     testbench anatomy block diagram
│   ├── Day-07_01_day7_spec_materials.docx           interface table, ASCII FSM, corner cases
│   ├── Day-09_01_day9_verification_planning.docx    refined FIFO features, Req-IDs, criteria
│   ├── Day-10_01_day10_checkers_stimulus_priority.docx  checker/stimulus/priority tables
│   ├── Day-11_01_day11_coverage_models.docx         code + functional coverage models
│   ├── Day-12_01_day12_traceability_audit.docx      traceability check + rubric self-review
│   ├── Day-12_02_issue_d7_01_regression_log.docx    min-duration regression log
│   ├── Day-12_03_issue_d7_02_regression_log.docx    multi-wrap regression log
│   ├── Day-13_02_Presentation_Day14.pptx            Day-14 deck, 20 slides + speaker notes
│   └── experiments/                       ← per-run simulation evidence
│       ├── Day-04_03_seq_detect_1011_smoke_log.docx
│       ├── Day-04_05_seq_detect_1011_overlap_log.docx
│       ├── Day-05_04_traffic_light_smoke_log.docx
│       └── Day-06_04_sync_fifo_smoke_log.docx
└── vvp and vcd and wave/                  ← compiled sims + waveform dumps
    ├── sim_d4_smoke.vvp     · d4_smoke.vcd     · d4_smoke.pdf
    ├── sim_d4_overlap.vvp   · d4_overlap.vcd   · d4_overlap.pdf
    ├── sim_d5_smoke.vvp     · d5_smoke.vcd     · d5_smoke.pdf
    ├── sim_d5_min.vvp       · d5_min.vcd       · d5_min.pdf
    ├── sim_d6_smoke.vvp     · d6_smoke.vcd     · d6_smoke.pdf
    └── sim_d6_multiwrap.vvp · d6_multiwrap.vcd · d6_multiwrap.pdf
```
---

## 3. The designs

### 3.1 `seq_detect_1011` — overlapping sequence detector

- **Ports:** `clk`, `rst_n` (async, active-low), `din` (1-bit serial), `detected` (1-bit pulse).
- **FSM:** genuine **Moore**, 5 states, 3-bit encoding — `IDLE → S1 → S10 → S101 → S1011`.
  `S1011` is a dedicated DETECT state; `assign detected = (state == S1011)`, a pure decode of state.
- **Overlap:** after a match, `S1011` transitions on the next bit exactly like `S1`
  (`din=1 → S1`, `din=0 → S10`), so `1011011` fires twice sharing the middle `1`.
- **Timing:** `detected` is HIGH for exactly one cycle, one clock after the 4th matching bit is
  sampled (ordinary registered Moore latency).
- **Key decision:** the Day-2 paper exercise started from a 4-state table, which makes `detected`
  depend on state *and* input — that is Mealy. The 5th state is what makes the output a function of
  state alone. See `ISSUE-D2-01` and `ISSUE-D4-01`.

### 3.2 `traffic_light` — FSM + counter datapath

- **Ports:** `clk`, `rst_n` (async, active-low); outputs `main_red/yellow/green`, `side_red/yellow/green`.
  No data input — the only thing that drives a transition is the counter reaching zero.
- **Parameters:** `MAIN_GREEN_TIME=4`, `MAIN_YELLOW_TIME=2`, `SIDE_GREEN_TIME=6`,
  `SIDE_YELLOW_TIME=2`, `MAX_DURATION=6` (sizes the counter). Small values chosen so simulation
  is short; a phase of duration *D* loads the counter with *D−1* and counts `D-1 … 0`.
- **FSM:** fixed round-robin `MAIN_GREEN → MAIN_YELLOW → SIDE_GREEN → SIDE_YELLOW →` (repeat),
  14-cycle loop. State register + down-counter in one `always_ff`; next-state, duration lookup and
  output logic in separate `always_comb` blocks. Outputs are pure Moore; safe all-red default.
- **Documented safety rule:** during both yellow phases the *other* road stays RED for the whole phase.
- **Key decision:** the reset branch loads `MAIN_GREEN_TIME - 1` — the **same** value a normal
  reload uses — so the first `MAIN_GREEN` is a true 4 cycles. An earlier draft loaded the full
  value (5-cycle first phase); see `ISSUE-D5-02` / `ISSUE-D5-03`.

### 3.3 `sync_fifo` — synchronous FIFO

- **Ports:** `clk`, `rst_n` (async, active-low), `wr_en`, `rd_en`, `din[WIDTH-1:0]`,
  `dout[WIDTH-1:0]`, `full`, `empty`. **Parameters:** `WIDTH=8`, `DEPTH=8`.
- **Architecture:** memory array + `wr_ptr` + `rd_ptr` + `count`, all updated in one `always_ff`.
  `full = (count == DEPTH)` and `empty = (count == 0)` are combinational — a count register is used
  instead of a raw pointer compare, which cannot distinguish full from empty. `count` is
  `$clog2(DEPTH+1)` = 4 bits (0…8), one wider than the pointers.
- **`dout`** is a combinational peek at `mem[rd_ptr]` (not a registered output); when `empty=1` it
  shows stale data, so a consumer must gate on `empty`. Documented in the RTL and the smoke log.
- **Simultaneous R/W:** both enables are qualified by `!full` / `!empty` *before* the case
  statement, so every `(wr_en, rd_en)` combination falls out correctly — including R+W while full
  (read only), R+W while empty (write only), R+W partially filled (both, count unchanged).

Full interface tables, microarchitecture, FSM specs, timing diagrams, corner cases and the RTL
listings are in **`docs/Day-08_01_RTL_Specifications.docx`** (see the limitation in §6.2).

---

## 4. Build & run

All simulations use Icarus Verilog. Run from the `Week-03/` directory. The compiled `.vvp` and the
`.vcd` / waveform `.pdf` outputs for each are already committed under `vvp and vcd and wave/`.

```sh
# RTL #1 — Sequence Detector
iverilog -g2012 -o sim_d4_smoke.vvp   rtl/Day-04_01_seq_detect_1011.sv tb/Day-04_02_seq_detect_1011_smoke_tb.sv   && vvp sim_d4_smoke.vvp
iverilog -g2012 -o sim_d4_overlap.vvp rtl/Day-04_01_seq_detect_1011.sv tb/Day-04_04_seq_detect_1011_overlap_tb.sv && vvp sim_d4_overlap.vvp

# RTL #2 — Traffic Light
iverilog -g2012 -o sim_d5_smoke.vvp rtl/Day-05_01_traffic_light.sv tb/Day-05_02_traffic_light_smoke_tb.sv        && vvp sim_d5_smoke.vvp
iverilog -g2012 -o sim_d5_min.vvp   rtl/Day-05_01_traffic_light.sv tb/Day-05_03_traffic_light_min_duration_tb.sv && vvp sim_d5_min.vvp

# RTL #3 — Synchronous FIFO
iverilog -g2012 -o sim_d6_smoke.vvp     rtl/Day-06_01_sync_fifo.sv tb/Day-06_02_sync_fifo_smoke_tb.sv     && vvp sim_d6_smoke.vvp
iverilog -g2012 -o sim_d6_multiwrap.vvp rtl/Day-06_01_sync_fifo.sv tb/Day-06_03_sync_fifo_multiwrap_tb.sv && vvp sim_d6_multiwrap.vvp
```

Each run writes a `dump.vcd`; the archived per-test dumps in `vvp and vcd and wave/` are renamed
copies (`d4_smoke.vcd`, `d4_overlap.vcd`, …) with a matching PDF of the waveform. All three designs
compile clean under `iverilog -g2012 -Wall` — zero errors, zero warnings.

Expected console output for every run is reproduced verbatim in the matching document under
`docs/experiments/`.

---

## 5. Verification status

| Design | Tests present | Result |
|---|---|---|
| `seq_detect_1011` | Smoke (`1101011`, by-eye, pre-edge logged) · self-checking **overlap** regression (`1011011`) | Smoke matches hand-trace cycle-for-cycle; overlap test asserts exactly 2 pulses, 3 cycles apart — **PASS** |
| `traffic_light` | Smoke (defaults 4/2/6/2, 20 cycles, `count` column exposed) · **min-duration** regression (`MAIN_YELLOW_TIME=1`) | Full 14-cycle loop + wraparound verified numerically; 1-cycle phase behaves correctly — **PASS** |
| `sync_fifo` | Smoke (fill → blocked write → drain → blocked read, **+ simultaneous R/W** while full/partial/empty) · self-checking **multi-wrap** regression (3× fill/drain, 24 r/w, software reference queue) | No data lost, order preserved, flags correct; 0 mismatches across 3 wraps — **PASS** |

**Scope — what is done and what is not.** The tests above are directed smoke tests plus focused
regressions. The full verification plan (Days 9–12) — feature lists, Req-IDs, checker/stimulus/
priority tables and coverage models for all three designs — is written as a **specification**:
plain-English and tabular descriptions of what a testbench should do. It has **not** yet been coded
as SystemVerilog `covergroup`/`bins`, `assert property` (SVA), or scoreboards with reference models,
so there are no measured coverage numbers. Building that testbench code and collecting real coverage
is the stated next step (see `docs/Day-12_01_day12_traceability_audit.docx`, §12.2, and slide 17 of
the deck).

---

## 6. Issue Log summary

Full detail — description, day found, root cause, fix — in **`docs/ISSU_LOG.docx`**.

| ID | Summary | Status |
|---|---|---|
| ISSUE-D2-01 | Assignment's transition-table format implies Mealy timing, not Moore | Resolved (5-state DETECT design) |
| ISSUE-D3-01 | "Checker" vs "scoreboard" terminology inconsistent across sources | Resolved (convention fixed) |
| ISSUE-D4-01 | Confusion over which cycle `detected` fires (post-edge print artifact) | Resolved (pulse is cycle 8, in `S1011`) |
| ISSUE-D5-01 | Part-select on a parenthesized expression — compile error | Fixed (rely on assignment-width truncation) |
| ISSUE-D5-02 | First `MAIN_GREEN` after reset was 5 cycles, not 4 (reset load off-by-one) | Fixed (load `MAIN_GREEN_TIME-1`) |
| ISSUE-D5-03 | Smoke TB mis-sampled and *hid* D5-02 | Fixed (per-cycle `posedge` logging + `count` column) |
| ISSUE-D6-01 | Required smoke sequence never exercises simultaneous read+write | Resolved (testbench extended) |
| ISSUE-D7-01 | Traffic Light minimum-duration (1 cycle) never tested | Resolved (`min_duration_tb`) |
| ISSUE-D7-02 | FIFO pointer wraparound only tested once per pointer | Resolved (`multiwrap_tb`, 3 wraps, scoreboard) |
| ISSUE-D8-01 | Day-8 re-read found 3 lingering doc/naming inconsistencies | Fixed |
| ISSUE-D9-01 | Original FIFO feature list missing the `empty`/read-blocking feature | Fixed (5 → 8 features) |
| ISSUE-D10-01 | Nearly assigned checker type from test history instead of property type | Fixed (reassigned to Assertion) |
| ISSUE-D12-01 | Detector & Traffic Light never got full Req-ID / traceability tables | Fixed (tables built); spec update pending — see §6.2 |

---

## 7. Documentation index

| Document                                               | Contents                                                                                                                                                     |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `docs/Day-08_01_RTL_Specifications.docx`               | Combined spec — all 3 designs: Overview, Key Features, Interface Table, Microarchitecture, FSM Specification, Timing, Corner Cases, RTL Code. (See §6.2.)    |
| `docs/Knowledge_Base.docx`                             | day-by-day entries (Days 1–12): topics studied, key concepts in the author's own words, experimental work outputs, and bugs/confusions encountered each day. |
| `docs/ISSU_LOG.docx`                                   | Every issue with day found, description, root cause, resolution, status — 13 entries. Standalone copy of Knowledge Base Part B, as deliverable #3.           |
| `docs/Learning Notes.pdf`                              | Study reference expanding every Learning Topic, Days 1–12.                                                                                                   |
| `docs/Day-02_01_seq_detect_state_diagram.docx`         | RTL #1 state diagram, transition table, output table, hand-trace; Traffic Light state-sequence table.                                                        |
| `docs/Day-03_01_testbench_anatomy_diagram.docx`        | Testbench anatomy block diagram (DUT + stimulus/monitor/checker/coverage).                                                                                   |
| `docs/Day-07_01_day7_spec_materials.docx`              | RTL #1 interface table, Traffic Light ASCII state diagram, corner-case lists (4 per design), FIFO overview.                                                  |
| `docs/Day-09_01_day9_verification_planning.docx`       | Refined FIFO feature list (8), test categories, Req-IDs, entry/exit criteria, traceability table.                                                            |
| `docs/Day-10_01_day10_checkers_stimulus_priority.docx` | Checker type + stimulus + priority for all 8 FIFO features; Traffic Light assertions; FIFO scoreboard description.                                           |
| `docs/Day-11_01_day11_coverage_models.docx`            | Sequence Detector FSM coverage model; FIFO `count` bin plan; `wr_en`×`rd_en` cross; updated feature table.                                                   |
| `docs/Day-12_01_day12_traceability_audit.docx`         | Traceability check across all 3 designs, gap-closing Req-ID tables for RTL #1/#2, rubric self-review.                                                        |
| `docs/Day-12_02_issue_d7_01_regression_log.docx`       | Regression log closing ISSUE-D7-01 (Traffic Light minimum duration).                                                                                         |
| `docs/Day-12_03_issue_d7_02_regression_log.docx`       | Regression log closing ISSUE-D7-02 (FIFO multi-wrap).                                                                                                        |
| `docs/experiments/` (×4)                               | Verbatim simulation logs with compile/run commands and result-vs-prediction checks, one per design plus the overlap run.                                     |
| `docs/Day-13_02_Presentation_Day14.pptx`               | Day-14 deck — 20 slides (18 presented + 2 backup for Q&A), 16:9, speaker notes embedded.                                                                     |

---

## 8. Deliverables checklist

| #   | Item                                                                     | Status                                                                                                 |
| --- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| 1   | `RTL_Specifications.docx` — all 3 RTLs, every section, RTL code included | Present (`docs/Day-08_01_RTL_Specifications.docx`); **needs reconciliation with corrected RTL** — §6.2 |
| 2   | `Knowledge_Base.docx` — daily entries + Issue Log + Final Reflection     | Present (`docs/Knowledge_Base.docx`)                                                                   |
| 3   | `ISSUE_LOG.md` — every problem, cause, resolution                        | Present as `docs/ISSU_LOG.docx`, 13 entries; **filename misspelled** — §6.3                            |
| —   | Three RTL designs, smoke-tested                                          | Complete — all 3 simulate clean; 6 sims (3 smoke + 3 regression) pass                                  |
| —   | Presentation deck                                                        | Built — 20 slides with speaker notes; dry-run still to be done — §6.4                                  |
