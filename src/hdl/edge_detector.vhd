-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 30.10.25
-- Design Name: 
-- Module Name: edge_detector
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Module providing edge detection capability. Its purpose for the project
--              is to properly detect button push and send the trigger signal.
--              IMPORTANT: the module assumes i_signal is synchornized
-- 
-- Dependencies: drone_utils_pkg
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: i_signal is provided by btn_debouncer, which synchornizes it
-- 
-----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;


entity edge_detector is
    generic (
        G_RISING_EDGE: boolean := true -- detect rising edge by default
    );
    port (
        i_clk   : in  std_logic;
        i_rst_n : in  std_logic;
        i_signal: in  std_logic;
        o_edge  : out std_logic -- set to high for one clock cycle
    );
end; -- end of the entity


architecture rtl of edge_detector is
    signal s_prev_i_signal: std_logic;
begin
    egde_detect_process : process (i_clk, i_rst_n) is
    begin
        if (i_rst_n = '0') then
            s_prev_i_signal <= '0';
            o_edge           <= '0';
        elsif rising_edge(i_clk) then
            s_prev_i_signal <= i_signal;

            if (G_RISING_EDGE = true) then
                -- detect rising edge
                if (s_prev_i_signal = '0' and i_signal = '1') then
                    o_edge <= '1';
                else
                    o_edge <= '0';
                end if;
            else
                -- detect falling edge
                if (s_prev_i_signal = '0' and i_signal = '1') then
                    o_edge <= '1';
                else
                    o_edge <= '0';
                end if;
            end if;
        end if;
    end process egde_detect_process;
end rtl; -- end of the architecture