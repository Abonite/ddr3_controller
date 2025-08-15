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

        DDR_CLK_PERIOD: time := -1 ns
    );
    port (
        clk             : in std_logic;
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
        o_ddr_dqs_n     : out std_logic_vector(DDR_DATA_WIDTH/8 - 1 downto 0);
        o_ddr_odt       : out std_logic := '0'
    );
end ddr3_controller;

architecture Behavioral of ddr3_controller is
    constant INIT: std_logic_vector(3 downto 0) := "0000";
    constant REST: std_logic_vector(3 downto 0) := "0001";
    constant ZQCL: std_logic_vector(3 downto 0) := "0010";
    constant RADY: std_logic_vector(3 downto 0) := "0100";
    
    signal r_curr_state: std_logic_vector(3 downto 0) := INIT;
    signal r_next_state: std_logic_vector(3 downto 0) := INIT;

    signal r_start_pu_reset: std_logic := '0';
    signal r_pu_resetting: std_logic := '0';
    signal w_pu_reset_finished: std_logic := '0';

    signal ddr_cke: std_logic := '0';
    signal ddr_cs_n: std_logic := '1';
    signal ddr_ras_n: std_logic := '1';
    signal ddr_cas_n: std_logic := '1';
    signal ddr_we_n: std_logic := '1';
    signal ddr_ba: std_logic_vector(2 downto 0) := (others => '0');
    signal ddr_dqm: std_logic_vector(DDR_DATA_WIDTH/8 - 1 downto 0) := (others => '1');
    signal ddr_addr: std_logic_vector(15 downto 0) := (others => '0');
    signal ddr_dq: std_logic_vector(DDR_DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ddr_reset_n: std_logic := '0';
    signal ddr_dqs: std_logic_vector(DDR_DATA_WIDTH/8 - 1 downto 0) := (others => '0');
    signal ddr_dqs_n: std_logic_vector(DDR_DATA_WIDTH/8 - 1 downto 0) := (others => '0');
    signal ddr_odt: std_logic := '0';

    signal w_pu_reset_reset_n: std_logic;
    signal w_pu_reset_cke: std_logic;
    signal w_pu_reset_cs_n: std_logic;
    signal w_pu_reset_ras_n: std_logic;
    signal w_pu_reset_cas_n: std_logic;
    signal w_pu_reset_we_n: std_logic;
    signal w_pu_reset_ba: std_logic_vector(2 downto 0);
    signal w_pu_reset_addr: std_logic_vector(15 downto 0);
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

    process(all) begin
        case r_curr_state is
            when INIT =>
                r_next_state <= REST;  -- Transition to REST state after INIT
            when REST =>
                if (w_pu_reset_finished = '1') then
                    r_next_state <= ZQCL;
                else
                    r_next_state <= REST;  -- Remain in INIT if condition not met
                end if;
            when ZQCL =>
                r_next_state <= RADY;  -- Loop back to INIT for simplicity
            when others =>
                r_next_state <= INIT;   -- Fallback to INIT
        end case;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    r_pu_resetting <= '0';  -- No reset in INIT state
                when REST =>
                    r_pu_resetting <= '1';  -- Trigger power-up reset in REST state
                when others =>
                    r_pu_resetting <= '0';  -- Trigger power-up reset on clock edge
                end case;
        else
            r_pu_resetting <= r_pu_resetting;  -- Default to no reset
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    r_start_pu_reset <= '0';  -- No reset in INIT state
                when REST =>
                    if (r_pu_resetting = '1') then
                        r_start_pu_reset <= '0';  -- Trigger power-up reset in REST state
                    else
                        r_start_pu_reset <= '1';  -- No reset if not resetting
                    end if;
                when others =>
                    r_start_pu_reset <= '0';  -- Trigger power-up reset on clock edge
                end case;
        else
            r_start_pu_reset <= r_start_pu_reset;  -- Default to no reset
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_cke <= '0';
                when REST =>
                    ddr_cke <= w_pu_reset_cke;
                when others =>
                    ddr_cke <= '1';
            end case;
        else
            ddr_cke <= ddr_cke;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_cs_n <= '1';
                when REST =>
                    ddr_cs_n <= w_pu_reset_cs_n;
                when others =>
                    ddr_cs_n <= '0';
            end case;
        else
            ddr_cs_n <= ddr_cs_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_ras_n <= '1';
                when REST =>
                    ddr_ras_n <= w_pu_reset_ras_n;
                when others =>
                    ddr_ras_n <= '1';
            end case;
        else
            ddr_ras_n <= ddr_ras_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_cas_n <= '1';
                when REST =>
                    ddr_cas_n <= w_pu_reset_cas_n;
                when others =>
                    ddr_cas_n <= '0';
            end case;
        else
            ddr_cas_n <= ddr_cas_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_we_n <= '1';
                when REST =>
                    ddr_we_n <= w_pu_reset_we_n;
                when others =>
                    ddr_we_n <= '0';
            end case;
        else
            ddr_we_n <= ddr_we_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_ba <= "000";
                when REST =>
                    ddr_ba <= w_pu_reset_ba;
                when others =>
                    ddr_ba <= "000";
            end case;
        else
            ddr_ba <= ddr_ba;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_dqm <= (others => '0');
                when REST =>
                    ddr_dqm <= std_logic_vector(to_unsigned(0, ddr_dqm'length));
                when others =>
                    ddr_dqm <= (others => '0');
            end case;
        else
            ddr_dqm <= ddr_dqm;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_addr <= (others => '0');
                when REST =>
                    ddr_addr <= w_pu_reset_addr;
                when others =>
                    ddr_addr <= (others => '0');
            end case;
        else
            ddr_addr <= ddr_addr;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_dq <= (others => '0');
                when REST =>
                    ddr_dq <= (others => '0');
                when others =>
                    ddr_dq <= (others => '0');
            end case;
        else
            ddr_dq <= ddr_dq;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_reset_n <= '0';
                when REST =>
                    ddr_reset_n <= w_pu_reset_reset_n;
                when others =>
                    ddr_reset_n <= '1';
            end case;
        else
            ddr_reset_n <= ddr_reset_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_dqs <= (others => '0');
                when REST =>
                    ddr_dqs <= (others => '0');
                when others =>
                    ddr_dqs <= (others => '0');
            end case;
        else
            ddr_dqs <= ddr_dqs;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_dqs_n <= (others => '0');
                when REST =>
                    ddr_dqs_n <= (others => '0');
                when others =>
                    ddr_dqs_n <= (others => '0');
            end case;
        else
            ddr_dqs_n <= ddr_dqs_n;
        end if;
    end process;

    process(clk) begin
        if rising_edge(clk) then
            case r_curr_state is
                when INIT =>
                    ddr_odt <= '0';
                when REST =>
                    ddr_odt <= '0';
                when others =>
                    ddr_odt <= '0';
            end case;
        else
            ddr_odt <= ddr_odt;
        end if;
    end process;

    u_reset: entity work.powerup_reset
        generic map (
            t_RESET => 200 us,
            t_CKE => DDR_tCKSRX,
            t_MRD => 4,
            t_XPR => 15 ns,

            DDR_CLK_PERIOD => DDR_CLK_PERIOD,

            MR0 => "1111111111111111",
            MR1 => "1010101010101010",
            MR2 => "0101010101010101",
            MR3 => "0000000000000000"
        )
        port map (
            clk => clk,

            i_resetting => r_start_pu_reset,
            o_reset_n => w_pu_reset_reset_n,
            o_cke => w_pu_reset_cke,
            o_cs_n => w_pu_reset_cs_n,
            o_ras_n => w_pu_reset_ras_n,
            o_cas_n => w_pu_reset_cas_n,
            o_we_n => w_pu_reset_we_n,
            o_ba => w_pu_reset_ba,
            o_addr => w_pu_reset_addr,

            o_reset_finished => w_pu_reset_finished
        );

    OBUFDS_inst : OBUFDS
        generic map (
            IOSTANDARD => "DEFAULT", -- Specify the output I/O standard
            SLEW => "FAST"
        )
        port map (
            O => o_ddr_ck_p,     -- Diff_p output (connect directly to top-level port)
            OB => o_ddr_ck_n,   -- Diff_n output (connect directly to top-level port)
            I => clk      -- Buffer input 
        );

    o_ddr_cke <= ddr_cke;
    o_ddr_cs_n <= ddr_cs_n;
    o_ddr_ras_n <= ddr_ras_n;
    o_ddr_cas_n <= ddr_cas_n;
    o_ddr_we_n <= ddr_we_n;
    o_ddr_ba <= ddr_ba;
    o_ddr_dqm <= ddr_dqm;
    o_ddr_addr <= ddr_addr;
    o_ddr_dq <= ddr_dq;
    o_ddr_reset_n <= ddr_reset_n;
    o_ddr_dqs <= ddr_dqs;
    o_ddr_dqs_n <= ddr_dqs_n;
    o_ddr_odt <= ddr_odt;
end architecture;