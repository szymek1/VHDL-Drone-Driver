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
    constant C_BASYS3_SYSCLK_HZ: integer := 100_000_000; -- system clock frequency (100MHz)
    constant C_PWM_CLK_HZ      : integer := 5_000;       -- target PWM frequency (5kHz)

    -- Simulation parameters
    constant C_BASYS3_SYSCLK_NS: time    := 10 ns;       -- 100MHz -> 10ns 

    -- Edge detector
    component edge_detector is
        generic (
            G_RISING_EDGE: boolean := true  -- detect rising edge by default
        );
        port (
            i_clk   : in  std_logic;
            i_rst_n : in  std_logic;
            i_signal: in  std_logic;
            o_edge  : out std_logic -- set to high for one clock cycle
        );
    end component; -- end of edge_detector

    -- PWM
    component pwm is
        generic (
            -- allowed values:
            -- - 15 %
            -- - 50 %
            -- - 90 %
            G_DUTY_CYCLE: integer
        );
        port (
            i_clk  : in std_logic;
            i_rst_n: in std_logic;
            o_pwm  : out std_logic;
            o_cnt  : out std_logic_vector(7 downto 0);
        );
    end component; -- end of pwm
    

end package drone_utils_pkg; -- end of the package