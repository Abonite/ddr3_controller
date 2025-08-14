library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity powerup_reset is
    generic (
        t_RESET: time := -1 us;
        t_CKE: time := -1 ns;
        t_XPR: time := -1 ns;
        t_MRD: integer := 1;

        UI_CLK_PERIOD: time := -1 ns;

        MR0: std_logic_vector(15 downto 0) := (others => '0');
        MR1: std_logic_vector(15 downto 0) := (others => '0');
        MR2: std_logic_vector(15 downto 0) := (others => '0');
        MR3: std_logic_vector(15 downto 0) := (others => '0')
    );
    port (
        clk                 : in std_logic;

        i_resetting         : in std_logic;

        o_reset_n           : out std_logic := '0';
        o_cke               : out std_logic := '0';
        o_cs_n              : out std_logic := '1';    
        o_ras_n             : out std_logic := '1';
        o_cas_n             : out std_logic := '1';
        o_we_n              : out std_logic := '1';
        o_ba                : out std_logic_vector(2 downto 0) := (others => '0');
        o_addr              : out std_logic_vector(15 downto 0) := (others => '0');
        o_reset_finished    : out std_logic := '0'
    );
end powerup_reset;

architecture Behavioral of powerup_reset is
    constant INIT : std_logic_vector(3 downto 0) := "0000";
    constant REST : std_logic_vector(3 downto 0) := "0001";
    constant RECK : std_logic_vector(3 downto 0) := "0010";
    constant CREG : std_logic_vector(3 downto 0) := "0100";
    constant FINS : std_logic_vector(3 downto 0) := "1000";

    constant RESET_COUNT_MAX : unsigned(16 downto 0) := to_unsigned(integer(t_RESET / UI_CLK_PERIOD), 17);
    constant CKE_COUNT_MAX : unsigned(16 downto 0) := to_unsigned(integer(t_CKE / UI_CLK_PERIOD), 17);
    constant RECK_COUNT_MAX : unsigned(17 downto 0) := to_unsigned(integer(500 us / UI_CLK_PERIOD), 18);
    constant XPR_COUNT_MAX : unsigned(17 downto 0) := to_unsigned(integer(t_XPR / UI_CLK_PERIOD), 18);
    constant MRD_COUNT_MAX : unsigned(17 downto 0) := to_unsigned(t_MRD, 18);

    signal r_curr_state : std_logic_vector := REST;
    signal r_next_state : std_logic_vector := REST;
    
    signal r_reset_counter : unsigned(16 downto 0) := (others => '0');
    signal r_reclk_counter : unsigned(17 downto 0) := (others => '0');
    signal r_mrd_counter : unsigned(17 downto 0) := (others => '0');
    signal r_xpr_counter : unsigned(17 downto 0) := (others => '0');
    signal r_mrd_index: unsigned(2 downto 0) := (others => '0');
    signal r_baddr: std_logic_vector(2 downto 0) := "010";
    signal r_addr: std_logic_vector(15 downto 0) := (others => '0');
    signal r_reset_n: std_logic := '0';
    signal r_cke: std_logic := '0';
    signal r_cs_n: std_logic := '1';
    signal r_ras_n: std_logic := '1';
    signal r_cas_n: std_logic := '1';
    signal r_we_n: std_logic := '1';
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
                if (r_mrd_counter = 0) then
                    r_cs_n <= '0';
                else
                    r_cs_n <= '0';
                end if;
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
                when CREG =>
                    if (r_mrd_counter = 0) then
                        r_ras_n <= '0';
                        r_cas_n <= '0';
                        r_we_n <= '0';
                    else
                        r_ras_n <= '1';
                        r_cas_n <= '1';
                        r_we_n <= '1';
                    end if;
                when others =>
                    r_ras_n <= '1';
                    r_cas_n <= '1';
                    r_we_n <= '1';
            end case;
        else
            r_ras_n <= r_ras_n;
            r_cas_n <= r_cas_n;
            r_we_n <= r_we_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when CREG =>
                    if (r_mrd_counter = 0) then
                        r_baddr <= std_logic_vector(r_mrd_index);
                    else
                        r_baddr <= (others => '0');
                    end if;
                when others =>
                    r_baddr <= (others => '0');
            end case;
        else
            r_baddr <= r_baddr;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when CREG =>
                    if (r_mrd_counter = 0 and r_mrd_index = 0) then
                        r_addr <= MR0;
                    elsif (r_mrd_counter = 0 and r_mrd_index = 1) then
                        r_addr <= MR1;
                    elsif (r_mrd_counter = 0 and r_mrd_index = 2) then
                        r_addr <= MR2;
                    elsif (r_mrd_counter = 0 and r_mrd_index = 3) then
                        r_addr <= MR3;
                    else
                        r_addr <= (others => '0');
                    end if;
                when others =>
                    r_addr <= (others => '0');
            end case;
        else
            r_addr <= r_addr;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
            when CREG =>
                if (r_mrd_counter = 0 and r_mrd_index /= 3) then
                    r_mrd_index <= r_mrd_index + 1;
                elsif (r_mrd_counter /= 0) then
                    r_mrd_index <= r_mrd_index;
                else
                    r_mrd_index <= "000";
                end if;
            when others =>
                r_mrd_index <= B"010";
            end case;
        else
            r_mrd_index <= r_mrd_index;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when CREG =>
                    if (r_mrd_counter < MRD_COUNT_MAX) then
                        r_mrd_counter <= r_mrd_counter + 1;
                    else
                        r_mrd_counter <= (others => '0');
                    end if;
                when others =>
                    r_mrd_counter <= (others => '0');
            end case;
        else
            r_mrd_counter <= r_mrd_counter;
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

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when RECK =>
                    if r_xpr_counter < XPR_COUNT_MAX then
                        r_xpr_counter <= r_xpr_counter + 1;
                    else
                        r_xpr_counter <= r_xpr_counter;
                    end if;
                when others =>
                    r_xpr_counter <= (others => '0');
            end case; 
        else
            r_xpr_counter <= r_xpr_counter;
        end if;
    end process;

    o_reset_n <= r_reset_n;
    o_cke <= r_cke;
    o_cs_n <= r_cs_n;
    o_ras_n <= r_ras_n;
    o_cas_n <= r_cas_n;
    o_we_n <= r_we_n;
end architecture;