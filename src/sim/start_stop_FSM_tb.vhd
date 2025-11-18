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


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.drone_utils_pkg.all;
use work.control_pkg.all;


entity start_stop_FSM_tb is
end; -- end of entity


architecture testbench of start_stop_FSM_tb is
    -- Constants
    constant C_CORRECT_DEBOUNCE_CLK_TICKS : positive := (C_BASYS3_SYSCLK_HZ / 1000) * C_DEBOUNCE_TIMEOUT_MS;
    -- DUVs signals
    signal i_clk          : std_logic := '0';
    signal i_rst_n        : std_logic := '0';
    signal i_signal       : std_logic := '0'; -- input to btn_debouncer
    signal o_btn_debounced: std_logic := '0'; -- output of btn_debouncer/ input to edge_detector
    signal o_edge         : std_logic;        -- output of edge_detector/input to FSM
    signal o_is_running   : std_logic;
begin
    btn_debouncer_duv: btn_debouncer 
        generic map (
            G_DEBOUNCE_TIMEOUT_MS => C_DEBOUNCE_TIMEOUT_MS,
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


    i_clk   <= not i_clk after C_BASYS3_SYSCLK_NS/2;
    i_rst_n <= '0', '1' after 3 * C_BASYS3_SYSCLK_NS;

    test_process: process is
    begin
        wait until i_rst_n = '1';
        -- Simulation begins here
        -- Perfect signal
        report "Perfect signal";
        i_signal <= '0';
        wait for 2 * C_BASYS3_SYSCLK_NS;

        i_signal <= '1';
        wait for (C_CORRECT_DEBOUNCE_CLK_TICKS + 2) * C_BASYS3_SYSCLK_NS;

        -- Debouncing: back to 0
        report "Bounce from 0 to 1 and then to 0 again";
        i_signal <= '0';
        wait for time(0.5 * real(C_CORRECT_DEBOUNCE_CLK_TICKS) * C_BASYS3_SYSCLK_NS);

        i_signal <= '1';
        wait for C_BASYS3_SYSCLK_NS;

        i_signal <= '0';
        wait for time(0.5 * real(C_CORRECT_DEBOUNCE_CLK_TICKS + 2) * C_BASYS3_SYSCLK_NS - C_BASYS3_SYSCLK_NS);

        -- Debouncing: from 0 to 1 and then to 0 and then to 1 again
        report "Bounce from 0 to 1 and then to 0 and to 1 again";
        i_signal <= '0';
        wait for time(0.1 * real(C_CORRECT_DEBOUNCE_CLK_TICKS) * C_BASYS3_SYSCLK_NS);

        i_signal <= '1';
        wait for time(0.1 * real(C_CORRECT_DEBOUNCE_CLK_TICKS) * C_BASYS3_SYSCLK_NS);

        i_signal <= '0';
        wait for time(0.2 * real(C_CORRECT_DEBOUNCE_CLK_TICKS) * C_BASYS3_SYSCLK_NS);

        i_signal <= '1';
        wait for (C_CORRECT_DEBOUNCE_CLK_TICKS + 10) * C_BASYS3_SYSCLK_NS;

        -- end of the simulation
        wait for 5 * C_BASYS3_SYSCLK_NS;
        assert false report "Simulation has finished" severity failure;
    end process test_process;

end testbench;