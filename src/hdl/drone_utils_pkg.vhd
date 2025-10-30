-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 30.10.25
-- Design Name: 
-- Module Name: drone_utils_pkg
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Utilities VHDL package with common generic modules to support
--              motors control:
--              -> edge_detector
--              -> pwm_generic
--              -> clk_divider_generic
--              
--              It also defines hardware parameters for the traget platform.
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


package drone_utils_pkg is
    -- General hardware parameters
    constant C_BASYS3_SYSCLK_HZ: integer := 50_000_000; -- system clock frequency (50MHz)
    constant C_PWM_CLK_HZ      : integer := 5_000;      -- target PWM frequency (5kHz)

    -- Edge detector
    component edge_detector is
        generic (
            G_RISING_EDGE: boolean := true; -- detect rising edge by default
        );
        port (
            i_clk: in std_logic;
            i_rst_n: in std_logic;
            i_signal: in std_logic;
            o_edge: out std_logic -- set to high for one clock cycle
        );
    end component; -- end of edge_detector
    

end package drone_utils_pkg; -- end of the package