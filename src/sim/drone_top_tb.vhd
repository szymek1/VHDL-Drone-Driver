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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
USE std.env.finish;

LIBRARY work;
USE work.drone_utils_pkg.ALL;
USE work.control_pkg.ALL;

ENTITY drone_top_tb IS
END ENTITY drone_top_tb;
ARCHITECTURE testbench OF drone_top_tb IS

    -- Constants
    CONSTANT C_BLACK_LINE : STD_LOGIC := '0';
    CONSTANT C_WHITE_LINE : STD_LOGIC := NOT C_BLACK_LINE;

    CONSTANT C_10_MS : TIME := 10 ms;
    CONSTANT C_30_MS : TIME := 30 ms;
    CONSTANT C_50_MS : TIME := 50 ms;

    -- DUVs signals
    SIGNAL s_clk : STD_LOGIC := '0';
    SIGNAL s_rst_n : STD_LOGIC := '1'; -- start out of reset
    SIGNAL s_bp_start_stop : STD_LOGIC := '0';
    SIGNAL s_bumper_g : STD_LOGIC; -- left sensor
    SIGNAL s_bumper_d : STD_LOGIC; -- right sensor

    -- Outputs from drone_top
    SIGNAL s_pwm_g_pos : STD_LOGIC;
    SIGNAL s_pwm_g_neg : STD_LOGIC;
    SIGNAL s_pwm_d_pos : STD_LOGIC;
    SIGNAL s_pwm_d_neg : STD_LOGIC;
    SIGNAL seg : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL an : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

    -- =================================================================
    -- DUT Instantiation
    -- =================================================================
    UUT : ENTITY work.drone_top
        PORT MAP(
            Clock => s_clk,
            BP_start_stop => s_bp_start_stop,
            Bumper_G => s_bumper_g,
            Bumper_D => s_bumper_d,
            PWM_G_pos => s_pwm_g_pos,
            PWM_G_neg => s_pwm_g_neg,
            PWM_D_pos => s_pwm_d_pos,
            PWM_D_neg => s_pwm_d_neg,
            seg => seg,
            an => an
        );

    s_clk <= NOT s_clk AFTER C_BASYS3_SYSCLK_NS / 2;

    test_process : PROCESS IS
    BEGIN
        REPORT "Stimulus: Simulation Started. FSM should be IDLE." SEVERITY note;
        s_bumper_g <= C_BLACK_LINE;
        s_bumper_d <= C_BLACK_LINE;
        s_bp_start_stop <= '0';
        WAIT FOR C_50_MS;

        -- Initialization, pressing the button
        REPORT "Stimulus: Pressing Start button." SEVERITY note;
        s_bp_start_stop <= '1';
        WAIT FOR C_30_MS;
        s_bp_start_stop <= '0';
        WAIT FOR C_10_MS;
        -- At this point: o_is_running should be '1'
        -- FSM should be in FORWARD state (50%, 50%)

        -- Drift Left (Turn Right)
        REPORT "Stimulus: Drifting Left (TURN RIGHT)." SEVERITY note;
        s_bumper_g <= C_BLACK_LINE;
        s_bumper_d <= C_WHITE_LINE;
        WAIT FOR C_50_MS; -- Should be in T_RIGHT (15%, 90%)

        -- Correct back to Forward
        REPORT "Stimulus: Correcting (FORWARD)." SEVERITY note;
        s_bumper_g <= C_BLACK_LINE;
        s_bumper_d <= C_BLACK_LINE;
        WAIT FOR C_50_MS; -- Should be in FORWARD (50%, 50%)

        -- Drift Right (Turn Left)
        REPORT "Stimulus: Drifting Right (TURN LEFT)." SEVERITY note;
        s_bumper_g <= C_WHITE_LINE;
        s_bumper_d <= C_BLACK_LINE;
        WAIT FOR C_50_MS; -- Should be in T_LEFT (90%, 15%)

        -- Lose the line (Both White)
        REPORT "Stimulus: Losing the line (Both WHITE)." SEVERITY note;
        s_bumper_g <= C_WHITE_LINE;
        s_bumper_d <= C_WHITE_LINE;
        WAIT FOR C_50_MS;

        -- Find line again
        REPORT "Stimulus: Finding line (FORWARD)." SEVERITY note;
        s_bumper_g <= C_BLACK_LINE;
        s_bumper_d <= C_BLACK_LINE;
        WAIT FOR C_50_MS;

        -- Press the button to Stop (Idle)
        REPORT "Stimulus: Pressing Stop button." SEVERITY note;
        s_bp_start_stop <= '1';
        WAIT FOR C_30_MS;
        s_bp_start_stop <= '0';
        WAIT FOR C_50_MS;
        -- At this point: o_is_running should be '0'
        -- FSM should be in IDLE state. Motors should be OFF.

        -- end of the simulation
        REPORT "Simulaiton has finished";
        finish;

    END PROCESS test_process;

END ARCHITECTURE testbench;