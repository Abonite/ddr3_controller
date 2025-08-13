library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity powerup_reset is
    generic (
        t_RESET: time := -1 us;
        t_CKE: time := -1 ns;

        CLK_PERIOD: time := -1 ns
    );
    port (
        clk                 : in std_logic;

        i_resetting         : in std_logic;

        o_reset_n           : out std_logic := '0';
        o_cke               : out std_logic := '0';
        o_cs_n              : out std_logic := '1';    
        o_reset_finished    : out std_logic := '0'
    );
end powerup_reset;

architecture Behavioral of powerup_reset is
    constant INIT : std_logic_vector(3 downto 0) := "0000";
    constant REST : std_logic_vector(3 downto 0) := "0001";
    constant RECK : std_logic_vector(3 downto 0) := "0010";
    constant CREG : std_logic_vector(3 downto 0) := "0100";
    constant FINS : std_logic_vector(3 downto 0) := "1000";

    constant RESET_COUNT_MAX : unsigned(16 downto 0) := to_unsigned(integer(t_RESET / CLK_PERIOD), 17);
    constant CKE_COUNT_MAX : unsigned(16 downto 0) := to_unsigned(integer(t_CKE / CLK_PERIOD), 17);
    constant RECK_COUNT_MAX : unsigned(17 downto 0) := to_unsigned(integer(500 us / CLK_PERIOD), 18);

    signal r_curr_state : std_logic_vector := REST;
    signal r_next_state : std_logic_vector := REST;
    
    signal r_reset_counter : unsigned(16 downto 0) := (others => '0');
    signal r_reclk_counter : unsigned(17 downto 0) := (others => '0');
    signal r_reset_n: std_logic := '0';
    signal r_cke: std_logic := '0';
    signal r_cs_n: std_logic := '1';
begin
    process (clk) begin
        if rising_edge(clk) then
            if (i_resetting = '1') then
                r_curr_state <= INIT;
            else
                r_curr_state <= r_next_state;
            end if;
        else
            r_curr_state <= r_curr_state;
        end if;
    end process;
    
    process (all) begin
        case r_curr_state is 
            when INIT =>
                if (i_resetting = '1') then
                    r_next_state <= REST;
                else
                    r_next_state <= INIT;
                end if;
            when REST =>
                if (r_reset_counter < RESET_COUNT_MAX) then
                    r_next_state <= REST;
                else
                    r_next_state <= RECK;
                end if;
            when RECK =>
                if (r_reclk_counter < RECK_COUNT_MAX) then
                    r_next_state <= RECK;
                else
                    r_next_state <= CREG;
                end if;
            when CREG =>
            when FINS =>
            when others =>
                r_next_state <= INIT;
        end case; 
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    r_reset_n <= '0';
                when REST =>
                    r_reset_n <= '0';
                when others =>
                    r_reset_n <= '1';
            end case;
        else
            r_reset_n <= r_reset_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    r_cke <= '1';
                when REST =>
                    if r_reset_counter < (RESET_COUNT_MAX - CKE_COUNT_MAX) then
                        r_cke <= '1';
                    else
                        r_cke <= '0';  -- Set CKE high after reset period
                    end if;
                when RECK =>
                    r_cke <= '0';
                when CREG =>
                    r_cke <= '1';
                when others =>
                    r_cke <= '0';
            end case;
        else
            r_cke <= r_cke;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
            when INIT =>
                r_cs_n <= '1';
            when REST =>
                r_cs_n <= '1';
            when RECK =>
                r_cs_n <= '1';
            when CREG =>
                r_cs_n <= '0';
            when others =>
                r_cs_n <= '0';
            end case;
        else
            r_cs_n <= r_cs_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when REST =>
                    if (r_reset_counter < RESET_COUNT_MAX) then
                        r_reset_counter <= r_reset_counter + 1;
                    else
                        r_reset_counter <= (others => '0');
                    end if;
                when others =>
                    r_reset_counter <= (others => '0');
            end case; 
        else
            r_reset_counter <= r_reset_counter;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when RECK =>
                    if r_reclk_counter < RECK_COUNT_MAX then
                        r_reclk_counter <= r_reclk_counter + 1;
                    else
                        r_reclk_counter <= (others => '0');
                    end if;
                when others =>
                    r_reclk_counter <= (others => '0');
            end case; 
        else
            r_reclk_counter <= r_reclk_counter;
        end if;
    end process;
end architecture;