-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 17.11.25
-- Design Name: 
-- Module Name: drone_top_tb
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Testbench of the top module
-- 
-- Dependencies: control_pkg, drone_utils_pkg
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.drone_utils_pkg.all;
use work.control_pkg.all;


entity drone_top_tb is 
end entity drone_top_tb;


architecture testbench of drone_top_tb is

    -- Constants
    constant C_BLACK_LINE : std_logic := '0';
    constant C_WHITE_LINE : std_logic := not C_BLACK_LINE;
    
    constant C_10_MS : time := 10 ms;
    constant C_30_MS : time := 30 ms;
    constant C_50_MS : time := 50 ms;

    -- DUVs signals
    signal s_clk           : std_logic := '0';
    signal s_rst_n         : std_logic := '1'; -- start out of reset
    signal s_bp_start_stop : std_logic := '0';
    signal s_bumper_g      : std_logic;        -- left sensor
    signal s_bumper_d      : std_logic;        -- right sensor
    
    -- Outputs from drone_top
    signal s_pwm_g_pos : std_logic;
    signal s_pwm_g_neg : std_logic;
    signal s_pwm_d_pos : std_logic;
    signal s_pwm_d_neg : std_logic;

begin

    -- =================================================================
    -- DUT Instantiation
    -- =================================================================
    UUT : entity work.drone_top
        port map (
            Clock         => s_clk,
            BP_start_stop => s_bp_start_stop,
            Bumper_G      => s_bumper_g,
            Bumper_D      => s_bumper_d,
            PWM_G_pos     => s_pwm_g_pos,
            PWM_G_neg     => s_pwm_g_neg,
            PWM_D_pos     => s_pwm_d_pos,
            PWM_D_neg     => s_pwm_d_neg
        );

    s_clk <= not s_clk after C_BASYS3_SYSCLK_NS / 2;

    test_process: process is
    begin
        report "Stimulus: Simulation Started. FSM should be IDLE." severity note;
        s_bumper_g <= C_BLACK_LINE; 
        s_bumper_d <= C_BLACK_LINE;
        s_bp_start_stop <= '0';
        wait for C_50_MS;

        -- Initialization, pressing the button
        report "Stimulus: Pressing Start button." severity note;
        s_bp_start_stop <= '1';
        wait for C_30_MS; 
        s_bp_start_stop <= '0';
        wait for C_10_MS;
        -- At this point: o_is_running should be '1'
        -- FSM should be in FORWARD state (50%, 50%)
        
        -- Drift Left (Turn Right)
        report "Stimulus: Drifting Left (TURN RIGHT)." severity note;
        s_bumper_g <= C_BLACK_LINE;
        s_bumper_d <= C_WHITE_LINE;
        wait for C_50_MS; -- Should be in T_RIGHT (15%, 90%)
        
        -- Correct back to Forward
        report "Stimulus: Correcting (FORWARD)." severity note;
        s_bumper_g <= C_BLACK_LINE;
        s_bumper_d <= C_BLACK_LINE;
        wait for C_50_MS; -- Should be in FORWARD (50%, 50%)

        -- Drift Right (Turn Left)
        report "Stimulus: Drifting Right (TURN LEFT)." severity note;
        s_bumper_g <= C_WHITE_LINE;
        s_bumper_d <= C_BLACK_LINE;
        wait for C_50_MS; -- Should be in T_LEFT (90%, 15%)
        
        -- Lose the line (Both White)
        report "Stimulus: Losing the line (Both WHITE)." severity note;
        s_bumper_g <= C_WHITE_LINE;
        s_bumper_d <= C_WHITE_LINE;
        wait for C_50_MS;
        
        -- Find line again
        report "Stimulus: Finding line (FORWARD)." severity note;
        s_bumper_g <= C_BLACK_LINE;
        s_bumper_d <= C_BLACK_LINE;
        wait for C_50_MS; 
        
        -- Press the button to Stop (Idle)
        report "Stimulus: Pressing Stop button." severity note;
        s_bp_start_stop <= '1';
        wait for C_30_MS;
        s_bp_start_stop <= '0';
        wait for C_50_MS;
        -- At this point: o_is_running should be '0'
        -- FSM should be in IDLE state. Motors should be OFF.

        -- end of the simulation
        report "Simulation has finished" severity note;
        assert false report "Simulation finished." severity failure;
        wait;
        
    end process test_process;

end architecture testbench;