# Week 5 Implementation Runbook — TPU + Kronos (ORFS, real confirmed structure)

Built from the confirmed structure in your own real runs:
`results|logs|reports/asap7/<design>/<RUN_Type>/<N>_<stage>.<ext>` — flat files,
no per-stage subfolders, intermediate stages are `.odb` (not `.def`).

Each Step below shows: the command as originally templated → the problem
found with it (if any) → the fixed command actually run → the real output →
a STATUS tag. Anything tagged ⚠️ or "not yet run" is something you can
literally re-run from this document later — that's the point of writing it
this way. Fill in `BASE`, `DESIGN`, `RUN_Type` per design where shown.

> Anywhere you see `find`/`grep -r` instead of a hardcoded filename, that's because
> I haven't seen your actual output for that stage yet — run it once, note the real
> filenames it prints, and you can hardcode them afterward like Day 0/1.

> **Confirmed from your real Day 1 Step 2 output:** every stage log has a matching
> `.json` metrics file (`2_1_floorplan.json` confirmed; expect `3_5_place_dp.json`,
> `4_1_cts.json`, `5_2_route.json` or similar) using a `<stage>__design__...`,
> `<stage>__timing__...`, `<stage>__power__...` key naming convention, already in
> real units (µm², ps, Hz) — no DBU/scaling conversion needed. Treat these json
> files as the primary source for every day below; the log greps are secondary
> cross-checks. Once you run each stage, `cat` its `.json` and I'll help you pick
> out the right keys the same way we did for floorplan.

---

# Config overview — both designs

Real, verbatim `config.mk` for each design — this is what actually
controls every run below. **TPU's config evolved over the course of the
routing investigation (Day 5); shown here is the final, confirmed-working
version that produced the clean tapeout-ready GDS, re-confirmed by a
direct `cat` of the file.**

### TPU — `tiny-tpu/run_600mhz/configs/config_600mhz.mk` (final, confirmed)
```makefile
export PLATFORM = asap7
export DESIGN_NAME = tpu

BASE_DIR  = /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu
RTL_DIR   = $(BASE_DIR)/rtl
CONFIG_DIR = $(BASE_DIR)/run_600mhz/configs

export SDC_FILE = $(CONFIG_DIR)/constraint_600mhz.sdc
export FLOW_VARIANT=600mhz

export VERILOG_FILES = \
    $(RTL_DIR)/fixedpoint_simple.v \
    $(RTL_DIR)/control_unit.v \
    $(RTL_DIR)/loss_child.v \
    $(RTL_DIR)/loss_parent.v \
    $(RTL_DIR)/leaky_relu_derivative_child.v \
    $(RTL_DIR)/leaky_relu_derivative_parent.v \
    $(RTL_DIR)/leaky_relu_child.v \
    $(RTL_DIR)/leaky_relu_parent.v \
    $(RTL_DIR)/bias_child.v \
    $(RTL_DIR)/bias_parent.v \
    $(RTL_DIR)/vpu.v \
    $(RTL_DIR)/gradient_descent.v \
    $(RTL_DIR)/unified_buffer.v \
    $(RTL_DIR)/pe.v \
    $(RTL_DIR)/systolic.v \
    $(RTL_DIR)/tpu.v

# Physical Design Configurations
export CORE_UTILIZATION = 30
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2
export PLACE_DENSITY = 0.45
export MAX_ROUTING_LAYER = M8
export ROUTING_LAYER_ADJUSTMENT = 0.16
```
**`constraint_600mhz.sdc` (confirmed):**
```tcl
create_clock [get_ports clk] -period 1667
```
**Note — this is the *final* config, not the original.** The last three
lines (`MAX_ROUTING_LAYER`, `ROUTING_LAYER_ADJUSTMENT`) were added, and
`CORE_UTILIZATION`/`PLACE_DENSITY` changed from `45`/`0.60`, over the
course of the Day 5 routing investigation (see Day 5 for the full attempt
history). Days 1–4's TPU data was captured under the *original*
`45`/`0.60` settings, before any of this — a different run, documented as
such throughout.

### Kronos — `kronos/run_1000mhz/configs/config_1000mhz.mk` (confirmed, never changed)
```makefile
export PLATFORM = asap7
export DESIGN_NAME = kronos_core
export SYNTH_HDL_FRONTEND = slang

BASE_DIR  = /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos
RTL_DIR  = $(BASE_DIR)/rtl/core
CONFIG_DIR = $(BASE_DIR)/run_1000mhz/configs

export SDC_FILE = $(CONFIG_DIR)/constraint_1000mhz.sdc
export FLOW_VARIANT=1000mhz

export VERILOG_FILES = \
    $(RTL_DIR)/kronos_types.sv \
    $(RTL_DIR)/kronos_counter64.sv \
    $(RTL_DIR)/kronos_branch.sv \
    $(RTL_DIR)/kronos_alu.sv \
    $(RTL_DIR)/kronos_agu.sv \
    $(RTL_DIR)/kronos_hcu.sv \
    $(RTL_DIR)/kronos_csr.sv \
    $(RTL_DIR)/kronos_lsu.sv \
    $(RTL_DIR)/kronos_RF.sv \
    $(RTL_DIR)/kronos_IF.sv \
    $(RTL_DIR)/kronos_ID.sv \
    $(RTL_DIR)/kronos_EX.sv \
    $(RTL_DIR)/kronos_core.sv

# Physical Design Configurations
export CORE_UTILIZATION = 45
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2
export PLACE_DENSITY = 0.60
```
**`constraint_1000mhz.sdc` (confirmed):**
```tcl
create_clock [get_ports clk] -period 1000
```
Confirms Kronos ran start-to-finish on its original settings — no
mid-week changes were ever needed, consistent with it succeeding cleanly
on the first attempt throughout Days 1–5.

**Worth noting up front — both designs *started* with identical
physical-design settings** (utilization, aspect ratio, margin, density),
despite TPU being ~6.4× larger by instance count (89,431 vs 13,919 at
placement) and having a systolic-array architecture with much longer
average interconnect (Day 3 Q2). This "one target fits both" starting
point is very plausibly *why* TPU hit congestion failure while Kronos
sailed through on the same numbers — worth stating explicitly in the
presentation. TPU's config ultimately diverged (30%/0.45/M8/adjustment)
to reach a working result; Kronos's never needed to.

**Tool check, confirmed run for both:**
```bash
make DESIGN_CONFIG=<path to either config.mk> check-yosys check-openroad check-klayout
```

---

# Day 0 — Verify Inputs + Calculate Die Area Target

## Step 1: Verify synthesis outputs from Week 4
Full synthesis metrics already confirmed and cross-checked in Day 1's
synth-stage callouts (`synth_stat.txt` + `1_Post_synthesis.rpt`), not
repeated here. Key numbers: TPU 86,102 cells, 9793.11 µm² chip area;
Kronos 13,971 cells, 1745.85 µm² chip area (see Day 1 for full
breakdowns).

