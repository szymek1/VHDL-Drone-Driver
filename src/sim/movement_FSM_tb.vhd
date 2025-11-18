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


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.drone_utils_pkg.all;
use work.control_pkg.all;


entity movement_FSM_tb is 
end; -- end of entity


architecture testbench of movement_FSM_tb is
    -- Constants
    constant C_TIMEOUT_MS : positive := 20;
    constant C_CORRECT_DEBOUNCE_CLK_TICKS : positive := (C_BASYS3_SYSCLK_HZ / 1000) * C_TIMEOUT_MS;
    
    -- Sensor Logic Constants (based on G_BLACK_LINE generic)
    constant C_BLACK_LINE : std_logic := '1'; -- ** ASSUMPTION: '0' = black, '1' = white **
    constant C_WHITE_LINE : std_logic := not C_BLACK_LINE;
    
    -- DUVs signals
    signal i_clk          : std_logic := '0';
    signal i_rst_n        : std_logic := '0';
    signal i_signal       : std_logic := '0'; -- input to btn_debouncer
    signal o_btn_debounced: std_logic := '0'; -- output of btn_debouncer
    signal o_edge         : std_logic;        -- output of edge_detector
    signal o_is_running   : std_logic;        -- output of start_stop_FSM
    signal i_sensor_l     : std_logic;        -- input to movement_FSM
    signal i_sensor_r     : std_logic;        -- input to movement_FSM
    signal o_pwm_enb      : std_logic;        -- output of movement_FSM
    
    -- FIX: Signals must match the type from the component port
    signal o_motor_l_pwm  : t_pwm_duty_cycle;
    signal o_motor_r_pwm  : t_pwm_duty_cycle;
    
    -- Test timing constants
    constant C_1_MS  : time := 1  ms;
    constant C_20_MS : time := 20 ms;
    constant C_30_MS : time := 30 ms;
    constant C_50_MS : time := 50 ms;
begin

    -- =================================================================
    -- DUT Instantiations
    -- =================================================================

    btn_debouncer_duv: btn_debouncer 
        generic map (
            G_DEBOUNCE_TIMEOUT_MS => C_TIMEOUT_MS,
            G_CLK_FREQ_HZ         => C_BASYS3_SYSCLK_HZ
        )
        port map (
            i_clk           => i_clk,
            i_rst_n         => i_rst_n,
            i_btn           => i_signal,
            o_btn_debounced => o_btn_debounced
        );

    egde_detector_duv: edge_detector 
        generic map (
            G_RISING_EDGE => true
        )
        port map (
            i_clk    => i_clk,
            i_rst_n  => i_rst_n,
            i_signal => o_btn_debounced,
            o_edge   => o_edge
        );

    start_stop_FSM_duv: start_stop_FSM
        port map (
            i_clk         => i_clk,
            i_rst_n       => i_rst_n,
            i_btn_pressed => o_edge,
            o_is_running  => o_is_running
        );

    -- FIX: Corrected component name typo (FMS -> FSM)
    movement_FSM_duv  : movement_FSM
        generic map (
            G_BLACK_LINE => C_BLACK_LINE
        )
        port map (
            i_clk         => i_clk,
            i_rst_n       => i_rst_n,
            i_is_running  => o_is_running,
            i_sensor_l    => i_sensor_l,
            i_sensor_r    => i_sensor_r,
            o_pwm_enb     => o_pwm_enb,
            o_motor_l_pwm => o_motor_l_pwm,
            o_motor_r_pwm => o_motor_r_pwm
        );

    -- =================================================================
    -- Clock and Reset Generators (Must be in main architecture)
    -- =================================================================
    i_clk   <= not i_clk after C_BASYS3_SYSCLK_NS/2;
    i_rst_n <= '0', '1' after 3 * C_BASYS3_SYSCLK_NS;

    -- =================================================================
    -- Test Process (Must be in main architecture)
    -- =================================================================
    test_process: process is
    begin
        wait until i_rst_n = '1';
        report "Stimulus: System is out of reset. FSM should be IDLE." severity note;
        i_sensor_l <= C_BLACK_LINE; -- Both sensors see white (lost)
        i_sensor_r <= C_BLACK_LINE;
        i_signal <= '0';
        wait for C_50_MS;

        -- 1. Press the button to start
        report "Stimulus: Pressing Start button." severity note;
        i_signal <= '1';
        wait for C_30_MS; -- Hold for 30ms (longer than 20ms timeout)
        i_signal <= '0';
        wait for C_1_MS;
        -- At this point: o_edge should have pulsed, o_is_running should be '1'
        -- FSM should be in STOPPED state (motors 0), looking for the line.
        
        -- 2. Find the line (Forward)
        report "Stimulus: Found line (FORWARD)." severity note;
        i_sensor_l <= C_WHITE_LINE;
        i_sensor_r <= C_WHITE_LINE;
        wait for C_50_MS; -- Should be in FORWARD (90%, 90%)
        
        -- 3. Drift Left (Turn Right)
        report "Stimulus: Drifting Left (TURN RIGHT)." severity note;
        i_sensor_l <= C_BLACK_LINE;
        i_sensor_r <= C_WHITE_LINE;
        wait for C_50_MS; -- Should be in T_RIGHT (15%, 50%)
        
        -- 4. Correct back to Forward
        report "Stimulus: Correcting (FORWARD)." severity note;
        i_sensor_l <= C_WHITE_LINE;
        i_sensor_r <= C_WHITE_LINE;
        wait for C_50_MS; -- Should be in FORWARD (90%, 90%)

        -- 5. Drift Right (Turn Left)
        report "Stimulus: Drifting Right (TURN LEFT)." severity note;
        i_sensor_l <= C_WHITE_LINE;
        i_sensor_r <= C_BLACK_LINE;
        wait for C_50_MS; -- Should be in T_LEFT (50%, 15%)
        
        -- 6. Lose the line (Stopped)
        -- report "Stimulus: Losing the line (STOPPED)." severity note;
        -- i_sensor_l <= C_WHITE_LINE;
        -- i_sensor_r <= C_WHITE_LINE;
        -- wait for C_50_MS; -- Should be in STOPPED (0%, 0%)
        
        -- 7. Press the button to Stop (Idle)
        report "Stimulus: Pressing Stop button." severity note;
        i_signal <= '1';
        wait for C_30_MS;
        i_signal <= '0';
        wait for C_50_MS;
        -- At this point: o_edge pulsed, o_is_running should be '0'
        -- FSM should be in IDLE state.

        -- end of the simulation
        assert false report "Simulation has finished" severity failure;
        wait; -- FIX: Added final 'wait'
        
    end process test_process;

end architecture testbench;