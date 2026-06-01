# ============================================================
# Imports
# ============================================================
import json
from pathlib import Path
from datetime import datetime, timezone

# ============================================================
# Script Constants
# ============================================================
SCRIPT_NAME = "05_ir_builder.py"
SCHEMA_VERSION = "0.1"
CURRENT_STAGE = "ir_builder"
PREVIOUS_STAGE = "parser_v0"


# ============================================================
# Directory Configuration
# ============================================================
PROJECT_ROOT = Path(__file__).resolve().parent.parent
INPUT_DIR = PROJECT_ROOT / "outputs" / "04_parser_v0"
OUTPUT_DIR = PROJECT_ROOT / "outputs" / "05_ir_builder"

AST_FILE = INPUT_DIR / "uart_ast.json"
METADATA_FILE = INPUT_DIR / "pipeline_metadata.json"


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
    return datetime.now(timezone.utc).isoformat()


# ============================================================
# Semantic Classification
# ============================================================


def classify_port_role(
    port_name,
):

    name = port_name.lower()

    if name in (
        "clk",
        "clock",
        "clk_i",
    ):
        return "clock"

    if "rst" in name or "reset" in name:
        return "reset"

    if name == "tx":
        return "serial_tx"

    if name == "rx":
        return "serial_rx"

    if name.endswith("_valid"):
        return "status"

    if name.endswith("_ready"):
        return "control"

    if "addr" in name or name == "address":
        return "address"

    if "data" in name:
        return "data"

    if name in (
        "we",
        "re",
        "enable",
        "en",
    ):
        return "control"

    return "unknown"


def classify_signal_role(
    signal_name,
):

    name = signal_name.lower()

    if name == "data_save":
        return "shift_register"

    if name == "count_8":
        return "bit_counter"

    if name in (
        "count_16",
        "baud_count",
    ):
        return "baud_counter"

    if name == "current_state":
        return "state_register"

    if name == "next_state":
        return "state_logic"

    if "data" in name:
        return "datapath"

    return "unknown"


# ============================================================
# AST → IR Conversion Functions
# ============================================================


def convert_parameter(
    parameter,
):

    return {
        "name": parameter.get("name"),
        "value": parameter.get("value"),
        "kind": parameter.get("kind"),
        "line": parameter.get("line"),
    }


def convert_port(
    port,
):

    return {
        "name": port.get("name"),
        "direction": port.get("direction"),
        "datatype": port.get("datatype"),
        "width": normalize_width(port.get("width")),
        "line": port.get("line"),
        "role": classify_port_role(
            port.get(
                "name",
                "",
            )
        ),
    }


def normalize_width(width):
    if width is None:
        return 1

    return width


def convert_signal(
    signal,
):

    return {
        "name": signal.get("name"),
        "datatype": signal.get("datatype"),
        "width": signal.get("width"),
        "line": signal.get("line"),
        "role": classify_signal_role(
            signal.get(
                "name",
                "",
            )
        ),
    }


def convert_instance(
    instance,
):

    return {
        "module": instance.get("module"),
        "instance": instance.get("instance"),
        "line": instance.get("line"),
    }


def convert_module(
    module,
):

    parameters = [
        convert_parameter(parameter)
        for parameter in module.get(
            "parameters",
            [],
        )
    ]

    ports = [
        convert_port(port)
        for port in module.get(
            "ports",
            [],
        )
    ]

    signals = [
        convert_signal(signal)
        for signal in module.get(
            "signals",
            [],
        )
    ]

    instances = [
        convert_instance(instance)
        for instance in module.get(
            "instances",
            [],
        )
    ]

    return {
        "module_name": module.get("name"),
        "metadata": module.get(
            "metadata",
            {},
        ),
        "parameters": parameters,
        "ports": ports,
        "signals": signals,
        "instances": instances,
        "assigns": module.get(
            "assigns",
            [],
        ),
        "always_blocks": module.get(
            "always_blocks",
            [],
        ),
    }


