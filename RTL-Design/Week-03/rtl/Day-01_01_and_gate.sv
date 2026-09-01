/* ============================================================================
   and_gate.sv
   Day 1 Experimental Work — Item 3: "Write a minimal SV module by hand (no simulator yet):
   a 2-input AND gate with a, b inputs and y output using assign. Annotate it fully."

   This module was written and annotated by hand, without running a simulator,
   per the assignment instructions.
   ============================================================================ */

`timescale 1ns/1ps        /* Match the rest of the repo's RTL files. Harmless for pure combinational logic
                             (no delays), but keeps the whole design compiling warning-free when this file
                             is built alongside timescaled ones. */

module and_gate (         /* 'module' begins the definition of a reusable hardware block. 'and_gate' is the
                             name other code will use to instantiate this block. */
    input  logic a,        /* 'input' — a signal driven from OUTSIDE this module; this block only ever reads it.
                             'logic' is the modern SystemVerilog 4-state data type (can hold 0, 1, X, Z), used here
                             instead of the legacy Verilog 'wire' keyword even though it behaves like a wire on
                             an input port. 'a' is the first operand of the AND. */
    input  logic b,        /* Second operand of the AND — same reasoning as 'a' above. */
    output logic y         /* 'output' — a signal driven from INSIDE this module, visible to whatever instantiates it.
                             'y' is the result of the AND operation. */
);                         /* Closes the port list. Note there is no semicolon-separated port *declaration* body
                             here beyond this — SystemVerilog lets us declare direction + type directly in the
                             port list (this is the modern "ANSI-style" port declaration, as opposed to older
                             Verilog which declared ports outside the parentheses). */

    assign y = a & b;      /* 'assign' creates a CONTINUOUS ASSIGNMENT — a permanent piece of combinational logic that
                             is always active. The moment 'a' or 'b' changes, 'y' re-evaluates immediately (in zero
                             simulated time / one delta cycle). '&' here is the BITWISE AND operator. Since 'a' and 'b'
                             are single bits, bitwise AND and logical AND produce the same result — but on multi-bit
                             vectors they would differ (bitwise AND would operate bit-by-bit across the whole vector,
                             while logical AND — '&&' — would collapse each operand to a single true/false value first).
                             Using '&' here is deliberate: it is the natural choice for describing an actual AND *gate*,
                             since a bitwise operator maps directly onto real AND-gate hardware. This assign statement
                             is the only behavioral content of the module — everything else is structure (ports) and
                             comments (annotation). */

endmodule                  /* Closes the module definition. Everything between 'module' and 'endmodule' describes
                             one piece of hardware: two input wires feeding a single 2-input AND gate, whose
                             output is 'y'. This is fully synthesizable — there are no delays, no 'initial'
                             blocks, and no simulation-only constructs anywhere in it. */

/* ----------------------------------------------------------------------------
   Notes (not required by the assignment, added for my own understanding):
   - This module has NO clock and NO reset because it is pure combinational logic — 'y' has no
     memory of anything, it is just a function of the current values of 'a' and 'b' at every instant.
   - If I wanted to test this without a simulator yet (per the assignment's "no simulator yet"
     instruction), I would trace it by hand using a truth table:
       a | b | y = a & b
       --|---|----------
       0 | 0 | 0
       0 | 1 | 0
       1 | 0 | 0
       1 | 1 | 1
   ---------------------------------------------------------------------------- */
