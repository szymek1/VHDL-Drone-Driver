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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY edge_detector IS
    GENERIC (
        G_RISING_EDGE : BOOLEAN := true -- detect rising edge by default
    );
    PORT (
        i_clk : IN STD_LOGIC;
        i_rst_n : IN STD_LOGIC;
        i_signal : IN STD_LOGIC;
        o_edge : OUT STD_LOGIC -- set to high for one clock cycle
    );
END; -- end of the entity
ARCHITECTURE rtl OF edge_detector IS
    SIGNAL s_prev_i_signal : STD_LOGIC;
BEGIN
    egde_detect_process : PROCESS (i_clk, i_rst_n) IS
    BEGIN
        IF (i_rst_n = '0') THEN
            s_prev_i_signal <= '0';
            o_edge <= '0';
        ELSIF rising_edge(i_clk) THEN
            s_prev_i_signal <= i_signal;

            IF (G_RISING_EDGE = true) THEN
                -- detect rising edge
                IF (s_prev_i_signal = '0' AND i_signal = '1') THEN
                    o_edge <= '1';
                ELSE
                    o_edge <= '0';
                END IF;
            ELSE
                -- detect falling edge
                IF (s_prev_i_signal = '0' AND i_signal = '1') THEN
                    o_edge <= '1';
                ELSE
                    o_edge <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS egde_detect_process;
END rtl; -- end of the architecture
