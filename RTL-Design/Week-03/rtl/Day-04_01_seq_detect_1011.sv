// =============================================================================
`timescale 1ns/1ps
// Module      : seq_detect_1011
// Description : Overlapping sequence detector for the bit pattern "1011" on a
//               serial input (din). "Overlapping" means the trailing bit of a
//               completed match may also be the first bit of the next match
//               (e.g. "1011011" fires twice, sharing the middle "1").
//
//               TRUE two-block Moore FSM. 'detected' is a pure function of the
//               CURRENT STATE alone (not of din) - the defining property of a
//               Moore machine. A dedicated DETECT state (S1011) is entered the
//               cycle after the 4th matching bit is sampled, and 'detected' is
//               HIGH exactly while the FSM sits in that state.
//
//               This is the resolution of the Moore-vs-Mealy question raised in
//               the Day 2 state-diagram note: a genuine Moore output for this
//               pattern needs a 5th state, which is added here. (An earlier
//               draft implemented a 4-state Mealy detector with a REGISTERED
//               output - that reproduces Moore *timing* but is not structurally
//               Moore, because its 'detected' is not a function of state alone.
//               See ISSUE-D4-01 in the Issue Log for that history.)
//
//               Timing: the completing (4th) bit is sampled at a clock edge;
//               the FSM enters S1011 on that edge, so 'detected' reads HIGH
//               during the FOLLOWING cycle - the ordinary one-cycle latency of
//               a clocked FSM. Verified in the Day 4 smoke test.
//
// Author      : Nur
// =============================================================================

module seq_detect_1011 (
    input  logic clk,      // system clock
    input  logic rst_n,    // active-low asynchronous reset
    input  logic din,      // serial input bit, one bit sampled per clk cycle
    output logic detected  // HIGH for one cycle when "1011" completes (Moore)
);

    // -------------------------------------------------------------------
    // State declaration (5 states -> 3 encoding bits).
    // Each state = "longest suffix of the input seen so far that is also a
    // prefix of 1011":
    //   IDLE  - ""     : no useful progress yet (reset state)
    //   S1    - "1"    : matched so far "1"
    //   S10   - "10"   : matched so far "10"
    //   S101  - "101"  : matched so far "101"  (one more '1' completes it)
    //   S1011 - "1011" : full match -> DETECT state; 'detected' HIGH here only
    // -------------------------------------------------------------------
    typedef enum logic [2:0] {IDLE, S1, S10, S101, S1011} state_t;
    state_t state, next_state;

    // -------------------------------------------------------------------
    // Block 1 - State register (sequential only, nothing else lives here).
    // Asynchronous active-low reset: guarantees a known state even before the
    // clock is toggling - the safer default for a control FSM.
    // -------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // -------------------------------------------------------------------
    // Block 2 - Next-state logic (pure combinational, no registers here).
    // Default assignment at the top avoids incomplete-case latch inference.
    //
    // Overlap handling: after a full match, the trailing '1' of "1011" is a
    // fresh 1-bit prefix, so S1011 transitions on the NEXT input exactly like
    // S1 does (din=1 -> S1, din=0 -> S10). Both S101 and S1011 fall back to
    // S10 on a '0' (the "...10" tail is still useful progress).
    // -------------------------------------------------------------------
    always_comb begin
        next_state = state;  // default: hold current state
        case (state)
            IDLE:  if (din) next_state = S1;    else next_state = IDLE;
            S1:    if (din) next_state = S1;     else next_state = S10;
            S10:   if (din) next_state = S101;   else next_state = IDLE;
            S101:  if (din) next_state = S1011;  else next_state = S10;  // 4th bit '1' -> DETECT
            S1011: if (din) next_state = S1;     else next_state = S10;  // overlap: acts like S1
            default: next_state = IDLE;                                  // safety net, unreachable
        endcase
    end

    // -------------------------------------------------------------------
    // Moore output: pure function of the current state. HIGH only in the
    // dedicated DETECT state, so it never depends on din and cannot glitch on
    // din. This is what makes the machine a genuine Moore FSM.
    // -------------------------------------------------------------------
    assign detected = (state == S1011);

endmodule
