#!/usr/bin/env python3
"""
rtl_design_analyzer.py

RTL Design Analyzer

Responsibilities:
    - Scan RTL repository
    - Classify files
    - Extract module declarations
    - Build dependency graph
    - Identify candidate top modules
    - Detect duplicate modules
    - Generate manifest and reports

Usage:
    python3 scripts/rtl_design_analyzer.py
"""

from pathlib import Path
from collections import defaultdict
import csv
import re
import sys
import json
from datetime import datetime

# ============================================================
# Configuration
# ============================================================
RTL_EXTENSIONS = {".v", ".sv"}
HEADER_EXTENSIONS = {".vh", ".svh"}

SCRIPT_DIR = Path(__file__).resolve().parent

OUTPUT_DIR = SCRIPT_DIR.parent / "analysis" / "day01_design_analysis"
rtl_root = SCRIPT_DIR.parent.parent.parent / "rtl" / "tiny-tpu"

SV_KEYWORDS = {
    "module",
    "endmodule",
    "always",
    "always_ff",
    "always_comb",
    "always_latch",
    "if",
    "else",
    "case",
    "endcase",
    "for",
    "foreach",
    "while",
    "assign",
    "generate",
    "endgenerate",
    "begin",
    "end",
    "initial",
    "logic",
    "wire",
    "reg",
    "integer",
    "parameter",
    "localparam",
    "generate",
    "endgenerate",
}

EXCLUDED_DIRS = {
    "test",
    "sva",
    "sim",
    "verification",
    "xor_demo",
    "mnist_demo",
    "tiny-tpu-hardened"
}

# ============================================================
# Regex
# ============================================================
MODULE_RE = re.compile(
    r"^\s*module\s+([a-zA-Z_][a-zA-Z0-9_]*)",
    re.MULTILINE,
)

INSTANTIATION_RE = re.compile(
    r"^\s*"
    r"([a-zA-Z_][a-zA-Z0-9_]*)"
    r"\s*(?:#\s*\([^;]*?\))?"
    r"\s+[a-zA-Z_][a-zA-Z0-9_]*"
    r"\s*\(",
    re.MULTILINE | re.DOTALL,
)

PORT_RE = re.compile(
    r"(input|output|inout).*?([a-zA-Z_][a-zA-Z0-9_]*)",
    re.MULTILINE
)

# ============================================================
# Port Extraction
# ============================================================
def extract_ports(filepath):

    try:
        text = filepath.read_text(errors="ignore")
    except Exception:
        return []

    return PORT_RE.findall(text)


#============================================================
# Clock and Reset Detection
#============================================================
def detect_clock_reset(ports):

    clocks = []
    resets = []

    for direction, name in ports:

        lower = name.lower()

        if "clk" in lower or "clock" in lower:
            clocks.append(name)

        if "rst" in lower or "reset" in lower:
            resets.append(name)

    return clocks, resets

#===========================================================
# Module Header Extraction
#===========================================================
def extract_module_header(filepath):

    text = filepath.read_text(errors="ignore")

    match = re.search(
        r"module\s+\w+\s*(?:#\s*\(.*?\))?\s*\((.*?)\)\s*;",
        text,
        re.DOTALL,
    )

    if not match:
        return ""

    return match.group(1)


#===========================================================
# Clock and Reset Detection from Module Header
#===========================================================
def detect_clock_reset_from_file(filepath):

    header = extract_module_header(filepath)

    header_lower = header.lower()

    clocks = []
    resets = []

    for signal in re.findall(
        r"[a-zA-Z_][a-zA-Z0-9_]*",
        header,
    ):

        lower = signal.lower()

        if "clk" in lower or "clock" in lower:
            clocks.append(signal)

        if "rst" in lower or "reset" in lower:
            resets.append(signal)

    return sorted(set(clocks)), sorted(set(resets))

