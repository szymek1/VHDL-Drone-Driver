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
--              -> pwm
--              -> btn_debouncer
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
PACKAGE drone_utils_pkg IS
    -- General hardware parameters
    CONSTANT C_BASYS3_SYSCLK_HZ : POSITIVE := 100_000_000; -- system clock frequency (100MHz)
    CONSTANT C_PWM_CLK_HZ : POSITIVE := 5_000; -- target PWM frequency (5kHz)
    CONSTANT C_DEBOUNCE_TIMEOUT_MS : POSITIVE := 20; -- 20ms of debounce time delay before the button
    -- is reevaluated

    -- Simulation parameters
    CONSTANT C_BASYS3_SYSCLK_NS : TIME := 10 ns; -- 100MHz -> 10ns 

    -- Edge detector
    COMPONENT edge_detector IS
        GENERIC (
            G_RISING_EDGE : BOOLEAN := true -- detect rising edge by default
        );
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst_n : IN STD_LOGIC;
            i_signal : IN STD_LOGIC;
            o_edge : OUT STD_LOGIC -- set to high for one clock cycle
        );
    END COMPONENT; -- end of edge_detector

    -- Button debouncer
    COMPONENT btn_debouncer IS
        GENERIC (
            G_DEBOUNCE_TIMEOUT_MS : POSITIVE := 20; -- button debounce time delay (by default 20ms)
            G_CLK_FREQ_HZ : POSITIVE := C_BASYS3_SYSCLK_HZ
        );
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst_n : IN STD_LOGIC;
            i_btn : IN STD_LOGIC;
            o_btn_debounced : OUT STD_LOGIC
        );
    END COMPONENT; -- end of btn_debouncer

    -- PWM
    COMPONENT pwm IS
        GENERIC (
            G_PWM_BITS : INTEGER; -- specifies the resolution
            -- if equal to 8 bits the PWM counter will
            -- count from 0 to 255

            G_CLK_DIV : POSITIVE := 78 -- clock divider, it specifies how many
            -- "fast clk ticks" equal one "slow clk tick"
            -- set by default to the value allowing to 
            -- create 5kHz signal from 100MHz clock
        );
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst_n : IN STD_LOGIC;
            i_enb : IN STD_LOGIC; -- when set high the PWM signal will be generated
            i_duty_cycle : IN unsigned(G_PWM_BITS - 1 DOWNTO 0);
            o_pwm : OUT STD_LOGIC;
            o_pwm_cnt : OUT unsigned(G_PWM_BITS - 1 DOWNTO 0)
        );
    END COMPONENT; -- end of pwm

    -- Utility functions
    FUNCTION compute_duty_cycle (percentage_value : INTEGER; bits : INTEGER) RETURN unsigned;

END PACKAGE drone_utils_pkg; -- end of the package
PACKAGE BODY drone_utils_pkg IS
    FUNCTION compute_duty_cycle (
        percentage_value : INTEGER;
        bits : INTEGER
    ) RETURN unsigned IS
        VARIABLE max_val : real;
        VARIABLE duty_real : real;
        VARIABLE duty_int : INTEGER;
    BEGIN
        max_val := (2.0 ** real(bits)) - 1.0;
        duty_real := (real(percentage_value) / 100.0) * max_val;
        duty_int := INTEGER(round(duty_real));
        RETURN to_unsigned(duty_int, bits);

    END FUNCTION compute_duty_cycle;

END drone_utils_pkg;