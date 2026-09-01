/* ============================================================================
   day1_annotated_dff_example.sv
   Day 1 Experimental Work — Item 2: "Find one example of a simple module in SystemVerilog...
   Annotate every line - what each keyword does, what each signal represents."

   Chosen example: a D flip-flop with active-low asynchronous reset. This is deliberately
   different from the AND gate (and_gate.sv, item 3) so the two annotated files together
   cover both a combinational example and a sequential example, per the concurrent-vs-procedural
   material from Learning Topic 1.4.
   ============================================================================ */

`timescale 1ns/1ps                /* Match the rest of the repo's RTL files. */

module d_flip_flop (              /* Basic hardware unit: a single-bit register (the
                                     smallest unit of memory in digital design). */
    input  logic clk,             /* Clock input. This signal's RISING EDGE is what triggers the
                                     flip-flop to capture a new value — it is not read continuously
                                     like a combinational input would be. */
    input  logic rst_n,           /* Active-LOW asynchronous reset. The trailing '_n' is a naming
                                     convention signaling "this is active when LOW," not a SystemVerilog
                                     keyword — it's a team/style convention, but a very common and
                                     important one to follow consistently (recall Day 7: active level
                                     must always be stated explicitly in a spec). */
    input  logic d,                /* Data input — the value that will be captured into the
                                     flip-flop on the next active clock edge. */
    output logic q                 /* Data output — holds the value that was most recently
                                     captured. This is the flip-flop's "memory." */
);

    always_ff @(posedge clk or negedge rst_n) begin
        /* 'always_ff' — SystemVerilog's dedicated procedural block for describing SEQUENTIAL
           (clocked) logic. Using this instead of a generic Verilog 'always' block lets tools
           and linters confirm this really is meant to be a register, catching accidental
           combinational-style mistakes early.

           The sensitivity list '@(posedge clk or negedge rst_n)' means: this block only runs
           in reaction to two specific events — the RISING edge of clk, OR the FALLING edge of
           rst_n. Nothing else (not a change in 'd' by itself) will trigger this block.
           Listing 'negedge rst_n' here is what makes the reset ASYNCHRONOUS — it can force q
           back to 0 immediately, even if clk is not currently ticking. */

        if (!rst_n) begin
            /* '!' is the logical NOT operator. '!rst_n' reads as "rst_n is currently LOW"
               (since rst_n is active-low). This branch has priority: whenever reset is
               asserted, it wins, regardless of what clk is doing. */
            q <= 1'b0;
            /* '<=' is a NON-BLOCKING assignment. Inside always_ff, non-blocking assignments
               are the correct, standard choice — they model the real hardware behavior where
               all flip-flops in a design appear to update simultaneously at the clock edge,
               rather than one after another in code order. '1'b0' is a sized literal:
               1 bit wide, base 'b' (binary), value 0. */
        end else begin
            q <= d;
            /* On a normal rising clock edge, with reset not asserted, the flip-flop simply
               captures whatever 'd' currently is and holds it at 'q' until the next active edge. */
        end
    end

endmodule
/* Closes the module. Everything inside always_ff is the ONLY place this design's state (q)
   is ever updated — this matches the Day 1/Day 2 principle that always_ff should be reserved
   exclusively for updating registers, never for combinational decision logic. */

/* ----------------------------------------------------------------------------
   Notes (not required by the assignment, added for my own understanding):
   - I chose this example instead of copying an example straight from a third-party site,
     per the assignment's "or from your study materials" alternative — this keeps the
     annotation exercise focused on genuinely explaining each keyword rather than reproducing
     someone else's code.
   - Contrast with and_gate.sv: that module has no clk, no memory, and uses a single 'assign'
     continuous assignment (pure combinational). This module has both a clock and memory, and
     uses 'always_ff' — assign/combinational vs always_ff/sequential is exactly the
     "concurrent vs procedural" distinction from Learning Topic 1.4.
   ---------------------------------------------------------------------------- */
