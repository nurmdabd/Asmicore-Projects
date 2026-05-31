#!/usr/bin/env python3
"""
02_sv_preprocessor.py

SystemVerilog Preprocessing Stage

Objective:
    - Load normalized RTL manifest
    - Load pipeline metadata
    - Detect preprocessing directives
    - Build dependency information
    - Generate flattened RTL
    - Generate preprocessing reports
    - Propagate pipeline metadata

Outputs:
    outputs/02_sv_preprocessor/
        ├── uart_preprocessed.sv
        ├── preprocess_dependency_map.md
        ├── preprocess_issues_log.md
        └── pipeline_metadata.json
"""

from __future__ import annotations

import csv
import json
import re
import sys

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path


# ============================================================
# Configuration
# ============================================================

SCRIPT_DIR = Path(__file__).resolve().parent

OUTPUT_DIR = (
    SCRIPT_DIR.parent
    / "outputs"
    / "02_sv_preprocessor"
)

OUTPUT_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


# ============================================================
# Regex
# ============================================================

INCLUDE_RE = re.compile(
    r'^\s*`include\s+"([^"]+)"',
    re.MULTILINE,
)

DEFINE_RE = re.compile(
    r"^\s*`define\s+([a-zA-Z_][a-zA-Z0-9_]*)",
    re.MULTILINE,
)

IFDEF_RE = re.compile(
    r"^\s*`(?:ifdef|ifndef|elsif)\s+",
    re.MULTILINE,
)

PACKAGE_IMPORT_RE = re.compile(
    r"([a-zA-Z_][a-zA-Z0-9_]*)::",
)

PARAMETER_RE = re.compile(
    r"""
    (?:parameter|localparam)
    \s+
    (?:\[[^\]]+\]\s+)?
    ([a-zA-Z_][a-zA-Z0-9_]*)
    \s*=\s*
    ([^;]+)
    """,
    re.VERBOSE,
)


# ============================================================
# Data Structures
# ============================================================

@dataclass
class PreprocessResult:

    include_count: int = 0
    macro_count: int = 0
    conditional_count: int = 0
    package_count: int = 0

    missing_includes: list[str] = field(default_factory=list)
    unresolved_macros: list[str] = field(default_factory=list)

    include_map: dict[str, list[str]] = field(default_factory=dict)
    package_map: dict[str, list[str]] = field(default_factory=dict)

    parameters: dict[str, str] = field(default_factory=dict)

    processed_files: list[str] = field(default_factory=list)


# ============================================================
# Manifest / Metadata
# ============================================================

def load_manifest(manifest_file: Path):

    entries = []

    with manifest_file.open(
        "r",
        newline="",
        encoding="utf-8",
    ) as fp:

        reader = csv.DictReader(fp)

        for row in reader:

            if row.get("processing_scope") != "INCLUDE":
                continue

            category = row.get("file_category", "")

            if category not in {
                "RTL_SOURCE",
                "HEADER",
                "PACKAGE",
            }:
                continue

            entries.append(row)

    return entries


def load_metadata(metadata_file: Path):

    with metadata_file.open(
        "r",
        encoding="utf-8",
    ) as fp:

        return json.load(fp)


# ============================================================
# Analysis
# ============================================================

def analyze_file(
    filepath: Path,
    result: PreprocessResult,
):

    text = filepath.read_text(
        encoding="utf-8",
        errors="ignore",
    )

    relative_name = str(filepath)

    includes = INCLUDE_RE.findall(text)

    result.include_count += len(includes)

    result.include_map[relative_name] = includes

    for include_file in includes:

        include_path = (
            filepath.parent
            / include_file
        )

        if not include_path.exists():
            result.missing_includes.append(
                f"{filepath.name}: {include_file}"
            )

    macros = DEFINE_RE.findall(text)

    result.macro_count += len(macros)

    conditionals = IFDEF_RE.findall(text)

    result.conditional_count += len(conditionals)

    packages = sorted(
        set(
            PACKAGE_IMPORT_RE.findall(text)
        )
    )

    result.package_count += len(packages)

    result.package_map[relative_name] = packages

    for name, value in PARAMETER_RE.findall(text):

        result.parameters[name] = value.strip()


