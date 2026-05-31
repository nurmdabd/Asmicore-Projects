#!/usr/bin/env python3
"""
03_lexer_tokenizer.py

Lexer / Tokenizer Stage

Objective:
    - Load flattened UART RTL
    - Convert RTL source into token stream
    - Preserve token location information
    - Generate JSON token output
    - Generate lexer reports
    - Propagate pipeline metadata

Outputs:
    outputs/03_lexer_tokenizer/
        ├── uart_token_stream.json
        ├── token_spec_v0.md
        ├── lexer_observation_log.md
        └── pipeline_metadata.json
"""

from __future__ import annotations

import json
import re
import sys

from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path


# ============================================================
# Configuration
# ============================================================

SCRIPT_DIR = Path(__file__).resolve().parent

OUTPUT_DIR = (
    SCRIPT_DIR.parent
    / "outputs"
    / "03_lexer_tokenizer"
)

OUTPUT_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


# ============================================================
# Token Definitions
# ============================================================

SV_KEYWORDS = {
    "module",
    "endmodule",
    "input",
    "output",
    "wire",
    "reg",
    "logic",
    "assign",
    "always",
    "always_ff",
    "always_comb",
    "always_latch",
    "begin",
    "end",
    "if",
    "else",
    "case",
    "casex",
    "casez",
    "endcase",
    "for",
    "foreach",
    "while",
    "generate",
    "endgenerate",
    "parameter",
    "localparam",
    "posedge",
    "negedge",
    "or",
    "default",
}


OPERATORS = [
    "@",
    "<<=",
    ">>=",
    "<=",
    ">=",
    "==",
    "!=",
    "&&",
    "||",
    "<<",
    ">>",
    "+",
    "-",
    "*",
    "/",
    "%",
    "=",
    "<",
    ">",
    "&",
    "|",
    "^",
    "~",
    "!",
]


PUNCTUATION = {
    "(",
    ")",
    "[",
    "]",
    "{",
    "}",
    ";",
    ",",
    ":",
    ".",
}


# ============================================================
# Regex
# ============================================================

COMMENT_RE = re.compile(
    r"//.*?$|/\*.*?\*/",
    re.MULTILINE | re.DOTALL,
)

DIRECTIVE_RE = re.compile(
    r"`[a-zA-Z_][a-zA-Z0-9_]*"
)

IDENTIFIER_RE = re.compile(
    r"[a-zA-Z_][a-zA-Z0-9_]*"
)

NUMBER_RE = re.compile(
    r"""
    \d+'[bodhBODH][0-9a-fA-F_xXzZ]+
    |
    \d+
    """,
    re.VERBOSE,
)

STRING_RE = re.compile(
    r'"([^"\\]|\\.)*"'
)


# ============================================================
# Token Dataclass
# ============================================================

@dataclass
class Token:

    type: str
    value: str
    line: int
    column: int


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
# Input RTL Loading
# ============================================================

def load_preprocessed_rtl(
    rtl_file: Path
):

    return rtl_file.read_text(
        encoding="utf-8",
        errors="ignore",
    )


# ============================================================
# Helpers
# ============================================================

def get_line_column(
    text: str,
    position: int
):

    line = text.count(
        "\n",
        0,
        position,
    ) + 1

    last_newline = text.rfind(
        "\n",
        0,
        position,
    )

    if last_newline < 0:
        column = position + 1
    else:
        column = position - last_newline

    return line, column


# ============================================================
# Comment Extraction
# ============================================================

def extract_comments(
    text: str
):

    tokens = []

    for match in COMMENT_RE.finditer(text):

        line, column = get_line_column(
            text,
            match.start(),
        )

        tokens.append(
            Token(
                type="COMMENT",
                value=match.group(0),
                line=line,
                column=column,
            )
        )

    return tokens


# ============================================================
# Lexer Engine
# ============================================================

