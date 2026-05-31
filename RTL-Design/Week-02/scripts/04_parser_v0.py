#!/usr/bin/env python3
"""
parser_v0.py

Stage-04 of RTL Analysis Pipeline

Input:
    uart_token_stream.json

Outputs:
    uart_ast.json
    parser_scope_v0.md
    unsupported_sv_patterns.md
    parser_observation_log.md
    pipeline_metadata.json
"""

import json
import sys
from pathlib import Path
from datetime import datetime

SCRIPT_DIR = Path(__file__).resolve().parent

OUTPUT_DIR = (
    SCRIPT_DIR.parent
    / "outputs"
    / "04_parser_v0"
)

OUTPUT_DIR.mkdir(
    parents=True,
    exist_ok=True
)

# ============================================================
# CONFIGURATION
# ============================================================

SCHEMA_VERSION = "0.1"

SUPPORTED_SIGNAL_TYPES = {
    "wire",
    "reg",
    "logic"
}

SUPPORTED_PORT_DIRECTIONS = {
    "input",
    "output",
    "inout"
}

SUPPORTED_PARAMETER_TYPES = {
    "parameter",
    "localparam"
}

UNSUPPORTED_PATTERNS = {
    "interface",
    "modport",
    "class",
    "covergroup",
    "assert",
    "property",
    "sequence",
    "generate"
}


# ============================================================
# TOKEN HELPERS
# ============================================================

def token_value(token):
    return token.get("value", "")


def token_type(token):
    return token.get("type", "")


def is_keyword(token, value):
    return (
        token_type(token) == "KEYWORD"
        and token_value(token) == value
    )


def is_identifier(token):
    return token_type(token) == "IDENTIFIER"


def safe_token(tokens, index):
    if 0 <= index < len(tokens):
        return tokens[index]
    return None

# ============================================================
# Metadata Loading
# ============================================================

def load_metadata(
    metadata_file: Path
):

    with metadata_file.open(
        "r",
        encoding="utf-8",
    ) as fp:

        return json.load(fp)

# ============================================================
# AST INITIALIZATION
# ============================================================

def create_empty_ast():
    return {
        "schema_version": SCHEMA_VERSION,
        "generated_at": datetime.now().isoformat(),
        "modules": []
    }


def create_module_node(name, line_start):
    return {
        "name": name,

        "metadata": {
            "line_start": line_start,
            "line_end": None
        },

        "parameters": [],
        "ports": [],
        "signals": [],
        "instances": [],
        "assigns": [],
        "always_blocks": []
    }


# ============================================================
# MODULE PARSING
# ============================================================

def parse_modules(tokens):
    """
    Detect:
        module <name>
        ...
        endmodule
    """

    modules = []

    current_module = None

    for idx, token in enumerate(tokens):

        if is_keyword(token, "module"):

            next_tok = safe_token(tokens, idx + 1)

            if next_tok and is_identifier(next_tok):

                current_module = create_module_node(
                    next_tok["value"],
                    token["line"]
                )

                modules.append(current_module)

        elif is_keyword(token, "endmodule"):

            if current_module is not None:

                current_module["metadata"]["line_end"] = token["line"]

                current_module = None

    return modules


# ============================================================
# PARAMETER PARSING
# ============================================================

def parse_parameters(tokens, modules):
    """
    Parse:

        parameter NAME = VALUE;
        localparam NAME = VALUE;
    """

    current_module = None
    module_index = 0

    for idx, token in enumerate(tokens):

        if is_keyword(token, "module"):
            if module_index < len(modules):
                current_module = modules[module_index]
                module_index += 1

        if token_type(token) != "KEYWORD":
            continue

        if token_value(token) not in SUPPORTED_PARAMETER_TYPES:
            continue

        name_tok = safe_token(tokens, idx + 1)

        if not name_tok or not is_identifier(name_tok):
            continue

        value = None

        search_idx = idx

        while search_idx < min(idx + 20, len(tokens)):

            t = tokens[search_idx]

            if token_value(t) == "=":

                rhs = safe_token(tokens, search_idx + 1)

                if rhs:
                    value = rhs["value"]

                break

            if token_value(t) == ";":
                break

            search_idx += 1

        if current_module is not None:

            current_module["parameters"].append(
                {
                    "name": name_tok["value"],
                    "value": value,
                    "kind": token_value(token),
                    "line": token["line"]
                }
            )


