// =============================================================================
// Testbench   : traffic_light_smoke_tb
// Purpose     : Smoke test using the small simulation-friendly durations
//               (4, 2, 6, 2 cycles). Prints cycle / state name / all 6 light
//               outputs / internal count every cycle, and runs 20 cycles to
//               observe one full loop (14 cycles: 4+2+6+2) plus into the
//               SECOND loop, confirming the wraparound repeats correctly.
//
//               LOGGING NOTE (see ISSUE-D5-03): logging is done in an
//               always @(posedge clk) block that reads the registered values
//               in the SAME cycle they are held (pre-edge / active region),
//               so cycle 1 is the very first cycle out of reset - INCLUDING
//               the reset-loaded count value. An earlier version sampled with
//               a for-loop of @(negedge clk) after two reset-settle negedges,
//               which silently skipped the reset cycle and under-counted the
//               first MAIN_GREEN phase by one. That masked ISSUE-D5-02.
// =============================================================================

`timescale 1ns/1ps

module traffic_light_smoke_tb;

    logic clk;
    logic rst_n;
    logic main_red, main_yellow, main_green;
    logic side_red, side_yellow, side_green;

    int cycle;

    traffic_light dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .main_red    (main_red),
        .main_yellow (main_yellow),
        .main_green  (main_green),
        .side_red    (side_red),
        .side_yellow (side_yellow),
        .side_green  (side_green)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, traffic_light_smoke_tb);
    end

    initial clk = 0;
    always #5 clk = ~clk;

    function string state_name(logic [1:0] s);
        case (s)
            2'd0: state_name = "MAIN_GREEN";
            2'd1: state_name = "MAIN_YELLOW";
            2'd2: state_name = "SIDE_GREEN";
            2'd3: state_name = "SIDE_YELLOW";
            default: state_name = "??";
        endcase
    endfunction

    // Honest per-cycle logger. Reads registered state/count in the active
    // region at the posedge -> the values held DURING this cycle (before this
    // edge's non-blocking updates), so the reset-loaded first cycle is shown.
    always @(posedge clk) begin
        if (rst_n) begin
            cycle++;
            $display("%0t\t%0d\t%-11s\t%0b\t%0b\t%0b\t%0b\t%0b\t%0b\t%0d",
                     $time, cycle, state_name(dut.state),
                     main_red, main_yellow, main_green,
                     side_red, side_yellow, side_green, dut.count);
            if (cycle == 20) begin
                $display("Smoke test complete.");
                $finish;
            end
        end
    end

    // This design has no data inputs (Learning Topic 5.1 - transitions are
    // driven solely by the counter reaching zero), so the stimulus is just
    // reset, then free-run.
    initial begin
        $display("time\tcycle\tstate\t\tmain_r\tmain_y\tmain_g\tside_r\tside_y\tside_g\tcount");
        rst_n = 0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1;
    end

endmodule
