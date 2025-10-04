library IEEE;
Library UNISIM;

use UNISIM.vcomponents.all;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity ddr3_phy is
    generic (
        ADDR_WIDTH: integer := -1;
        DATA_WIDTH: integer := -1;
        BURST_LENTH: integer := -1
        
    );
    port(
        ddr_clk : in std_logic;

        i_user_command: in std_logic_vector(4 downto 0);
        i_user_dqs_delay: in std_logic;
        i_user_baddr: in std_logic_vector(2 downto 0);
        i_user_addr: in std_logic_vector((ADDR_WIDTH - 1) downto 0);
        i_user_data:    in std_logic_vector(((BURST_LENTH * DATA_WIDTH) - 1) downto 0);

        o_ddr_reset_n: out std_logic := '0';
        o_ddr_ck_p: out std_logic := '0';
        o_ddr_ck_n: out std_logic := '1';
        o_ddr_cke: out std_logic := '0';
        o_ddr_cs_n: out std_logic := '1';
        o_ddr_ras_n: out std_logic := '1';
        o_ddr_cas_n: out std_logic := '1';
        o_ddr_we_n: out std_logic := '1';
        o_ddr_ba: out std_logic_vector(2 downto 0);
        o_ddr_addr: out std_logic_vector(15 downto 0);
        o_ddr_dqs_p: inout std_logic_vector(((DATA_WIDTH / 8) - 1) downto 0);
        o_ddr_dqs_n: inout std_logic_vector(((DATA_WIDTH / 8) - 1) downto 0);
        o_ddr_dqm: out std_logic_vector(((DATA_WIDTH / 8) - 1) downto 0);
        o_ddr_dq: inout std_logic_vector((DATA_WIDTH - 1) downto 0);
        o_ddr_odt: out std_logic
    );
end entity ddr3_phy;

architecture Behaveioral of ddr3_phy is
    
begin


    DQ_IO_GEN: for i in 0 to DATA_WIDTH generate
        OSERDESE2_inst : OSERDESE2
        generic map (
            DATA_RATE_OQ => "DDR",   -- DDR, SDR
            DATA_RATE_TQ => "DDR",   -- DDR, BUF, SDR
            DATA_WIDTH => 8,         -- Parallel data width (2-8,10,14)
            INIT_OQ => '0',          -- Initial value of OQ output (1'b0,1'b1)
            INIT_TQ => '0',          -- Initial value of TQ output (1'b0,1'b1)
            SERDES_MODE => "MASTER", -- MASTER, SLAVE
            SRVAL_OQ => '0',         -- OQ output value when RST is used (1'b0,1'b1)
            SRVAL_TQ => '0',         -- TQ output value when RST is used (1'b0,1'b1)
            TBYTE_CTL => "FALSE",    -- Enable tristate byte operation (FALSE, TRUE)
            TBYTE_SRC => "FALSE",    -- Tristate byte source (FALSE, TRUE)
            TRISTATE_WIDTH => 4      -- 3-state converter width (1,4)
        )
        port map (
            OFB => OFB,             -- 1-bit output: Feedback path for data
            OQ => OQ,               -- 1-bit output: Data path output
            -- SHIFTOUT1 / SHIFTOUT2: 1-bit (each) output: Data output expansion (1-bit each)
            SHIFTOUT1 => SHIFTOUT1,
            SHIFTOUT2 => SHIFTOUT2,
            TBYTEOUT => TBYTEOUT,   -- 1-bit output: Byte group tristate
            TFB => TFB,             -- 1-bit output: 3-state control
            TQ => TQ,               -- 1-bit output: 3-state control
            CLK => ddr_clk,             -- 1-bit input: High speed clock
            CLKDIV => '0',       -- 1-bit input: Divided clock
            -- D1 - D8: 1-bit (each) input: Parallel data inputs (1-bit each)
            D1 => i_user_data((i * DATA_WIDTH) + 0),
            D2 => i_user_data((i * DATA_WIDTH) + 1),
            D3 => i_user_data((i * DATA_WIDTH) + 2),
            D4 => i_user_data((i * DATA_WIDTH) + 3),
            D5 => i_user_data((i * DATA_WIDTH) + 4),
            D6 => i_user_data((i * DATA_WIDTH) + 5),
            D7 => i_user_data((i * DATA_WIDTH) + 6),
            D8 => i_user_data((i * DATA_WIDTH) + 7),
            OCE => OCE,             -- 1-bit input: Output data clock enable
            RST => RST,             -- 1-bit input: Reset
            -- SHIFTIN1 / SHIFTIN2: 1-bit (each) input: Data input expansion (1-bit each)
            SHIFTIN1 => SHIFTIN1,
            SHIFTIN2 => SHIFTIN2,
            -- T1 - T4: 1-bit (each) input: Parallel 3-state inputs
            T1 => T1,
            T2 => T2,
            T3 => T3,
            T4 => T4,
            TBYTEIN => TBYTEIN,     -- 1-bit input: Byte group tristate
            TCE => TCE              -- 1-bit input: 3-state clock enable
        ); 
        end generate;
end architecture Behaveioral;