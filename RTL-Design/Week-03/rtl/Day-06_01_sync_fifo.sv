// =============================================================================
`timescale 1ns/1ps
// Module      : sync_fifo
// Description : Synchronous FIFO (single clock domain for both read and
//               write sides - Learning Topic 6.1). Memory array, write
//               pointer, read pointer, and the count register are all
//               updated in ONE always_ff block, per the assignment.
//               full/empty are derived COMBINATIONALLY from count
//               (Learning Topic 6.4 - raw wr_ptr==rd_ptr comparison alone
//               is ambiguous between "just reset" and "completely full",
//               so a count register is used instead, which is the simpler
//               of the two standard approaches).
// =============================================================================

module sync_fifo #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 8
) (
    input  logic clk,
    input  logic rst_n,          // active-low asynchronous reset
    input  logic wr_en,
    input  logic rd_en,
    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,
    output logic full,
    output logic empty
);

    // Pointer width only needs to address DEPTH locations (0..DEPTH-1).
    localparam int PTR_WIDTH = $clog2(DEPTH);
    // Count must represent 0..DEPTH inclusive (DEPTH+1 possible values),
    // which needs one more bit than the pointers themselves - e.g. for
    // DEPTH=8, pointers are 3 bits (0-7) but count needs 4 bits (0-8).
    localparam int CNT_WIDTH = $clog2(DEPTH + 1);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic [CNT_WIDTH-1:0] count;

    // full/empty - combinational, derived from count alone (not from
    // comparing wr_ptr to rd_ptr, which cannot distinguish full from empty
    // on its own - Learning Topic 6.4).
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // Read data - combinational "peek" at the current front of the queue.
    // Design decision (documented explicitly, not left implicit - Day 7
    // principle): dout always shows mem[rd_ptr], regardless of rd_en. When
    // rd_en pulses (and the FIFO isn't empty), rd_ptr advances on the next
    // clock edge and dout will then show the NEXT entry. This keeps the
    // design to exactly the four registers the assignment specifies
    // (mem, wr_ptr, rd_ptr, count) with no separate output register.
    assign dout = mem[rd_ptr];

    // ---------------------------------------------------------------
    // Memory array, write pointer, read pointer, and count - all in
    // ONE always_ff block, per the assignment.
    //
    // Both wr_en and rd_en are individually qualified by !full / !empty
    // BEFORE deciding which case applies. This is what correctly handles
    // every combination automatically, including the trickier ones:
    //   - write while full            -> blocked (data would be lost)
    //   - read while empty            -> blocked (undefined data)
    //   - simultaneous read+write     -> count unchanged, both proceed
    //   - simultaneous read+write,
    //     but FIFO is full            -> only the read proceeds (frees a
    //                                    slot; the write is still blocked
    //                                    since there was no room BEFORE
    //                                    this cycle's read takes effect)
    //   - simultaneous read+write,
    //     but FIFO is empty           -> only the write proceeds
    // ---------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin  // write only
                    mem[wr_ptr] <= din;
                    wr_ptr <= (wr_ptr == DEPTH - 1) ? '0 : wr_ptr + 1'b1;
                    count  <= count + 1'b1;
                end
                2'b01: begin  // read only
                    rd_ptr <= (rd_ptr == DEPTH - 1) ? '0 : rd_ptr + 1'b1;
                    count  <= count - 1'b1;
                end
                2'b11: begin  // simultaneous read + write - count unchanged
                    mem[wr_ptr] <= din;
                    wr_ptr <= (wr_ptr == DEPTH - 1) ? '0 : wr_ptr + 1'b1;
                    rd_ptr <= (rd_ptr == DEPTH - 1) ? '0 : rd_ptr + 1'b1;
                end
                default: begin  // 2'b00 - no valid operation this cycle
                    // explicit empty branch (not left as an implicit
                    // "do nothing") so nothing is inferred as a latch
                end
            endcase
        end
    end

endmodule
