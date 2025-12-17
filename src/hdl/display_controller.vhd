-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 24.11.25
-- Design Name: 
-- Module Name: display_controller
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Package declaring driver for the 7-segment embedded display.
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.screen_utils_pkg.ALL;
ENTITY display_controller IS
    GENERIC (
        G_REFRESH_PER_DIGIT_MS : POSITIVE := 1; -- 1ms by default
        G_CLK_FREQ_HZ : POSITIVE := 100_000_000 -- 100 MHz by default
    );
    PORT (
        i_clk : IN STD_LOGIC;
        i_rst_n : IN STD_LOGIC;
        i_digit_0 : IN t_digit_val; -- rightmost digit
        i_digit_1 : IN t_digit_val;
        i_digit_2 : IN t_digit_val;
        i_digit_3 : IN t_digit_val; -- leftmost digit
        o_anodes : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        o_segments : OUT t_segment
    );
END; -- end of the entity
ARCHITECTURE rtl OF display_controller IS
    SIGNAL r_counter : unsigned(18 DOWNTO 0) := (OTHERS => '0');
    SIGNAL s_digit_select : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL s_active_digit_val : t_digit_val;

    CONSTANT C_DIGIT_ID_00 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00"; -- rightmost
    CONSTANT C_DIGIT_ID_01 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    CONSTANT C_DIGIT_ID_10 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    CONSTANT C_DIGIT_ID_11 : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11"; -- leftmost

BEGIN

    p_screen_timer : PROCESS (i_clk, i_rst_n)
    BEGIN
        IF (i_rst_n = '0') THEN
            r_counter <= (OTHERS => '0');
        ELSIF rising_edge(i_clk) THEN
            r_counter <= r_counter + 1;
        END IF;
    END PROCESS p_screen_timer;

    s_digit_select <= STD_LOGIC_VECTOR(r_counter(r_counter'high DOWNTO r_counter'high - 1));

    p_digit_mux : PROCESS (s_digit_select, i_digit_0, i_digit_1, i_digit_2, i_digit_3)
    BEGIN
        CASE s_digit_select IS
            WHEN C_DIGIT_ID_00 =>
                o_anodes <= "1110";
                s_active_digit_val <= i_digit_0;

            WHEN C_DIGIT_ID_01 =>
                o_anodes <= "1101";
                s_active_digit_val <= i_digit_1;

            WHEN C_DIGIT_ID_10 =>
                o_anodes <= "1011";
                s_active_digit_val <= i_digit_2;

            WHEN C_DIGIT_ID_11 =>
                o_anodes <= "0111";
                s_active_digit_val <= i_digit_3;

            WHEN OTHERS =>
                o_anodes <= "1111";
                s_active_digit_val <= DIGIT_OFF;

        END CASE;
    END PROCESS p_digit_mux;

    o_segments <= get_segment_from_int(s_active_digit_val);

END rtl;