# ============================================================
# IR Construction Functions
# ============================================================


def build_hierarchy_hints(
    ast,
):

    hierarchy = {}

    for module in ast.get(
        "modules",
        [],
    ):

        module_name = module.get("name")

        child_modules = []

        for instance in module.get(
            "instances",
            [],
        ):

            child_modules.append(instance.get("module"))

        if child_modules:

            hierarchy[module_name] = child_modules

    return hierarchy


def build_fsm_hints(
    metadata,
):

    return {
        "states": metadata.get(
            "fsm_states_detected",
            [],
        )
    }


def build_statistics(
    metadata,
):

    return {
        "module_count": metadata.get(
            "modules_detected",
            0,
        ),
        "port_count": metadata.get(
            "ports_detected",
            0,
        ),
        "signal_count": metadata.get(
            "signals_detected",
            0,
        ),
        "instance_count": metadata.get(
            "instances_detected",
            0,
        ),
        "always_block_count": metadata.get(
            "always_blocks_detected",
            0,
        ),
        "assign_count": metadata.get(
            "assigns_detected",
            0,
        ),
    }


def build_metadata_section(
    metadata,
):

    top_modules = metadata.get(
        "top_modules",
        [],
    )

    return {
        "generated_by": SCRIPT_NAME,
        "generated_at": timestamp(),
        "schema_version": SCHEMA_VERSION,
        "design_name": metadata.get(
            "design_name",
            "unknown",
        ),
        "top_module": top_modules[0] if top_modules else "unknown",
        "input_ast": "uart_ast.json",
        "input_metadata": "pipeline_metadata.json",
    }


def build_modules(
    ast,
):

    modules = []

    for module in ast.get(
        "modules",
        [],
    ):

        modules.append(convert_module(module))

    return modules


def build_ir(
    ast,
    metadata,
):

    modules = build_modules(ast)

    ir = {
        "schema_version": SCHEMA_VERSION,
        "metadata": build_metadata_section(metadata),
        "statistics": build_statistics(metadata),
        "fsm_hints": build_fsm_hints(metadata),
        "hierarchy_hints": build_hierarchy_hints(ast),
        "modules": modules,
    }

    return ir


# ============================================================
# Artifact Generation Functions
# ============================================================


def build_ir_schema():

    return {
        "schema_version": SCHEMA_VERSION,
        "metadata": {},
        "statistics": {},
        "fsm_hints": {},
        "hierarchy_hints": {},
        "modules": [],
    }


