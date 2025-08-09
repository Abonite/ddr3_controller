library IEEE;

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
        reset           : in std_logic;

        o_ddr_ck_p      : out std_logic;
        o_ddr_ck_n      : out std_logic;
        o_ddr_cke       : out std_logic;
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
    
    constant RESET_COUNT_MAX : unsigned(16 downto 0) := to_unsigned(integer(200 us / CLK_PERIOD), 17);
    
    signal r_curr_state: std_logic_vector(3 downto 0) := INIT;
    signal r_next_state: std_logic_vector(3 downto 0) := INIT;

    signal reset_counter: unsigned(16 downto 0) := (others => '0');
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

    process(r_curr_state, reset_counter) begin
        case r_curr_state is
            when INIT =>
                r_next_state <= REST;  -- Transition to REST state after INIT
            when REST =>
                if (reset_counter = RESET_COUNT_MAX) then
                    r_next_state <= ZQCL;
                else
                    r_next_state <= REST;  -- Remain in INIT if condition not met
                end if;
            when ZQCL =>
                o_ddr_reset_n <= '1';  -- Assuming ZQCL does not change reset state
                r_next_state <= INIT;  -- Loop back to INIT for simplicity

            when others =>
                o_ddr_reset_n <= '0';  -- Default case, can be modified as needed
                r_next_state <= INIT;   -- Fallback to INIT
        end case;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    o_ddr_reset_n <= '0';
                when REST =>
                    o_ddr_reset_n <= '0';
                when others =>
                    o_ddr_reset_n <= '1';
            end case;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when REST =>
                    if reset_counter < RESET_COUNT_MAX then
                        reset_counter <= reset_counter + 1;
                    else
                        reset_counter <= (others => '0');
                    end if;
                when others =>
                    reset_counter <= (others => '0');
            end case; 
        else
            reset_counter <= reset_counter;
        end if;
    end process;

end architecture;