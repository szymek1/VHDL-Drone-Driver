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


entity edge_detector is
    generic (
        G_RISING_EDGE: boolean := true; -- detect rising edge by default
    );
    port (
        i_clk   : in  std_logic;
        i_rst_n : in  std_logic;
        i_signal: in  std_logic;
        o_edge  : out std_logic -- set to high for one clock cycle
    );
end; -- end of the entity


architecture rtl of edge_detector is
    signal s_prev_i_signals: std_logic_vector(2 downto 0);
    -- s_prev_i_signals(0) and s_prev_i_signals(1) are the 2-bit shift register
    -- s_prev_i_signals(2) holds the previous value of the synchronized signal
begin
    egde_detect_process : process (i_clk, rst_n) is
    begin
        if (i_rst_n = '0') then
            s_prev_i_signals <= (others => '0');
            o_edge           <= '0';
        elsif rising_edge(i_clk) then
            s_prev_i_signals(0) <= i_signal;
            s_prev_i_signals(1) <= s_prev_i_signals(0);
            s_prev_i_signals(2) <= s_prev_i_signals(1);

            alias s_safe_signal      : std_logic is s_prev_i_signals(1);
            alias s_safe_signal_prev : std_logic is s_prev_i_signals(2);

            if (G_RISING_EDGE = true) then
                -- detect rising edge
                if (s_safe_signal = '1' and s_safe_signal_prev = '0') then
                    o_edge <= '1';
                else
                    o_edge <= '0';
                end if;
            else
                -- detect falling edge
                if (s_safe_signal = '0' and s_safe_signal_prev = '1') then
                    o_edge <= '1';
                else
                    o_edge <= '0';
                end if;
            end if;
        end if;
    end process egde_detect_process;
end rtl; -- end of the architecture