# ============================================================
# PORT PARSING
# ============================================================

def extract_width(tokens, start_idx):

    width = None

    if (
        safe_token(tokens, start_idx)
        and token_value(tokens[start_idx]) == "["
    ):

        pieces = []

        idx = start_idx

        while idx < len(tokens):

            pieces.append(token_value(tokens[idx]))

            if token_value(tokens[idx]) == "]":
                break

            idx += 1

        width = "".join(pieces)

    return width


def parse_ports(tokens, modules):

    current_module = None
    module_index = 0

    idx = 0

    while idx < len(tokens):

        token = tokens[idx]

        if is_keyword(token, "module"):

            if module_index < len(modules):
                current_module = modules[module_index]
                module_index += 1

        if token_value(token) not in SUPPORTED_PORT_DIRECTIONS:
            idx += 1
            continue

        direction = token_value(token)

        datatype = None
        width = None
        name = None

        cursor = idx + 1

        next_tok = safe_token(tokens, cursor)

        if next_tok and token_value(next_tok) in SUPPORTED_SIGNAL_TYPES:

            datatype = token_value(next_tok)
            cursor += 1

        if (
            safe_token(tokens, cursor)
            and token_value(tokens[cursor]) == "["
        ):

            width = extract_width(tokens, cursor)

            while (
                cursor < len(tokens)
                and token_value(tokens[cursor]) != "]"
            ):
                cursor += 1

            cursor += 1

        ident_tok = safe_token(tokens, cursor)

        if ident_tok and is_identifier(ident_tok):

            name = ident_tok["value"]

            if current_module is not None:

                current_module["ports"].append(
                    {
                        "name": name,
                        "direction": direction,
                        "datatype": datatype,
                        "width": width,
                        "line": token["line"]
                    }
                )

        idx += 1

# ============================================================
# SIGNAL PARSING
# ============================================================

def parse_signals(tokens, modules):

    current_module = None
    module_index = 0

    idx = 0

    while idx < len(tokens):

        token = tokens[idx]

        if is_keyword(token, "module"):

            if module_index < len(modules):
                current_module = modules[module_index]
                module_index += 1

        if token_value(token) not in SUPPORTED_SIGNAL_TYPES:
            idx += 1
            continue

        datatype = token_value(token)

        width = None
        name = None

        cursor = idx + 1

        if (
            safe_token(tokens, cursor)
            and token_value(tokens[cursor]) == "["
        ):

            width = extract_width(tokens, cursor)

            while (
                cursor < len(tokens)
                and token_value(tokens[cursor]) != "]"
            ):
                cursor += 1

            cursor += 1

        ident_tok = safe_token(tokens, cursor)

        if ident_tok and is_identifier(ident_tok):

            name = ident_tok["value"]

            if current_module is not None:

                port_names = {
                    port["name"]
                    for port in current_module["ports"]
                }

                signal_names = {
                    signal["name"]
                    for signal in current_module["signals"]
                }

                if (
                    name not in port_names
                    and name not in signal_names
                ):

                    current_module["signals"].append(
                        {
                            "name": name,
                            "datatype": datatype,
                            "width": width,
                            "line": token["line"]
                        }
                    )

        idx += 1


# ============================================================
# INSTANCE PARSING
# ============================================================

def parse_instances(tokens, modules):

    current_module = None
    module_index = 0

    idx = 0

    while idx < len(tokens):

        token = tokens[idx]

        if is_keyword(token, "module"):

            if module_index < len(modules):
                current_module = modules[module_index]
                module_index += 1

        first = safe_token(tokens, idx)
        second = safe_token(tokens, idx + 1)
        third = safe_token(tokens, idx + 2)

        if (
            first
            and second
            and third
            and is_identifier(first)
            and is_identifier(second)
            and token_value(third) == "("
        ):

            if current_module is not None:

                current_module["instances"].append(
                    {
                        "module": first["value"],
                        "instance": second["value"],
                        "line": first["line"]
                    }
                )

        idx += 1


# ============================================================
# ASSIGN PARSING
# ============================================================

