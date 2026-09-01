// =============================================================================
// Testbench   : seq_detect_1011_smoke_tb
// Purpose     : Minimal smoke test - drive the hand-traced stimulus vector
//               (1 1 0 1 0 1 1) plus two trailing 0s, print din / state /
//               detected every cycle, and confirm by eye that the design
//               matches the Day 2 hand-trace prediction.
//
// TIMING / PREDICTION (matches the Day 2 state-diagram hand-trace):
//   This is a Moore FSM. 'detected' is HIGH only while the machine is in the
//   dedicated DETECT state S1011. The pattern "1011" is completed by the 4th
//   matching bit (the 7th input bit here). That bit is sampled at the cycle-7
//   clock edge WHILE the machine is in S101, moving it into S1011; so
//   'detected' reads HIGH in the FOLLOWING cycle (cycle 8), which is the
//   ordinary one-cycle latency of a clocked FSM output.
//
//   Logging is done in an always @(posedge clk) block that reads the
//   registered state in the cycle it is HELD (pre-edge). So each row shows:
//   the state the FSM is in during that cycle, the din bit being consumed on
//   that cycle's edge, and detected for that cycle. Prediction:
//       cycle 7: state=S101,  din=1 (the 4th bit), detected=0
//       cycle 8: state=S1011,               detected=1   <-- the pulse
//       cycle 9: state=S10,                 detected=0   (clears)
//   (An earlier draft used a 4-state Mealy skeleton with a registered output
//   and post-edge printing, which put the pulse on the cycle-7 row and led to
//   a muddled "no extra delay" note. Superseded; see ISSUE-D4-01, corrected.)
// =============================================================================

`timescale 1ns/1ps

module seq_detect_1011_smoke_tb;

    logic clk;
    logic rst_n;
    logic din;
    logic detected;

    int cycle;

    // Cycle-indexed stimulus: bits for cycles 1..9.
    //   real vector 1 1 0 1 0 1 1  (bits 1-7), then two trailing 0s (8-9)
    logic [0:8] stim = 9'b110101100;

    seq_detect_1011 dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .din      (din),
        .detected (detected)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, seq_detect_1011_smoke_tb);
    end

    initial clk = 0;
    always #5 clk = ~clk;

    // Readable state name (mirrors the DUT's 5-state enum, 3 encoding bits).
    function string state_name(logic [2:0] s);
        case (s)
            3'd0: state_name = "IDLE";
            3'd1: state_name = "S1";
            3'd2: state_name = "S10";
            3'd3: state_name = "S101";
            3'd4: state_name = "S1011";
            default: state_name = "??";
        endcase
    endfunction

    // Stimulus: drive din on the negedge so it is stable before the posedge
    // that samples it. din on a given cycle's row is the bit consumed by that
    // cycle's rising edge.
    initial begin
        rst_n = 0;
        din   = 0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1;
        for (int i = 0; i < 9; i++) begin
            din = stim[i];
            @(negedge clk);
        end
        din = 0;
    end

    // Honest per-cycle logger: reads the state/detected held DURING this cycle
    // (pre-edge), so the one-cycle Moore latency is visible directly.
    initial $display("time\tcycle\tstate\tdin\tdetected");
    always @(posedge clk) begin
        if (rst_n) begin
            cycle++;
            $display("%0t\t%0d\t%-5s\t%0b\t%0b",
                     $time, cycle, state_name(dut.state), din, detected);
            if (cycle == 9) begin
                $display("Smoke test complete.");
                $finish;
            end
        end
    end

endmodule
