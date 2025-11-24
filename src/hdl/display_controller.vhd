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


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.screen_utils_pkg.all;


entity display_controller is
    generic (
        G_REFRESH_PER_DIGIT_MS: positive := 1;          -- 1ms by default
        G_CLK_FREQ_HZ         : positive := 100_000_000 -- 100 MHz by default
    );
    port (
        i_clk     : in std_logic;
        i_reset   : in std_logic;
        i_digit_0 : in t_digit_val; -- rightmost digit
        i_digit_1 : in t_digit_val;
        i_digit_2 : in t_digit_val;
        i_digit_3 : in t_digit_val; -- leftmost digit
        o_anodes  : out std_logic_vector(3 downto 0);
        o_segments: out t_segment
    );
end; -- end of the entity


architecture rtl of display_controller is
end rtl;