# ============================================================
# File Classification
# ============================================================
def classify_file(path: Path) -> str:

    if path.name == "Makefile":
        return "BUILD_SCRIPT"

    if path.suffix in HEADER_EXTENSIONS:
        return "HEADER"

    if path.suffix == ".sv" and path.stem.endswith("_pkg"):
        return "PACKAGE"

    if path.suffix in RTL_EXTENSIONS:

        if any(part.lower() == "tb" for part in path.parts):
            return "TESTBENCH"

        return "RTL_SOURCE"

    if path.suffix == ".md":
        return "DOCUMENTATION"

    if path.suffix.lower() in {
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".bmp",
    }:
        return "IMAGE"

    return "UNKNOWN"


# ============================================================
# Module Extraction
# ============================================================
def extract_modules(filepath: Path):

    try:
        text = filepath.read_text(errors="ignore")
    except Exception:
        return []

    return MODULE_RE.findall(text)


def extract_instantiations(filepath: Path):

    try:
        text = filepath.read_text(errors="ignore")
    except Exception:
        return []

    insts = []

    for match in INSTANTIATION_RE.findall(text):

        if match in SV_KEYWORDS:
            continue

        if match == "module":
            continue

        insts.append(match)
    # print(f"\n[DEBUG] {filepath.name}")
    # print(sorted(set(insts)))   

    return insts


# ============================================================
# Repository Scan
# ============================================================
def scan_repository(root_dir: Path):

    file_entries = []

    module_to_file = {}

    duplicate_modules = defaultdict(list)

    instantiated_modules = set()

    parent_child = defaultdict(list)

    for path in sorted(root_dir.rglob("*")):

        if any(part in EXCLUDED_DIRS for part in path.parts):
            continue

        if not path.is_file():
            continue

        category = classify_file(path)

        module_name = ""

        if category in {
            "RTL_SOURCE",
            "TESTBENCH",
            "PACKAGE",
        }:

            modules = extract_modules(path)

            if modules:

                for module_name in modules:
                    module_to_file[module_name] = path
                    duplicate_modules[module_name].append(path)

            insts = extract_instantiations(path)

            if category == "RTL_SOURCE":

                for inst in insts:

                    instantiated_modules.add(inst)

                    if module_name:
                        parent_child[module_name].append(inst)

        processing_scope = (
            "INCLUDE"
            if category
            in {
                "RTL_SOURCE",
                "PACKAGE",
                "HEADER",
            }
            else "EXCLUDE"
        )

        dependency = "-"

        if module_name:
            dependency = ";".join(
                sorted(
                    set(
                        parent_child.get(
                            module_name,
                            [],
                        )
                    )
                )
            )

        file_entries.append(
            {
                "relative_path": str(path.relative_to(root_dir)),
                "file_name": path.name,
                "file_category": category,
                "file_extension": path.suffix,
                "module_name": module_name,
                "dependency": dependency,
                "processing_scope": processing_scope,
                "remarks": "",
            }
        )

    return (
        file_entries,
        module_to_file,
        instantiated_modules,
        parent_child,
        duplicate_modules,
    )


# ============================================================
# Top Module Detection
# ============================================================
def identify_top_modules(
    module_to_file,
    instantiated_modules,
    parent_child,
):

    candidates = []

    excluded_testbenches = []

    TB_MODULE_PATTERNS = (
        "_tb",
        "tb_",
        "_test",
        "test_",
    )

    TB_DIRECTORY_NAMES = {
        "tb",
        "testbench",
        "testbenches",
        "sim",
        "simulation",
        "dv",
        "verification",
    }

    for module in module_to_file:

        source_file = module_to_file[module]

        has_children = module in parent_child and len(parent_child[module]) > 0

        instantiated_elsewhere = module in instantiated_modules

        module_lower = module.lower()

        is_tb_module = any(pattern in module_lower for pattern in TB_MODULE_PATTERNS)

        is_tb_directory = any(
            part.lower() in TB_DIRECTORY_NAMES for part in source_file.parts
        )

        if is_tb_module or is_tb_directory:

            excluded_testbenches.append(module)

            continue

        if has_children and not instantiated_elsewhere:
            candidates.append(module)

    return (
        sorted(candidates),
        sorted(excluded_testbenches),
    )


