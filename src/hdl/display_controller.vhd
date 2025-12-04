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

LIBRARY work;
USE work.screen_utils_pkg.ALL;
ENTITY display_controller IS
    GENERIC (
        G_REFRESH_PER_DIGIT_MS : POSITIVE := 1; -- 1ms by default
        G_CLK_FREQ_HZ : POSITIVE := 100_000_000 -- 100 MHz by default
    );
    PORT (
        i_clk : IN STD_LOGIC;
        i_reset : IN STD_LOGIC;
        i_digit_0 : IN t_digit_val; -- rightmost digit
        i_digit_1 : IN t_digit_val;
        i_digit_2 : IN t_digit_val;
        i_digit_3 : IN t_digit_val; -- leftmost digit
        o_anodes : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        o_segments : OUT t_segment
    );
END; -- end of the entity
ARCHITECTURE rtl OF display_controller IS
END rtl;