def parse_assigns(tokens, modules):

    current_module = None
    module_index = 0

    idx = 0

    while idx < len(tokens):

        token = tokens[idx]

        if is_keyword(token, "module"):

            if module_index < len(modules):
                current_module = modules[module_index]
                module_index += 1

        if not is_keyword(token, "assign"):
            idx += 1
            continue

        lhs = None
        rhs_tokens = []

        cursor = idx + 1

        lhs_tok = safe_token(tokens, cursor)

        if lhs_tok and is_identifier(lhs_tok):
            lhs = lhs_tok["value"]

        while cursor < len(tokens):

            if token_value(tokens[cursor]) == "=":
                cursor += 1
                break

            cursor += 1

        while cursor < len(tokens):

            if token_value(tokens[cursor]) == ";":
                break

            rhs_tokens.append(token_value(tokens[cursor]))

            cursor += 1

        rhs = " ".join(rhs_tokens)

        if current_module is not None:

            current_module["assigns"].append(
                {
                    "lhs": lhs,
                    "rhs": rhs,
                    "line": token["line"]
                }
            )

        idx += 1


# ============================================================
# ALWAYS BLOCK PARSING
# ============================================================

def parse_always_blocks(tokens, modules):

    current_module = None
    module_index = 0

    idx = 0

    while idx < len(tokens):

        token = tokens[idx]

        if is_keyword(token, "module"):

            if module_index < len(modules):
                current_module = modules[module_index]
                module_index += 1

        if not is_keyword(token, "always"):
            idx += 1
            continue

        sensitivity_tokens = []

        cursor = idx + 1

        while cursor < len(tokens):

            sensitivity_tokens.append(
                token_value(tokens[cursor])
            )

            if token_value(tokens[cursor]) == ")":
                break

            cursor += 1

        sensitivity = " ".join(sensitivity_tokens)

        if current_module is not None:

            current_module["always_blocks"].append(
                {
                    "type": "always",
                    "line_start": token["line"],
                    "sensitivity": sensitivity
                }
            )

        idx += 1


# ============================================================
# UNSUPPORTED PATTERN DETECTION
# ============================================================

def detect_unsupported_patterns(tokens):

    found = set()

    for token in tokens:

        if token_value(token) in UNSUPPORTED_PATTERNS:
            found.add(token_value(token))

    return sorted(list(found))


# ============================================================
# REPORT GENERATION
# ============================================================

def write_json(path, data):

    with open(path, "w") as fp:
        json.dump(data, fp, indent=4)


def write_parser_scope(path):

    content = """# Parser Scope v0

Supported Constructs

- module
- parameter
- localparam
- ports
- wire
- reg
- logic
- instances
- assign
- always

Unsupported Constructs

- interface
- modport
- class
- covergroup
- assert
- property
- sequence
- generate
"""

    with open(path, "w") as fp:
        fp.write(content)


def write_unsupported_report(path, unsupported):

    with open(path, "w") as fp:

        fp.write("# Unsupported SystemVerilog Patterns\n\n")

        if not unsupported:
            fp.write("No unsupported constructs detected.\n")
            return

        for item in unsupported:
            fp.write(f"- {item}\n")


def write_observation_log(path, ast):

    total_modules = len(ast["modules"])

    with open(path, "w") as fp:

        fp.write("# Parser Observation Log\n\n")
        fp.write(f"Modules Detected: {total_modules}\n\n")

        for module in ast["modules"]:

            fp.write(f"## {module['name']}\n")

            fp.write(
                f"- Parameters: {len(module['parameters'])}\n"
            )

            fp.write(
                f"- Ports: {len(module['ports'])}\n"
            )

            fp.write(
                f"- Signals: {len(module['signals'])}\n"
            )

            fp.write(
                f"- Instances: {len(module['instances'])}\n"
            )

            fp.write(
                f"- Assigns: {len(module['assigns'])}\n"
            )

            fp.write(
                f"- Always Blocks: "
                f"{len(module['always_blocks'])}\n\n"
            )


def build_metadata(ast):

    metadata = {
        "modules_detected": len(ast["modules"]),
        "ports_detected": 0,
        "signals_detected": 0,
        "instances_detected": 0,
        "always_blocks_detected": 0,
        "assigns_detected": 0
    }

    for module in ast["modules"]:

        metadata["ports_detected"] += \
            len(module["ports"])

        metadata["signals_detected"] += \
            len(module["signals"])

        metadata["instances_detected"] += \
            len(module["instances"])

        metadata["always_blocks_detected"] += \
            len(module["always_blocks"])

        metadata["assigns_detected"] += \
            len(module["assigns"])

    return metadata

