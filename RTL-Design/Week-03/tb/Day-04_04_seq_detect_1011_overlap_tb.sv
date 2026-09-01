// =============================================================================
// Testbench   : seq_detect_1011_overlap_tb
// Purpose     : Dedicated, SELF-CHECKING regression for the overlapping-match
//               corner case (Day 7 corner case #1). The Day 4 smoke vector
//               1101011 contains only ONE occurrence of "1011", so it does NOT
//               actually exercise overlap. This test drives 1011011, which
//               contains TWO occurrences that share the middle '1':
//                   1 0 1 1 0 1 1
//                   \______/          match #1  (bits 1-4)
//                         \______/    match #2  (bits 4-7, overlapping)
//               and asserts that 'detected' pulses exactly twice, on the
//               expected cycles, 3 cycles apart (the minimum gap for an
//               overlapping 1011 - the overlap reuses 1 bit of the 4).
//
//               Mirrors the pattern used for the FIFO (smoke + self-checking
//               multiwrap) and the traffic light (smoke + min-duration): a
//               plain smoke test plus a focused, self-checking regression.
// =============================================================================

`timescale 1ns/1ps

module seq_detect_1011_overlap_tb;

    logic clk, rst_n, din, detected;
    int   cycle;
    int   pulses;
    logic ok;

    // cycles 1..9 : 1 0 1 1 0 1 1 then two trailing 0s
    logic [0:8] stim = 9'b101101100;

    // Expected: with the 5-state Moore FSM (detected HIGH in state S1011,
    // one cycle after each completing 4th bit), pulses land in cycle 5 and
    // cycle 8 - two pulses, exactly 3 cycles apart.
    localparam int EXP_PULSE_A = 5;
    localparam int EXP_PULSE_B = 8;

    seq_detect_1011 dut (.clk(clk), .rst_n(rst_n), .din(din), .detected(detected));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, seq_detect_1011_overlap_tb);
    end

    initial clk = 0;
    always #5 clk = ~clk;

    function string state_name(logic [2:0] s);
        case (s)
            3'd0: state_name = "IDLE";  3'd1: state_name = "S1";
            3'd2: state_name = "S10";   3'd3: state_name = "S101";
            3'd4: state_name = "S1011"; default: state_name = "??";
        endcase
    endfunction

    initial begin
        rst_n = 0; din = 0; pulses = 0; ok = 1;
        @(negedge clk); @(negedge clk);
        rst_n = 1;
        for (int i = 0; i < 9; i++) begin din = stim[i]; @(negedge clk); end
        din = 0;
    end

    initial $display("time\tcycle\tstate\tdin\tdetected");
    always @(posedge clk) begin
        if (rst_n) begin
            cycle++;
            $display("%0t\t%0d\t%-5s\t%0b\t%0b",
                     $time, cycle, state_name(dut.state), din, detected);
            if (detected) begin
                pulses++;
                if (cycle != EXP_PULSE_A && cycle != EXP_PULSE_B) begin
                    ok = 0; $display("  FAIL: unexpected detected pulse at cycle %0d", cycle);
                end
            end
            if (cycle == 9) begin
                if (pulses != 2) begin
                    ok = 0;
                    $display("  FAIL: expected exactly 2 overlapping detections, got %0d", pulses);
                end
                if (ok) $display("PASS: overlapping 1011 detected twice (cycles %0d and %0d, 3-cycle gap).",
                                 EXP_PULSE_A, EXP_PULSE_B);
                else    $display("RESULT: FAIL");
                $finish;
            end
        end
    end

endmodule