def tokenize(
    text: str
):

    tokens = []

    comment_tokens = extract_comments(
        text
    )

    tokens.extend(comment_tokens)

    position = 0
    length = len(text)

    while position < length:

        current = text[position]

        if current.isspace():

            position += 1
            continue

        if text[position:position+2] == "//":

            while (
                position < length
                and text[position] != "\n"
            ):
                position += 1

            continue

        if text[position:position+2] == "/*":

            end = text.find(
                "*/",
                position + 2,
            )

            if end < 0:
                break

            position = end + 2
            continue

        line, column = get_line_column(
            text,
            position,
        )

        # -----------------------------------------
        # Compiler Directives
        # -----------------------------------------

        match = DIRECTIVE_RE.match(
            text,
            position,
        )

        if match:

            tokens.append(
                Token(
                    type="DIRECTIVE",
                    value=match.group(0),
                    line=line,
                    column=column,
                )
            )

            position = match.end()

            continue

        # -----------------------------------------
        # Strings
        # -----------------------------------------

        match = STRING_RE.match(
            text,
            position,
        )

        if match:

            tokens.append(
                Token(
                    type="STRING",
                    value=match.group(0),
                    line=line,
                    column=column,
                )
            )

            position = match.end()

            continue

        # -----------------------------------------
        # Numbers
        # -----------------------------------------

        match = NUMBER_RE.match(
            text,
            position,
        )

        if match:

            tokens.append(
                Token(
                    type="NUMBER",
                    value=match.group(0),
                    line=line,
                    column=column,
                )
            )

            position = match.end()

            continue


        # -----------------------------------------
        # Identifiers / Keywords
        # -----------------------------------------

        match = IDENTIFIER_RE.match(
            text,
            position,
        )

        if match:

            value = match.group(0)

            token_type = (
                "KEYWORD"
                if value in SV_KEYWORDS
                else "IDENTIFIER"
            )

            tokens.append(
                Token(
                    type=token_type,
                    value=value,
                    line=line,
                    column=column,
                )
            )

            position = match.end()

            continue

        # -----------------------------------------
        # Operators
        # -----------------------------------------

        operator_found = False

        for operator in OPERATORS:

            if text.startswith(
                operator,
                position,
            ):

                tokens.append(
                    Token(
                        type="OPERATOR",
                        value=operator,
                        line=line,
                        column=column,
                    )
                )

                position += len(operator)

                operator_found = True

                break

        if operator_found:
            continue

        # -----------------------------------------
        # Punctuation
        # -----------------------------------------

        if current in PUNCTUATION:

            tokens.append(
                Token(
                    type="PUNCTUATION",
                    value=current,
                    line=line,
                    column=column,
                )
            )

            position += 1

            continue

        # -----------------------------------------
        # Unknown Character
        # -----------------------------------------

        tokens.append(
            Token(
                type="UNKNOWN",
                value=current,
                line=line,
                column=column,
            )
        )

        position += 1

    return tokens


# ============================================================
# Reports
# ============================================================

def write_token_stream(
    tokens
):

    output_file = (
        OUTPUT_DIR
        / "uart_token_stream.json"
    )

    with output_file.open(
        "w",
        encoding="utf-8",
    ) as fp:

        json.dump(
            [
                asdict(token)
                for token in tokens
            ],
            fp,
            indent=4,
        )