def write_mapping_table():

    mapping_file = OUTPUT_DIR / "ast_to_ir_mapping_table.md"

    content = """
# AST to IR Mapping Table

| AST Node | IR Field |
|-----------|-----------|
| Module | modules[] |
| Parameter | modules[].parameters[] |
| Port | modules[].ports[] |
| Signal | modules[].signals[] |
| Instance | modules[].instances[] |
| Assign | modules[].assigns[] |
| Always Block | modules[].always_blocks[] |

## Semantic Enrichment

| Source Field | Added IR Field |
|--------------|----------------|
| Port Name | role |
| Signal Name | role |
| Metadata | statistics |
| FSM States | fsm_hints |
| Instances | hierarchy_hints |
"""

    with open(
        mapping_file,
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write(content.strip())


def write_observation_log(
    ir,
):

    observation_file = OUTPUT_DIR / "ir_observation_log.md"

    lines = []

    lines.append("# IR Builder Observations")

    lines.append("")

    lines.append("Protocol Summary Generated: Yes")

    lines.append(f"Modules Converted: " f"{ir['statistics']['module_count']}")

    lines.append(f"Ports Converted: " f"{ir['statistics']['port_count']}")

    lines.append(f"Signals Converted: " f"{ir['statistics']['signal_count']}")

    lines.append(f"Instances Converted: " f"{ir['statistics']['instance_count']}")

    lines.append("")

    lines.append("FSM States Detected:")

    for state in ir.get(
        "fsm_hints",
        {},
    ).get(
        "states",
        [],
    ):

        lines.append(f"- {state}")

    with open(
        observation_file,
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write("\n".join(lines))


def build_ir_metadata(
    ir,
):

    return {
        "ir_schema_version": SCHEMA_VERSION,
        "ir_file": "uart_ir.json",
        "protocol_summary": "uart_protocol_summary.json",
        "modules_converted": ir.get(
            "statistics",
            {},
        ).get(
            "module_count",
            0,
        ),
        "ports_converted": ir.get(
            "statistics",
            {},
        ).get(
            "port_count",
            0,
        ),
        "signals_converted": ir.get(
            "statistics",
            {},
        ).get(
            "signal_count",
            0,
        ),
        "hierarchy_entries": len(
            ir.get(
                "hierarchy_hints",
                {},
            )
        ),
        "fsm_states": ir.get(
            "fsm_hints",
            {},
        ).get(
            "states",
            [],
        ),
    }


def write_pipeline_metadata(
    previous_metadata,
    ir_metadata,
):

    metadata = dict(previous_metadata)

    metadata.update(ir_metadata)

    metadata["previous_stage"] = metadata.get(
        "current_stage",
        PREVIOUS_STAGE,
    )

    metadata["current_stage"] = CURRENT_STAGE

    metadata["generated_by"] = SCRIPT_NAME

    metadata["ir_generated"] = True

    metadata["ir_output_file"] = "uart_ir.json"

    metadata["timestamp"] = timestamp()

    write_json(
        OUTPUT_DIR / "pipeline_metadata.json",
        metadata,
    )


def build_uart_summary(
    ir,
):

    top_module = ir["metadata"].get("top_module", "unknown")

    submodules = ir.get("hierarchy_hints", {}).get(top_module, [])

    top_ports = []

    for module in ir["modules"]:

        if module["module_name"] == top_module:

            top_ports = module["ports"]

            break

    ports = []
    for port in top_ports:

        ports.append(
            {
                "name": port["name"],
                "direction": port["direction"],
                "width": port.get("width"),
                "role": port.get("role", "unknown"),
            }
        )

    reset_info = {}
    for port in top_ports:

        if port.get("role") == "reset":

            reset_info = {"signal": port["name"], "polarity": "active_high"}

            break
    states = ir.get("fsm_hints", {}).get("states", [])

    fsm = {"tx": states, "rx": states}

    datapath = set()

    for module in ir["modules"]:

        for signal in module["signals"]:

            role = signal.get("role")

            if role in (
                "shift_register",
                "bit_counter",
                "baud_counter",
            ):

                datapath.add(signal["name"])
    return {
        "schema_version": SCHEMA_VERSION,
        "protocol": "UART",
        "top_module": top_module,
        "submodules": submodules,
        "ports": ports,
        "fsm": fsm,
        "datapath": sorted(list(datapath)),
        "reset": reset_info,
    }


# ============================================================
# Main Pipeline
# ============================================================


def main():

    ensure_output_directory()

    ast = load_json(AST_FILE)

    metadata = load_json(METADATA_FILE)

    ir = build_ir(
        ast,
        metadata,
    )

    write_json(
        OUTPUT_DIR / "uart_ir.json",
        ir,
    )

    summary = build_uart_summary(ir)

    write_json(
        OUTPUT_DIR / "uart_protocol_summary.json",
        summary,
    )

    write_json(
        OUTPUT_DIR / "sample_base_ir.json",
        ir,
    )

    write_json(
        OUTPUT_DIR / "ir_schema_v0_1.json",
        build_ir_schema(),
    )

    write_mapping_table()

    write_observation_log(ir)

    ir_metadata = build_ir_metadata(ir)

    write_pipeline_metadata(
        metadata,
        ir_metadata,
    )

    print("[INFO] IR Builder Completed")

    print(f"[INFO] Output Directory: " f"{OUTPUT_DIR}")


if __name__ == "__main__":

    main()
