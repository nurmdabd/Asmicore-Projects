# ORFS-Native-Troubleshooting

## Purpose

This document records the issues encountered while installing and validating OpenROAD-flow-scripts (ORFS) natively with Bazel on Ubuntu 22.04 / WSL2.

The goal is to preserve troubleshooting knowledge that is not present in the standard installation documentation.

---

# Issue 1: ORFS Docker Flow Fails During CTS

## Symptoms

The flow repeatedly stopped during CTS.

Error:

```text
Error: cts.tcl, 83 child killed: illegal instruction
```

Observed on:

```text
openroad/orfs:latest
openroad/orfs:26Q2-345-gc361bcac5
```

Platforms tested:

```text
Nangate45/gcd
ASAP7/gcd
```

---

## Investigation

CTS always progressed through:

```text
repair_timing
detailed_placement
```

and then crashed near:

```tcl
check_placement -verbose
```

inside:

```text
flow/scripts/cts.tcl
```

Line:

```tcl
82 check_placement -verbose
83 }
```

The crash occurred after OpenROAD had already completed major CTS work.

---

## Attempts

Tried:

- Latest ORFS image
    
- Older ORFS image
    
- Multiple image tags
    
- Fresh flow runs
    
- Both Nangate45 and ASAP7
    

All exhibited the same failure.

---

## Conclusion

The issue appears related to:

```text
Docker ORFS image
+
WSL2 / Docker Desktop runtime
```

rather than:

```text
OpenROAD-flow-scripts
ASAP7
Nangate45
Design files
```

---

## Resolution

Abandoned Docker-based execution and switched to a native Bazel build.

Native OpenROAD completed CTS successfully.

---

# Issue 2: Missing Bazelisk

## Symptoms

Running:

```bash
bash bazel/install.sh
```

failed with:

```text
bazelisk: command not found
```

---

## Cause

The installation script invokes:

```text
bazelisk
```

directly.

Having only:

```text
bazel
```

available is insufficient.

---

## Resolution

Install Bazelisk and create both symlinks:

```bash
sudo ln -sf ~/bin/bazelisk /usr/local/bin/bazel
sudo ln -sf ~/bin/bazelisk /usr/local/bin/bazelisk
```

---

# Issue 3: Missing readline Development Files

## Symptoms

Yosys build failed with:

```text
fatal error: readline/readline.h: No such file or directory
```

---

## Cause

Missing package:

```text
libreadline-dev
```

---

## Resolution

```bash
sudo apt install libreadline-dev
```

---

# Issue 4: Missing Tcl Development Files

## Symptoms

Yosys build failed with:

```text
fatal error: tcl.h: No such file or directory
```

---

## Cause

Missing package:

```text
tcl-dev
```

---

## Resolution

```bash
sudo apt install tcl-dev
```

---

# Issue 5: Missing libffi Development Files

## Symptoms

Yosys build failed with:

```text
fatal error: ffi.h: No such file or directory
```

---

## Cause

Missing package:

```text
libffi-dev
```

---

## Resolution

```bash
sudo apt install libffi-dev
```

---

# Issue 6: Yosys Installed Into Wrong Directory

## Symptoms

Expected:

```text
tools/install/yosys
```

Observed:

```text
tools/yosys/tools/install/yosys
```

---

## Cause

The variable:

```bash
BUILD_WORKSPACE_DIRECTORY
```

was not set.

The install script therefore used a relative path.

---

## Resolution

Before running installation:

```bash
export BUILD_WORKSPACE_DIRECTORY=$HOME/EDA/OpenROAD-flow-scripts
```

Then rerun:

```bash
bash bazel/install.sh --skip-openroad --threads 8
```

---

# Issue 7: yosys-config Generated Relative Paths

## Symptoms

yosys-slang compilation failed.

Errors:

```text
fatal error: kernel/rtlil.h: No such file or directory
```

even though:

```text
rtlil.h
```

existed.

---

## Investigation

Running:

```bash
tools/install/yosys/bin/yosys-config --datdir
```

returned:

```text
./tools/install/yosys/share/yosys
```

instead of an absolute path.

Inside:

```text
tools/yosys-slang/build
```

that relative path pointed to a non-existent directory.

---

## Resolution

Patch:

```bash
YROOT="$HOME/EDA/OpenROAD-flow-scripts/tools/install/yosys"

sed -i \
"s#\./tools/install/yosys#$YROOT#g" \
tools/install/yosys/bin/yosys-config
```

Verification:

```bash
tools/install/yosys/bin/yosys-config --datdir
```

should return an absolute path.

---

# Issue 8: yosys-slang Built But Was Not Installed

## Symptoms

Build succeeded.

File existed:

```text
tools/yosys-slang/build/slang.so
```

but ORFS could not use it.

---

## Cause

Compilation completed, but installation step was never executed.

---

## Resolution

Run:

```bash
cd tools/yosys-slang

cmake --install build
```

Verify:

```bash
find tools/install/yosys -name slang.so
```

Expected:

```text
tools/install/yosys/share/yosys/plugins/slang.so
```

---

# Issue 9: OpenROAD Missing Runtime Libraries

## Symptoms

OpenROAD failed to start:

```text
error while loading shared libraries:
libxcb-cursor.so.0
```

Later:

```text
libxcb-icccm.so.4
```

---

## Cause

Missing Qt/XCB runtime dependencies.

---

## Resolution

Install required packages:

```bash
sudo apt install \
libxcb-cursor0 \
libxcb-icccm4
```

Additional XCB packages may be required depending on the system.

---

# Issue 10: KLayout 0.26.2 Crashed During GDS Merge

## Symptoms

Flow completed routing.

Failed during:

```text
6_1_merge
```

Error:

```text
Signal number: 11
```

KLayout version:

```text
0.26.2
```

---

## Investigation

Crash occurred while processing:

```text
def2stream.py
```

during final GDS generation.

The design itself was valid.

---

## Resolution

Remove Ubuntu package:

```bash
sudo apt remove klayout
```

Install newer KLayout.

Verified working version:

```text
KLayout 0.30.9
```

After upgrading:

```text
ASAP7 GDS merge completed successfully.
```

---

# Issue 11: OpenROAD GUI Warnings

## Symptoms

Messages such as:

```text
Could not find Qt platform plugin "wayland"
```

and:

```text
GUI-0010
GUI-0066
```

appeared during flow execution.

---

## Cause

These are informational GUI warnings generated while creating screenshots and reports.

---

## Resolution

No action required.

The flow completes successfully.

---

# Final Validation Results

The following completed successfully:

## Nangate45

```bash
make DESIGN_CONFIG=./designs/nangate45/gcd/config.mk
```

Generated:

```text
results/nangate45/gcd/base/6_final.gds
```

---

## ASAP7

```bash
make DESIGN_CONFIG=./designs/asap7/gcd/config.mk
```

Generated:

```text
results/asap7/gcd/base/6_final.gds
```

---

# Known Good Tool Versions

```text
OpenROAD : bazel-nostamp
Yosys    : 0.64 (git 8449dd470)
KLayout  : 0.30.9
```

---

# Key Lesson Learned

The original blocker was not:

- ASAP7
    
- Nangate45
    
- ORFS flow scripts
    
- CTS configuration
    

The root problem was the Docker-based execution environment.

After moving to a native Bazel build, both reference designs completed successfully through final GDS generation.