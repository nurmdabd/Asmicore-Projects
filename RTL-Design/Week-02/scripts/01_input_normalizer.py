#!/usr/bin/env python3
"""
01_input_normalizer.py

Input Normalization Stage for RTL Analysis Pipeline

Responsibilities:
    - Scan RTL repository
    - Classify files
    - Extract module declarations
    - Build dependency graph
    - Identify candidate top modules
    - Detect duplicate modules
    - Generate manifest and reports

Usage:
    python3 scripts/01_input_normalizer.py rtl/UART
"""

from pathlib import Path
from collections import defaultdict
import csv
import re
import sys

# ============================================================
# Configuration
# ============================================================

RTL_EXTENSIONS = {".v", ".sv"}
HEADER_EXTENSIONS = {".vh", ".svh"}

SCRIPT_DIR = Path(__file__).resolve().parent

OUTPUT_DIR = SCRIPT_DIR.parent / "outputs" / "01_input_normalizer"

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
}

# ============================================================
# Regex
# ============================================================

MODULE_RE = re.compile(
    r"^\s*module\s+([a-zA-Z_][a-zA-Z0-9_]*)",
    re.MULTILINE,
)

INSTANTIATION_RE = re.compile(
    r"^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s+" r"[a-zA-Z_][a-zA-Z0-9_]*\s*\(",
    re.MULTILINE,
)

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

        if match not in SV_KEYWORDS:
            insts.append(match)

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

                module_name = modules[0]

                module_to_file[module_name] = path

                duplicate_modules[module_name].append(path)

            insts = extract_instantiations(path)

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

        dependency = ""

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

    for module in module_to_file:

        has_children = module in parent_child and len(parent_child[module]) > 0

        instantiated_elsewhere = module in instantiated_modules

        if has_children and not instantiated_elsewhere:
            candidates.append(module)

    return sorted(candidates)


# ============================================================
# Module Roles
# ============================================================


def determine_module_roles(
    module_to_file,
    instantiated_modules,
    top_candidates,
):

    roles = {}

    for module in module_to_file:

        if module in top_candidates:
            roles[module] = "TOP"

        elif module in instantiated_modules:
            roles[module] = "SUBMODULE"

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

    manifest_file = OUTPUT_DIR / "uart_file_manifest.csv"

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

        fp.write("Ready for " "sv_preprocessor.py\n")


# ============================================================
# Main
# ============================================================


def main():

    if len(sys.argv) != 2:

        print(
            "\n"
            "============================================================\n"
            " INPUT NORMALIZER ERROR\n"
            "============================================================\n\n"
            "Missing required RTL repository path.\n\n"
            "Usage:\n"
            "    python3 01_input_normalizer.py <rtl_root>\n\n"
            "Example:\n"
            "    python3 scripts/01_input_normalizer.py rtl/UART\n"
        )
        sys.exit(1)

    rtl_root = Path(sys.argv[1])

    if not rtl_root.exists():

        print(f"ERROR: {rtl_root} not found")
        sys.exit(1)

    (
        entries,
        module_to_file,
        instantiated_modules,
        parent_child,
        duplicate_modules,
    ) = scan_repository(rtl_root)

    candidates = identify_top_modules(
        module_to_file,
        instantiated_modules,
        parent_child,
    )

    module_roles = determine_module_roles(
        module_to_file,
        instantiated_modules,
        candidates,
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

    print("\nInput normalization complete.")

    print(f"Results written to:\n" f"{OUTPUT_DIR}\n")


if __name__ == "__main__":
    main()
