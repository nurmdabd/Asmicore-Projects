// =============================================================================
`timescale 1ns/1ps
// Testbench   : traffic_light_min_duration_tb
// Purpose     : Regression test closing ISSUE-D7-01. Instantiates traffic_light
//               with MAIN_YELLOW_TIME=1 (the minimum realistic value) to
//               confirm the load-vs-decrement priority still advances exactly
//               one cycle later when a phase's duration is 1 - it is loaded
//               with count=0 and is immediately due for reload the very next
//               cycle, with no skip and no extra hang cycle.
//
//               Logging uses the same honest always @(posedge clk) scheme as
//               the smoke TB (see ISSUE-D5-03): cycle 1 is the first cycle out
//               of reset, reset-loaded count included.
// =============================================================================

module traffic_light_min_duration_tb;

    logic clk, rst_n;
    logic main_red, main_yellow, main_green;
    logic side_red, side_yellow, side_green;
    int cycle;

    // Override MAIN_YELLOW_TIME to 1; leave the others at default (4, 6, 2)
    // so the 1-cycle phase sits between two normal-duration phases.
    traffic_light #(.MAIN_YELLOW_TIME(1)) dut (
        .clk(clk), .rst_n(rst_n),
        .main_red(main_red), .main_yellow(main_yellow), .main_green(main_green),
        .side_red(side_red), .side_yellow(side_yellow), .side_green(side_green)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, traffic_light_min_duration_tb);
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

    always @(posedge clk) begin
        if (rst_n) begin
            cycle++;
            $display("%0t\t%0d\t%-11s\t%0b\t%0b\t%0b\t%0b\t%0b\t%0b\t%0d",
                     $time, cycle, state_name(dut.state),
                     main_red, main_yellow, main_green,
                     side_red, side_yellow, side_green, dut.count);
            if (cycle == 16) begin
                $display("Min-duration regression test complete.");
                $finish;
            end
        end
    end

    initial begin
        $display("time\tcycle\tstate\t\tmain_r\tmain_y\tmain_g\tside_r\tside_y\tside_g\tcount");
        rst_n = 0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1;
    end

endmodule
