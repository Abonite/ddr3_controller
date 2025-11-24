module phaser_in_phy_sim();
    logic sys_clk;
    logic m_clk;
    logic p_clk;
    logic rst;

    initial begin
        sys_clk = 1'b0;

        forever begin
            #2 sys_clk = ~sys_clk;
        end

    end

    initial begin
        rst = 1'b1;
        #1000;
        rst = 1'b0;
    end

    initial begin
        m_clk   = 1'b0;

        forever begin
            #4 m_clk = ~m_clk;
        end
    end

    initial begin
        p_clk   = 1'b0;

        forever begin
            #4 p_clk = ~p_clk;
        end
    end

    logic [6:0] counterreadval;
    logic dqsfound;
    logic dqsoutofrange;
    logic fineoverflow;
    logic iclk;
    logic iclkdiv;
    logic iserdesrst;
    logic phaselocked;
    logic rclk;
    logic wrenable;

    logic in;

    always_ff @(sys_clk) begin
        in <= $urandom_range(0,1);
    end

    PHASER_IN_PHY #(
        .BURST_MODE         	(),
        .CLKOUT_DIV         	(),
        .DQS_AUTO_RECAL     	(),
        .DQS_BIAS_MODE      	(),
        .DQS_FIND_PATTERN   	(),
        .FINE_DELAY         	(),
        .FREQ_REF_DIV       	(),
        .IS_RST_INVERTED    	(),
        .MEMREFCLK_PERIOD   	(4.000),
        .OUTPUT_CLK_SRC     	(),
        .PHASEREFCLK_PERIOD 	(4.000),
        .REFCLK_PERIOD      	(2.000),
        .SEL_CLK_OFFSET     	(),
        .SYNC_IN_DIV_RST    	(),
        .WR_CYCLES          	()
    ) u_PHASER_IN_PHY (
        .COUNTERREADVAL  	(counterreadval),
        .DQSFOUND        	(dqsfound),
        .DQSOUTOFRANGE   	(dqsoutofrange),
        .FINEOVERFLOW    	(fineoverflow),
        .ICLK            	(iclk),
        .ICLKDIV         	(iclkdiv),
        .ISERDESRST      	(iserdesrst),
        .PHASELOCKED     	(phaselocked),
        .RCLK            	(rclk),
        .WRENABLE        	(wrenable),
        .BURSTPENDINGPHY 	(),
        .COUNTERLOADEN   	(),
        .COUNTERLOADVAL  	(),
        .COUNTERREADEN   	(),
        .ENCALIBPHY      	(),
        .FINEENABLE      	(),
        .FINEINC         	(),
        .FREQREFCLK      	(sys_clk),
        .MEMREFCLK       	(m_clk),
        .PHASEREFCLK     	(p_clk),
        .RANKSELPHY      	(),
        .RST             	(rst              ),
        .RSTDQSFIND      	(rst),
        .SYNCIN          	(1'b0),
        .SYSCLK          	(sys_clk          )
    );
    
endmodule