# ============================================================
# Module Roles
# ============================================================
def determine_module_roles(
    module_to_file,
    instantiated_modules,
    top_candidates,
    excluded_testbenches,
):

    roles = {}

    for module in module_to_file:

        if module in top_candidates:
            roles[module] = "TOP"

        elif module in instantiated_modules:
            roles[module] = "SUBMODULE"

        elif module in excluded_testbenches:
            roles[module] = "TESTBENCH"

        else:
            roles[module] = "UNKNOWN"

    return roles


# ============================================================
# Reports
# ============================================================
def write_manifest(entries):

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )

    summary_file = OUTPUT_DIR / "design_summary.json"
    manifest_file = OUTPUT_DIR / "rtl_file_manifest.csv"
    with manifest_file.open(
        "w",
        newline="",
    ) as fp:

        writer = csv.DictWriter(
            fp,
            fieldnames=[
                "relative_path",
                "file_name",
                "file_category",
                "file_extension",
                "module_name",
                "module_role",
                "dependency",
                "processing_scope",
                "remarks",
            ],
        )

        writer.writeheader()

        for row in entries:
            writer.writerow(row)


def write_top_module_report(
    candidates,
    module_to_file,
    parent_child,
):

    report_file = OUTPUT_DIR / "candidate_top_modules.md"

    with report_file.open("w") as fp:

        fp.write("# Candidate Top Modules\n\n")

        if not candidates:

            fp.write("No candidate top modules found.\n")
            return

        for mod in candidates:

            fp.write(f"## {mod}\n\n")

            fp.write(f"Source File: " f"{module_to_file[mod]}\n\n")

            fp.write("Instantiated Submodules:\n")

            for child in sorted(
                set(
                    parent_child.get(
                        mod,
                        [],
                    )
                )
            ):
                fp.write(f"- {child}\n")

            fp.write("\nConfidence: HIGH\n\n")


def write_notes(
    root_dir,
    entries,
    candidates,
    duplicate_modules,
):

    notes_file = OUTPUT_DIR / "input_normalization_notes.md"

    category_counts = defaultdict(int)

    for row in entries:
        category_counts[row["file_category"]] += 1

    unknown_files = [
        row["relative_path"] for row in entries if row["file_category"] == "UNKNOWN"
    ]

    duplicates = {
        module: paths for module, paths in duplicate_modules.items() if len(paths) > 1
    }

    with notes_file.open("w") as fp:
        fp.write("# Input Normalization Notes\n\n")
        fp.write(f"Repository: " f"{root_dir}\n\n")
        fp.write("## Summary\n\n")
        fp.write(f"Total Files: " f"{len(entries)}\n\n")
        fp.write("## File Categories\n\n")
        for category, count in sorted(category_counts.items()):
            fp.write(f"- {category}: " f"{count}\n")

        fp.write("\n")
        fp.write("## Detected Top Modules\n\n")

        if candidates:
            for mod in candidates:
                fp.write(f"- {mod}\n")

        else:
            fp.write("None\n")

        fp.write("\n")
        fp.write("## Suspicious Files\n\n")

        if unknown_files:
            for item in unknown_files:
                fp.write(f"- {item}\n")

        else:
            fp.write("None\n")

        fp.write("\n")
        fp.write("## Duplicate Module Definitions\n\n")

        if duplicates:
            for module, paths in duplicates.items():
                fp.write(f"{module}\n")
                for path in paths:
                    fp.write(f"  - {path}\n")

        else:
            fp.write("None\n")

        fp.write("\n")
        fp.write("## Normalization Status\n\n")
        fp.write("Repository scan completed successfully.\n")
        fp.write("Ready for " "sv_preprocessor.py\n\n")
        fp.write("Pipeline Metadata:\n")
        fp.write("- pipeline_metadata.json\n")


