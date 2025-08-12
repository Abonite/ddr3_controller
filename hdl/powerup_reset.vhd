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
        o_cs                : out std_logic := '0';    
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
   
    signal curr_state : std_logic_vector := REST;
    signal next_state : std_logic_vector := REST;
    
    signal reset_counter : unsigned(16 downto 0) := (others => '0');
    signal reclk_counter : unsigned(17 downto 0) := (others => '0');
begin
    process (clk) begin
        if rising_edge(clk) then
            if (i_resetting = '1') then
                curr_state <= INIT;
            else
                curr_state <= next_state;
            end if;
        else
            curr_state <= curr_state;
        end if;
    end process;
    
    process (all) begin
       case curr_state is 
            when INIT =>
                if (i_resetting) then
                    next_state <= REST;
                else
                    next_state <= INIT;
                end if;
            when REST =>
                if reset_counter < RESET_COUNT_MAX then
                    next_state <= REST;
                else
                    next_state <= RECK;
                end if;
            when RECK =>
            when CREG =>
            when FINS =>
            when others =>
                next_state <= INIT;
        end case; 
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case curr_state is
                when INIT =>
                    o_reset_n <= '0';
                when REST =>
                    o_reset_n <= '0';
                when others =>
                    o_reset_n <= '1';
            end case;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case curr_state is
                when INIT =>
                    o_cke <= '1';
                when REST =>
                    if reset_counter < (RESET_COUNT_MAX - CKE_COUNT_MAX) then
                        o_cke <= '1';
                    else
                        o_cke <= '0';  -- Set CKE high after reset period
                    end if;
                when others =>
                    o_cke <= '0';
            end case;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case curr_state is
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

    process(clk) begin
        if rising_edge(clk) then
            case curr_state is
                when RECK =>
                    if reclk_counter < RECK_COUNT_MAX then
                        reclk_counter <= reclk_counter + 1;
                    else
                        reclk_counter <= (others => '0');
                    end if;
                when others =>
                    reclk_counter <= (others => '0');
            end case; 
        else
            reclk_counter <= reclk_counter;
        end if;
    end process;
end architecture;