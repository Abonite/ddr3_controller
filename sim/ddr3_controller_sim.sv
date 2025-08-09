module ddr3_controller_sim();
    localparam CLK_PERIOD = 10; // Clock period in nanoseconds (100 MHz)

    logic clk;
    logic rst;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk; // Toggle clock every half period
    end

    initial begin
        rst = 1; // Assert reset
        # (CLK_PERIOD * 20); // Hold reset for 20 clock cycles
        rst = 0; // Deassert reset
        # (CLK_PERIOD * 2000); // Run simulation for additional time
        $finish; // End simulation
    end

    ddr3_controller #(
        .CLK_PERIOD (CLK_PERIOD)
    ) dut (
        .clk    (clk),
        .reset  (rst)
    );

endmodule;