# ============================================================
# Pipeline Metadata
# ============================================================
def write_pipeline_metadata(
    root_dir,
    candidates,
    excluded_testbenches,
):

    metadata_file = OUTPUT_DIR / "pipeline_metadata.json"

    metadata = {
        "pipeline_version": "1.0",
        "design_name": root_dir.name,
        "rtl_root": str(root_dir.resolve()),
        "generated_by": "01_input_normalizer.py",
        "current_stage": "input_normalizer",
        "top_modules": candidates,
        "excluded_testbenches": (excluded_testbenches),
        "timestamp": datetime.now().isoformat(),
    }

    with metadata_file.open("w") as fp:

        json.dump(
            metadata,
            fp,
            indent=4,
        )


def write_design_summary(
    module_to_file,
    candidates,
):

    top_module = ""

    for candidate in candidates:

        if candidate.lower() == "tpu":
            top_module = candidate
            break

    if not top_module and candidates:
        top_module = candidates[0]

    clocks = []
    resets = []

    if top_module:

        top_file = module_to_file[top_module]

        clocks, resets = detect_clock_reset_from_file(
            top_file
        )

    summary = {
        "design_name": "tiny-tpu",
        "top_module": top_module,
        "clock_ports": clocks,
        "reset_ports": resets,
        "module_count": len(module_to_file),
    }

    with open(
        OUTPUT_DIR / "design_summary.json",
        "w",
    ) as fp:

        json.dump(
            summary,
            fp,
            indent=4,
        )

# ============================================================
# Main
# ============================================================
def main():

    # if len(sys.argv) != 2:

    #     print(
    #         "\n"
    #         "============================================================\n"
    #         " SV PREPROCESSOR ERROR\n"
    #         "============================================================\n\n"
    #         "Missing required manifest file.\n\n"
    #         "Usage:\n"
    #         "    python3 02_sv_preprocessor.py "
    #         "<uart_file_manifest.csv>\n\n"
    #         "Example:\n"
    #         "    python3 scripts/02_sv_preprocessor.py outputs/01_input_normalizer/"
    #         "uart_file_manifest.csv\n"
    #     )
    #     sys.exit(1)

    # rtl_root = Path(sys.argv[1])

    # if not rtl_root.exists():

    #     print(f"ERROR: {rtl_root} not found")
    #     sys.exit(1)

    (
        entries,
        module_to_file,
        instantiated_modules,
        parent_child,
        duplicate_modules,
    ) = scan_repository(rtl_root)

    (
        candidates,
        excluded_testbenches,
    ) = identify_top_modules(
        module_to_file,
        instantiated_modules,
        parent_child,
    )

    module_roles = determine_module_roles(
        module_to_file,
        instantiated_modules,
        candidates,
        excluded_testbenches,
    )

    for row in entries:

        module_name = row["module_name"]

        row["module_role"] = module_roles.get(
            module_name,
            "",
        )

    write_manifest(entries)

    write_top_module_report(
        candidates,
        module_to_file,
        parent_child,
    )

    write_notes(
        rtl_root,
        entries,
        candidates,
        duplicate_modules,
    )

    write_pipeline_metadata(
        rtl_root,
        candidates,
        excluded_testbenches,
    )

    write_design_summary(
        module_to_file,
        candidates,
    )

    print("\n=== MODULES FOUND ===")
    for module in sorted(module_to_file):
        print(module)

    print("\n=== TOP MODULE CANDIDATES ===")

    detected_top = ""

    for candidate in candidates:

        if candidate.lower() == "tpu":
            detected_top = candidate
            break

    if not detected_top and candidates:
        detected_top = candidates[0]

    print("\nDetected Top Module:")
    print(detected_top if detected_top else "NONE")

    print("\n=== PARENT CHILD RELATIONSHIP ===")
    for parent, children in parent_child.items():
        print(f"{parent} -> {sorted(set(children))}")

    tpu_file = module_to_file.get(detected_top)

    if tpu_file:

        clocks, resets = detect_clock_reset_from_file(
            tpu_file
        )

        print("\n=== TPU CLOCK RESET ===")
        print("Clock :", clocks)
        print("Reset :", resets)

    print("\nInput normalization complete.")

    print(f"Results written to:\n" f"{OUTPUT_DIR}\n")


if __name__ == "__main__":
    main()
