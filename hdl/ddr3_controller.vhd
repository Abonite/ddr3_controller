library IEEE;
Library UNISIM;

use UNISIM.vcomponents.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ddr3_controller is
    generic (
        DDR_DATA_WIDTH: integer := -1;
        DDR_BURST_LENGTH: integer := -1;

        DDR_tXPR: time := -1 ns;
        DDR_tCKSRX: time := -1 ns;
        DDR_tMRD: time := -1 ns;
        DDR_tMODE: time := -1 ns;
        DDR_tDLLK: time := -1 ns;
        DDR_tZQinit: time := -1 ns;

        CLK_PERIOD: time := -1 ns
    );
    port (
        clk             : in std_logic;
        ddr_clk         : in std_logic;
        reset           : in std_logic;

        o_ddr_ck_p      : out std_logic;
        o_ddr_ck_n      : out std_logic;
        o_ddr_cke       : out std_logic := '0';
        o_ddr_cs_n      : out std_logic;
        o_ddr_ras_n     : out std_logic;
        o_ddr_cas_n     : out std_logic;
        o_ddr_we_n      : out std_logic;
        o_ddr_ba        : out std_logic_vector(2 downto 0);
        o_ddr_dqm       : out std_logic_vector(DDR_DATA_WIDTH/8 - 1 downto 0);
        o_ddr_addr      : out std_logic_vector(15 downto 0);
        o_ddr_dq        : out std_logic_vector(DDR_DATA_WIDTH - 1 downto 0);
        o_ddr_reset_n   : out std_logic := '0';
        o_ddr_dqs       : out std_logic_vector(DDR_DATA_WIDTH/8 - 1 downto 0);
        o_ddr_dqs_n     : out std_logic_vector(DDR_DATA_WIDTH/8 - 1 downto 0)
    );
end ddr3_controller;

architecture Behavioral of ddr3_controller is
    constant INIT: std_logic_vector(3 downto 0) := "0000";
    constant REST: std_logic_vector(3 downto 0) := "0001";
    constant ZQCL: std_logic_vector(3 downto 0) := "0010";
    
    signal r_curr_state: std_logic_vector(3 downto 0) := INIT;
    signal r_next_state: std_logic_vector(3 downto 0) := INIT;

    signal resetting: std_logic := '0';
    signal resetted: std_logic := '0';
begin
    process(clk) begin
        if rising_edge(clk) then
            if (reset = '1') then
                r_curr_state <= INIT;
            else
                r_curr_state <= r_next_state;
            end if;
        else
            r_curr_state <= r_curr_state;
        end if;
    end process;

    process(r_curr_state, resetted) begin
        case r_curr_state is
            when INIT =>
                r_next_state <= REST;  -- Transition to REST state after INIT
            when REST =>
                if (resetted = '1') then
                    r_next_state <= ZQCL;
                else
                    r_next_state <= REST;  -- Remain in INIT if condition not met
                end if;
            when ZQCL =>
                r_next_state <= INIT;  -- Loop back to INIT for simplicity
            when others =>
                r_next_state <= INIT;   -- Fallback to INIT
        end case;
    end process;

    u_reset: entity work.powerup_reset
        generic map (
            t_RESET => 200 us,
            t_CKE => DDR_tCKSRX,
            t_MRD => 4,

            UI_CLK_PERIOD => CLK_PERIOD,

            MR0 => "1111111111111111",
            MR1 => "1010101010101010",
            MR2 => "0101010101010101",
            MR3 => "0000000000000000"
        )
        port map (
            clk => clk,
            i_resetting => resetting,
            o_reset_n => o_ddr_reset_n,
            o_cke => o_ddr_cke,
            o_reset_finished => resetted
        );

    OBUFDS_inst : OBUFDS
        generic map (
            IOSTANDARD => "DEFAULT", -- Specify the output I/O standard
            SLEW => "FAST"
        )
        port map (
            O => o_ddr_ck_p,     -- Diff_p output (connect directly to top-level port)
            OB => o_ddr_ck_n,   -- Diff_n output (connect directly to top-level port)
            I => ddr_clk      -- Buffer input 
        );
  
end architecture;