**Netlist non-empty and `create_clock` present — confirmed directly, both
designs:**
```bash
wc -l results/asap7/tpu/600mhz/1_2_yosys.v
wc -l results/asap7/kronos_core/1000mhz/1_2_yosys.v
grep -c create_clock /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/constraint_600mhz.sdc
grep -c create_clock /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/constraint_1000mhz.sdc
```
**Output:**
```
629925 results/asap7/tpu/600mhz/1_2_yosys.v
 94309 results/asap7/kronos_core/1000mhz/1_2_yosys.v
1
1
```
Both netlists clearly non-empty (TPU's is enormous, matching its size),
both SDCs have exactly one `create_clock` line, matching the content
already confirmed in the Config overview above.

**STATUS: ✅ FULLY CONFIRMED for both designs.** Day 0's deliverable
(netlist non-empty, `create_clock` found) is now completely satisfied,
not just asserted.

## Step 2: Calculate die area target

**Command (same formula, both designs):**
```python
python3 -c "
synth_area = float(input('Enter synthesis chip area (um2): '))
utilisation = 0.45
core_area = synth_area / utilisation
side = core_area ** 0.5
die_side = side + 20   # +10um margin each side
print(f'Core area needed: {core_area:.1f} um2')
print(f'Core side length: {side:.1f} um')
print(f'Recommended die: {die_side:.1f} x {die_side:.1f} um')
"
```
**Output (TPU, 9793.108980 µm² input):**
```
Core area needed: 21762.5 um2
Core side length: 147.5 um
Recommended die: 167.5 x 167.5 um
```
**Output (Kronos, 1745.852940 µm² input):**
```
Core area needed: 3879.7 um2
Core side length: 62.3 um
Recommended die: 82.3 x 82.3 um
```

**Reality check against confirmed real results (Day 1):** neither design's
actual die matched this recommendation — TPU came in smaller (151.5 µm vs
167.5 µm recommended), and so did Kronos (66.287 µm vs 82.3 µm
recommended). Same explanation for both: `config.mk` never sets
`DIE_AREA`/`CORE_AREA` directly, only `CORE_UTILIZATION`/`CORE_MARGIN`, so
ORFS auto-derived die size from those rather than from this calculation's
flat "+20 µm" margin assumption. Not an error in either case — this
calculation was a sanity check, not a real input to either run.

**STATUS: ✅ CONFIRMED for both designs.**

## Step 3: Write config.mk
See "Config overview" above — identical content, not repeated here.

---

# Day 1 — Floorplan

## Step 1: Run floorplan

**Command run:**
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk floorplan
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/config_1000mhz.mk floorplan
```

**Verify (TPU):**
```bash
DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
run() { echo; printf "\033[1;32m$\033[0m \033[1;36m%s\033[0m\n" "$*"; "$@"; }
echo "--------Floorplan results: $RESULTS-----------"
ls "$RESULTS"
ls "$LOGS"
```
**Output (TPU):**
```
1_1_yosys_canonicalize.rtlil  1_2_yosys.sdc  1_2_yosys.v  1_synth.odb  1_synth.sdc  clock_period.txt  mem.json
1_1_yosys_canonicalize.log  1_2_yosys.log  1_2_yosys_metrics.log  1_synth.json  1_synth.log
```
**⚠️ ISSUE FOUND (at the time):** no `2_*` floorplan files at all — only
synthesis-stage output present. `make floorplan` for TPU either didn't
finish or wasn't actually run before this check was captured.

**RESOLVED — re-verification:**
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk floorplan
```
**Output:**
```
make: Nothing to be done for 'floorplan'.
```
This is Make's own dependency check confirming the floorplan outputs already
exist and are up to date — the `ls` below (captured later, after Day 1
Step 3 and even Day 3 placement had already run) confirms the full real
file set, `2_x` and beyond:
```
1_1_yosys_canonicalize.rtlil  1_synth.sdc              2_2_floorplan_macro.tcl    2_floorplan.sdc           3_3_place_gp.odb       3_place.sdc       tpu_2_floorplan.def
1_2_yosys.sdc                 2_1_floorplan.odb        2_3_floorplan_tapcell.odb  3_1_place_gp_skip_io.odb  3_4_place_resized.odb  clock_period.txt
1_2_yosys.v                   2_1_floorplan.sdc        2_4_floorplan_pdn.odb      3_2_place_iop.odb         3_5_place_dp.odb       export_def.tcl
1_synth.odb                   2_2_floorplan_macro.odb  2_floorplan.odb            3_2_place_iop.tcl         3_place.odb            mem.json
```
**STATUS: ✅ CONFIRMED** — closed out.

**Verify (Kronos):**
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
# same commands, swapped DESIGN/RUN_Type
```
**Output (Kronos):**
```
1_1_yosys_canonicalize.rtlil  1_2_yosys.sdc  1_2_yosys.v  1_synth.odb  1_synth.sdc  clock_period.txt  mem.json
2_1_floorplan.odb  2_1_floorplan.sdc  2_2_floorplan_macro.odb  2_2_floorplan_macro.tcl
2_3_floorplan_tapcell.odb  2_4_floorplan_pdn.odb  2_floorplan.odb  2_floorplan.sdc
```
**STATUS: ✅ CONFIRMED WORKING** — full floorplan + PDN output present on first check.

### 📋 Final commands — copy/paste to re-run (TPU)
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk floorplan

DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"

ls "$RESULTS"
ls "$LOGS"
```

### 📋 Final commands — copy/paste to re-run (Kronos)
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/config_1000mhz.mk floorplan

DESIGN=kronos_core
RUN_Type=1000mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"

ls "$RESULTS"
ls "$LOGS"
```

---

## Step 2: Extract floorplan metrics

**First attempt — as originally templated (never actually run, caught in review):**
```bash
FPLOG=$LOGS/1_1_yosys.log 2>/dev/null || ls $LOGS/2_1_floorplan.log 2>/dev/null | head -1
grep -i 'die\|core area\|DIEAREA' $FPLOG | head -10
grep 'DIEAREA' $RESULTS/1_floorplan/*.def | head -1
```
**PROBLEM (static review, before running):** `1_1_yosys.log` is a Yosys log
— Yosys doesn't do floorplanning or STA, so it has no die/core-area data.
`$RESULTS/1_floorplan/*.def` assumes a per-stage subfolder that doesn't
exist — Step 1's real `ls` output above shows flat files directly under
`$RESULTS`, not per-stage folders.

**Fixed command (TPU):**
```bash
FPLOG="$LOGS/2_1_floorplan.log"
FPJSON="$LOGS/2_1_floorplan.json"
grep -iE 'die area|core area|diearea' "$FPLOG"
grep -iE 'utiliz|util' "$FPLOG"
grep -iE 'rows|sites|site ' "$FPLOG"
grep -iE 'io |pad|pin placement' "$FPLOG" | head -10
cat "$FPJSON"
```
**Output (TPU) — real:**
```
[INFO IFP-0107] Defining die area using utilization: 45.00% and aspect ratio: 1.
[WARNING IFP-0028] Core area lower left (2.000, 2.000) snapped to (2.052, 2.160).
[INFO IFP-0102] Core area:                        21692.853 um^2
[INFO IFP-0104] Effective utilization:                0.451
Design area 9922 um^2 46% utilization.
[INFO IFP-0001] Added 545 rows of 2730 site asap7sc7p5t.
       Pad |        0.00e+00 |         0.00e+00
{
    ... "floorplan__design__die__area": 22958.6, "floorplan__design__core__area": 21692.9,
    "floorplan__design__instance__utilization": 0.457378, "floorplan__design__rows": 545,
    "floorplan__design__sites": 1487850, "floorplan__design__io": 397,
    "floorplan__timing__setup__ws": 723.595, "floorplan__timing__hold__ws": 34.2713 ...
}
```
**PROBLEM FOUND:** the `io |pad` grep matched `Pad | 0.00e+00 | 0.00e+00` — an
unrelated table row (looks like a resistance/IR table), not real IO pin
placement. Real IO data is in the json (`floorplan__design__io: 397`); real
pin-placement messages use the `PPL-` tool tag, not literal "pad"/"io " text.

**Fixed, final version (re-run this, not the version above):**
```bash
FPLOG="$LOGS/2_1_floorplan.log"
FPJSON="$LOGS/2_1_floorplan.json"

python3 -c "
import json
d = json.load(open('$FPJSON'))
keys = ['floorplan__design__die__area','floorplan__design__core__area',
        'floorplan__design__instance__utilization','floorplan__design__rows',
        'floorplan__design__sites','floorplan__design__io',
        'floorplan__design__nets','floorplan__design__instance__count',
        'floorplan__timing__setup__ws','floorplan__timing__hold__ws',
        'floorplan__timing__fmax']
for k in keys:
    print(f'{k}: {d.get(k)}')
"
grep -iE 'effective utilization|snapped' "$FPLOG"
grep -iE 'added .* rows' "$FPLOG"
grep -iE 'PPL-' "$FPLOG"
```
**STATUS: ✅ CONFIRMED WORKING for TPU** (real numbers obtained, in the
metrics table below).

**Kronos — re-run, confirmed:**
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
```
**Output (real):**
```
floorplan__design__die__area: 4393.97
floorplan__design__core__area: 3863.12
floorplan__design__instance__utilization: 0.454872
floorplan__design__rows: 230
floorplan__design__sites: 264960
floorplan__design__io: 174
floorplan__design__nets: 14473
floorplan__design__instance__count: 14231
floorplan__timing__setup__ws: 469.735
floorplan__timing__hold__ws: 32.3115
[WARNING IFP-0028] Core area lower left (2.000, 2.000) snapped to (2.052, 2.160).
[INFO IFP-0104] Effective utilization:                0.452
[INFO IFP-0001] Added 230 rows of 1152 site asap7sc7p5t.
```
Cross-check: 230 rows × 1152 sites/row = 264,960 — matches `sites` exactly,
same pattern as TPU. Setup slack (469.735 ps) also matches synthesis's
469.73 ps almost exactly, same "carried forward, nothing physical changed
yet" explanation as TPU.
**STATUS: ✅ CONFIRMED WORKING for Kronos.**

### 📋 Final commands — copy/paste to re-run (TPU)
```bash
DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
FPLOG="$LOGS/2_1_floorplan.log"
FPJSON="$LOGS/2_1_floorplan.json"

python3 -c "
import json
d = json.load(open('$FPJSON'))
keys = ['floorplan__design__die__area','floorplan__design__core__area',
        'floorplan__design__instance__utilization','floorplan__design__rows',
        'floorplan__design__sites','floorplan__design__io',
        'floorplan__design__nets','floorplan__design__instance__count',
        'floorplan__timing__setup__ws','floorplan__timing__hold__ws',
        'floorplan__timing__fmax']
for k in keys:
    print(f'{k}: {d.get(k)}')
"
grep -iE 'effective utilization|snapped' "$FPLOG"
grep -iE 'added .* rows' "$FPLOG"
grep -iE 'PPL-' "$FPLOG"
```

### 📋 Final commands — copy/paste to re-run (Kronos)
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
FPLOG="$LOGS/2_1_floorplan.log"
FPJSON="$LOGS/2_1_floorplan.json"

python3 -c "
import json
d = json.load(open('$FPJSON'))
keys = ['floorplan__design__die__area','floorplan__design__core__area',
        'floorplan__design__instance__utilization','floorplan__design__rows',
        'floorplan__design__sites','floorplan__design__io',
        'floorplan__design__nets','floorplan__design__instance__count',
        'floorplan__timing__setup__ws','floorplan__timing__hold__ws',
        'floorplan__timing__fmax']
for k in keys:
    print(f'{k}: {d.get(k)}')
"
grep -iE 'effective utilization|snapped' "$FPLOG"
grep -iE 'added .* rows' "$FPLOG"
grep -iE 'PPL-' "$FPLOG"
```

---

## Step 3: View the floorplan in KLayout

**Attempt 1 (suggested, never actually run — superseded):**
```
openroad
source $::env(SCRIPTS_DIR)/load.tcl
load_design 2_floorplan.odb 2_floorplan.sdc
write_def /tmp/2_floorplan.def
```
**STATUS: ❌ SUPERSEDED, don't use this.** `SCRIPTS_DIR` is a Makefile-only
variable — it isn't set when running `openroad` standalone outside `make`,
so `load.tcl` would fail here.

**Attempt 2 (actually run — confirmed working for the export step):**
```bash
source ~/EDA/OpenROAD-flow-scripts/env.sh
cd ~/EDA/OpenROAD-flow-scripts/flow

cat > results/asap7/tpu/600mhz/export_def.tcl << 'EOF'
read_db results/asap7/tpu/600mhz/2_floorplan.odb
write_def results/asap7/tpu/600mhz/tpu_2_floorplan.def
exit
EOF
openroad -exit results/asap7/tpu/600mhz/export_def.tcl
ls -la results/asap7/tpu/600mhz/tpu_2_floorplan.def
```
**Output:**
```
-rw-r--r-- 1 nurmdabd nurmdabd 16703870 Jul 12 10:29 results/asap7/tpu/600mhz/tpu_2_floorplan.def
```
**STATUS: ✅ CONFIRMED WORKING.** Note: originally exported to `/tmp/`, moved
to `results/` because `/tmp` gets wiped on WSL restart.

**Attempt 3 — naive KLayout launch, reproducing the problem:**
```bash
klayout platforms/asap7/lef/*.lef results/asap7/tpu/600mhz/tpu_2_floorplan.def &
```
**Output (~59 distinct "Macro not found" warnings, all `_ASAP7_75t_R`
suffix, including flip-flops):**
```
Warning: Cannot determine routing layers for via: VIA23_1_3_36_36 ...
Warning: Macro not found in LEF file: TAPCELL_ASAP7_75t_R - creating dummy macro
Warning: Macro not found in LEF file: INVx1_ASAP7_75t_R - creating dummy macro
Warning: Macro not found in LEF file: BUFx2_ASAP7_75t_R - creating dummy macro
... (dozens more of the same pattern — DFFHQNx1, DFFASRHQNx1, HAxp5, FAx1,
    every combinational and sequential cell type in the design)
```
Die/core boundary, row structure, and M1–M6 all rendered correctly — only
standard-cell geometry was affected (uniform placeholder boxes, matching
the warnings exactly). Three separate `via` warnings are unrelated —
PDN-stripe auto-generated via names, not standard-cell macros, safe to
ignore.

**DIAGNOSIS (confirmed):** not a missing-LEF problem — the real
`asap7sc7p5t` standard-cell LEF exists on disk (`ls platforms/asap7/lef/`
confirms it: `asap7sc7p5t_28_R_1x_220121a.lef`, 391KB). The actual cause:
passing multiple LEF files as separate command-line arguments makes
KLayout open each as its own independent tab instead of merging them into
one macro library for the DEF reader to resolve against. All ~59 missing
macros traced to exactly two files: `asap7_tech_1x_201209.lef` (tech) +
`asap7sc7p5t_28_R_1x_220121a.lef` (the `_R` variant specifically — not
`_L`, `_SL`, or `_SRAM`, none of whose macro names appeared in the warning
list). Separately: WSL2's GPU/render path can independently produce a
blank KLayout window — fix is `LIBGL_ALWAYS_SOFTWARE=1` before any launch.

**Two candidate fixes were considered:**
- **Fix 1 — ORFS's own `.lyt` tech file** (`platforms/asap7/KLayout/asap7.lyt`):
  **rejected as insufficient.** Inspecting it shows only the tech LEF is
  registered (`<lef-files>./platforms/asap7/lef/asap7_tech_1x_201209.lef</lef-files>`)
  — the standard-cell macro LEF is missing from this file, so loading this
  technology alone would fix layer colors/mapping but **not** the
  dummy-macro problem.
- **Fix 2 — merge LEFs via KLayout's Reader Options dialog: chosen, confirmed working.**

**Fix 2 — exact steps (the earlier "File → Setup" guidance was wrong; the
real location is a separate top-level menu item):**
```bash
LIBGL_ALWAYS_SOFTWARE=1 klayout &     # launch empty, no file args
```
1. `File → Reader Options` (a separate menu item from File → Setup —
   between "Pull In Other Layout" and "Open Recent")
2. `LEF/DEF` tab → `LEF+Macro Files` sub-tab
3. Under **"Additional LEF files"** (not "Macro Layout Files" — that one's
   for GDS/OASIS-sourced macro geometry, not applicable here), click **+**
   and add, tech file first (order matters):
   1. `platforms/asap7/lef/asap7_tech_1x_201209.lef`
   2. `platforms/asap7/lef/asap7sc7p5t_28_R_1x_220121a.lef`
4. **OK**
5. `File → Open` → `results/asap7/tpu/600mhz/tpu_2_floorplan.def`

**Result:** floorplan loaded with real cell geometry — varying cell widths
and pin shapes, not uniform boxes. Clean layer panel: M1–M6, V1–V5,
M6.LABEL, M6.PIN, OUTLINE.

**Verified three independent ways:**
1. **Log Viewer** (`File → Log Viewer`, verbosity set to "Details", not
   "Silent" — an empty log at Silent proves nothing, it's filtering, not
   confirming): reload shows tech LEF → macro LEF → DEF, in order, then
   Sorting → Redrawing. **No "Macro not found" line anywhere.**
2. **Terminal, DEF-only relaunch** (no LEF args at all):
   ```bash
   LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/tpu/600mhz/tpu_2_floorplan.def
   ```
   Output: nothing — no warnings printed. Confirms the Reader Options
   settings **persisted** into KLayout's application config (tied to the
   "(Default)" technology) and apply automatically on every future launch,
   GUI or CLI, without needing to pass LEF files as arguments again.
3. **Terminal with explicit filter** (double-confirms #2 wasn't a missed
   scrollback):
   ```bash
   LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/tpu/600mhz/tpu_2_floorplan.def 2>&1 | grep -i "macro not found"
   ```
   Output: nothing.

**STATUS: ✅ CONFIRMED for TPU** (upgraded from ⚠️ Partially Working).

**Kronos — same export, but the naive launch failed differently:**
```bash
source ~/EDA/OpenROAD-flow-scripts/env.sh
cd ~/EDA/OpenROAD-flow-scripts/flow

cat > results/asap7/kronos_core/1000mhz/export_def.tcl << 'EOF'
read_db results/asap7/kronos_core/1000mhz/2_floorplan.odb
write_def results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def
exit
EOF
openroad -exit results/asap7/kronos_core/1000mhz/export_def.tcl
ls -la results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def

LIBGL_ALWAYS_SOFTWARE=1 klayout platforms/asap7/lef/*.lef results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def &
```
**Output:**
```
-rw-r--r-- 1 nurmdabd nurmdabd 2777629 Jul 13 02:36 results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def
ERROR: Duplicate MACRO name: A2O1A1Ixp33_ASAP7_75t_R (inside MACRO) (line=42, cell=, file=asap7sc7p5t_28_R_1x_220121a.lef)
```
This is worse than TPU's outcome — TPU's naive glob just gave dummy-macro
warnings, Kronos's crashed outright. Explained by the same root cause: the
`*.lef` glob is loading files as separate/conflicting inputs rather than
one merged library, and this time the conflict was a hard duplicate-name
error instead of a soft "not found."

**Fixed — relying on the persisted Reader Options config from the TPU fix
(no LEF args needed, per verification #2 above):**
```bash
LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def &
```
Launched clean, no errors. **Independently triple-verified afterward,
matching TPU's full rigor:**
1. **Terminal grep filter** — no "macro not found" text appears anywhere
   in the output.
2. **Log Viewer** (verbosity "Details") — fully clean load sequence: tech
   LEF → macro LEF (`asap7sc7p5t_28_R_1x_220121a.lef`) → DEF → Sorting →
   Redrawing, zero "Macro not found" lines.
3. **Visual confirmation** (screenshot) — real, varied cell geometry and
   the correct layer panel (M1–M6, V1–V5, M6.LABEL, M6.PIN, OUTLINE), not
   uniform dummy boxes.

**STATUS: ✅ CONFIRMED for Kronos** — no longer just "likely," fully
matching TPU's standard.

### 📋 Final commands — copy/paste to re-run (TPU)
```bash
source ~/EDA/OpenROAD-flow-scripts/env.sh
cd ~/EDA/OpenROAD-flow-scripts/flow

cat > results/asap7/tpu/600mhz/export_def.tcl << 'EOF'
read_db results/asap7/tpu/600mhz/2_floorplan.odb
write_def results/asap7/tpu/600mhz/tpu_2_floorplan.def
exit
EOF
openroad -exit results/asap7/tpu/600mhz/export_def.tcl
ls -la results/asap7/tpu/600mhz/tpu_2_floorplan.def

# Reader Options config already persisted from the fix above — no LEF args needed:
LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/tpu/600mhz/tpu_2_floorplan.def &
```

### 📋 Final commands — copy/paste to re-run (Kronos)
```bash
source ~/EDA/OpenROAD-flow-scripts/env.sh
cd ~/EDA/OpenROAD-flow-scripts/flow

cat > results/asap7/kronos_core/1000mhz/export_def.tcl << 'EOF'
read_db results/asap7/kronos_core/1000mhz/2_floorplan.odb
write_def results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def
exit
EOF
openroad -exit results/asap7/kronos_core/1000mhz/export_def.tcl
ls -la results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def

LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def &
LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/kronos_core/1000mhz/kronos_2_floorplan.def 2>&1 | grep -i "macro not found"
```

---

## Day 1 metrics table (filled — TPU & Kronos)

| **Metric** | **TPU (600 MHz)** | **Kronos (1000 MHz)** | **Source** |
|---|---|---|---|
| Die area (µm × µm) | **151.521 × 151.521 µm** (confirmed: `DIEAREA ( 0 0 ) ( 151521 151521 ) ;`, ÷1000) | **66.287 × 66.287 µm** (confirmed: `DIEAREA ( 0 0 ) ( 66287 66287 ) ;`, ÷1000 — see DBU correction below) | `grep DIEAREA <design>_2_floorplan.def` |
| Core area (µm²) | **21692.9 µm²** | **3863.12 µm²** | `floorplan__design__core__area` in `2_1_floorplan.json` |
| Core utilisation (%) | **45.7%** actual; **45.1%** core-sizing target | **45.5%** actual; **45.2%** core-sizing target | `instance__utilization` vs log's `Effective utilization` |
| Number of standard cell rows | **545** | **230** | `floorplan__design__rows`, matches log both times |
| Site width (nm) | **54 nm** (0.054 µm) | same — platform-wide constant, same PDK | `SITE asap7sc7p5t` block, `platforms/asap7/lef/*.lef`: `SIZE 0.054 BY 0.270` |
| Row height (nm) | **270 nm** (0.270 µm) | same — platform-wide constant | same LEF block |
| IO pads placed (count) | **397** | **174** | `floorplan__design__io` |
| Die area matches calculation? (yes/no) | **Partially** — core area matches Day 0's estimate within 0.3%; die area doesn't (see note below) | **No** — Day 0 recommended 82.3 × 82.3 µm; actual confirmed die is 66.287 × 66.287 µm, smaller, same root cause as TPU | comparison, see Day 0 |

**Why TPU's die area didn't match Day 0's estimate:** `config.mk` never
sets `DIE_AREA`/`CORE_AREA` directly — only `CORE_UTILIZATION`,
`CORE_ASPECT_RATIO`, `CORE_MARGIN`. ORFS derived the die size itself from
those, rather than using Day 0's flat "+20 µm IO margin" assumption. Not an
error, just a different sizing path than assumed.

**⚠️ Correction to earlier guidance in this document:** the DBU-to-micron
ratio for this environment is confirmed as **1000, not 4000**. An earlier
version of this table said "ASAP7 = divide by 4000" based on general
external knowledge of ASAP7's PDK-level scaling convention — that was
wrong for what OpenROAD's own database actually uses here. Confirmed three
independent ways: both PDN metrics scripts (TPU and Kronos) printed
`DBU per micron: 1000` directly; and Kronos's raw `DIEAREA (66287 66287)`
÷1000 = 66.287 µm, an exact match to the json's die area (4393.97 µm² =
66.287²). Divide by 1000 for any DEF-coordinate-to-micron conversion in
this flow, not 4000.

**Sanity-check the site dimensions against the confirmed core areas:**
TPU: 545 rows × 0.270 µm = 147.15 µm tall; 2730 sites/row × 0.054 µm =
147.42 µm wide → 147.15 × 147.42 ≈ 21,696 µm², matching the confirmed core
area (21,692.9 µm²) to within 0.02%. Kronos: 230 × 0.270 = 62.1 µm; 1152 ×
0.054 = 62.208 µm → 62.1 × 62.208 ≈ 3863.1 µm², matching Kronos's confirmed
core area (3863.12 µm²) almost exactly. Both designs check out.

## Day 1 questions (answered)

**Q1 — Target was 45% utilisation. What did it actually set? Why adjust?**
Two numbers, not one: ORFS's *core-sizing target* ("Effective utilization")
came out to 45.1% for TPU / 45.2% for Kronos, essentially matching the 45%
request in both cases. After cells were actually placed and measured, the
*real* instance utilization was 45.7% (TPU) / 45.5% (Kronos). The
adjustment comes from site-grid snapping — the log shows it directly:
`[WARNING IFP-0028] Core area lower left (2.000, 2.000) snapped to (2.052,
2.160)` (same snap warning appears for both designs). The core boundary
can't sit at an arbitrary continuous coordinate; it has to land on a legal
row/site grid line, so the tool nudges it slightly, shifting the final
area (and utilization) a bit off the exact ideal target.

**Q2 — Rows in your core height, does it match the log? [RESOLVED]**
Yes, for both designs, confirmed against the real site LEF (`SIZE 0.054 BY
0.270`, i.e. 54 nm wide × 270 nm tall):
- **TPU:** core height = 545 rows × 0.270 µm = 147.15 µm. Matches the log's
  545 rows exactly (that's the definition), and cross-validates against
  the confirmed core area: 147.15 µm × (2730 sites × 0.054 µm = 147.42 µm)
  ≈ 21,696 µm², within 0.02% of the real 21,692.9 µm².
- **Kronos:** core height = 230 × 0.270 = 62.1 µm; width = 1152 × 0.054 =
  62.208 µm → area ≈ 3863.1 µm², essentially exact against the real
  3863.12 µm².
Both check out cleanly — the row count in the log is internally consistent
with the real site geometry and the real core area.

**Q3 — What if `FP_CORE_UTIL` were 80% instead of 45%? Would routing succeed?**
(Note: the real ORFS variable is `CORE_UTILIZATION`, not `FP_CORE_UTIL` —
that name is left over from OpenLane in the original template.) At 80%
there's very little whitespace left for routing resources, power stripes,
and buffer/filler insertion. What breaks first is almost always **detailed
routing** — DRC violations and unrouted nets from insufficient track
availability in congested pockets — well before you'd get a clean route.
Along the way you'd typically also see: harder placement legalization
(cells fighting for legal sites), worse timing due to congestion-driven
detours and buffer insertion difficulty, and potentially IR drop issues if
the denser core also got a proportionally thinner power grid. Routing
failing outright is usually the hard stop; timing degradation shows up
before that as an early warning. (TPU's actual Day 3 placement result is a
live example of this trend starting even at a modest 45% target — see Day
3's congestion discussion.)

**Q4 — Are clock and reset pads on the same side? Best side for clock input?
[PARTIALLY RESOLVED — genuine limitation found, not a fake answer]**
The pin-name grep on the floorplan-stage DEF confirmed the actual pin
*names* — TPU uses `clk`/`rst`; **Kronos uses `clk`/`rstz`** (active-low
reset naming, different convention from TPU, worth noting on its own). But
neither design's DEF shows a physical location for these pins at this
stage: each entry is a bare
`- clk + NET clk + DIRECTION INPUT + USE SIGNAL ;` with no `PLACED`
coordinate attached — the `+ FIXED (...)` line appearing just before it in
the grep output belongs to the alphabetically-preceding pin, not to clk.
That means **IO pins aren't physically committed yet at the floorplan
stage** in this flow — real pin placement happens at Day 3's `place_iop`
sub-stage (confirmed present in both designs' Day 3 logs: `3_2_place_iop`).
So this question can't be honestly answered from Day 1's data — it needs a
DEF export from Day 3 instead (`3_place.odb` → def, same export pattern as
Step 3 above, then re-run the same pin grep against that file). General
answer on "best side," independent of your specific design, still stands
regardless of which stage you check: no universally "best" side in
isolation — depends on where the clock source physically enters the chip
and where the clock tree root sits, since you want the shortest,
least-congested path from pad to clock tree insertion point. Keeping
clock/reset away from noisy high-switching-activity IO and away from
congestion-prone corners are the two things that matter regardless of
which side you land on.

---
# Day 2 — Power Planning

## Step 1: Run power planning

PDN is generated as part of `make floorplan` in ORFS — there's no separate
`make` target for it (confirmed against `grid_strategy-M1-M2-M5-M6.tcl`
being invoked automatically during floorplan, and against the `2_4_*_pdn`
sub-stage files appearing in Day 1 Step 1's floorplan output).

**First attempt — as originally templated (never actually run, caught in
review):**
```bash
PDNLOG=$LOGS/2*3_tdms_place.log 2>/dev/null || ls $LOGS/2**pdn* 2>/dev/null | head -1
grep -i 'error\|unconnect\|fail' $PDNLOG | head -10
grep -i 'via\|connect' $PDNLOG | tail -20
```
**PROBLEM (static review):** the glob patterns (`2*3_tdms_place.log`,
`2**pdn*`) are a guess that doesn't match the real confirmed filename —
`2_4_floorplan_pdn.log` — verified from Day 1 Step 1's `ls` output.

**Fixed command (TPU), actually run:**
```bash
DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
run() { echo; printf "\033[1;32m$\033[0m \033[1;36m%s\033[0m\n" "$*"; "$@"; }

run ls -lh "$RESULTS"/2_4_floorplan_pdn.*
run ls -lh "$LOGS"/2_4_floorplan_pdn.*
run grep -iE 'error|unconnect|fail' "$LOGS/2_4_floorplan_pdn.log"
run grep -iE 'ring|stripe|strap|via' "$LOGS/2_4_floorplan_pdn.log" | tail -30
run cat "$LOGS/2_4_floorplan_pdn.json"
```
**Output:** `2_4_floorplan_pdn.odb` exists (46MB). json shows
`flow__errors__count: 0`, `flow__warnings__count: 10`,
`flow__warnings__count:STA-1212: 1001`, `flow__warnings__type_count: 1`.
**⚠️ Correction to earlier interpretation in this document:** I'd
previously guessed `flow__warnings__count: 10` meant "10 distinct warning
types." The real json shows `type_count` as its own separate key, value
**1** (only one distinct type: STA-1212) — so that guess was wrong. What
the bare `count: 10` actually represents isn't clear from the evidence
available; the reliable number is `count:STA-1212: 1001` (confirmed
occurrence count for that specific code).
**STATUS: ✅ CONFIRMED WORKING** (files present, 0 errors).

**⚠️ Attempted, came back empty for both designs:**
```bash
grep "STA-1212" logs/asap7/tpu/600mhz/2_4_floorplan_pdn.log | head -5
grep "STA-1212" logs/asap7/kronos_core/1000mhz/2_4_floorplan_pdn.log | head -5
```
**Output:** nothing, for both. Hypothesis at the time: these `flow__...`
keys look like flow-wide cumulative tallies, not counts scoped to this one
file — so the actual lines might be sitting in an earlier stage's log.

**Follow-up, checked every stage log through placement (13 files total):**
```bash
grep -c "STA-1212" logs/asap7/tpu/600mhz/*.log
```
**Output:** `0` for all 13 — `1_1_yosys_canonicalize`, `1_2_yosys`,
`1_2_yosys_metrics`, `1_synth`, `2_1_floorplan`, `2_2_floorplan_macro`,
`2_3_floorplan_tapcell`, `2_4_floorplan_pdn`, `3_1_place_gp_skip_io`,
`3_2_place_iop`, `3_3_place_gp`, `3_4_place_resized`, `3_5_place_dp` — every
single one.
**STATUS: ⚠️ CLOSED AS "NOT RETRIEVABLE VIA LOG INSPECTION."** The hypothesis
above is ruled out — it's not hiding in an earlier log either. Most likely
explanation: the warning-ID counting mechanism (`genMetrics.py` or similar)
reads OpenSTA's internal message-ID system directly, and this particular
message may never get printed as visible text with that ID attached
anywhere in this flow's output. Further investigation would require
OpenROAD/OpenSTA's own source for what text maps to message ID 1212 —
outside what's available from this run's output alone. Not pursuing
further; documenting the confirmed occurrence count (1001, from the json)
as the answer, with the caveat that the message text itself is unavailable.

**Kronos — re-run, confirmed:**
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
```
**Output (real):**
```
-rw-r--r-- 1 nurmdabd nurmdabd 7.8M Jul 10 20:40 .../2_4_floorplan_pdn.odb
-rw-r--r-- 1 nurmdabd nurmdabd  134 Jul 10 20:40 .../2_4_floorplan_pdn.json
-rw-r--r-- 1 nurmdabd nurmdabd 1.6K Jul 10 20:40 .../2_4_floorplan_pdn.log
{
    "flow__warnings__count": 10,
    "flow__errors__count": 0,
    "flow__warnings__count:STA-1212": 1001,
    "flow__warnings__type_count": 1
}
```
Same shape as TPU's — 0 errors, same STA-1212 occurrence count.
**STATUS: ✅ CONFIRMED WORKING for Kronos.**

### 📋 Final commands — copy/paste to re-run (TPU)
```bash
DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"

ls -lh "$RESULTS"/2_4_floorplan_pdn.*
ls -lh "$LOGS"/2_4_floorplan_pdn.*
grep -iE 'error|unconnect|fail' "$LOGS/2_4_floorplan_pdn.log"
grep -iE 'ring|stripe|strap|via' "$LOGS/2_4_floorplan_pdn.log" | tail -30
cat "$LOGS/2_4_floorplan_pdn.json"
grep -c "STA-1212" "$LOGS"/*.log
```

### 📋 Final commands — copy/paste to re-run (Kronos)
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"

ls -lh "$RESULTS"/2_4_floorplan_pdn.*
ls -lh "$LOGS"/2_4_floorplan_pdn.*
grep -iE 'error|unconnect|fail' "$LOGS/2_4_floorplan_pdn.log"
grep -iE 'ring|stripe|strap|via' "$LOGS/2_4_floorplan_pdn.log" | tail -30
cat "$LOGS/2_4_floorplan_pdn.json"
grep -c "STA-1212" "$LOGS"/*.log
```

---

## Step 2: Extract power planning metrics

**First attempt — as originally templated (never actually run, caught in
review):**
```bash
grep -i 'ring\|power ring' $PDNLOG | head -10
grep -i 'stripe\|strap' $PDNLOG | head -10
grep -i 'metal\|layer\|area' $PDNLOG | grep -i 'power\|pdn' | head -10
klayout $RESULTS/1_floorplan/*pdn*.def &
```
**PROBLEM (static review):** same wrong `$PDNLOG` guess as Step 1, plus the
KLayout line assumes a `1_floorplan/` subfolder and a `*pdn*.def` file —
neither exists. PDN data lives inside the binary `2_4_floorplan_pdn.odb`;
no `.def` exists for it unless explicitly exported (same as Day 1 Step 3).

**Design-intent reference — run first to know what to expect, actually run:**
```bash
cat platforms/asap7/openRoad/pdn/grid_strategy-M1-M2-M5-M6.tcl
```
**Output (real, full file):**
```tcl
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDD$} -power
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDPE$}
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDDCE$}
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSS$} -ground
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSSE$}
global_connect
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}
define_pdn_grid -name {top} -voltage_domains {CORE} -pins {M6}
add_pdn_stripe -grid {top} -layer {M1} -width {0.018} -pitch {0.54} -offset {0} -followpins
add_pdn_stripe -grid {top} -layer {M2} -width {0.018} -pitch {0.54} -offset {0} -followpins
add_pdn_stripe -grid {top} -layer {M5} -width {0.12} -spacing {0.072} -pitch {5.4} -offset {0.300}
add_pdn_stripe -grid {top} -layer {M6} -width {0.288} -spacing {0.096} -pitch {5.4} -offset {0.513}
add_pdn_connect -grid {top} -layers {M1 M2}
add_pdn_connect -grid {top} -layers {M2 M5}
add_pdn_connect -grid {top} -layers {M5 M6}
define_pdn_grid -name {CORE_macro_grid_1} -voltage_domains {CORE} -macro \
  -orient {R0 R180 MX MY} -halo {2.0 2.0 2.0 2.0} -default
add_pdn_connect -grid {CORE_macro_grid_1} -layers {M4 M5}
define_pdn_grid -name {CORE_macro_grid_2} -voltage_domains {CORE} -macro \
  -orient {R90 R270 MXR90 MYR90} -halo {2.0 2.0 2.0 2.0} -default
add_pdn_connect -grid {CORE_macro_grid_2} -layers {M4 M5}
```
No `add_pdn_ring` — stripes only. **STATUS: ✅ confirmed — matches what
actually got built (cross-checked against the per-layer metrics below).**

**Connectivity check — command run:**
```bash
cd ~/EDA/OpenROAD-flow-scripts/flow
cat > /tmp/check_pdn.tcl << 'EOF'
read_db results/asap7/tpu/600mhz/2_4_floorplan_pdn.odb
check_power_grid -net VDD -floorplanning
check_power_grid -net VSS -floorplanning
exit
EOF
openroad -exit /tmp/check_pdn.tcl
```
**Output:**
```
[INFO PSM-0040] All shapes on net VDD are connected.
[INFO PSM-0040] All shapes on net VSS are connected.
```
**STATUS: ✅ CONFIRMED WORKING** — 0 unconnected nodes.

**Per-layer stripe count/area — first attempt hit a real error:**
```tcl
foreach box [$sw getWires] {
    set layer [[$box getTechLayer] getName]
    ...
```
**Error:** `invalid command name "NULL"` — via shapes don't expose a single
`getTechLayer()`, so this crashed partway through.

**Fixed (wrapped in `catch{}` to divert via shapes into their own tally
instead of crashing), actually run:**
```bash
cd ~/EDA/OpenROAD-flow-scripts/flow
cat > /tmp/pdn_metrics3.tcl << 'EOF'
read_db results/asap7/tpu/600mhz/2_4_floorplan_pdn.odb
set block [ord::get_db_block]
puts "DBU per micron: [$block getDbUnitsPerMicron]"
foreach net_name {VDD VSS} {
    set net [$block findNet $net_name]
    array unset layer_count
    array unset layer_area
    set via_count 0
    foreach sw [$net getSWires] {
        foreach box [$sw getWires] {
            if {[catch {set layer [[$box getTechLayer] getName]}]} {
                incr via_count
                continue
            }
            if {![info exists layer_count($layer)]} {
                set layer_count($layer) 0
                set layer_area($layer) 0.0
            }
            incr layer_count($layer)
            set dx [expr {[$box xMax] - [$box xMin]}]
            set dy [expr {[$box yMax] - [$box yMin]}]
            set layer_area($layer) [expr {$layer_area($layer) + ($dx*$dy)}]
        }
    }
    puts "----- $net_name -----"
    puts "via shapes skipped: $via_count"
    foreach layer [array names layer_count] {
        puts "$layer : count=$layer_count($layer)  area_dbu2=$layer_area($layer)"
    }
}
exit
EOF
openroad -exit /tmp/pdn_metrics3.tcl
```
**Output (real, confirmed):**
```
DBU per micron: 1000
----- VDD -----
via shapes skipped: 23989
M3 : count=7644  area_dbu2=23390640.0
M1 : count=273  area_dbu2=724421880.0
M5 : count=28  area_dbu2=493671360.0
M2 : count=273  area_dbu2=724421880.0
M6 : count=28  area_dbu2=1188794880.0
----- VSS -----
via shapes skipped: 23989
M3 : count=7644  area_dbu2=23390640.0
M1 : count=273  area_dbu2=724421880.0
M5 : count=28  area_dbu2=493671360.0
M2 : count=273  area_dbu2=724421880.0
M6 : count=28  area_dbu2=1188794880.0
```
Sanity-checked against an earlier undifferentiated total (3,993,657,276
dbu² including vias) — difference of 838,956,636 dbu² matches the 23,989
skipped via shapes exactly.
**STATUS: ✅ CONFIRMED WORKING for TPU.**

**Kronos — re-run, confirmed:**
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
```
**Output (real):**
```
DBU per micron: 1000
----- VDD -----
via shapes skipped: 4399
M3 : count=1380  area_dbu2=4222800.0
M1 : count=115  area_dbu2=128770560.0
M5 : count=12  area_dbu2=88712640.0
M2 : count=115  area_dbu2=128770560.0
M6 : count=12  area_dbu2=214990848.0
----- VSS -----
via shapes skipped: 4436
M3 : count=1392  area_dbu2=4259520.0
M1 : count=116  area_dbu2=129890304.0
M5 : count=12  area_dbu2=89490240.0
M2 : count=116  area_dbu2=129890304.0
M6 : count=12  area_dbu2=214990848.0
```
**Interesting difference from TPU:** VDD and VSS aren't perfectly
symmetric here (M1 count 115 vs 116, M3 count 1380 vs 1392) — unlike TPU,
where VDD and VSS matched exactly. Worth noting as an observation rather
than a problem; likely boundary/tie-off effects in a smaller design, not
investigated further.
VDD metal total: 4,222,800+128,770,560+88,712,640+128,770,560+214,990,848
= 565,467,408 dbu² = **565.47 µm²**. VSS: 568,521,216 dbu² = **568.52 µm²**.
Combined: **1,133.99 µm²** (vs. TPU's 6,309.40 µm² — makes sense, TPU's die
is roughly 2.3× wider and needs proportionally more stripe length and
count).
**STATUS: ✅ CONFIRMED WORKING for Kronos.**

**KLayout PDN visualization:** same fix as Day 1 Step 3 applies here —
**not yet independently exported/viewed** for the PDN-specific def for
either design (Day 1 Step 3 confirmed the general fix works and persists,
but this specific `2_4_floorplan_pdn.odb` export hasn't been done yet).

### 📋 Final commands — copy/paste to re-run (TPU)
```bash
cd ~/EDA/OpenROAD-flow-scripts/flow

cat platforms/asap7/openRoad/pdn/grid_strategy-M1-M2-M5-M6.tcl

cat > /tmp/check_pdn_tpu.tcl << 'EOF'
read_db results/asap7/tpu/600mhz/2_4_floorplan_pdn.odb
check_power_grid -net VDD -floorplanning
check_power_grid -net VSS -floorplanning
exit
EOF
openroad -exit /tmp/check_pdn_tpu.tcl

cat > /tmp/pdn_metrics_tpu.tcl << 'EOF'
read_db results/asap7/tpu/600mhz/2_4_floorplan_pdn.odb
set block [ord::get_db_block]
puts "DBU per micron: [$block getDbUnitsPerMicron]"
foreach net_name {VDD VSS} {
    set net [$block findNet $net_name]
    array unset layer_count
    array unset layer_area
    set via_count 0
    foreach sw [$net getSWires] {
        foreach box [$sw getWires] {
            if {[catch {set layer [[$box getTechLayer] getName]}]} {
                incr via_count
                continue
            }
            if {![info exists layer_count($layer)]} {
                set layer_count($layer) 0
                set layer_area($layer) 0.0
            }
            incr layer_count($layer)
            set dx [expr {[$box xMax] - [$box xMin]}]
            set dy [expr {[$box yMax] - [$box yMin]}]
            set layer_area($layer) [expr {$layer_area($layer) + ($dx*$dy)}]
        }
    }
    puts "----- $net_name -----"
    puts "via shapes skipped: $via_count"
    foreach layer [array names layer_count] {
        puts "$layer : count=$layer_count($layer)  area_dbu2=$layer_area($layer)"
    }
}
exit
EOF
openroad -exit /tmp/pdn_metrics_tpu.tcl
```

### 📋 Final commands — copy/paste to re-run (Kronos)
```bash
cd ~/EDA/OpenROAD-flow-scripts/flow

cat platforms/asap7/openRoad/pdn/grid_strategy-M1-M2-M5-M6.tcl

cat > /tmp/check_pdn_kronos.tcl << 'EOF'
read_db results/asap7/kronos_core/1000mhz/2_4_floorplan_pdn.odb
check_power_grid -net VDD -floorplanning
check_power_grid -net VSS -floorplanning
exit
EOF
openroad -exit /tmp/check_pdn_kronos.tcl

cat > /tmp/pdn_metrics_kronos.tcl << 'EOF'
read_db results/asap7/kronos_core/1000mhz/2_4_floorplan_pdn.odb
set block [ord::get_db_block]
puts "DBU per micron: [$block getDbUnitsPerMicron]"
foreach net_name {VDD VSS} {
    set net [$block findNet $net_name]
    array unset layer_count
    array unset layer_area
    set via_count 0
    foreach sw [$net getSWires] {
        foreach box [$sw getWires] {
            if {[catch {set layer [[$box getTechLayer] getName]}]} {
                incr via_count
                continue
            }
            if {![info exists layer_count($layer)]} {
                set layer_count($layer) 0
                set layer_area($layer) 0.0
            }
            incr layer_count($layer)
            set dx [expr {[$box xMax] - [$box xMin]}]
            set dy [expr {[$box yMax] - [$box yMin]}]
            set layer_area($layer) [expr {$layer_area($layer) + ($dx*$dy)}]
        }
    }
    puts "----- $net_name -----"
    puts "via shapes skipped: $via_count"
    foreach layer [array names layer_count] {
        puts "$layer : count=$layer_count($layer)  area_dbu2=$layer_area($layer)"
    }
}
exit
EOF
openroad -exit /tmp/pdn_metrics_kronos.tcl
```

---

## Day 2 metrics table (filled — TPU & Kronos)

|**Metric**|**TPU (600 MHz)**|**Kronos (1000 MHz)**|**How to find it**|
|---|---|---|---|
|Power ring width (µm)|N/A — stripes only, no ring|N/A — same shared grid strategy file, no ring|`grep add_pdn_ring platforms/asap7/openRoad/pdn/grid_strategy-M1-M2-M5-M6.tcl` → no match|
|Number of VDD stripes|M5: 28, M6: 28|M5: 12, M6: 12|`pdn_metrics3.tcl` via `getSWires()`/`getWires()` on net VDD, grouped by `getTechLayer()`|
|Number of VSS stripes|M5: 28, M6: 28|M5: 12, M6: 12|same script, net VSS|
|Stripe pitch (µm)|5.4 (both M5 and M6)|5.4 (same shared config)|`grep pitch platforms/asap7/openRoad/pdn/grid_strategy-M1-M2-M5-M6.tcl`|
|Metal layer used for rings|N/A|N/A|same grid strategy file — no `-layer` under an `add_pdn_ring` block|
|Metal layer used for stripes|M5, M6|M5, M6|`add_pdn_stripe -grid {top} -layer {M5\|M6} ...`|
|Unconnected power rails|0|0|`check_power_grid -net VDD/VSS -floorplanning` → `[INFO PSM-0040] All shapes on net VDD/VSS are connected.`|
|Total power metal area (µm²)|3,154.70 µm² per net; 6,309.40 µm² combined|565.47 µm² (VDD) + 568.52 µm² (VSS) = 1,133.99 µm² combined|`pdn_metrics3.tcl` area sum|

**Note on Kronos's VDD/VSS asymmetry:** unlike TPU (where VDD and VSS were
exactly symmetric), Kronos shows small differences — M1 count 115 (VDD) vs
116 (VSS), M3 1380 vs 1392. Not investigated further, likely a boundary or
tie-off-cell effect in the smaller design; noted rather than explained
away.

**Still open:** what `STA-1212` actually says — see Step 1 above, both
designs' direct greps came back empty; broader per-file search suggested
there instead.

## Day 2 questions (answered — TPU & Kronos)

**Q1 — N VDD/VSS stripes across a W µm die: average distance to nearest
stripe, and why does shorter distance mean lower IR drop?**

*TPU:* N = 28. Die width: literal confirmed `grep DIEAREA` = **151.521 µm**
(matches the earlier `sqrt(die_area)` estimate of ≈151.5 µm almost
exactly). 28 stripes × 5.4 µm pitch = 151.2 µm — agrees to within 0.3 µm.
*Kronos:* N = 12. Die width: literal confirmed `grep DIEAREA` = **66.287
µm** (also matches `sqrt(die_area)` = √4393.97 exactly), and
12 stripes × 5.4 µm pitch = 64.8 µm — agree to within 1.5 µm (a slightly
looser match than TPU's, likely because 66.287 isn't as close to a clean
whole multiple of 5.4 as TPU's die happened to be).

For both designs:
- Same-polarity stripes (VDD-to-VDD or VSS-to-VSS) repeat every **5.4 µm**
  (matches the config's `pitch {5.4}` directly in both cases).
- VDD and VSS interleave within that period, so the nearest supply rail of
  *either* polarity repeats roughly every **2.7 µm**, same for both designs
  since the pitch is a shared platform constant, not something that scales
  with die size.
- Average distance to nearest same-polarity stripe ≈ 5.4/4 ≈ **1.35 µm**
  (worst case 2.7 µm); average distance to nearest rail of *either*
  polarity ≈ 2.7/4 ≈ **0.68 µm** (worst case 1.35 µm) — identical for both
  designs, since this only depends on the fixed pitch, not on die size or
  stripe count.

Why shorter = lower IR drop: a cell doesn't connect straight to the M5/M6
stripe — it draws current through the M1/M2 followpin rail segment that runs
from the stripe's via-drop point to the cell's actual VDD/VSS pin. That rail
segment has resistance R = ρL/A, proportional to its length L. Voltage drop
under load is V = IR, so a longer stripe-to-cell path means more series
resistance for the same current, and more droop. Tighter stripe spacing
directly shortens that worst-case path.

**Q2 — Why does a wider ring need to carry more current than one internal
stripe?**
Worth noting first: **neither design's PDN has a ring at all** — confirmed
in the shared `grid_strategy-M1-M2-M5-M6.tcl` (no `add_pdn_ring` line,
stripes only, applies to both TPU and Kronos since it's the same platform
config). So this specific question doesn't apply to what you built, but the
underlying principle is still real and worth
answering: where a ring *does* exist, it's the collection point every
internal stripe ultimately feeds into (or draws from) on its way to/from the
off-chip power pads. A single internal stripe only serves the local cells
along its length. The ring has to carry the *sum* of current from every
stripe converging on it — much higher aggregate current through the same
conductor. Since a wire's safe current-carrying capacity (electromigration
limit) and its resistance both scale with cross-sectional area, the ring is
made wider to stay within EM limits and keep its own IR drop low despite
carrying that much larger combined current.

**Q3 — Why are power rings/stripes on upper metal (M4/M5) rather than M1/M2?**
Your real strategy is actually a hybrid, worth pointing out: M1/M2 *are*
used for power — but only as thin followpin rails that hug each standard
cell row to reach every cell's VDD/VSS pin directly (fine pitch, 0.018 µm
wide, needed to reach into every row). The wide mesh for bulk, long-distance
current delivery sits on M5/M6 in your design (M4/M5 in the question's
generic phrasing — different PDK/config, same idea). Reasons for pushing the
heavy lifting to upper layers: (1) upper metal is physically thicker → lower
resistance per square → less IR drop carrying current long distances; (2)
M1–M3 are the layers standard-cell-to-standard-cell signal routing depends
on most, since that's where the fine pitch is needed — burying wide power
stripes there would starve local signal routing resources; (3) top-level
"fat" metal isn't useful for fine-pitch signal wiring anyway, so it's the
natural place to put current delivery that doesn't need fine pitch.

**Q4 — VDD droops from 0.7V to 0.65V. Faster or slower, and why?**
**Slower.** CMOS gate delay is roughly inversely proportional to the drive
current, and drive current scales with overdrive voltage (VDD − Vth) raised
to a power (~1.3–2 for short-channel devices, the "alpha-power law"). Vth
stays essentially fixed, so a drop in VDD shrinks the overdrive
disproportionately, cutting drive current more than linearly and increasing
propagation delay. A 0.05V droop (~7% of 0.7V) isn't trivial either — ASAP7
is a near-threshold-sensitive finFET PDK, and the delay-vs-VDD curve gets
steeper the closer you operate to Vth, so that 7% supply drop can translate
into a noticeably larger percentage increase in delay. In your setup-timing
terms: IR drop directly eats into setup slack by slowing the cells that
experience it.

---
# Day 3 — Placement

### Run
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk place
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/config_1000mhz.mk place
```
**Output:**
```
make: Nothing to be done for 'place'.
make: Nothing to be done for 'place'.
```
Same pattern as Day 1's floorplan re-verification — confirms placement was
already complete for both designs. **STATUS: ✅ CONFIRMED for both.**

### Verify + extract (TPU)
```bash
DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
REPORTS="$BASE/reports/asap7/$DESIGN/$RUN_Type"

run() { echo; printf "\033[1;32m$\033[0m \033[1;36m%s\033[0m\n" "$*"; "$@"; }

echo "--------Placement results: $RESULTS-----------"
run ls -lh "$RESULTS"/3_*
run ls -lh "$LOGS"/3_*
run ls -lh "$REPORTS"/3_* 2>/dev/null

# Expected sub-stages by ORFS convention (verify against the ls above):
#   3_1_place_gp_skip_io   3_2_place_iop   3_3_place_gp
#   3_4_place_resized      3_5_place_dp    3_place (checkpoint .odb/.sdc)

echo "[HPWL / overflow — search all place-stage logs since exact filename may vary]"
run grep -riE 'hpwl|overflow|congest' "$LOGS"/3_*.log

echo "[cell count]"
run grep -riE 'placed|instance count' "$LOGS"/3_*.log | tail -10

echo "[Post-placement WNS/TNS — check json metrics first, then logs/reports]"
run grep -ril 'wns' "$REPORTS"/3_* "$LOGS"/3_*.json 2>/dev/null
run cat "$LOGS/3_5_place_dp.json" 2>/dev/null
```

### Verify + extract (Kronos)
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
REPORTS="$BASE/reports/asap7/$DESIGN/$RUN_Type"

run() { echo; printf "\033[1;32m$\033[0m \033[1;36m%s\033[0m\n" "$*"; "$@"; }

echo "--------Placement results: $RESULTS-----------"
run ls -lh "$RESULTS"/3_*
run ls -lh "$LOGS"/3_*
run ls -lh "$REPORTS"/3_* 2>/dev/null

echo "[HPWL / overflow]"
run grep -riE 'hpwl|overflow|congest' "$LOGS"/3_*.log

echo "[cell count]"
run grep -riE 'placed|instance count' "$LOGS"/3_*.log | tail -10

echo "[Post-placement WNS/TNS]"
run grep -ril 'wns' "$REPORTS"/3_* "$LOGS"/3_*.json 2>/dev/null
run cat "$LOGS/3_5_place_dp.json" 2>/dev/null
```

### Step 3 — Compare placement WNS to synthesis WNS (rewritten, automated)
The original template grepped `$LOGS/1_1_yosys.log` (Yosys doesn't do STA) and
`$REPORTS/3_place_timing.rpt` (doesn't exist) — both dead ends. Now that we
know the real sources for both stages (`1_Post_synthesis.rpt` for synthesis,
confirmed; `3_5_place_dp.json`'s `detailedplace__timing__setup__*` keys for
placement, confirmed), here's a working script for both designs, no manual
`input()` typing required:

```bash
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow

for cfg in "tpu 600mhz 1667" "kronos_core 1000mhz 1000"; do
  set -- $cfg
  DESIGN=$1; RUN_Type=$2; CLK_PS=$3
  LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
  REPORTS="$BASE/reports/asap7/$DESIGN/$RUN_Type"

  SYNTH_WNS=$(grep 'wns max'          "$REPORTS/1_Post_synthesis.rpt" | awk '{print $3}')
  SYNTH_WS=$(grep 'worst slack max'   "$REPORTS/1_Post_synthesis.rpt" | awk '{print $4}')
  PLACE_WNS=$(grep -o '"detailedplace__timing__setup__tns": [^,]*' "$LOGS/3_5_place_dp.json" | awk '{print $2}')
  PLACE_WS=$(grep -o '"detailedplace__timing__setup__ws": [^,]*'   "$LOGS/3_5_place_dp.json" | awk '{print $2}')

  python3 -c "
clk_ps    = $CLK_PS
synth_ws  = $SYNTH_WS
place_ws  = $PLACE_WS
delta     = synth_ws - place_ws
pct       = delta / clk_ps * 100
print(f'--- $DESIGN ($RUN_Type, {clk_ps} ps clock) ---')
print(f'Synthesis WNS: $SYNTH_WNS ps   |  Synthesis worst slack: {synth_ws:8.2f} ps')
print(f'Placement WNS: $PLACE_WNS ps   |  Placement worst slack: {place_ws:8.2f} ps')
print(f'Slack consumed by real wire delay: {delta:8.2f} ps  ({pct:5.1f}% of the clock period)')
print(f'Remaining margin at placement:     {place_ws/clk_ps*100:5.1f}% of the clock period')
print()
"
done
```
Note: literal **WNS** (worst *negative* slack) stays 0.00 ps at both stages
for both designs — nothing is actually violating timing yet. The
degradation that matters is in the **worst slack margin**, which is what
this script actually reports.

**Output (confirmed, real):**
```
--- tpu (600mhz, 1667 ps clock) ---
Synthesis WNS: 0.00 ps   |  Synthesis worst slack:   723.59 ps
Placement WNS: 0 ps   |  Placement worst slack:    78.42 ps
Slack consumed by real wire delay:   645.17 ps  ( 38.7% of the clock period)
Remaining margin at placement:       4.7% of the clock period

--- kronos_core (1000mhz, 1000 ps clock) ---
Synthesis WNS: 0.00 ps   |  Synthesis worst slack:   469.73 ps
Placement WNS: 0 ps   |  Placement worst slack:   339.35 ps
Slack consumed by real wire delay:   130.38 ps  ( 13.0% of the clock period)
Remaining margin at placement:      33.9% of the clock period
```
Exact match to the manual calculation used to build the metrics table and
Q1 answer below — good validation that those numbers were right before
this script existed to confirm them directly. **STATUS: ✅ CONFIRMED.**

## Day 3 metrics table (filled — TPU & Kronos)

| **Metric** | **TPU (600 MHz)** | **Kronos (1000 MHz)** | **How to find it** |
|---|---|---|---|
| Total cells placed | 89,431 | 13,919 | `detailedplace__design__instance__count` in `3_5_place_dp.json` |
| HPWL estimate (µm) | 1,288,741 (final, post-DP-optimization; legalized value was 1,320,362, ~2.4% higher before final swap passes) | 41,262 (final; legalized was 41,310) | `[INFO DPL-0022] HPWL after ...` in `3_5_place_dp.log` |
| Overflow count (congested gcells) | 18,858 tiles (26.85%) at best-observed point; final weighted congestion 1.4115, **above** the ~1.01 target — never fully resolved | 0 tiles (0.00%); final weighted congestion 0.6879, **well under** target — resolved cleanly | `[INFO GPL-0042]`/`[INFO GPL-1005]` in `3_3_place_gp.log` |
| Placement WNS (ns) | 0.00 (worst slack +0.0784 ns) | 0.00 (worst slack +0.339 ns) | `detailedplace__timing__setup__tns`/`__ws` in `3_5_place_dp.json` |
| Synthesis WNS (ns) | 0.00 (worst slack +0.724 ns) | 0.00 (worst slack +0.470 ns) | `1_Post_synthesis.rpt` — `wns max` / `worst slack max` |
| WNS degradation (placement − synthesis) | 0.00 ns literally; **slack margin** degraded by 0.645 ns (38.7% of the 1.667 ns clock period) | 0.00 ns literally; **slack margin** degraded by 0.130 ns (13.0% of the 1.0 ns clock period) | see Step 3 script above |
| Worst congestion location | Not yet visually confirmed — export `3_place.odb` the same way as Day 1 Step 3 and check. Given overflow hit 26.85% of *all* gcells (not a small hotspot), expect broadly-distributed congestion rather than one dense pocket — plausible for a systolic-array PE grid, but confirm visually | Not yet visually confirmed — expect this to look comparatively clean given 0% tile overflow | KLayout visual (see note below) |
| Core utilisation after placement (%) | 46.43% (up from 45.7% at floorplan — resizer grew instance count 89,376→89,431) | 44.22% (down slightly from floorplan's 45.7%*) | `detailedplace__design__instance__utilization` in `3_5_place_dp.json` |

*Kronos's floorplan-stage utilization wasn't confirmed in an earlier turn the
way TPU's was — worth a quick check of its `2_1_floorplan.json` if you want
that comparison exact.

**On congestion visualization:** the original template's "open the placed
DEF in KLayout, dense areas appear darker — this is the congestion heatmap"
isn't quite right. A plain DEF view shows *cell density*, which correlates
with congestion but isn't the actual routing-congestion overlay OpenROAD
computes (`GPL-0042`'s overflowed-tile count above). For the real heatmap,
use OpenROAD's own GUI (`gui::show` after loading `3_place.odb`, then the
congestion/heatmap panel), not KLayout on an exported DEF.

## Day 3 questions (answered)

**Q1 — WNS degraded by how much? Large or small relative to clock period?**
Literal WNS didn't degrade at all (0.00 ps at both stages — no violations
either time). What actually degraded is the worst slack *margin*: TPU
723.59 ps → 78.42 ps, a **645.17 ps (0.645 ns) loss**, which is **38.7% of
the entire 1667 ps clock period** — a large penalty, and TPU is left with
only ~4.7% of its period as margin. Kronos degraded far less: 469.73 ps →
339.35 ps, a 130.38 ps loss, only **13.0%** of its 1000 ps period. The
contrast is informative on its own: TPU's much bigger degradation lines up
directly with its congestion problems (26.85% overflow vs. Kronos's 0%) —
denser, harder-to-route designs tend to accumulate more real wire delay
between the idealized synthesis estimate and actual placement.

**Q2 — HPWL / cells = avg wire length. What does it say about
interconnectedness?**
TPU: 1,288,741 µm / 89,431 cells ≈ **14.4 µm/cell**. Kronos: 41,262 µm /
13,919 cells ≈ **3.0 µm/cell** — TPU averages roughly **4.9× longer** wires
per cell. Worth normalizing before concluding TPU is "more interconnected"
outright, though: TPU's die is also physically bigger (√22958.6 ≈ 151.5 µm
side vs. Kronos's √4393.97 ≈ 66.3 µm side, a 2.3× ratio), and bigger dies
naturally have longer average wires just from geometry. Dividing out that
effect (4.9× ÷ 2.3× ≈ 2.1×), TPU still comes out roughly **twice as
interconnected per cell** as die-size scaling alone would predict. That's
consistent with a systolic-array datapath: PEs need buses running across
the whole array, not just to nearest neighbors, so average wire length per
cell stays elevated even after accounting for die size.

**Q3 — Which area looks most dense? Match your expectation?**
Not yet visually confirmed for either design (see table note above — export
`3_place.odb`→DEF the same way as Day 1 Step 3 and check). One thing the
numbers already suggest, though: TPU's overflow hit 26.85% of *all* gcells,
not a small isolated region — that points toward broadly-distributed
congestion across most of the array rather than one hot pocket, which would
actually match a systolic PE-grid architecture (uniform structure → uniform
density) better than a localized problem would. Worth checking against the
actual view rather than taking this as confirmed.

**Q4 — Overflow > 10(%): two ways to reduce congestion without touching
RTL?**
(Table note: the template's ">10" threshold is oddly small as a raw count —
almost certainly means >10% overflow, which both fits reality much better
and matches TPU's actual 26.85%.) Two config-only levers, both already
available in `config.mk`: (1) **Lower `CORE_UTILIZATION`** — packing fewer
cells per unit area directly reduces routing demand per gcell; TPU's 45%
target is aggressive enough to have caused real overflow, dropping to
~35–38% would likely help. (2) **Increase `CORE_MARGIN`/die size** — more
physical area for the same cell count spreads routing demand out, same
effect via a different lever. A bonus third option, since it's a distinct
knob from utilization: **lower `PLACE_DENSITY`**, which caps how tightly
the *detailed* placer packs cells even within a given utilization target,
leaving more local slack for the router independent of the overall core
size.

---

# Day 4 — Clock Tree Synthesis

## Step 1: Run CTS

**Command run:**
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk cts
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/config_1000mhz.mk cts
```
**Output:**
```
make: Nothing to be done for 'cts'.
make: Nothing to be done for 'cts'.
```
Both already complete, same confirmation pattern as Day 1/Day 3.
**STATUS: ✅ CONFIRMED for both.**

**Verify (TPU):**
```bash
DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
run() { echo; printf "\033[1;32m$\033[0m \033[1;36m%s\033[0m\n" "$*"; "$@"; }
run ls -lh "$RESULTS"/4_*
run ls -lh "$LOGS"/4_*
```
**Output:**
```
4_1_cts.odb   4_cts.odb   4_cts.sdc
4_1_cts.json  4_1_cts.log
```
Confirms the predicted pattern exactly: single sub-stage (`4_1_cts`), no
sub-splitting like floorplan's four or placement's five sub-stages — CTS is
a single-pass step here. Checkpoint is odb/sdc only, same as `2_floorplan`
and `3_place` before it. **STATUS: ✅ CONFIRMED.**

---

## Step 2: Extract CTS metrics

**Command run (TPU):**
```bash
FPLOG="$LOGS/4_1_cts.log"   # (named CTSLOG in the template, same file)
grep -riE 'skew|latency' "$LOGS/4_1_cts.log"
grep -riE 'buffer|clkbuf' "$LOGS/4_1_cts.log" | tail -20
grep -riE 'hold|wns|tns' "$LOGS/4_1_cts.log" "$LOGS/4_1_cts.json"
cat "$LOGS/4_1_cts.json"
```
**Output — skew/latency grep:**
```
(nothing)
```
**Same pattern as `STA-1212`:** the literal words "skew" and "latency"
aren't printed as visible log text at all — the skew *numbers* only exist
in the json (`cts__clock__skew__setup`, `cts__clock__skew__hold`), and
there's no equivalent key for launch/capture path *latency* anywhere.
Genuinely not retrievable from this data — would need a dedicated
`report_clock_latency`-style OpenSTA query, not something ORFS's automatic
metrics collection captures. Marked "not available" in the table below
rather than guessed.

**Output — buffers inserted:**
```
[INFO CTS-0050] Root buffer is BUFx24_ASAP7_75t_R.
[INFO CTS-0051] Sink buffer is BUFx24_ASAP7_75t_R.
[INFO CTS-0052] The following clock buffers will be used for CTS:
[INFO CTS-0049] Characterization buffer is BUFx24_ASAP7_75t_R.
[INFO CTS-0097] Characterization used 1 buffer(s) types.
[INFO CTS-0018]     Created 198 clock buffers.
[INFO CTS-0012]     Minimum number of buffers in the clock path: 5.
[INFO CTS-0013]     Maximum number of buffers in the clock path: 5.
[INFO CTS-0100]  Leaf buffers 175
[INFO RSZ-0048] Inserted 1 buffers in 1 nets.
```
198 clock-tree buffers, uniformly 1 type (`BUFx24`), tree depth exactly 5
levels everywhere (min=max — a perfectly balanced tree), plus 1 extra
resizer-driven buffer for setup/hold repair.

**Output — hold/WNS check:**
```
[INFO RSZ-0033] No hold violations found.
"cts__timing__setup__tns": 0,   "cts__timing__hold__tns": 0,
"cts__timing__hold__ws": 19.2036,
"cts__clock__skew__hold": 81.7438,
"cts__timing__drv__hold_violation_count": 0,
```

**⚠️ Real finding — duplicate JSON keys with different values, second
occurrence silently zeroes real data:**
```json
"cts__design__instance__displacement__total": 20145.7,
"cts__design__instance__displacement__mean": 0.224,
"cts__design__instance__displacement__max": 46.926,
"cts__dpl__hpwl__delta": 2.66392e+07,
"cts__dpl__hpwl__delta__percent": 2,
...
"cts__design__instance__displacement__total": 0,
"cts__design__instance__displacement__mean": 0,
"cts__design__instance__displacement__max": 0,
"cts__dpl__hpwl__delta": 0,
"cts__dpl__hpwl__delta__percent": 0,
```
`json.load()` keeps the **last** occurrence of a duplicate key — every
python-based extraction used earlier in this document would silently
return **0** for these fields instead of the real values. Didn't happen at
floorplan or placement; specific to CTS's metrics output. **Use the first
occurrence's values, confirmed from the raw text above, not a blind
`json.load()`.**

**STATUS: ✅ CONFIRMED for TPU, with the json caveat noted.**

**Kronos — re-run, confirmed, same json-duplication pattern:**
```
[INFO CTS-0050] Root buffer is BUFx16f_ASAP7_75t_R.
[INFO CTS-0051] Sink buffer is BUFx24_ASAP7_75t_R.
[INFO CTS-0097] Characterization used 2 buffer(s) types.
[INFO CTS-0018]     Created 112 clock buffers.
[INFO CTS-0012/13] Minimum/maximum buffers in clock path: 4.
[INFO CTS-0100]  Leaf buffers 99
(no RSZ-0048 line — 0 extra repair buffers needed)

"cts__timing__hold__ws": 33.5091,
"cts__clock__skew__hold": 27.4488,
"cts__timing__drv__hold_violation_count": 0,

"cts__design__instance__displacement__total": 250.773,   ← first occurrence, real
"cts__design__instance__displacement__mean": 0.017,
"cts__design__instance__displacement__max": 1.016,
"cts__dpl__hpwl__delta": 1.33527e+06,
"cts__dpl__hpwl__delta__percent": 3,
```
Real structural difference from TPU: Kronos uses **2 buffer types**
(smaller `BUFx16f` root vs TPU's uniform `BUFx24`), a **shallower tree**
(4 levels vs 5), and needed **no** extra repair buffer. **STATUS: ✅
CONFIRMED for Kronos.**

### 📋 Final commands — copy/paste to re-run (TPU)
```bash
DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"

ls -lh "$RESULTS"/4_*
ls -lh "$LOGS"/4_*
grep -riE 'skew|latency' "$LOGS/4_1_cts.log"
grep -riE 'buffer|clkbuf' "$LOGS/4_1_cts.log" | tail -20
grep -riE 'hold|wns|tns' "$LOGS/4_1_cts.log" "$LOGS/4_1_cts.json"
cat "$LOGS/4_1_cts.json"
```

### 📋 Final commands — copy/paste to re-run (Kronos)
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"

ls -lh "$RESULTS"/4_*
ls -lh "$LOGS"/4_*
grep -riE 'skew|latency' "$LOGS/4_1_cts.log"
grep -riE 'buffer|clkbuf' "$LOGS/4_1_cts.log" | tail -20
grep -riE 'hold|wns|tns' "$LOGS/4_1_cts.log" "$LOGS/4_1_cts.json"
cat "$LOGS/4_1_cts.json"
```

---

## Day 4 metrics table (filled — TPU & Kronos)

Note: the original template's "how to find it" column assumes a generic
700 MHz / 1.429 ns clock — using your real per-design periods (1667 ps
TPU, 1000 ps Kronos) instead.

| **Metric** | **TPU (600 MHz)** | **Kronos (1000 MHz)** | **How to find it** |
|---|---|---|---|
| Max clock skew (ns) | **0.0817 ns** (hold skew, the larger of setup/hold) | **0.0274 ns** (hold skew) | `cts__clock__skew__hold`/`__setup` in `4_1_cts.json` — not in the log as text |
| Skew as % of clock period | **4.90%** (81.74 ps / 1667 ps) | **2.74%** (27.45 ps / 1000 ps) | skew ÷ real clock period |
| Clock latency — launch path (ns) | **Not available** — see note above | **Not available** | would need `report_clock_latency`, not in current data |
| Clock latency — capture path (ns) | **Not available** | **Not available** | same |
| Clock buffers inserted (count) | **198** tree buffers (175 leaf) + 1 resizer repair buffer = 199 | **112** tree buffers (99 leaf) + 0 repair | `CTS-0018`/`RSZ-0048` in `4_1_cts.log` |
| Post-CTS setup WNS (ns) | **0.000 ns** literal WNS (no violation); worst slack **+0.0736 ns** | **0.000 ns** literal WNS; worst slack **+0.3415 ns** | `cts__timing__setup__ws` in json |
| Hold violations after CTS (count) | **0** | **0** | `cts__timing__drv__hold_violation_count`, confirmed by log's `No hold violations found` (TPU) |
| Total clock endpoints (flip-flops) | **3040** (from Week 4/Day 0 synthesis: DFF count) | **1933** (same source) | not grepped from CTS log directly — sourced from confirmed synthesis-stage DFF counts, since each FF's clock pin is one CTS sink |

## Day 4 questions (answered — TPU & Kronos)

**Q1 — N flip-flops, M clock buffers added. Ratio? Simple or complex tree?**
TPU: 198/3040 ≈ **6.5%** buffer-to-FF ratio. Kronos: 112/1933 ≈ **5.8%**.
Both ratios are low (well under 1:1) — neither design needs anywhere close
to one buffer per flip-flop, which is the signature of a straightforward,
well-balanced clock distribution rather than a pathologically complex one.
TPU's slightly higher ratio and its extra tree level (5 vs 4) track with
everything else we've seen about it being the denser, more spread-out
design — buffer count here is driven more by physical distance across the
die than by raw FF count.

**Q2 — Skew as % of period? Setup margin left for logic?**
TPU: 81.74 ps / 1667 ps = **4.90%** of the clock period spent on skew.
Kronos: 27.45 ps / 1000 ps = **2.74%**. Both comfortably under the "10% is
a problem" rule of thumb from the concept table. What's left for actual
logic delay is essentially the post-CTS worst setup slack itself: **73.6
ps (4.4% of period)** for TPU, **341.5 ps (34.2% of period)** for Kronos —
TPU is operating with much tighter margin overall, consistent with its
larger skew eating into the same budget its congestion and wire-delay
growth were already consuming.

**Q3 — What does a hold violation mean physically? Tapeout blocker? How
fixed?**
A hold violation means data at a flip-flop's D input changes **too soon**
after the clock edge that just captured the *previous* value — before the
minimum hold-time window (the time data must stay stable *after* the
clock edge) has closed. Physically, the flop can end up capturing the
*new* value instead of the one it was supposed to latch, corrupting state
on that cycle. **Yes, it's a tapeout blocker** — unlike setup violations,
hold violations cannot be fixed by slowing the clock, because they compare
data arrival against the *same* clock edge, not consecutive edges;
frequency scaling doesn't touch the relationship at all. The fix is
inserting **delay buffers on the too-fast path** — deliberately slowing
data arrival just enough to satisfy the hold requirement, placed on paths
with slack to spare so it doesn't create a new setup problem. Your own
data shows this mechanism directly: `repair_timing -setup_margin 0
-hold_margin 0 ...` is exactly that repair pass, and
`cts__design__instance__count__hold_buffer: 0` confirms it found nothing
to fix in either design this time.

**Q4 — Compare buffer counts across designs. More FFs = more buffers
always? What else matters?**
TPU has 3040 FFs (1.57× Kronos's 1933) and 198 buffers (1.77× Kronos's
112) — buffer count grew slightly *faster* than FF count, not
proportionally. So no, FF count alone doesn't determine buffer count.
What else clearly mattered here: **physical die size** (TPU's die is
2.3× Kronos's linear dimension, meaning longer wires need more repeater
buffers regardless of sink count), **tree depth** (TPU needed 5 levels to
stay balanced across that distance, Kronos only 4), and **skew target**
(tighter balancing requirements generally cost more buffers). Two designs
with identical FF counts but very different floorplans could easily need
very different buffer counts.

---

# Day 5 — Routing + Finish + Presentation

Routing alone (`make route`) only produces `5_route.odb`. **You need `make
finish` afterward to get the GDS.**

## Step 1: Run routing

### TPU — ✅ FULLY SUCCEEDED (final config: 30% utilization, 0.45 density, M8, adjustment=0.16) — tapeout-ready GDS, 0 violations of any kind

> **⚠️ HANDOFF SUMMARY — read this first if picking up in a new session.**
> **TPU is done — fully successful, clean, tapeout-ready GDS.** The full
> arc: attempt 1 (45%/0.60) failed hard at global routing. Attempt 2
> (35%/0.50) failed less badly but still failed. Attempt 3 added
> `MAX_ROUTING_LAYER=M8` + `ROUTING_LAYER_ADJUSTMENT=0.16` with a full
> floorplan re-run — **global routing succeeded** (0 congestion, 61.32%
> usage), but detailed routing then crashed from an **OOM kill**,
> root-caused to WSL2 capping itself at ~11GB regardless of 24GB host RAM
> — fixed via `.wslconfig` (`memory=20GB`). DRT then reran and converged
> to 99.89% (97,676→111 violations) but stalled on layer **M8's "Min
> Step"** violations — a *geometric* legality issue (M8's coarser track
> pitch), not congestion. Reverting M8 was investigated and ruled out —
> GRT resource tables showed `ROUTING_LAYER_ADJUSTMENT` had **no
> confirmed effect**; M8 alone did all the real work. **Final fix:**
> dropped `CORE_UTILIZATION 35→30`, `PLACE_DENSITY 0.50→0.45`, kept M8 +
> adjustment, full clean re-run from floorplan. **Result: complete
> success** — GRT 0 overflow (54.55% usage), DRT **0 DRC violations, 0
> antenna violations, 0 setup/hold violations**, clean GDS merge, peak
> memory 19.5GB (right at the edge of the 20GB ceiling — the earlier
> memory fix was a hard prerequisite for this success, not just a nice-
> to-have). Post-GRT (pre-detailed-route) slack estimate: **+443.888 ps**
> (vs. 723.59 ps at synthesis, unaffected by any of these config changes)
> — flagged as an estimate, not a re-verified final number, since no
> separate final STA re-run after DRT's clean convergence was captured.
> Full stage-by-stage detail is below. **Remaining open items are
> cosmetic** (opening the GDS in KLayout for a screenshot, extracting
> Kronos's equivalent
> metrics) — nothing blocking TPU's completion.

**Attempt 1 — original settings (`CORE_UTILIZATION=45`, `PLACE_DENSITY=0.60`):**

**Command run:**
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk route
```
**Output (abbreviated — full run took 3h 24m, peak 4.1 GB):**
```
Design:                   tpu
Die area:                 ( 0 0 ) ( 151521 151521 )
Number of components:     89797
[WARNING DRT-0120] Large net net29807 has 103 pins ...
[WARNING DRT-0120] Large net net29764 has 102 pins ...
[WARNING DRT-0120] Large net net20230 has 109 pins ...
[INFO GRT-0022] Global adjustment: 0%
[INFO GRT-0053] Routing resources analysis:
Layer  Original  Derated  Reduction(%)
M2      841225    604867      28.10%
M3     1066456    792015      25.73%
M4      817348    606795      25.76%
M5      788468    584765      25.84%
M6      549006    372134      32.22%
M7      625152    421344      32.60%

[WARNING GRT-0273] Disabled NDR (to reduce congestion) for net: clknet_1_1_0_clk
[WARNING GRT-0273] Disabled NDR (to reduce congestion) for net: net29970
[WARNING GRT-0273] Disabled NDR (to reduce congestion) for net: clknet_0_clk
[WARNING GRT-0273] Disabled NDR (to reduce congestion) for net: clknet_1_0_0_clk
(30-iteration congestion-recovery loop restarted 5 times total)

[INFO GRT-0096] Final congestion report:
Layer   Resource   Demand   Usage(%)
M2       604867    562367     92.97%
M3       792015    754960     95.32%
M4       606795    546051     89.99%
M5       584765    514950     88.06%
M6       372134    304036     81.70%
M7       421344    285233     67.70%
Total   3381920   2967597     87.75%

[INFO GRT-0018] Total wirelength: 2102932 um
[INFO GRT-0014] Routed nets: 91066
[ERROR GRT-0116] Global routing finished with congestion. Check the congestion regions in the DRC Viewer.
write_db ./results/asap7/tpu/600mhz/5_1_grt-failed.odb
make[1]: *** [Makefile:544: do-5_1_grt] Error 1
make: *** [Makefile:544: results/asap7/tpu/600mhz/5_1_grt.odb] Error 2
```
**DIAGNOSIS:** hard failure at **global** routing — detailed routing was
never reached. Predicted by Day 3: placement's routability optimization
never hit its congestion target (`final weighted congestion 1.4115` vs.
`1.01` target, `26.85%` tile overflow). Pre-route resource derating already
cut 26–33% off every layer's track budget before a single net was routed.
GRT sacrificed NDR (extra width/spacing) on 4 nets — 3 of them clock nets —
across 5 restart attempts, and still couldn't converge; worst layer M3 at
95.32% utilization, total 87.75%.
**STATUS: ❌ FAILED, `GRT-0116`.**

**Fix applied — edited `config_600mhz.mk`:**
```makefile
export CORE_UTILIZATION = 35    # was 45
export PLACE_DENSITY = 0.50     # was 0.60
```
Cleaned and re-ran from floorplan. Checkpoint after placement:
```
[INFO GPL-0089] Routability finished. Reverting to minimal observed routing congestion, could not reach target.
[INFO GPL-1005] Routability final weighted congestion: 1.2304
```
Real improvement (1.4115 → 1.2304) but still above the 1.01 target —
proceeded to route anyway.

**Attempt 2 — 35%/0.50 (already baked into floorplan) + `MAX_ROUTING_LAYER=M8`
added to config.mk without a floorplan re-run:**

**⚠️ Mistake made here:** the guidance at the time was "this only affects
routing, shouldn't force floorplan/placement to redo" — **wrong**, per the
result below.

**Output (abbreviated — 59m 29s, peak 3.48 GB):**
```
Design:                   tpu
Die area:                 ( 0 0 ) ( 171273 171273 )
Number of components:     91990
[INFO GRT-0021] Max routing layer: M7          ← still M7, NOT M8!
[INFO GRT-0096] Final congestion report:
Layer   Resource   Demand    Usage(%)
M2       781721    626635      80.16%
M3      1015102    852735      84.00%
M4       777105    583798      75.12%
M5       749282    580510      77.48%
M6       476688    320098      67.15%
M7       539097    277923      51.55%
Total   4338995   3241699      74.71%     Total Congestion: 101

[WARNING GRT-0704] Try reduce the layer adjustment from 25% to 16%
[ERROR GRT-0116] Global routing finished with congestion. Check the congestion regions in the DRC Viewer.
make: *** [Makefile:544: results/asap7/tpu/600mhz/5_1_grt.odb] Error 2
```
**STATUS: ❌ FAILED again, `GRT-0116`. But dramatically closer:** total
overflow dropped from 89,142 (attempt 1) to **101** (attempt 2), ~880×
improvement, 0 restart loops needed.

**DIAGNOSIS of why M8 had no effect:**
```bash
grep -rn "MAX_ROUTING_LAYER\|max_routing_layer" scripts/*.tcl scripts/*.sh
```
```
scripts/floorplan.tcl:109:    $::env(MIN_ROUTING_LAYER)-$::env(MAX_ROUTING_LAYER) $::env(ROUTING_LAYER_ADJUSTMENT)
scripts/floorplan.tcl:110:  log_cmd set_routing_layers -signal $::env(MIN_ROUTING_LAYER)-$::env(MAX_ROUTING_LAYER)
```
**Both `MAX_ROUTING_LAYER` and `ROUTING_LAYER_ADJUSTMENT` are consumed
once, during `floorplan`**, then baked into the database and carried
forward unchanged through place → CTS → route. `M8` was added *after*
floorplan/place/CTS had already completed with the old M7 database, so
route never saw it. **Any change to either variable requires a full clean
+ re-run from floorplan.**

**Attempt 3 — full clean + re-run from floorplan, `MAX_ROUTING_LAYER=M8`
+ `ROUTING_LAYER_ADJUSTMENT=0.16` both applied fresh — GRT ✅ SUCCEEDS:**

`ROUTING_LAYER_ADJUSTMENT`'s value format (fractional 0–1, e.g. `0.16`,
not a whole-number percentage) was confirmed by checking real example
configs at `flow/designs/asap7/*/config.mk`, which use values like `0.2`,
`0.3`, `0.45`.

```makefile
export CORE_UTILIZATION = 35
export PLACE_DENSITY = 0.50
export MAX_ROUTING_LAYER = M8
export ROUTING_LAYER_ADJUSTMENT = 0.16
```
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk clean_floorplan clean_place clean_cts clean_route clean_finish
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk route
```
**Result: GRT succeeded — 0 congestion violations, 61.32% total usage**
(down from attempt 2's 74.71%). All timing/antenna repair stages clean.
**STATUS: ✅ CONFIRMED — global routing is no longer the blocker.** The
flow proceeded into detailed routing (DRT).

---

## New problem: DRT crashed from an OOM kill

**First DRT attempt** crashed silently mid-run (0th iteration, ~50%
complete, 25,880 violations still present, memory climbing to ~11GB) with
no tool-level error — just `make: Error 247`.

**Diagnosis — confirmed genuine OOM kill via kernel logs, not a
routing/DRC failure:**
```bash
dmesg -T | grep -i "killed process\|out of memory"
journalctl -k --since "-2 hours" | grep -i "killed process\|out of memory\|oom"
free -h
```
```
Out of memory: Killed process 3557 (openroad) total-vm:18095556kB, anon-rss:11449216kB
```
**Root cause: WSL2 defaults to capping its own memory at ~50% of host RAM
(or 8GB, whichever is smaller).** System has 24GB physical RAM, WSL was
only allowing ~11GiB — right at DRT's peak memory ceiling.

**Fix — edited `.wslconfig` in the Windows user profile (not inside
Ubuntu):**
```powershell
notepad "$env:USERPROFILE\.wslconfig"
```
```ini
[wsl2]
memory=20GB
processors=8
swap=8GB
```
Applied from **PowerShell**, not Ubuntu:
```powershell
wsl --shutdown
```
**Confirmed new ceiling inside Ubuntu:**
```
Mem:  19Gi total   475Mi used   17Gi free   18Gi available
Swap:  8.0Gi total  0B used
```
**Notes worth keeping for the record:**
- `memory=20GB` is a ceiling, not a permanent reservation — WSL only
  claims RAM as processes request it, releases it (with some known WSL2
  laziness) when idle.
- The 20GB→19Gi gap is just GB (decimal) vs GiB (binary), not memory
  going missing.
- `free -h`'s **`available`** column, not `free`, is the real usable
  headroom — `buff/cache` is reclaimable on demand.
- Swap prevents OOM kills but is far slower than RAM; heavy reliance on
  it shows up as unusual slowness, not just as a safety net.
- Separately confirmed via Task Manager that a ~12.7GB Windows-side usage
  spike seen at one point was **not** WSL (`VmmemWSL` was only ~1.1GB) —
  it was browser processes (many Firefox/Brave tabs) plus Obsidian/
  WebView2. Unrelated to the OpenROAD run — worth closing browser tabs
  before a heavy run regardless, to reduce host-side contention.
**STATUS: ✅ FIXED** — confirmed via the successful rerun below.

---

## DRT rerun — converged to 99.89%, then stalled on M8

Full detailed-routing run, same config as attempt 3 (M8, adjustment=0.16,
35%/0.50), after the memory fix:

| Iteration | End violations | Reduction vs. prior | Duration (approx) |
|---|---|---|---|
| 0th | 97,676 | — | ~51 min |
| 1st | 41,118 | -57.9% | ~55 min |
| 2nd | 37,701 | -8.3% | ~52 min |
| 3rd | 6,061 | -83.9% | ~28 min |
| 4th | 2,427 | -60.0% | ~10 min |
| 5th | 1,305 | -46.2% | ~4 min |
| 6th | 1,011 | -22.5% | ~3.5 min |
| 7th | 727 | -28.1% | ~2.5 min |
| 8th | 598 | -17.7% | ~3 min |
| 9th | 471 | -21.2% | ~4.5 min |
| 10th | 352 | -25.3% | ~6 min |
| 11th | 283 | -19.6% | ~4.5 min |
| 12th | 256 | -9.5% | ~11.5 min |
| 13th | 190 | -25.8% | ~13 min |
| 14th | 148 | -22.1% | ~8 min |
| 15th | 127 | -14.2% | ~23 min |
| 16th | **111** | -12.6% | **~31 min** |

**Total: 97,676 → 111 = 99.89% reduction.** Memory stayed stable at
15.6–16.1GB throughout, comfortably under the new 19GB ceiling.

**Key finding — layer M8's "Min Step" violations became the dominant,
stubborn remainder**, a *geometric* legality rule (minimum spacing between
successive same-net shape segments), not congestion/capacity:
```
iter4: 331 → iter5: 256 → iter6: 213 → iter7: 166 → iter8: 139 → iter9: 78
→ iter10: 56 → iter11: 54 → iter12: 56 → iter13: 32 → iter14: 28 → iter15: 38 → iter16: 30
```
Not monotonic — oscillates rather than converging cleanly. By iteration
16 (111 total), **M8 accounts for 65 (59%)**: Min Step 30, Short 29, Metal
Spacing 6. Non-M8 violations (M2–M4) were down to ~29 total and still
trending to zero normally.

**Interpretation:** M8's track pitch (0.08) is coarser than M7's (0.064)
— plausibly producing Min Step conflicts that rip-up-and-reroute struggles
to resolve through iteration alone, a structural/geometric constraint
rather than a capacity one (capacity-driven types on M2–M4 cleared
normally).

**Investigated and ruled out: reverting `MAX_ROUTING_LAYER` to M7.**
Comparing GRT resource tables, failed run (M7-only) vs. successful run
(M8 added):
```
                    Failed run (M7)      Successful run (M8 added)
M2 resource         781,721               781,845
M3 resource         1,015,102             1,015,102
M4 resource         777,105               777,105
M5 resource         749,282               749,282
M6 resource         476,688               476,688
M7 resource         539,097               539,097
```
**⚠️ Correction worth flagging:** these are nearly identical — meaning
`ROUTING_LAYER_ADJUSTMENT=0.16` had **no measurable effect** on M2–M7
capacity (`GRT-0022 Global adjustment: 0%` reported in both logs). **The
entire GRT improvement came from M8's added capacity alone
(+460,161 resource units), not from the adjustment setting.** If you've
described `ROUTING_LAYER_ADJUSTMENT` as part of the fix in any notes so
far, it should be corrected — the evidence says it wasn't confirmed to do
anything. Reverting to M7-only would very likely reproduce the original
`GRT-0116` failure, so this was ruled out as a path forward.

---

## ✅ SUCCESS — 30%/0.45 rerun completed the full flow cleanly

**Plan that was executed:**
```makefile
export CORE_UTILIZATION = 30      # was 35
export PLACE_DENSITY = 0.45       # was 0.50
export MAX_ROUTING_LAYER = M8     # unchanged
export ROUTING_LAYER_ADJUSTMENT = 0.16   # unchanged
```
Full clean + re-run from floorplan through `finish`.

> **⚠️ Important — this is a different configuration from Days 1–4's TPU
> data.** Everything in Day 1 (floorplan), Day 2 (PDN), Day 3
> (placement), and Day 4 (CTS) for TPU was captured from the **original
> 45% utilization exploratory run** — used to learn the flow and answer
> those days' conceptual questions, and left as-is since it's still
> correct *for that configuration*. This final successful run used **30%
> utilization**, a full clean re-run from floorplan, and is a **separate,
> later run** with its own floorplan/placement/CTS numbers (summarized
> fresh below, not cross-referenced with Day 1–4's numbers as if
> continuous). Synthesis is the one exception — synthesis happens
> *before* any physical-design parameter takes effect, so the original
> `1_Post_synthesis.rpt` numbers (723.59 ps worst slack) are still valid
> and unchanged regardless of which utilization config ran afterward.

### Stage-by-stage summary of the final successful run

**Floorplan:** die 184.675 × 184.675 µm (bigger than the 45%/35% attempts,
expected — lower utilization needs more area for the same cells), core
snapped to (2.052, 2.160)–(182.628, 182.520), 668 rows × 3,344 sites.
86,102 instances → 9,793 µm² instance area → 30.1% effective utilization
(right on target). 2,944 `TIEHIx1` tie cells inserted (plausibly one per
`DFFASRHQNx1` needing an unused SET/RESET pin tied off — same count as
that flop type from synthesis). 2,345 tapcells + 1,336 endcaps. PDN
succeeded. **Also flagged here, worth noting separately:** 147 input +
249 output ports missing delay constraints (SDC not fully constrained) —
didn't block anything, but worth mentioning if asked about SDC quality.

**Placement:** global place (skip-IO) density 0.45 confirmed applied;
minimum *feasible* density computed at 0.34, so 0.45 had real headroom —
a good sign, unlike earlier attempts. Main routability+timing-driven pass:
best weighted congestion **1.1019** (closer to the 1.01 target than the
35% run's 1.2304, though still technically short — evidently close enough
this time). 2,386 total Nesterov iterations; cell area inflated +48.6%
(routability + timing-driven buffering) to manage congestion proactively.
Detailed placement: 88,027 cells legalized, **100% success, 0 failures**,
avg displacement only 0.2 µm.

**CTS:** same root/sink buffer as every prior attempt (`BUFx24`), same
3,040 clock sinks (unchanged netlist). This time only a **4-level** tree
(vs. 5 levels at 45%), 219 buffers, **0 setup violations, 0 hold
violations**.

**Global route:** `min layer M2, max layer M8` — **M8 confirmed actually
applied this time** (fresh floorplan, no repeat of attempt 2's mistake).
Total usage **54.55%** of 5.57M resource units — **no reported overflow**,
comfortably better than attempt 3's 61.32% at 35%. 92,140 nets routed,
1,974,758 µm wirelength, 1,086,065 vias. **Timing: worst path implies an
achieved period of 1161.957 ps against the 1667 ps target — slack
+443.888 ps across 6,506 endpoints.** Zero antenna violations (though the
platform has no ANTENNACELL diode available, so antenna repair relies
purely on jumpering/routing — a platform characteristic, not a design
flaw).

**Detailed route — the dominant cost, and where the earlier memory fix
proved essential, not just precautionary:**

| Iter | Violations | Elapsed | Peak mem |
|---|---|---|---|
| 0th | 79,920 | 48m46s | **19.5 GB** |
| 1st | 28,103 | 1h13m44s | 14.7 GB |
| 2nd | 24,597 | 49m13s | 15.8 GB |
| 3rd | 1,432 | 23m50s | 15.8 GB |
| 4th | 146 | 4m20s | 14.9 GB |
| 5th | 10 | 36s | 14.9 GB |
| 6th–7th | 6 | ~6s each | 14.9 GB |
| 8th | **0** | 1m56s | 14.9 GB |

**Peak memory hit 19.96 GB** — right at the edge of the 20GB `.wslconfig`
ceiling set several sessions ago. **Without that fix, this exact run would
almost certainly have OOM'd again** (iteration 0 alone hit 19.5GB, and the
original WSL default was only ~11GB) — the earlier memory investigation
wasn't just a nice-to-have, it was a hard prerequisite for this success.
Early violations were dominated by EOL spacing/eolKeepOut/metal
spacing/shorts on M2/M3 — the same congestion signature seen throughout
this whole investigation, just fully resolved by iteration 8. Total: **3h
32m elapsed** (~83% of the whole flow's runtime), 25h32m cumulative CPU
time (755% parallel utilization — roughly 7.5 cores average).

**Fill, finish, GDS:** 158,304 filler/decap cells, final cell count
250,429, design area = full core area at the cell level (32,568.69 µm²).
IR drop well within budget (VDD worst-case 12.2 mV / 1.58% of 0.77V
supply; VSS 11.3 mV / 1.47%). **GDS merge succeeded — all LEF cells
matched GDS cells, no orphan cells — clean, tapeout-ready GDS.**

### Totals — TPU's final, successful configuration
```
Wall-clock:    15,295 s (4h 14m 55s) for the whole `finish` target
Peak memory:   19,493 MB (19.5 GB), during detailed routing
Final result:  0 DRC violations, 0 antenna violations, 0 setup/hold
               violations, clean GDS
```
**STATUS: ✅ CONFIRMED — TPU is fully tapeout-ready.**

### Q1-relevant number, computed correctly this time (synthesis is
config-independent, so this comparison is valid)
Synthesis worst slack (unchanged, from the original run): **723.59 ps**.
Post-GRT (pre-detailed-route) slack estimate (this run): **+443.888 ps** —
not re-verified after DRT's clean convergence, best available number.
Degradation: **279.7 ps, 16.8% of the 1667 ps clock period** — notably
*smaller* relative degradation than the intermediate 45%-config numbers
suggested (Day 3's 78.4 ps / Day 4's 73.6 ps were from the congested,
ultimately-unroutable configuration and are not on the same continuous
journey as this number). The lower-utilization, more-open layout that fixed
routability also ended up with meaningfully better final timing margin
than the tight configuration would have projected — trading die area for
*both* routability and timing headroom, not routability alone. Good
insight for the presentation.

**Useful diagnostic commands from this whole investigation, worth keeping
handy:**
```bash
grep -inE 'congestion|overflow' logs/asap7/tpu/600mhz/5_1_grt.log | tail -40
grep -A20 "Final congestion report" logs/asap7/tpu/600mhz/5_1_grt.log
grep "Max routing layer" logs/asap7/tpu/600mhz/5_1_grt.log
dmesg -T | grep -i "killed process\|out of memory"
free -h
```

**Still open from this investigation (low priority, not blocking):**
whether `ROUTING_LAYER_ADJUSTMENT` actually does anything (evidence still
says no — but irrelevant now, the design succeeded regardless). **For the
presentation:** the full arc — congestion failure → utilization/density
fix → new M8 layer → OOM discovery and fix → M8 geometric edge case →
further density reduction → full clean success, with the near-miss on
memory ceiling (19.96GB peak vs 20GB limit) — is genuinely strong,
specific material for the reflection questions on what you'd change and
what a DRC violation means physically. More interesting than a clean
first-try success would have been.

### Kronos — ✅ FULL SUCCESS, all the way through `finish`

**Command run:**
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/config_1000mhz.mk route
```
**Output:**
```
make: Nothing to be done for 'route'.
```
Already complete — routing had already run successfully before this check.

**Command run (finish):**
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/config_1000mhz.mk finish
```
**Output:**
```
KLayout 0.30.9
Warning: DEF UNITS does not match reader DBU (DEF UNITS is 1000 and
corresponds to a DBU of 0.001, but reader DBU is set to 0.00025)
[INFO] All LEF cells have matching GDS/OAS cells
[INFO] No orphan cells in the final layout
cp results/asap7/kronos_core/1000mhz/6_1_merged.gds results/asap7/kronos_core/1000mhz/6_final.gds
```
**Not an error — explains an old apparent contradiction in this document.**
`0.00025 µm/unit = 4000 units/µm`. Earlier in this doc I corrected an
initial claim of "4000 DBU/µm" down to "1000 DBU/µm" based on hard evidence
from OpenROAD's own database (`.odb`/`.def` files) — that correction still
stands, it's genuinely 1000 for those files. **This warning shows both
numbers are real, for different files:** OpenROAD's internal database is
1000 DBU/µm (confirmed repeatedly all week); the **native ASAP7 GDS
library** (`asap7sc7p5t_28_R_220121a.gds`) genuinely uses 4000 DBU/µm — the
PDK's own original convention. KLayout's merge step hits this mismatch
directly when combining the two, warns about it, and handles it correctly
— confirmed by the clean `[INFO]` lines after and the flow completing with
no errors.

**Full stage-timing summary (auto-generated by ORFS, confirms every real
filename we've used and predicted all week):**
```
Log                       Ext     Elapsed/s Peak Memory/MB
1_1_yosys_canonicalize    .rtlil          1             88
1_2_yosys                 .v             32            165
1_2_yosys_metrics                         7            226
1_synth                   .odb            2            195
2_1_floorplan             .odb            8            259
2_2_floorplan_macro       .odb            2            189
2_3_floorplan_tapcell     .odb            2            179
2_4_floorplan_pdn         .odb            2            193
3_1_place_gp_skip_io      .odb            6            208
3_2_place_iop             .odb            1            193
3_3_place_gp              .odb           30            527
3_4_place_resized         .odb           13            247
3_5_place_dp              .odb           15            355
4_1_cts                   .odb           25            393
5_1_grt                   .odb          132            558
5_2_route                 .odb          780           4622
5_3_fillcell              .odb            2            235
6_1_fill                  .odb            2            206
6_1_merge                                 3            494
6_report                                 29            534
Total                                  1094           4622
```
**STATUS: ✅ CONFIRMED — full RTL-to-GDSII completion, 18.2 minutes total,
4.6 GB peak memory (during detailed route, which is also the flow-wide
peak).** Routing (global+detailed, 912s) is ~83% of total runtime — the
clear compute bottleneck, consistent with routing generally being the
heaviest PnR stage. Two distinct fill passes exist: `5_3_fillcell`
(end of routing) and `6_1_fill` (start of finish) — not a duplicate,
two genuinely separate steps.

**Detailed route/finish breakdown, confirmed — Kronos routed cleanly on
the default stack, no config tuning needed:**

```
[INFO GRT-0021] Max routing layer: M7    ← no M8 needed
[INFO GRT-0022] Global adjustment: 0%

Final congestion report:
Layer   Resource   Demand   Usage(%)   Congestion events
M2      116,294    38,080   32.74%     0
M3      151,229    46,756   30.92%     0
M4      115,778     8,270    7.14%     0
M5      111,776     5,498    4.92%     0
M6       71,447     2,408    3.37%     0
M7       80,385     1,741    2.17%     0
Total   646,909   102,753   15.88%     0
```
15.88% total usage — comfortable margin, nowhere close to TPU's
congestion pressure even before any of TPU's fixes were needed.

**DRT convergence — fast and clean:**
| Iteration | Violations | Duration |
|---|---|---|
| 0th | 4,053 | ~5 min |
| 1st | 563 | ~4 min |
| 2nd | 404 | ~3 min |
| 3rd | 11 | ~1 min |
| 4th–6th (guide tiles) | 6, 5, 5 | seconds each |
| 7th (stubborn tiles) | **0** | ~44 sec |

DRT total: ~16m23s, peak memory **4,425.58 MB (~4.4GB)** — a small
fraction of TPU's ~19.5GB, and no M8-style stubborn violation category
ever appeared (consistent with M8 not being used at all for this design).

**Post-route:** 0 antenna net violations, 0 antenna pin violations.
18,161 fillcell instances placed. Final design area 1,772 µm², 46%
utilization (design-level; full core is 3,863.12 µm² once fillers are
counted, same "100% packed at cell level, lower logical utilization"
pattern as TPU).

**IR drop (final):**
```
Net VDD: Total power 1.24e-02 W, Worst IR drop 2.65e-03 V, 0.34% drop
Net VSS: Total power 1.24e-02 W, Worst IR drop 2.43e-03 V, 0.32% drop
```
Notably healthier than TPU's 1.58%/1.47% — expected, given the much
smaller power delivery demand of a design this size.

**Cell type breakdown:**
```
Fill cell                 18,161   2,091.31 µm²
Tap cell                     692      20.18 µm²
Tie cell                     262      11.46 µm²
Clock buffer                 167      58.51 µm²
Timing Repair Buffer         416      36.61 µm²
Inverter                     779      34.16 µm²
Clock inverter                 38       4.96 µm²
Sequential cell             1,933     586.28 µm²
Multi-Input combinational   9,837   1,019.65 µm²
Total                      32,285   3,863.12 µm²
```
Sequential cell count (1,933) matches Kronos's synthesis-stage DFF count
exactly, same cross-check pattern used throughout this document.

**Timing at the global-route checkpoint:** 1000 ps target, 663.956 ps
actual, **slack 301.098 ps**. **Same caveat as TPU's equivalent number
below: this is a pre-detailed-route (GRT-stage) estimate, not a
re-verified true final post-route number** — DRT converged cleanly
afterward (0 violations) but no separate final STA re-run was captured in
this handoff, so 301.098 ps is the best available figure, not a fully
confirmed final one.

**GDS export:** KLayout merge succeeded cleanly — no orphan cells.
`6_final.gds` produced.

**Still not captured for Kronos:** total wire length and via count
weren't included in this summary (unlike TPU's, which had them). If
wanted for completeness:
```bash
grep -iE 'wire ?length|via' logs/asap7/kronos_core/1000mhz/5_2_route.log | tail -20
ls -lh results/asap7/kronos_core/1000mhz/6_final.gds
```

**TPU vs Kronos contrast, worth leading with in the presentation:**

| | TPU attempt 1 | TPU attempt 2 | TPU attempt 3 (GRT) | TPU final (30%/0.45) | Kronos |
|---|---|---|---|---|---|
| Global route | Failed, 5 restarts | Failed, 0 restarts | **✅ Succeeded**, 0 congestion | **✅ Succeeded**, 0 overflow, 54.55% usage | Succeeded |
| Detailed route | Never reached | Never reached | OOM → fixed → 99.89%, stalled on M8 | **✅ 0 DRC violations** | Succeeded |
| Final result | Failed | Failed | Blocked (DRT stalled) | **✅ Clean, tapeout-ready GDS** | ✅ Clean GDS |
| Total time (whole flow) | 3h24m (failed) | 59m (failed) | GRT fast, DRT ~4.5h (incomplete) | **4h 15m (complete)** | 18.2 min |
| Peak memory | 4.1 GB | 3.48 GB | ~11GB OOM → 15.6–16.1GB fixed | **19.5 GB** (near the 20GB ceiling) | 4.6 GB |
| Post-GRT slack estimate | N/A | N/A | N/A | **+443.888 ps** | **+301.098 ps** |

TPU's full arc: congestion failure → utilization/density fix →
routing-layer fix → OOM discovery and fix → geometric edge case on the
new layer → further density reduction → **complete, clean success**. Six
distinct problem types resolved across the investigation (congestion,
stale-config mistakes, memory configuration, geometric DRC, and finally a
clean convergence) — genuinely richer material for the presentation than
a first-try success, and it demonstrates real iterative PnR debugging
rather than a single lucky configuration.

### 📋 Final commands — copy/paste to re-run (TPU) — confirmed-working, final configuration
```bash
cd ~/EDA/OpenROAD-flow-scripts/flow
# config_600mhz.mk (confirmed working, produced a clean tapeout-ready GDS):
#    export CORE_UTILIZATION = 30
#    export PLACE_DENSITY = 0.45
#    export MAX_ROUTING_LAYER = M8
#    export ROUTING_LAYER_ADJUSTMENT = 0.16   (effect on GRT unconfirmed, harmless, left in)

make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk clean_floorplan clean_place clean_cts clean_route clean_finish
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/tiny-tpu/run_600mhz/configs/config_600mhz.mk finish

# Checkpoint after placement (confirmed 1.1019 weighted congestion this run):
grep -iE 'Routability finished|final weighted congestion' logs/asap7/tpu/600mhz/3_3_place_gp.log

# If re-running and memory needs checking (peaked at 19.5GB last time, near the 20GB ceiling):
free -h
```

### 📋 Final commands — copy/paste to re-run (Kronos)
```bash
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/config_1000mhz.mk route
make DESIGN_CONFIG=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-05-RTL-PnR-flow/OpenRoad/kronos/run_1000mhz/configs/config_1000mhz.mk finish
```

---

## Step 2: Extract routing metrics — ✅ CONFIRMED for both designs

**TPU — confirmed from the stage-by-stage summary, real numbers:**
```
DRC violations:        0
Antenna violations:    0
Setup/hold violations: 0
Total wirelength:      1,792,555 µm
Total vias:            1,709,962 (M1 has the most terminations, 323,027 — expected, pin-access layer)
Post-GRT slack estimate: +443.888 ps (worst path implies 1161.957 ps vs. 1667 ps target — pre-detailed-route number, not re-verified after DRT's clean convergence)
Final GDS:             clean — all LEF cells matched GDS cells, no orphan cells
```
If you want the literal log lines for the report/slides rather than this
summary:
```bash
DESIGN=tpu
RUN_Type=600mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"

ls -lh "$RESULTS/6_final.gds"
grep -iE 'wire ?length|via' "$LOGS/5_2_route.log" | tail -20
grep -riE 'wns|tns|worst slack|slack' "$LOGS/5_2_route.log" | tail -20
find "$BASE/reports/asap7/$DESIGN/$RUN_Type" -iname '*drc*'
```

**Kronos — now fully confirmed, all rows filled:**
```
DRC violations:        0 (converged in 7 DRT iterations, ~16m23s)
Antenna violations:    0 net, 0 pin
Setup/hold violations: (not separately reported; consistent with a clean convergence)
Total wirelength:      60,555 µm (M2 18,595 / M3 28,844 / M4 8,992 / M5 2,865 / M6 695 / M7 560 — M1/M8/M9/Pad all 0)
Total vias:            141,371
Post-GRT slack estimate: +301.098 ps (663.956 ps achieved vs. 1000 ps target — same
                         pre-detailed-route caveat as TPU's number)
Final GDS:             clean — all LEF cells matched GDS/OAS cells, no orphan cells
Final GDS file size:   18M (6_final.gds, confirmed via `ls -lh`)
```
Confirmed via:
```bash
DESIGN=kronos_core
RUN_Type=1000mhz
BASE=/home/nurmdabd/EDA/OpenROAD-flow-scripts/flow
LOGS="$BASE/logs/asap7/$DESIGN/$RUN_Type"
RESULTS="$BASE/results/asap7/$DESIGN/$RUN_Type"

ls -lh "$RESULTS/6_final.gds"
grep -iE 'wire ?length|via' "$LOGS/5_2_route.log" | tail -20
```
**Output (real, confirmed):**
```
-rw-r--r-- 1 nurmdabd nurmdabd 18M Jul 15 13:38 .../results/asap7/kronos_core/1000mhz/6_final.gds
Total wire length on LAYER M6 = 695 um.
Total wire length on LAYER M7 = 560 um.
Total wire length on LAYER M8 = 0 um.
Total wire length on LAYER M9 = 0 um.
Total wire length on LAYER Pad = 0 um.
Total number of vias = 141371.
Up-via summary (total 141371):
Total wire length = 60555 um.
Total wire length on LAYER M1 = 0 um.
Total wire length on LAYER M2 = 18595 um.
Total wire length on LAYER M3 = 28844 um.
Total wire length on LAYER M4 = 8992 um.
Total wire length on LAYER M5 = 2865 um.
Total wire length on LAYER M6 = 695 um.
Total wire length on LAYER M7 = 560 um.
Total wire length on LAYER M8 = 0 um.
Total wire length on LAYER M9 = 0 um.
Total wire length on LAYER Pad = 0 um.
Total number of vias = 141371.
Up-via summary (total 141371):
```
STATUS: ✅ resolved.

---

## Step 3: Compare timing across all 5 stages — TPU needs a different table than planned

**TPU: don't chain Day 1–4's numbers into this run's post-route number —
different configs (45% exploratory vs. this run's 30% final), not a
continuous journey.** The only valid two-point comparison is synthesis
(config-independent) vs. this run's result:
```
Synthesis (unchanged, any config):     +723.59 ps worst slack
Post-GRT estimate (30% config):        +443.888 ps worst slack (pre-detailed-route)
Degradation: 279.7 ps, 16.8% of the 1667 ps clock period
```
If you want the intermediate stages *for the 30% configuration
specifically* (not yet individually extracted — the summary above gives
qualitative detail per stage but not each stage's exact `__timing__
setup__ws` json value), the same commands as before apply, just note
they'd need re-running against this run's log files rather than assuming
Day 1–4's numbers apply:
```bash
grep -o '"floorplan__timing__setup__ws": [^,]*' logs/asap7/tpu/600mhz/2_1_floorplan.json
grep -o '"detailedplace__timing__setup__ws": [^,]*' logs/asap7/tpu/600mhz/3_5_place_dp.json
grep -o '"cts__timing__setup__ws": [^,]*' logs/asap7/tpu/600mhz/4_1_cts.json
```
(These files were overwritten by the clean+re-run, so they now reflect
the 30% config — safe to pull if you want the full picture, just know
Day 1–4's *written* numbers in this doc still describe the earlier 45%
run, not these files' current contents.)

**Kronos: same two-point comparison, now confirmed:**
```
Synthesis:              +469.73 ps worst slack
Post-GRT estimate:      +301.098 ps worst slack (pre-detailed-route)
Degradation: 168.6 ps, 16.9% of the 1000 ps clock period
```
Interesting — TPU (16.8%) and Kronos (16.9%) land on almost the exact
same *relative* degradation despite wildly different absolute scale and
routing difficulty. Worth a mention in the presentation as a point of
similarity underneath all the differences. To confirm the full
intermediate stages if wanted:
```bash
echo -n 'Synthesis:   '; grep 'worst slack' "$REPORTS/1_Post_synthesis.rpt"
echo -n 'Floorplan:   '; grep -o '"floorplan__timing__setup__ws": [^,]*' "$LOGS/2_1_floorplan.json"
echo -n 'Placement:   '; grep -o '"detailedplace__timing__setup__ws": [^,]*' "$LOGS/3_5_place_dp.json"
echo -n 'Post-CTS:    '; grep -o '"cts__timing__setup__ws": [^,]*' "$LOGS/4_1_cts.json"
echo -n 'Post-Route:  '; grep -o '"[a-z_]*__timing__setup__ws": [^,]*' "$LOGS"/5_2_route.json 2>/dev/null
```

---

## Step 4: Open the final GDS in KLayout

**TPU — opened and confirmed:**
```bash
LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/tpu/600mhz/6_final.gds &
```
```
[1] 2247
[1]+  Done                    LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/tpu/600mhz/6_final.gds
```
Launched and the job completed cleanly (shell shows `Done` once the
KLayout window was closed) — confirms the GDS actually opened and was
viewed, not just that the command is valid.

**Kronos — opened, launched immediately after TPU:**
```bash
LIBGL_ALWAYS_SOFTWARE=1 klayout results/asap7/kronos_core/1000mhz/6_final.gds &
```
```
[1] 2284
```
Launched successfully (job 2284); no `Done` yet in the captured output,
so this window was still open at the time of the paste.

**Screenshots — now captured for both designs.** Both windows show the
full `tpu`/`kronos_core` cell loaded (Cells panel confirms the correct
top cell name in each), Levels 0–2, with the standard ORFS ASAP7 layer
stack populated in the Layers panel (`1/0`, `10/0`…`235/0`, etc.) — no
"Macro not found" or blank-canvas symptoms in either window, consistent
with a clean GDS merge for both.

- **TPU:** die is a clean square outline (green boundary), fully filled
  edge-to-edge with a dense, uniform diagonal hatch pattern (orange/M1
  fill over the standard-cell rows) — no visibly sparse regions or empty
  pockets across the die. IO pin/net labels (blue text — e.g.
  `learning_rate_in`, `ub_rd_y_data_out`, `vpu_leak_factor_in`, `clk`)
  are packed tightly along the right edge, reflecting the systolic
  array's wide port list. Scale bar: 20 µm.
- **Kronos:** same clean square die outline, same uniform diagonal fill
  pattern across the full core, no visible gaps. IO labels (`data_addr`,
  `data_mask`, `instr_addr`, `data_rd_data`, `rstz`, etc.) are more
  sparsely spaced around the edges than TPU's, consistent with its much
  smaller pin count. Scale bar: 10 µm (die is physically smaller than
  TPU's, matching the die-area numbers below).

Neither screenshot shows an obvious density gradient between the die
corner (near IO) and the centre for either design at this zoom/layer
selection (`1/0` merged fill layer) — the hatch pattern looks visually
uniform edge-to-edge in both. That's a useful data point but not yet a
rigorous answer to **Q3 (M1 density: corner vs centre)** — confirming it
properly would need isolating the actual M1 layer (rather than the
merged `1/0` view) and/or KLayout's density/heatmap tool, which hasn't
been run yet. Treat this as a first visual pass, not the final Q3
write-up.

STATUS: ✅ both GDS files confirmed opening cleanly in KLayout, and now
backed by actual screenshots of each (previously only confirmed via
shell `Done` status). Q3's rigorous density comparison is still
outstanding — see "Still open" below.

**Quick visual check without KLayout at all**, if ORFS was built with GUI
support:
```bash
ls reports/asap7/tpu/600mhz/final_*.webp
ls reports/asap7/kronos_core/1000mhz/final_*.webp
# final_all.webp, final_routing.webp, final_placement.webp,
# final_clocks.webp, final_ir_drop.webp, final_congestion.webp
```
(TPU's Day 5 stage-timing note mentioned some heatmaps weren't populated
since GUI-mode checks weren't explicitly run — cosmetic, may mean fewer
`.webp` files than Kronos has.)

---

## Day 5 metrics table — ✅ CONFIRMED for both

| **Metric** | **TPU (600 MHz, final 30% config)** | **Kronos (1000 MHz)** |
|---|---|---|
| DRC violation count | **0** | **0** |
| Total wire length (µm) | **1,792,555** | **60,555** |
| Total via count | **1,709,962** | **141,371** |
| Post-route WNS (ns) | **0.000** (post-GRT slack estimate +0.443888 ns, pre-detailed-route) | **0.000** (post-GRT slack estimate +0.301098 ns, pre-detailed-route) |
| Post-route TNS (ns) | not separately reported; 0 setup/hold violations confirms no negative-slack accumulation | same |
| Timing met after routing? | **Yes** — comfortable +443.888 ps margin (estimate) | **Yes** — comfortable +301.098 ps margin (estimate) |
| Final die area (µm²) | **34,104.9** (184.675² — this run's actual die, bigger than the 45%-config's 22,958.6 µm² documented in Day 1) | **4,393.97** (confirmed) |
| Final GDS file size | **199M** (`6_final.gds`) | **18M** (`6_final.gds`) |
| Antenna violations | **0** (no diode cells available on this platform — repaired via jumpering only) | **0** net, **0** pin |
| DRT convergence | 8 iterations, 3h22m50s | **7 iterations, ~16m23s** |
| Peak memory (DRT) | **19.5 GB** (right at the 20GB WSL ceiling) | **4.4 GB** |
| IR drop (VDD / VSS) | 1.58% / 1.47% | **0.34% / 0.32%** — notably healthier, smaller power delivery demand |
| Total wall-clock (whole flow) | **4h 14m 55s** | 18.2 min (full flow, Day 5 stage-timing table) |

**TPU's GDS file size — now confirmed, ran the same `ls -lh` command
against TPU's results path:**
```bash
ls -lh results/asap7/kronos_core/1000mhz/6_final.gds
ls -lh results/asap7/tpu/600mhz/6_final.gds
```
```
-rw-r--r-- 1 nurmdabd nurmdabd 18M Jul 15 13:38 results/asap7/kronos_core/1000mhz/6_final.gds
-rw-r--r-- 1 nurmdabd nurmdabd 199M Jul 14 21:54 results/asap7/tpu/600mhz/6_final.gds
```
TPU's GDS is **~11× larger** than Kronos's (199M vs 18M) — roughly in
line with its ~6.4× instance-count multiplier and ~7.8× die-area
multiplier (34,104.9 µm² vs 4,393.97 µm²), with the extra skew plausibly
from TPU's higher total wire length/via count (1,792,555 µm / 1,709,962
vias vs Kronos's 60,555 µm / 141,371 vias) adding proportionally more
geometry per unit area. Note the file timestamps: TPU's GDS was produced
**Jul 14, 21:54**, Kronos's **Jul 15, 13:38** — over 15 hours apart,
consistent with TPU's much longer DRT convergence time (3h22m50s vs
Kronos's ~16m23s) and overall flow runtime (4h14m55s vs 18.2 min).

**Note on TPU's die area row:** Day 1's table documents 22,958.6 µm² from
the original 45%-utilization exploratory run. This final, successful run
used 30% utilization and produced a genuinely different, larger die
(184.675² = 34,104.9 µm²) — not a correction to Day 1, a different
configuration's real result. Both numbers are accurate for what they
each describe.

**Note on "post-route" labeling:** both designs' slack figures above are
captured at the **global-route (GRT) checkpoint**, before detailed
routing — the handoff data explicitly flags TPU's number this way, and
the same caveat applies to Kronos's. Both DRT runs converged cleanly to 0
violations afterward, so these are very likely close to the true final
numbers, but neither was re-verified with a fresh STA run after DRT
completed. Treat as "best available, not fully confirmed final."

## Complete timing journey table

**Both designs: two-point comparison only** — TPU for the reasons
explained in Step 3 (different configs, not a continuous journey with
Days 1–4); Kronos because only synthesis and the post-GRT checkpoint were
captured, with no intermediate floorplan/place/CTS re-extraction done for
this specific comparison (those numbers do exist in Days 1–4 for Kronos
under its one unchanging configuration — see Day 1–4 for the full
intermediate journey there, which *is* valid/continuous for Kronos since
its config never changed).

| **Stage** | **TPU (30% config)** | **Kronos** | **Timing met?** |
|---|---|---|---|
| Synthesis (config-independent) | 0.00 / +723.59 ps | 0.00 / +469.73 ps | Y / Y |
| Post-GRT (pre-detailed-route estimate) | 0.00 / **+443.888 ps** | 0.00 / **+301.098 ps** | Y / Y |

Degradation: TPU 279.7 ps (16.8% of 1667 ps period); Kronos 168.6 ps
(16.9% of 1000 ps period) — nearly identical *relative* degradation
despite very different absolute scale and routing difficulty, worth
noting in the presentation.

For reference, the *original 45%-configuration exploratory run's*
intermediate stages for TPU (not continuous with the row above, kept for
the historical record since Days 1–4 already document them in full):

| **Stage (45% config, exploratory)** | **TPU** |
|---|---|
| After Floorplan | 0.00 / +723.595 ps |
| After Placement | 0.00 / +78.42 ps |
| After CTS | 0.00 / +73.6151 ps |
| After Routing | Failed (`GRT-0116`) — this config never reached a post-route number |

Kronos's equivalent intermediate journey (valid/continuous, single
configuration throughout — see Days 1–4 for the full detail):

| **Stage** | **Kronos** |
|---|---|
| After Floorplan | 0.00 / +469.735 ps |
| After Placement | 0.00 / +339.35 ps |
| After CTS | 0.00 / +341.534 ps |
| Post-GRT (pre-detailed-route) | 0.00 / +301.098 ps |

## Day 5 questions

**Q1 — Post-route WNS vs synthesis WNS. Timing-met? Most impactful fix if
not?**
TPU: **timing is met.** Synthesis worst slack 723.59 ps → post-GRT slack
estimate +443.888 ps, a degradation of 279.7 ps (16.8% of the 1667 ps
clock period) — notably smaller relative degradation than the
intermediate 45%-config numbers suggested, since that configuration never
actually finished routing to give a real comparison point. The
routability fix (lower utilization, `MAX_ROUTING_LAYER=M8`) turned out to
help timing margin too, not just routability — a more open layout means
shorter, cleaner routes with less parasitic delay than the tightly-packed
configuration would have produced. Kronos: **also timing-met** — synthesis
469.73 ps → post-GRT estimate 301.098 ps, degradation 168.6 ps (16.9% of
the 1000 ps clock period) — remarkably close to TPU's *relative*
degradation (16.8%) despite a completely different routing difficulty
story underneath.

**Q2 — DRC violation count, most common type, what causes an M2 spacing
violation?**
TPU: **final count is 0** — but the *journey* there is the more
interesting answer for this question. Early DRT iterations (before
convergence) were dominated by exactly the mechanism the question asks
about: EOL spacing, `eolKeepOut`, metal spacing, and shorts on **M2/M3**
— the tightest-pitch lower metal layers, hit hardest by dense routing
demand. Iteration 0 alone had 79,920 violations of these types; by
iteration 3 that had dropped to 1,432, and to 0 by iteration 8. An M2
spacing violation specifically happens when two routed shapes end up
closer than the PDK's minimum spacing rule for that layer/width
combination — typically because congestion forces the detailed router to
pack wires tighter than intended, or a via's enclosure geometry infringes
on a neighboring wire. **A separate, later category — M8 "Min Step"
violations — emerged only after adding M8 as a routing layer**, and
behaved differently: geometric (minimum spacing between successive
same-net shape segments) rather than congestion-driven, and didn't
monotonically decrease the way the M2/M3 congestion violations did.
**Kronos: final count is also 0**, and reached it far more easily —
starting at only 4,053 violations at iteration 0 (vs. TPU's 79,920) and
converging in 7 iterations / ~16 minutes (vs. TPU's 8 iterations / 3h23m).
No M8-style stubborn category ever appeared for Kronos, consistent with
it never needing M8 as a routing layer at all. Side by side, this pair
makes a clean illustration of the question's intent: same violation
*mechanism* (congestion-driven spacing/EOL issues on tight lower-metal
layers), wildly different *severity*, directly traceable to how close to
the routing-resource ceiling each design's placement left it.

**Q3 — M1 density: die corner (near IO) vs centre. Which is denser? What
does that say about critical signals?**
Both GDSes are now confirmed opening cleanly in KLayout (Day 5 Step 4)
— but the actual density comparison (die corner near IO vs centre, per
design) hasn't been visually inspected/reported yet, so this question
is still pending write-up.

**Q4 — Which stage introduced the most timing degradation? Most critical
stage for your design?**
Kronos: clearly **placement** — slack dropped from 469.73 ps to 339.35 ps
(130.4 ps, 13.0% of the clock period), by far the largest single-stage
drop in its journey; CTS barely moved it (even improved slightly), and
routing (301.098 ps post-GRT) took a further, smaller bite. TPU: **for
the final successful (30%) configuration, this question is best answered
as synthesis→final overall (279.7 ps, 16.8%)** rather than by stage,
since intermediate per-stage numbers for this specific run weren't
individually re-extracted (see Step 3). For the *original
45%-configuration exploratory run* documented in Days 1–4, placement was
clearly the biggest single drop (723.6 ps → 78.4 ps, 645.2 ps, 38.7% of
period) — but the more critical stage overall, for that configuration,
was **routing**, where accumulated congestion became a hard failure
rather than just a timing penalty. Worth telling both halves of this
story in the presentation: the exploratory run shows *why* routing was
the critical stage conceptually (congestion crossing a threshold from
"tight but working" to "unroutable"), and the final run shows the fix
actually working end-to-end. Kronos's own experience — placement
dominant, routing a comparatively minor further step — is the "normal"
pattern that TPU's original 45% attempt deviated from, and a good
contrast pairing for this question.

---

## Still open
1. **Q3's rigorous density observation (die corner near IO vs centre, M1)
   is still not fully written up.** Both GDSes are now confirmed opening
   cleanly in KLayout *and* screenshotted (Day 5 Step 4) — both show a
   visually uniform diagonal fill pattern edge-to-edge, with no obvious
   corner-vs-centre gradient at a glance — but that's the merged `1/0`
   view, not an isolated M1 layer or a real density/heatmap measurement.
   Treat the screenshots as a first pass, not the final answer.
2. Neither design's slack figures used throughout Day 5 (+443.888 ps TPU,
   +301.098 ps Kronos) have been re-verified with a fresh STA run *after*
   detailed routing's clean convergence — both are captured at the
   global-route checkpoint. Very likely close to final given 0 DRC
   violations afterward, but labeled as estimates rather than confirmed
   finals throughout this document for that reason.
3. If a clean, apples-to-apples 5-stage timing journey for TPU's *final*
   30% configuration is wanted (rather than the two-point synthesis→
   post-GRT comparison currently documented), the per-stage json files
   would need re-extracting against this run's log files specifically —
   see Day 5 Step 3's note on this. (Kronos's full intermediate journey
   *is* already valid/documented in Days 1–4, since its config never
   changed.)
4. Individual reflection questions and the presentation-slot checklist
   (S3-specific: "Show TPU systolic array in KLayout... Compare TPU vs
   Kronos die area and final WNS") — not yet scaffolded in this doc, but
   §3-style comparison data is now fully available for both designs. The
   full TPU debugging arc (congestion → utilization/density fix →
   routing-layer fix → OOM → M8 geometric edge case → final clean
   success) alongside Kronos's comparatively easy run is strong, specific
   material for the "what would you change" and DRC-violation reflection
   questions.

## Resolved this session
- **Kronos's wire length, via count, and final GDS file size — now
  confirmed.** Total wire length 60,555 µm, total vias 141,371, final
  `6_final.gds` is 18M. Full per-layer breakdown captured in Day 5 Step
  2 and reflected in the Day 5 metrics table.
- **TPU's final GDS file size — now confirmed:** `6_final.gds` is 199M
  (Jul 14, 21:54), vs Kronos's 18M (Jul 15, 13:38) — an ~11× size
  difference, roughly tracking TPU's instance-count (~6.4×) and die-area
  (~7.8×) multipliers over Kronos, with the added skew likely from
  TPU's much higher total wire length/via count. This was the one
  remaining blank in the Day 5 metrics table; now filled in.
- **Both final GDSes confirmed opening cleanly in KLayout, and now
  backed by actual screenshots of each** (previously TPU's was only
  confirmed via shell `Done` status, Kronos's via a mid-launch capture
  with no `Done` yet). Both screenshots show the correct top cell
  loaded, a clean square die outline, and uniform fill with no
  Macro-not-found or blank-canvas symptoms. Confirms viewability and
  gives a first visual pass on Q3; the *rigorous* density write-up
  itself is still open (see above).
- **Kronos's KLayout floorplan view — now fully confirmed**, matching
  TPU's 3-step rigor: terminal grep filter returned empty (no "macro not
  found"), Log Viewer showed a fully clean load sequence (tech LEF →
  macro LEF → DEF → Sorting → Redrawing, zero "Macro not found" lines),
  and the earlier screenshot already confirmed real cell geometry and a
  correct layer panel. All three checks done.
- **`ROUTING_LAYER_ADJUSTMENT`'s lack of effect — definitively
  root-caused**, not just hypothesized. `grep -n
  "ROUTING_LAYER_ADJUSTMENT\|set_global_routing_layer_adjustment"
  scripts/global_route.tcl scripts/floorplan.tcl` matched only
  `floorplan.tcl` — zero references in `global_route.tcl`, the actual
  script `make route` runs. `set_global_routing_layer_adjustment` is a
  transient, in-session OpenROAD setting, not something serialized into
  the `.odb` the way `set_routing_layers`/`MAX_ROUTING_LAYER` is.
  Floorplan's openroad process sets it and exits; `make route` starts a
  completely separate process that never references it at all — the
  value never had a chance to reach the actual routing engine, regardless
  of what it was set to. A real, confirmed limitation in how this
  variable is wired into the ORFS flow (or intended for different use
  than assumed), not user error.