def write_pipeline_metadata(
    previous_metadata,
    parser_metadata,
    unsupported,
):

    metadata = dict(
        previous_metadata
    )

    metadata.update(
        parser_metadata
    )

    metadata["previous_stage"] = (
        metadata.get(
            "current_stage",
            "lexer_tokenizer"
        )
    )

    metadata["current_stage"] = (
        "parser_v0"
    )

    metadata["generated_by"] = (
        "04_parser_v0.py"
    )

    metadata["ast_file"] = (
        "uart_ast.json"
    )

    metadata["parser_schema_version"] = (
        SCHEMA_VERSION
    )

    metadata["unsupported_patterns"] = (
        unsupported
    )

    metadata["unsupported_pattern_count"] = (
        len(unsupported)
    )

    metadata["timestamp"] = (
        datetime.now().isoformat()
    )

    metadata_file = (
        OUTPUT_DIR
        / "pipeline_metadata.json"
    )

    with open(
        metadata_file,
        "w",
        encoding="utf-8"
    ) as fp:

        json.dump(
            metadata,
            fp,
            indent=4
        )


# ============================================================
# MAIN
# ============================================================

def main():

    if len(sys.argv) != 2:

        print(
            "\n"
            "============================================================\n"
            " PARSER V0 ERROR\n"
            "============================================================\n\n"
            "Missing required token stream file.\n\n"
            "Usage:\n"
            "    python3 04_parser_v0.py "
            "<uart_token_stream.json>\n\n"
            "Example:\n"
            "    python3 scripts/04_parser_v0.py \\\n"
            "        outputs/03_lexer_tokenizer/"
            "uart_token_stream.json\n"
        )
        sys.exit(1)

    token_stream_file = Path(
        sys.argv[1]
    ).resolve()

    if not token_stream_file.exists():
        print(
            "\n"
            "============================================================\n"
            " PARSER V0 ERROR\n"
            "============================================================\n\n"
            f"Token stream file not found:\n"
            f"    {token_stream_file}\n"
        )
        sys.exit(1)

    metadata_file = (
        token_stream_file.parent
        / "pipeline_metadata.json"
    )

    if not metadata_file.exists():
        print(
            "\n"
            "============================================================\n"
            " PARSER V0 ERROR\n"
            "============================================================\n\n"
            f"Metadata file not found:\n"
            f"    {metadata_file}\n\n"
            "Run lexer_tokenizer.py first.\n"
        )
        sys.exit(1)

    previous_metadata = load_metadata(
        metadata_file
    )

    with open(token_stream_file, "r") as fp:
        tokens = json.load(fp)

    ast = create_empty_ast()

    modules = parse_modules(tokens)

    parse_parameters(tokens, modules)
    parse_ports(tokens, modules)
    parse_signals(tokens, modules)
    parse_instances(tokens, modules)
    parse_assigns(tokens, modules)
    parse_always_blocks(tokens, modules)

    ast["modules"] = modules

    unsupported = detect_unsupported_patterns(tokens)

    write_json(
        OUTPUT_DIR / "uart_ast.json",
        ast
    )

    write_parser_scope(
        OUTPUT_DIR / "parser_scope_v0.md"
    )

    write_unsupported_report(
        OUTPUT_DIR / "unsupported_sv_patterns.md",
        unsupported
    )

    write_observation_log(
        OUTPUT_DIR / "parser_observation_log.md",
        ast
    )

    parser_metadata = build_metadata(
        ast
    )

    write_pipeline_metadata(
        previous_metadata,
        parser_metadata,
        unsupported,
    )

    print(
        "\n"
        "============================================================\n"
        " PARSER V0 COMPLETE\n"
        "============================================================\n\n"
        f"AST File:\n"
        f"    {OUTPUT_DIR / 'uart_ast.json'}\n\n"
        f"Metadata File:\n"
        f"    {OUTPUT_DIR / 'pipeline_metadata.json'}\n"
    )


if __name__ == "__main__":
    main()