# ============================================================
# Flatten RTL
# ============================================================

def generate_flattened_rtl(
    rtl_root: Path,
    entries,
):

    output_file = (
        OUTPUT_DIR
        / "uart_preprocessed.sv"
    )

    with output_file.open(
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write(
            "// ============================================================\n"
        )
        fp.write(
            "// PREPROCESSED RTL\n"
        )
        fp.write(
            "// Generated by 02_sv_preprocessor.py\n"
        )
        fp.write(
            "// ============================================================\n\n"
        )

        for row in entries:

            relative_path = row["relative_path"]

            source_file = (
                rtl_root
                / relative_path
            )

            fp.write(
                "// ============================================================\n"
            )

            fp.write(
                f"// File: {relative_path}\n"
            )

            fp.write(
                "// ============================================================\n\n"
            )

            text = source_file.read_text(
                encoding="utf-8",
                errors="ignore",
            )

            fp.write(text)

            fp.write("\n\n")

    return output_file


# ============================================================
# Reports
# ============================================================

def write_dependency_map(
    entries,
    result: PreprocessResult,
):

    report_file = (
        OUTPUT_DIR
        / "preprocess_dependency_map.md"
    )

    with report_file.open(
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write(
            "# Preprocess Dependency Map\n\n"
        )

        fp.write(
            "## Processed Files\n\n"
        )

        fp.write(
            "| File | Type |\n"
        )

        fp.write(
            "|------|------|\n"
        )

        for row in entries:

            fp.write(
                f"| {row['relative_path']} | "
                f"{row['file_category']} |\n"
            )

        fp.write("\n")

        fp.write(
            "## Include Relationships\n\n"
        )

        if result.include_count == 0:

            fp.write(
                "No include directives found.\n\n"
            )

        else:

            for source, includes in result.include_map.items():

                fp.write(
                    f"### {source}\n"
                )

                for item in includes:
                    fp.write(
                        f"- {item}\n"
                    )

                fp.write("\n")

        fp.write(
            "## Package Dependencies\n\n"
        )

        if result.package_count == 0:

            fp.write(
                "No package dependencies found.\n"
            )

        else:

            for source, packages in result.package_map.items():

                if not packages:
                    continue

                fp.write(
                    f"### {source}\n"
                )

                for pkg in packages:
                    fp.write(
                        f"- {pkg}\n"
                    )

                fp.write("\n")


def write_issue_log(
    result: PreprocessResult,
):

    report_file = (
        OUTPUT_DIR
        / "preprocess_issues_log.md"
    )

    with report_file.open(
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write(
            "# Preprocess Issues Log\n\n"
        )

        fp.write(
            "## Summary\n\n"
        )

        fp.write(
            f"- Include Directives Found: "
            f"{result.include_count}\n"
        )

        fp.write(
            f"- Macro Definitions Found: "
            f"{result.macro_count}\n"
        )

        fp.write(
            f"- Conditional Blocks Found: "
            f"{result.conditional_count}\n"
        )

        fp.write(
            f"- Package Dependencies Found: "
            f"{result.package_count}\n\n"
        )

        fp.write(
            "## Parameters\n\n"
        )

        if not result.parameters:

            fp.write(
                "No parameters detected.\n\n"
            )

        else:

            for name, value in sorted(
                result.parameters.items()
            ):

                fp.write(
                    f"- {name} = {value}\n"
                )

            fp.write("\n")

        fp.write(
            "## Issues\n\n"
        )

        issues_found = False

        if result.missing_includes:

            issues_found = True

            fp.write(
                "### Missing Include Files\n\n"
            )

            for item in result.missing_includes:

                fp.write(
                    f"- {item}\n"
                )

            fp.write("\n")

        if result.unresolved_macros:

            issues_found = True

            fp.write(
                "### Unresolved Macros\n\n"
            )

            for item in result.unresolved_macros:

                fp.write(
                    f"- {item}\n"
                )

            fp.write("\n")

        if not issues_found:

            fp.write(
                "No preprocessing issues detected.\n"
            )


# ============================================================
# Metadata
# ============================================================

def write_pipeline_metadata(
    previous_metadata,
    result: PreprocessResult,
):

    metadata_file = (
        OUTPUT_DIR
        / "pipeline_metadata.json"
    )

    metadata = dict(previous_metadata)

    metadata["previous_stage"] = (
        metadata.get(
            "current_stage",
            "input_normalizer",
        )
    )

    metadata["current_stage"] = (
        "sv_preprocessor"
    )

    metadata["generated_by"] = (
        "02_sv_preprocessor.py"
    )

    metadata["preprocessed_files"] = (
        result.processed_files
    )

    metadata["flattened_output"] = (
        "uart_preprocessed.sv"
    )

    metadata["include_count"] = (
        result.include_count
    )

    metadata["macro_count"] = (
        result.macro_count
    )

    metadata["conditional_count"] = (
        result.conditional_count
    )

    metadata["package_count"] = (
        result.package_count
    )

    metadata["parameters"] = (
        result.parameters
    )

    metadata["timestamp"] = (
        datetime.now().isoformat()
    )

    with metadata_file.open(
        "w",
        encoding="utf-8",
    ) as fp:

        json.dump(
            metadata,
            fp,
            indent=4,
        )


# ============================================================
# Main
# ============================================================

def main():

    if len(sys.argv) != 2:

        print(
            "\n"
            "============================================================\n"
            " LEXER TOKENIZER ERROR\n"
            "============================================================\n\n"
            "Missing required preprocessed RTL file.\n\n"
            "Usage:\n"
            "    python3 03_lexer_tokenizer.py "
            "<uart_preprocessed.sv>\n\n"
            "Example:\n"
            "    python3 scripts/03_lexer_tokenizer.py \\\n"
            "        outputs/02_sv_preprocessor/"
            "uart_preprocessed.sv\n"
        )

        sys.exit(1)

    manifest_file = Path(
        sys.argv[1]
    ).resolve()

    if not manifest_file.exists():
        print(
            "\n"
            "============================================================\n"
            " SV PREPROCESSOR ERROR\n"
            "============================================================\n\n"
            f"Manifest file not found:\n"
            f"    {manifest_file}\n"
        )
        sys.exit(1)



    metadata_file = (
        manifest_file.parent
        / "pipeline_metadata.json"
    )

    if not metadata_file.exists():
        print(
            "\n"
            "============================================================\n"
            " SV PREPROCESSOR ERROR\n"
            "============================================================\n\n"
            f"Metadata file not found:\n"
            f"    {metadata_file}\n\n"
            "Run input_normalizer.py first.\n"
        )
        sys.exit(1)

    entries = load_manifest(
        manifest_file
    )

    metadata = load_metadata(
        metadata_file
    )

    rtl_root = Path(
        metadata["rtl_root"]
    )

    result = PreprocessResult()

    for row in entries:

        relative_path = (
            row["relative_path"]
        )

        source_file = (
            rtl_root
            / relative_path
        )

        if not source_file.exists():
            continue

        analyze_file(
            source_file,
            result,
        )

        result.processed_files.append(
            relative_path
        )

    generate_flattened_rtl(
        rtl_root,
        entries,
    )

    write_dependency_map(
        entries,
        result,
    )

    write_issue_log(
        result,
    )

    write_pipeline_metadata(
        metadata,
        result,
    )

    print(
        "\n"
        "SV preprocessing complete.\n"
        "\n"
        "Results written to:\n"
        f"{OUTPUT_DIR.resolve()}\n"
    )


if __name__ == "__main__":
    main()
