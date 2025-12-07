-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 08.11.25
-- Design Name: 
-- Module Name: start_stop_FSM_tb
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Testbench of Start/Stop FSM. It instantiates edge detection as well.
-- 
-- Dependencies: control_pkg, edge_detector (input provider)
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.env.finish;

LIBRARY work;
USE work.drone_utils_pkg.ALL;
USE work.control_pkg.ALL;

ENTITY start_stop_FSM_tb IS
END; -- end of entity
ARCHITECTURE testbench OF start_stop_FSM_tb IS
    -- Constants
    CONSTANT C_CORRECT_DEBOUNCE_CLK_TICKS : POSITIVE := (C_BASYS3_SYSCLK_HZ / 1000) * C_DEBOUNCE_TIMEOUT_MS;
    -- DUVs signals
    SIGNAL i_clk : STD_LOGIC := '0';
    SIGNAL i_rst_n : STD_LOGIC := '0';
    SIGNAL i_signal : STD_LOGIC := '0'; -- input to btn_debouncer
    SIGNAL o_btn_debounced : STD_LOGIC := '0'; -- output of btn_debouncer/ input to edge_detector
    SIGNAL o_edge : STD_LOGIC; -- output of edge_detector/input to FSM
    SIGNAL o_is_running : STD_LOGIC;
BEGIN
    btn_debouncer_duv : btn_debouncer
    GENERIC MAP(
        G_DEBOUNCE_TIMEOUT_MS => C_DEBOUNCE_TIMEOUT_MS,
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
    i_clk <= NOT i_clk AFTER C_BASYS3_SYSCLK_NS/2;
    i_rst_n <= '0', '1' AFTER 3 * C_BASYS3_SYSCLK_NS;

    test_process : PROCESS IS
    BEGIN
        WAIT UNTIL i_rst_n = '1';
        -- Simulation begins here
        -- Perfect signal
        REPORT "Perfect signal";
        i_signal <= '0';
        WAIT FOR 2 * C_BASYS3_SYSCLK_NS;

        i_signal <= '1';
        WAIT FOR (C_CORRECT_DEBOUNCE_CLK_TICKS + 2) * C_BASYS3_SYSCLK_NS;

        -- Debouncing: back to 0
        REPORT "Bounce from 0 to 1 and then to 0 again";
        i_signal <= '0';
        WAIT FOR TIME(0.5 * real(C_CORRECT_DEBOUNCE_CLK_TICKS) * C_BASYS3_SYSCLK_NS);

        i_signal <= '1';
        WAIT FOR C_BASYS3_SYSCLK_NS;

        i_signal <= '0';
        WAIT FOR TIME(0.5 * real(C_CORRECT_DEBOUNCE_CLK_TICKS + 2) * C_BASYS3_SYSCLK_NS - C_BASYS3_SYSCLK_NS);

        -- Debouncing: from 0 to 1 and then to 0 and then to 1 again
        REPORT "Bounce from 0 to 1 and then to 0 and to 1 again";
        i_signal <= '0';
        WAIT FOR TIME(0.1 * real(C_CORRECT_DEBOUNCE_CLK_TICKS) * C_BASYS3_SYSCLK_NS);

        i_signal <= '1';
        WAIT FOR TIME(0.1 * real(C_CORRECT_DEBOUNCE_CLK_TICKS) * C_BASYS3_SYSCLK_NS);

        i_signal <= '0';
        WAIT FOR TIME(0.2 * real(C_CORRECT_DEBOUNCE_CLK_TICKS) * C_BASYS3_SYSCLK_NS);

        i_signal <= '1';
        WAIT FOR (C_CORRECT_DEBOUNCE_CLK_TICKS + 10) * C_BASYS3_SYSCLK_NS;

        -- end of the simulation
        REPORT "Simulaiton has finished";
        finish;

    END PROCESS test_process;

END testbench;