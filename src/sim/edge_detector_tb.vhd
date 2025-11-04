-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 04.11.25
-- Design Name: 
-- Module Name: edge_detector_tb
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Testbench for edge_detector
-- 
-- Dependencies: drone_utils_pkg
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


entity edge_detector_tb is 
end; -- end of entity


architecture testbench of edge_detector_tb is
    signal i_clk   : std_logic := '0';
    signal i_rst_n : std_logic := '0';
    signal i_signal: std_logic := '0';
    signal o_edge  : std_logic;
begin

    duv: edge_detector 
        generic map (
            G_RISING_EDGE => true
        )

        port map (
            i_clk    => i_clk,
            i_rst_n  => i_rst_n,
            i_signal => i_signal,
            o_edge   => o_edge
        );

    i_clk   <= not i_clk after C_BASYS3_SYSCLK_NS/2;
    i_rst_n <= '0', '1' after 3 * C_BASYS3_SYSCLK_NS;

    test_process: process is
    begin
        wait until i_rst_n = '1';
        -- Simulation begins here
        i_signal <= '0';
        wait for 2 * C_BASYS3_SYSCLK_NS;

        i_signal <= '1';
        wait for 3 * C_BASYS3_SYSCLK_NS;

        i_signal <= '0';
        wait for C_BASYS3_SYSCLK_NS;

        i_signal <= '1';
        wait for 3 * C_BASYS3_SYSCLK_NS;

        -- end of the simulation
        wait for 5 * C_BASYS3_SYSCLK_NS;
        assert false report "Simulation has finished" severity failure;


    end process test_process;

end testbench; -- end of the architecture