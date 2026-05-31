# ============================================================
# Imports
# ============================================================
import json
from pathlib import Path
from datetime import datetime, timezone

# ============================================================
# Script Constants
# ============================================================
SCRIPT_NAME = "06_clock_reset_analyzer.py"
SCHEMA_VERSION = "0.1"

CURRENT_STAGE = "clock_reset_analyzer"
PREVIOUS_STAGE = "ir_builder"

ACTIVE_LOW_SUFFIXES = (
    "_n",
    "_b",
)

# ============================================================
# Directory Configuration
# ============================================================
PROJECT_ROOT = Path(__file__).resolve().parent.parent

INPUT_DIR = (
    PROJECT_ROOT
    / "outputs"
    / "05_ir_builder"
)

OUTPUT_DIR = (
    PROJECT_ROOT
    / "outputs"
    / "06_clock_reset_analyzer"
)

IR_FILE = INPUT_DIR / "uart_ir.json"

METADATA_FILE = (
    INPUT_DIR
    / "pipeline_metadata.json"
)

# ============================================================
# Utility Functions
# ============================================================


def ensure_output_directory():

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True,
    )


def load_json(
    filepath,
):

    with open(
        filepath,
        "r",
        encoding="utf-8",
    ) as fp:

        return json.load(fp)


def write_json(
    filepath,
    data,
):

    with open(
        filepath,
        "w",
        encoding="utf-8",
    ) as fp:

        json.dump(
            data,
            fp,
            indent=4,
        )


def timestamp():

    return datetime.now(
        timezone.utc
    ).isoformat()


# ============================================================
# Analysis Functions
# ============================================================


def get_ports_by_role(
    module,
    role,
):

    result = []

    for port in module.get(
        "ports",
        [],
    ):

        if port.get("role") == role:

            result.append(port)

    return result


def determine_reset_polarity(
    reset_name,
):

    name = reset_name.lower()

    for suffix in ACTIVE_LOW_SUFFIXES:

        if name.endswith(suffix):

            return "active_low"

    return "active_high"


def is_sequential_block(
    sensitivity,
):

    sensitivity = (
        sensitivity or ""
    ).lower()

    return (
        "posedge" in sensitivity
        or "negedge" in sensitivity
    )


def determine_reset_type(
    always_blocks,
    reset_names,
):

    sequential_found = False

    for block in always_blocks:

        sensitivity = (
            block.get(
                "sensitivity",
                "",
            )
            .lower()
        )

        if not is_sequential_block(
            sensitivity
        ):
            continue

        sequential_found = True

        for reset_name in reset_names:

            if (
                reset_name.lower()
                in sensitivity
            ):

                return "asynchronous"

    if sequential_found:

        return "synchronous"

    return "combinational_only"


def analyze_module(
    module,
):

    clock_ports = get_ports_by_role(
        module,
        "clock",
    )

    reset_ports = get_ports_by_role(
        module,
        "reset",
    )

    always_blocks = module.get(
        "always_blocks",
        [],
    )

    sequential_blocks = 0

    for block in always_blocks:

        if is_sequential_block(
            block.get(
                "sensitivity",
                "",
            )
        ):

            sequential_blocks += 1

    combinational_blocks = (
        len(always_blocks)
        - sequential_blocks
    )

    reset_entries = []

    for reset in reset_ports:

        reset_entries.append(
            {
                "name": reset.get(
                    "name"
                ),
                "polarity": determine_reset_polarity(
                    reset.get(
                        "name",
                        "",
                    )
                ),
            }
        )

    reset_names = [
        reset.get("name")
        for reset in reset_ports
    ]

    return {
        "module_name": module.get(
            "module_name"
        ),
        "clock_signals": [
            port.get("name")
            for port in clock_ports
        ],
        "reset_signals": reset_entries,
        "reset_type": determine_reset_type(
            always_blocks,
            reset_names,
        ),
        "always_blocks": {
            "total": len(
                always_blocks
            ),
            "sequential": sequential_blocks,
            "combinational": combinational_blocks,
        },
    }


def analyze_clock_reset(
    ir,
):

    modules = []

    clock_names = set()

    reset_names = set()

    for module in ir.get(
        "modules",
        [],
    ):

        result = analyze_module(
            module
        )

        modules.append(result)

        for clock in result[
            "clock_signals"
        ]:

            clock_names.add(clock)

        for reset in result[
            "reset_signals"
        ]:

            reset_names.add(
                reset["name"]
            )

    return {
        "schema_version":
            SCHEMA_VERSION,
        "metadata": {
            "generated_by":
                SCRIPT_NAME,
            "generated_at":
                timestamp(),
            "input_ir":
                "uart_ir.json",
            "input_metadata":
                "pipeline_metadata.json",
        },
        "summary": {
            "modules_analyzed":
                len(modules),
            "unique_clock_signals":
                len(clock_names),
            "unique_reset_signals":
                len(reset_names),
            "clock_names":
                sorted(clock_names),
            "reset_names":
                sorted(reset_names),
        },
        "modules": modules,
    }


