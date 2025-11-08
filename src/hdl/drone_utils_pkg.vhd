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
use ieee.numeric_std.all;


package drone_utils_pkg is
    -- General hardware parameters
    constant C_BASYS3_SYSCLK_HZ   : positive := 100_000_000; -- system clock frequency (100MHz)
    constant C_PWM_CLK_HZ         : positive := 5_000;       -- target PWM frequency (5kHz)
    constant C_DEBOUNCE_TIMEOUT_MS: positive := 20;          -- 20ms of debounce time delay before the button
                                                             -- is reevaluated

    -- Simulation parameters
    constant C_BASYS3_SYSCLK_NS: time    := 10 ns;        -- 100MHz -> 10ns 

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

    -- Button debouncer
    component btn_debouncer is
        generic (
            G_DEBOUNCE_TIMEOUT_MS: positive := 20; -- button debounce time delay (by default 20ms)
            G_CLK_FREQ_HZ        : positive := C_BASYS3_SYSCLK_HZ
        );
        port (
            i_clk          : in std_logic;
            i_rst_n        : in std_logic;
            i_btn          : in std_logic;
            o_btn_debounced: out std_logic
        );
    end component; -- end of btn_debouncer

    -- PWM
    component pwm is
        generic (
            G_PWM_BITS: integer;        -- specifies the resolution
                                        -- if equal to 8 bits the PWM counter will
                                        -- count from 0 to 255

            G_CLK_DIV : positive := 78  -- clock divider, it specifies how many
                                        -- "fast clk ticks" equal one "slow clk tick"
                                        -- set by default to the value allowing to 
                                        -- create 5kHz signal from 100MHz clock
        );
        port (
            i_clk           : in  std_logic;
            i_rst_n         : in  std_logic;
            i_enb           : in  std_logic; -- when set high the PWM signal will be generated
            i_duty_cycle    : in  unsigned(G_PWM_BITS - 1 downto 0);
            o_pwm           : out std_logic;
            o_pwm_cnt       : out unsigned(G_PWM_BITS - 1 downto 0)
        );
    end component; -- end of pwm
    

end package drone_utils_pkg; -- end of the package