-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 17.11.25
-- Design Name: 
-- Module Name: start_stop_FSM_tb
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Testbench of Movement FSM. It instantiates edge detection as well.
-- 
-- Dependencies: control_pkg, drone_utils_pkg, edge_detector (input provider)
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY work;
USE work.drone_utils_pkg.ALL;
USE work.control_pkg.ALL;
ENTITY movement_FSM_tb IS
END; -- end of entity
ARCHITECTURE testbench OF movement_FSM_tb IS
    -- Constants
    CONSTANT C_TIMEOUT_MS : POSITIVE := 20;
    CONSTANT C_CORRECT_DEBOUNCE_CLK_TICKS : POSITIVE := (C_BASYS3_SYSCLK_HZ / 1000) * C_TIMEOUT_MS;

    -- Sensor Logic Constants (based on G_BLACK_LINE generic)
    CONSTANT C_BLACK_LINE : STD_LOGIC := '1'; -- ** ASSUMPTION: '0' = black, '1' = white **
    CONSTANT C_WHITE_LINE : STD_LOGIC := NOT C_BLACK_LINE;

    -- DUVs signals
    SIGNAL i_clk : STD_LOGIC := '0';
    SIGNAL i_rst_n : STD_LOGIC := '0';
    SIGNAL i_signal : STD_LOGIC := '0'; -- input to btn_debouncer
    SIGNAL o_btn_debounced : STD_LOGIC := '0'; -- output of btn_debouncer
    SIGNAL o_edge : STD_LOGIC; -- output of edge_detector
    SIGNAL o_is_running : STD_LOGIC; -- output of start_stop_FSM
    SIGNAL i_sensor_l : STD_LOGIC; -- input to movement_FSM
    SIGNAL i_sensor_r : STD_LOGIC; -- input to movement_FSM
    SIGNAL o_pwm_enb : STD_LOGIC; -- output of movement_FSM

    -- FIX: Signals must match the type from the component port
    SIGNAL o_motor_l_pwm : t_pwm_duty_cycle;
    SIGNAL o_motor_r_pwm : t_pwm_duty_cycle;

    -- Test timing constants
    CONSTANT C_1_MS : TIME := 1 ms;
    CONSTANT C_20_MS : TIME := 20 ms;
    CONSTANT C_30_MS : TIME := 30 ms;
    CONSTANT C_50_MS : TIME := 50 ms;
BEGIN

    -- =================================================================
    -- DUT Instantiations
    -- =================================================================

    btn_debouncer_duv : btn_debouncer
    GENERIC MAP(
        G_DEBOUNCE_TIMEOUT_MS => C_TIMEOUT_MS,
        G_CLK_FREQ_HZ => C_BASYS3_SYSCLK_HZ
    )
    PORT MAP(
        i_clk => i_clk,
        i_rst_n => i_rst_n,
        i_btn => i_signal,
        o_btn_debounced => o_btn_debounced
    );

    egde_detector_duv : edge_detector
    GENERIC MAP(
        G_RISING_EDGE => true
    )
    PORT MAP(
        i_clk => i_clk,
        i_rst_n => i_rst_n,
        i_signal => o_btn_debounced,
        o_edge => o_edge
    );

    start_stop_FSM_duv : start_stop_FSM
    PORT MAP(
        i_clk => i_clk,
        i_rst_n => i_rst_n,
        i_btn_pressed => o_edge,
        o_is_running => o_is_running
    );

    -- FIX: Corrected component name typo (FMS -> FSM)
    movement_FSM_duv : movement_FSM
    GENERIC MAP(
        G_BLACK_LINE => C_BLACK_LINE
    )
    PORT MAP(
        i_clk => i_clk,
        i_rst_n => i_rst_n,
        i_is_running => o_is_running,
        i_sensor_l => i_sensor_l,
        i_sensor_r => i_sensor_r,
        o_pwm_enb => o_pwm_enb,
        o_motor_l_pwm => o_motor_l_pwm,
        o_motor_r_pwm => o_motor_r_pwm
    );

    -- =================================================================
    -- Clock and Reset Generators (Must be in main architecture)
    -- =================================================================
    i_clk <= NOT i_clk AFTER C_BASYS3_SYSCLK_NS/2;
    i_rst_n <= '0', '1' AFTER 3 * C_BASYS3_SYSCLK_NS;

    -- =================================================================
    -- Test Process (Must be in main architecture)
    -- =================================================================
    test_process : PROCESS IS
    BEGIN
        WAIT UNTIL i_rst_n = '1';
        REPORT "Stimulus: System is out of reset. FSM should be IDLE." SEVERITY note;
        i_sensor_l <= C_BLACK_LINE; -- Both sensors see white (lost)
        i_sensor_r <= C_BLACK_LINE;
        i_signal <= '0';
        WAIT FOR C_50_MS;

        -- 1. Press the button to start
        REPORT "Stimulus: Pressing Start button." SEVERITY note;
        i_signal <= '1';
        WAIT FOR C_30_MS; -- Hold for 30ms (longer than 20ms timeout)
        i_signal <= '0';
        WAIT FOR C_1_MS;
        -- At this point: o_edge should have pulsed, o_is_running should be '1'
        -- FSM should be in STOPPED state (motors 0), looking for the line.

        -- 2. Find the line (Forward)
        REPORT "Stimulus: Found line (FORWARD)." SEVERITY note;
        i_sensor_l <= C_WHITE_LINE;
        i_sensor_r <= C_WHITE_LINE;
        WAIT FOR C_50_MS; -- Should be in FORWARD (90%, 90%)

        -- 3. Drift Left (Turn Right)
        REPORT "Stimulus: Drifting Left (TURN RIGHT)." SEVERITY note;
        i_sensor_l <= C_BLACK_LINE;
        i_sensor_r <= C_WHITE_LINE;
        WAIT FOR C_50_MS; -- Should be in T_RIGHT (15%, 50%)

        -- 4. Correct back to Forward
        REPORT "Stimulus: Correcting (FORWARD)." SEVERITY note;
        i_sensor_l <= C_WHITE_LINE;
        i_sensor_r <= C_WHITE_LINE;
        WAIT FOR C_50_MS; -- Should be in FORWARD (90%, 90%)

        -- 5. Drift Right (Turn Left)
        REPORT "Stimulus: Drifting Right (TURN LEFT)." SEVERITY note;
        i_sensor_l <= C_WHITE_LINE;
        i_sensor_r <= C_BLACK_LINE;
        WAIT FOR C_50_MS; -- Should be in T_LEFT (50%, 15%)

        -- 6. Lose the line (Stopped)
        -- report "Stimulus: Losing the line (STOPPED)." severity note;
        -- i_sensor_l <= C_WHITE_LINE;
        -- i_sensor_r <= C_WHITE_LINE;
        -- wait for C_50_MS; -- Should be in STOPPED (0%, 0%)

        -- 7. Press the button to Stop (Idle)
        REPORT "Stimulus: Pressing Stop button." SEVERITY note;
        i_signal <= '1';
        WAIT FOR C_30_MS;
        i_signal <= '0';
        WAIT FOR C_50_MS;
        -- At this point: o_edge pulsed, o_is_running should be '0'
        -- FSM should be in IDLE state.

        -- end of the simulation
        ASSERT false REPORT "Simulation has finished" SEVERITY failure;
        WAIT; -- FIX: Added final 'wait'

    END PROCESS test_process;

END ARCHITECTURE testbench;