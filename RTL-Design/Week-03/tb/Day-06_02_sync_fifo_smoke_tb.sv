// =============================================================================
`timescale 1ns/1ps
// Testbench   : sync_fifo_smoke_tb
// Purpose     : Required smoke sequence per the assignment:
//                 reset -> fill to full -> attempt one extra write (blocked)
//                 -> drain to empty -> attempt one extra read (blocked)
//               PLUS an added block specifically exercising simultaneous
//               read+write (while full, while partially filled, and while
//               empty) - the base sequence above never actually creates a
//               cycle where wr_en and rd_en are both asserted together, and
//               the assignment explicitly calls out "handle simultaneous
//               read+write - count must not change" as something to verify,
//               not just implement.
//               Prints wr_en / rd_en / din / dout / count / full / empty
//               every cycle. WIDTH=8, DEPTH=8 (assignment defaults).
// =============================================================================

module sync_fifo_smoke_tb;

    localparam int WIDTH = 8;
    localparam int DEPTH = 8;

    logic clk, rst_n;
    logic wr_en, rd_en;
    logic [WIDTH-1:0] din;
    logic [WIDTH-1:0] dout;
    logic full, empty;

    int cycle;

    sync_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .wr_en  (wr_en),
        .rd_en  (rd_en),
        .din    (din),
        .dout   (dout),
        .full   (full),
        .empty  (empty)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, sync_fifo_smoke_tb);
    end

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic do_cycle(input string label);
        @(negedge clk);
        $display("%0t\t%0d\t%-20s\t%0b\t%0b\t%0h\t%0h\t%0d\t%0b\t%0b",
                  $time, cycle, label, wr_en, rd_en, din, dout,
                  dut.count, full, empty);
        cycle++;
    endtask

    initial begin
        $display("time\tcycle\tphase\t\t\twr\trd\tdin\tdout\tcount\tfull\tempty");
        cycle = 1;
        wr_en = 0; rd_en = 0; din = '0;

        // --- Reset ---
        rst_n = 0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1;

        // === REQUIRED SEQUENCE =========================================

        // --- Fill to full: 8 writes, din = 0x10..0x17 ---
        for (int i = 0; i < DEPTH; i++) begin
            wr_en = 1; rd_en = 0; din = 8'h10 + i[7:0];
            do_cycle("fill");
        end

        // --- Attempt one extra write while full (should be blocked) ---
        wr_en = 1; rd_en = 0; din = 8'hFF;  // poison value - must NOT appear later
        do_cycle("write-while-full");

        // === ADDED: simultaneous read+write coverage ====================
        // (not exercised by the base sequence above, but explicitly called
        // out in the assignment as something to "handle")

        // --- Simultaneous R+W while FULL: only the read should proceed;
        //     this write (0xA0) must NOT be stored, since there was no room
        //     BEFORE this cycle's read takes effect ---
        wr_en = 1; rd_en = 1; din = 8'hA0;
        do_cycle("simul-RW-while-full");

        // --- Simultaneous R+W while partially filled (count=7 now, neither
        //     full nor empty): BOTH should proceed, count unchanged ---
        wr_en = 1; rd_en = 1; din = 8'hA1;
        do_cycle("simul-RW-normal");

        wr_en = 0; rd_en = 0; din = '0;
        do_cycle("idle");

        // --- Drain the remaining 7 entries. Expected order: 0x12, 0x13,
        //     0x14, 0x15, 0x16, 0x17, then 0xA1 (the value written during
        //     the simultaneous R+W above) - confirming 0x10 (consumed
        //     earlier) and 0xFF (blocked, never stored) correctly never
        //     reappear ---
        for (int i = 0; i < 7; i++) begin
            wr_en = 0; rd_en = 1; din = '0;
            do_cycle("drain");
        end

        // --- Attempt one extra read while empty (should be blocked) ---
        wr_en = 0; rd_en = 1; din = '0;
        do_cycle("read-while-empty");

        // --- Simultaneous R+W while EMPTY: only the write should proceed;
        //     the read must be blocked (nothing valid to return) ---
        wr_en = 1; rd_en = 1; din = 8'hB0;
        do_cycle("simul-RW-while-empty");

        // --- Drain the final single entry (0xB0) to confirm it landed
        //     correctly and the FIFO returns to empty cleanly ---
        wr_en = 0; rd_en = 1; din = '0;
        do_cycle("final-drain");

        $display("Smoke test complete.");
        $finish;
    end

endmodule
