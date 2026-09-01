// =============================================================================
`timescale 1ns/1ps
// Testbench   : sync_fifo_multiwrap_tb
// Purpose     : Regression test closing ISSUE-D7-02. Runs THREE consecutive
//               fill-then-drain cycles back to back (instead of just one),
//               so both wr_ptr and rd_ptr wrap around the DEPTH boundary
//               multiple times in a row. Checks data integrity across every
//               wrap, not just the first one - a systematic addressing bug
//               at the wrap point could plausibly only surface on a SECOND
//               or THIRD wrap if the first one happened to mask it.
// =============================================================================

module sync_fifo_multiwrap_tb;

    localparam int WIDTH = 8;
    localparam int DEPTH = 8;

    logic clk, rst_n;
    logic wr_en, rd_en;
    logic [WIDTH-1:0] din;
    logic [WIDTH-1:0] dout;
    logic full, empty;

    int cycle;
    int errors;
    logic [WIDTH-1:0] expected_q[$];  // software reference queue (scoreboard-style)
    logic [WIDTH-1:0] expected_val;

    sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en),
        .din(din), .dout(dout), .full(full), .empty(empty)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, sync_fifo_multiwrap_tb);
    end

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic do_write(input [7:0] val);
        wr_en = 1; rd_en = 0; din = val;
        @(negedge clk);
        expected_q.push_back(val);
        cycle++;
    endtask

    task automatic do_read();
        logic [WIDTH-1:0] captured;
        wr_en = 0; rd_en = 1; din = '0;
        captured = dout;  // combinational peek BEFORE the clock edge - this is the value this read actually consumes
        @(negedge clk);
        expected_val = expected_q.pop_front();
        if (captured !== expected_val) begin
            $display("  MISMATCH at cycle %0d: read_value=%0h expected=%0h", cycle, captured, expected_val);
            errors++;
        end
        cycle++;
    endtask

    initial begin
        errors = 0;
        cycle = 1;
        wr_en = 0; rd_en = 0; din = '0;
        rst_n = 0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1;

        $display("Running 3 consecutive fill-then-drain cycles (24 writes, 24 reads total)...");

        for (int loop = 0; loop < 3; loop++) begin
            // Fill to full - use a different value range each loop so a
            // stale-data bug from a PREVIOUS wrap would be obvious
            for (int i = 0; i < DEPTH; i++) begin
                do_write(8'(loop * 8'h20 + i));
            end
            // Drain to empty, checking every value against the reference queue
            for (int i = 0; i < DEPTH; i++) begin
                do_read();
            end
        end

        wr_en = 0; rd_en = 0;
        @(negedge clk);

        if (errors == 0)
            $display("PASS: all 24 reads across 3 wraps matched the reference queue exactly.");
        else
            $display("FAIL: %0d mismatch(es) found.", errors);

        $display("Multi-wrap regression test complete.");
        $finish;
    end

endmodule
