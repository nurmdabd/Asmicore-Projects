# 

## OpenROAD-flow-scripts (ORFS) Native Installation Using Bazel

### Overview

This guide installs OpenROAD-flow-scripts (ORFS) natively on Ubuntu 22.04 or WSL2 using Bazel. The resulting environment includes:

- OpenROAD
    
- Yosys
    
- yosys-slang
    
- KLayout
    
- OpenROAD-flow-scripts (ORFS)
    

The installation is performed without Docker.

---

# 1. System Requirements

Recommended:

- Ubuntu 22.04 LTS
    
- WSL2 or Native Linux
    
- x86_64 CPU
    
- 8 GB RAM minimum
    
- 50 GB free disk space
    

Verify architecture:

```bash
uname -m
```

Expected:

```text
x86_64
```

---

# 2. Clone OpenROAD-flow-scripts

```bash
git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git

cd OpenROAD-flow-scripts
```

If the repository is already cloned:

```bash
git submodule update --init --recursive
```

Verify:

```bash
git submodule status
```

Expected major submodules:

```text
tools/OpenROAD
tools/yosys
tools/yosys-slang
tools/kepler-formal
```

---

# 3. Install Build Dependencies

Update package lists:

```bash
sudo apt update
```

Install required packages:

```bash
sudo apt install -y \
    build-essential \
    git \
    cmake \
    pkg-config \
    bison \
    flex \
    gawk \
    tcl \
    tcl-dev \
    libreadline-dev \
    libffi-dev \
    zlib1g-dev \
    openjdk-17-jdk
```

Verify:

```bash
which bison
which flex
which cmake
which tclsh

java -version
```

---

# 4. Install Bazelisk

Create a local binary directory:

```bash
mkdir -p ~/bin
```

Download Bazelisk:

```bash
curl -L \
https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 \
-o ~/bin/bazelisk
```

Make executable:

```bash
chmod +x ~/bin/bazelisk
```

Create system links:

```bash
sudo ln -sf ~/bin/bazelisk /usr/local/bin/bazel
sudo ln -sf ~/bin/bazelisk /usr/local/bin/bazelisk
```

Verify:

```bash
bazel version
bazelisk version
```

---

# 5. Build OpenROAD, Yosys and yosys-slang

Move to the repository root:

```bash
cd ~/EDA/OpenROAD-flow-scripts
```

Set workspace location:

```bash
export BUILD_WORKSPACE_DIRECTORY=$HOME/EDA/OpenROAD-flow-scripts
```

Run the installation script:

```bash
bash bazel/install.sh --threads 8
```

The build may take a significant amount of time depending on CPU performance.

Successful installation should create:

```text
tools/install/OpenROAD
tools/install/yosys
```

---

# 6. Verify Installed Components

OpenROAD:

```bash
tools/install/OpenROAD/bin/openroad -version
```

Expected output similar to:

```text
bazel-nostamp
```

Yosys:

```bash
tools/install/yosys/bin/yosys -V
```

Expected output similar to:

```text
Yosys 0.64
```

Verify yosys-slang installation:

```bash
find tools/install/yosys -name "slang.so"
```

Expected:

```text
tools/install/yosys/share/yosys/plugins/slang.so
```

---

# 7. Install KLayout

Install a recent KLayout release.

Verify installation:

```bash
klayout -v
```

Expected output similar to:

```text
KLayout 0.30.x
```

---

# 8. Activate ORFS Environment

From repository root:

```bash
cd ~/EDA/OpenROAD-flow-scripts

source env.sh
```

Verify:

```bash
which openroad
which yosys
```

Expected:

```text
.../tools/install/OpenROAD/bin/openroad
.../tools/install/yosys/bin/yosys
```

---

# 9. Validate Using Nangate45 GCD

Move into the flow directory:

```bash
cd flow
```

Run:

```bash
make DESIGN_CONFIG=./designs/nangate45/gcd/config.mk
```

Expected result:

```text
results/nangate45/gcd/base/6_final.gds
```

---

# 10. Validate Using ASAP7 GCD

Run:

```bash
make DESIGN_CONFIG=./designs/asap7/gcd/config.mk
```

Expected result:

```text
results/asap7/gcd/base/6_final.gds
```

---

# 11. Tool Version Verification

Check installed versions:

```bash
tools/install/OpenROAD/bin/openroad -version

tools/install/yosys/bin/yosys -V

klayout -v
```

Example:

```text
OpenROAD : bazel-nostamp
Yosys    : 0.64
KLayout  : 0.30.9
```

---

# 12. Save Build Revisions

Record exact commits for reproducibility:

```bash
git -C tools/OpenROAD rev-parse HEAD

git -C tools/yosys rev-parse HEAD

git -C tools/yosys-slang rev-parse HEAD
```

Store these hashes alongside project documentation.

---

# Expected Final Directory Structure

```text
OpenROAD-flow-scripts/
├── flow/
├── tools/
│   ├── OpenROAD/
│   ├── yosys/
│   ├── yosys-slang/
│   └── install/
│       ├── OpenROAD/
│       └── yosys/
└── env.sh
```

---

# Success Criteria

The installation is considered successful when:

- OpenROAD launches successfully.
    
- Yosys launches successfully.
    
- slang.so exists under the Yosys plugins directory.
    
- KLayout launches successfully.
    
- Nangate45 GCD completes.
    
- ASAP7 GCD completes.
    
- Final GDS files are generated for both test designs.