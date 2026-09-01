// =============================================================================
`timescale 1ns/1ps
// Module      : traffic_light
// Description : Traffic light controller cycling through four timed phases:
//                 MAIN_GREEN -> MAIN_YELLOW -> SIDE_GREEN -> SIDE_YELLOW -> (repeat)
//               Durations are parameterized (small default values chosen so
//               the smoke test finishes quickly in simulation - see Day 5
//               Learning Topic 5.2, "parameter for duration values - makes
//               the design testable with short durations").
//
//               FSM + datapath pattern (Learning Topic 5.1): the FSM decides
//               WHAT phase comes next (a fixed round-robin sequence - there
//               is no external input driving this design at all); a
//               down-counter datapath decides HOW LONG to stay in each
//               phase. The FSM only advances when the counter reaches zero.
//
// Author      : Nur (RTL implemented as part of Day 5 experimental work)
// =============================================================================

module traffic_light #(
    parameter int MAIN_GREEN_TIME  = 4,  // cycles to hold MAIN_GREEN
    parameter int MAIN_YELLOW_TIME = 2,  // cycles to hold MAIN_YELLOW
    parameter int SIDE_GREEN_TIME  = 6,  // cycles to hold SIDE_GREEN
    parameter int SIDE_YELLOW_TIME = 2,  // cycles to hold SIDE_YELLOW
    // Must be >= the largest of the four durations above. Only this one
    // parameter needs widening if you increase any duration beyond 6 -
    // it sizes the counter, nothing else.
    parameter int MAX_DURATION     = 6
) (
    input  logic clk,
    input  logic rst_n,        // active-low asynchronous reset

    output logic main_red,
    output logic main_yellow,
    output logic main_green,
    output logic side_red,
    output logic side_yellow,
    output logic side_green
);

    // -------------------------------------------------------------------
    // State declaration - four phases, fixed round-robin sequence.
    // Unlike Day 4's sequence detector, there is no external input here:
    // the ONLY thing that ever causes a transition is the counter
    // reaching zero.
    // -------------------------------------------------------------------
    typedef enum logic [1:0] {
        MAIN_GREEN, MAIN_YELLOW, SIDE_GREEN, SIDE_YELLOW
    } state_t;
    state_t state, next_state;

    localparam int CNT_WIDTH = $clog2(MAX_DURATION);
    logic [CNT_WIDTH-1:0] count;             // down-counter: current phase's remaining cycles
    logic [CNT_WIDTH-1:0] next_duration_m1;  // duration-1 for whichever phase comes next

    // -------------------------------------------------------------------
    // Next-state logic (always_comb) - purely the fixed sequence. This
    // block only answers "what comes after what," never "when" - timing
    // is entirely the counter's job, kept in a separate block on purpose
    // (Learning Topic 5.1: "FSM controls state, counter controls duration").
    // -------------------------------------------------------------------
    always_comb begin
        case (state)
            MAIN_GREEN:  next_state = MAIN_YELLOW;
            MAIN_YELLOW: next_state = SIDE_GREEN;
            SIDE_GREEN:  next_state = SIDE_YELLOW;
            SIDE_YELLOW: next_state = MAIN_GREEN;
            default:     next_state = MAIN_GREEN;  // safety net, unreachable
        endcase
    end

    // Duration-minus-1 for whichever state we are ABOUT to enter (used only
    // at the instant the counter gets reloaded, in the always_ff below).
    // Minus 1 because the reload cycle itself is the first of that phase's
    // 'duration' cycles - e.g. MAIN_GREEN_TIME=4 means 4 total cycles in
    // MAIN_GREEN, so the counter counts 3,2,1,0 (4 values).
    always_comb begin
        case (next_state)
            MAIN_GREEN:  next_duration_m1 = MAIN_GREEN_TIME  - 1;
            MAIN_YELLOW: next_duration_m1 = MAIN_YELLOW_TIME - 1;
            SIDE_GREEN:  next_duration_m1 = SIDE_GREEN_TIME  - 1;
            SIDE_YELLOW: next_duration_m1 = SIDE_YELLOW_TIME - 1;
            default:     next_duration_m1 = MAIN_GREEN_TIME  - 1;
        endcase
    end

    // -------------------------------------------------------------------
    // State register + down-counter, in ONE always_ff, per the assignment.
    // Load-vs-decrement priority: reaching zero (i.e. "done") always wins
    // over plain decrementing, since that is the one event that means
    // "this phase is over, move on and reload for the next one."
    // -------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= MAIN_GREEN;
            count <= MAIN_GREEN_TIME - 1;  // -1 so the FIRST MAIN_GREEN lasts exactly
                                           // MAIN_GREEN_TIME cycles, identical to every
                                           // later MAIN_GREEN (see ISSUE-D5-02, corrected)
        end else if (count == '0) begin
            state <= next_state;
            count <= next_duration_m1;
        end else begin
            count <= count - 1'b1;
        end
    end

    // -------------------------------------------------------------------
    // Output logic (always_comb) - pure Moore output, a function of state
    // alone. One-hot-per-road-pair style: exactly one of {red, yellow,
    // green} is HIGH per road at all times.
    //
    // Explicit design decision (documented, not left implicit - see Day 7's
    // "don't leave it implicit" principle): during BOTH yellow phases, the
    // *other* road is RED for the entire phase. There is never a moment
    // where both roads show anything other than "one green/yellow, one
    // red."
    // -------------------------------------------------------------------
    always_comb begin
        {main_red, main_yellow, main_green, side_red, side_yellow, side_green} = '0;
        case (state)
            MAIN_GREEN:  begin main_green  = 1'b1; side_red    = 1'b1; end
            MAIN_YELLOW: begin main_yellow = 1'b1; side_red    = 1'b1; end
            SIDE_GREEN:  begin main_red    = 1'b1; side_green  = 1'b1; end
            SIDE_YELLOW: begin main_red    = 1'b1; side_yellow = 1'b1; end
            default:     begin main_red    = 1'b1; side_red    = 1'b1; end  // safe all-red default
        endcase
    end

endmodule