# ============================================================
# Artifact Generation Functions
# ============================================================


def write_observation_log(
    report,
):

    observation_file = (
        OUTPUT_DIR
        / "clock_reset_observation_log.md"
    )

    lines = []

    lines.append(
        "# Clock Reset Analyzer Observations"
    )

    lines.append("")

    summary = report["summary"]

    lines.append(
        f"Modules Analyzed: "
        f"{summary['modules_analyzed']}"
    )

    lines.append("")

    lines.append(
        "Clock Signals:"
    )

    for clock in summary[
        "clock_names"
    ]:

        lines.append(
            f"- {clock}"
        )

    lines.append("")

    lines.append(
        "Reset Signals:"
    )

    for reset in summary[
        "reset_names"
    ]:

        lines.append(
            f"- {reset}"
        )

    lines.append("")

    for module in report[
        "modules"
    ]:

        lines.append("---")

        lines.append("")

        lines.append(
            f"## {module['module_name']}"
        )

        lines.append("")

        lines.append(
            f"Reset Type: "
            f"{module['reset_type']}"
        )

        lines.append("")

        lines.append(
            f"Sequential Always Blocks: "
            f"{module['always_blocks']['sequential']}"
        )

    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append(
        "Limitation:"
    )
    lines.append(
        "IR schema v0.1 does not preserve procedural assignments."
    )
    lines.append(
        "Register reset values cannot be extracted."
    )

    with open(
        observation_file,
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write(
            "\n".join(lines)
        )


def write_rules_document():

    rules_file = (
        OUTPUT_DIR
        / "clock_reset_rules_v0.md"
    )

    content = """
# Clock Reset Analysis Rules v0.1

## Clock Detection

role == "clock"

## Reset Detection

role == "reset"

## Reset Polarity

*_n -> active_low

*_b -> active_low

otherwise -> active_high

## Reset Type

Reset present in sensitivity list
    -> asynchronous

Sequential blocks only
    -> synchronous

No sequential blocks
    -> combinational_only

## Limitation

IR schema v0.1 does not preserve procedural assignments.

Register reset values are unavailable.
"""

    with open(
        rules_file,
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write(
            content.strip()
        )


# ============================================================
# Metadata Functions
# ============================================================


def build_clock_reset_metadata(
    report,
):

    summary = report[
        "summary"
    ]

    return {
        "clock_reset_schema_version":
            SCHEMA_VERSION,
        "clock_reset_report":
            "clock_reset_report.json",
        "modules_analyzed":
            summary[
                "modules_analyzed"
            ],
        "unique_clock_signals":
            summary[
                "unique_clock_signals"
            ],
        "unique_reset_signals":
            summary[
                "unique_reset_signals"
            ],
        "clock_names":
            summary[
                "clock_names"
            ],
        "reset_names":
            summary[
                "reset_names"
            ],
    }


def write_pipeline_metadata(
    previous_metadata,
    clock_reset_metadata,
):

    metadata = dict(
        previous_metadata
    )

    metadata.update(
        clock_reset_metadata
    )

    metadata["previous_stage"] = (
        metadata.get(
            "current_stage",
            PREVIOUS_STAGE,
        )
    )

    metadata["current_stage"] = (
        CURRENT_STAGE
    )

    metadata["generated_by"] = (
        SCRIPT_NAME
    )

    metadata[
        "clock_reset_analysis_completed"
    ] = True

    metadata[
        "timestamp"
    ] = timestamp()

    write_json(
        OUTPUT_DIR
        / "pipeline_metadata.json",
        metadata,
    )


# ============================================================
# Main Pipeline
# ============================================================


def main():

    ensure_output_directory()

    ir = load_json(
        IR_FILE
    )

    metadata = load_json(
        METADATA_FILE
    )

    report = analyze_clock_reset(
        ir
    )

    write_json(
        OUTPUT_DIR
        / "clock_reset_report.json",
        report,
    )

    write_observation_log(
        report
    )

    write_rules_document()

    clock_reset_metadata = (
        build_clock_reset_metadata(
            report
        )
    )

    write_pipeline_metadata(
        metadata,
        clock_reset_metadata,
    )

    print(
        "[INFO] Clock Reset Analyzer Completed"
    )

    print(
        f"[INFO] Output Directory: "
        f"{OUTPUT_DIR}"
    )


if __name__ == "__main__":

    main()