module ddr3_controller_sim();
    localparam CLK_PERIOD = 10; // Clock period in nanoseconds (100 MHz)
    localparam DDR_CLK_PERIOD = 3; // DDR clock period in nanoseconds (666 MHz)

    logic clk;
    logic rst;

    logic ddr_clk;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk; // Toggle clock every half period
    end

    initial begin
        ddr_clk = 0;
        forever #(DDR_CLK_PERIOD/2) ddr_clk = ~ddr_clk; // Toggle DDR clock every half period
    end

    initial begin
        rst = 1; // Assert reset
        # (CLK_PERIOD * 20); // Hold reset for 20 clock cycles
        rst = 0; // Deassert reset
    end

    ddr3_controller #(
        .CLK_PERIOD (CLK_PERIOD)
    ) dut (
        .clk    (clk),
        .ddr_clk(ddr_clk),
        .reset  (rst)
    );

endmodule;