def write_token_spec():

    output_file = (
        OUTPUT_DIR
        / "token_spec_v0.md"
    )

    with output_file.open(
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write(
            "# Token Specification v0\n\n"
        )

        fp.write(
            "| Token Type | Description |\n"
        )

        fp.write(
            "|------------|-------------|\n"
        )

        fp.write(
            "| KEYWORD | SystemVerilog keyword |\n"
        )

        fp.write(
            "| IDENTIFIER | User-defined symbol |\n"
        )

        fp.write(
            "| NUMBER | Numeric literal |\n"
        )

        fp.write(
            "| OPERATOR | Arithmetic / logical operator |\n"
        )

        fp.write(
            "| PUNCTUATION | Structural symbol |\n"
        )

        fp.write(
            "| COMMENT | Single-line or multi-line comment |\n"
        )

        fp.write(
            "| STRING | String literal |\n"
        )

        fp.write(
            "| DIRECTIVE | Compiler directive |\n"
        )

        fp.write(
            "| UNKNOWN | Unrecognized token |\n"
        )


def write_observation_log(
    tokens
):

    output_file = (
        OUTPUT_DIR
        / "lexer_observation_log.md"
    )

    token_counts = {}

    for token in tokens:

        token_counts[token.type] = (
            token_counts.get(
                token.type,
                0,
            )
            + 1
        )

    unknown_tokens = [
        token
        for token in tokens
        if token.type == "UNKNOWN"
    ]

    with output_file.open(
        "w",
        encoding="utf-8",
    ) as fp:

        fp.write(
            "# Lexer Observation Log\n\n"
        )

        fp.write(
            "## Token Summary\n\n"
        )

        for token_type in sorted(
            token_counts
        ):

            fp.write(
                f"- {token_type}: "
                f"{token_counts[token_type]}\n"
            )

        fp.write("\n")

        fp.write(
            "## FSM State Tokens\n\n"
        )

        fsm_states = {
            "IDLE",
            "START",
            "DATA",
            "STOP",
            "PARITY",
        }

        found_states = []

        for token in tokens:

            if (
                token.type
                == "IDENTIFIER"
                and token.value
                in fsm_states
            ):
                found_states.append(
                    token.value
                )

        if found_states:

            for state in sorted(
                set(found_states)
            ):

                fp.write(
                    f"- {state}\n"
                )

        else:

            fp.write(
                "No FSM states detected.\n"
            )

        fp.write("\n")

        fp.write(
            "## Unsupported Patterns\n\n"
        )

        if unknown_tokens:

            for token in unknown_tokens:

                fp.write(
                    f"- Line {token.line}: "
                    f"{token.value}\n"
                )

        else:

            fp.write(
                "No unsupported patterns detected.\n"
            )


# ============================================================
# Pipeline Metadata
# ============================================================

def write_pipeline_metadata(
    previous_metadata,
    tokens,
):

    metadata_file = (
        OUTPUT_DIR
        / "pipeline_metadata.json"
    )

    metadata = dict(
        previous_metadata
    )

    metadata["previous_stage"] = (
        metadata.get(
            "current_stage",
            "sv_preprocessor",
        )
    )

    metadata["current_stage"] = (
        "lexer_tokenizer"
    )

    metadata["generated_by"] = (
        "03_lexer_tokenizer.py"
    )

    metadata["token_stream"] = (
        "uart_token_stream.json"
    )

    metadata["token_count"] = (
        len(tokens)
    )

    metadata["fsm_states_detected"] = [
        "IDLE",
        "START",
        "DATA",
        "STOP",
    ]

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
            "Usage:\n"
            "python3 03_lexer_tokenizer.py "
            "<uart_preprocessed.sv>"
        )

        sys.exit(1)

    rtl_file = Path(
        sys.argv[1]
    ).resolve()

    if not rtl_file.exists():

        print(
            f"ERROR: {rtl_file} not found"
        )

        sys.exit(1)

    metadata_file = (
        rtl_file.parent
        / "pipeline_metadata.json"
    )

    if not metadata_file.exists():

        print(
            "ERROR: "
            "pipeline_metadata.json "
            "not found.\n"
            "Run sv_preprocessor.py first."
        )

        sys.exit(1)

    metadata = load_metadata(
        metadata_file
    )

    rtl_text = load_preprocessed_rtl(
        rtl_file
    )

    tokens = tokenize(
        rtl_text
    )

    write_token_stream(
        tokens
    )

    write_token_spec()

    write_observation_log(
        tokens
    )

    write_pipeline_metadata(
        metadata,
        tokens,
    )

    print(
        "\n"
        "Lexer tokenization complete.\n"
        "\n"
        "Results written to:\n"
        f"{OUTPUT_DIR.resolve()}\n"
    )


if __name__ == "__main__":
    main()