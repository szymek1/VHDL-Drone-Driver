-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 08.11.25
-- Design Name: 
-- Module Name: start_stop_FSM
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Start/Stop FSM which responds to the input signal provided by
--              edge_detector. Whenever it sets btn_pressed to 1 it switches a state.
--              This FMS has two states:
--              -> IDLE (default): idicates that the drone is not moving
--              -> RUNNING: drone is moving and actively searching for the black line
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
ENTITY start_stop_FSM IS
    PORT (
        i_clk : IN STD_LOGIC;
        i_rst_n : IN STD_LOGIC;
        i_btn_pressed : IN STD_LOGIC; -- provided by edge_detector
        o_is_running : OUT STD_LOGIC
    );
END; -- end of the entity
ARCHITECTURE rtl OF start_stop_FSM IS
    TYPE t_state IS (IDLE, RUNNING);
    SIGNAL curr_state : t_state;
    SIGNAL is_running : STD_LOGIC; -- internal value for indicating that the machine is running
BEGIN
    start_stop_FSM_process : PROCESS (i_clk, i_rst_n) IS
    BEGIN
        IF (i_rst_n = '0') THEN
            curr_state <= IDLE;
            is_running <= '0';
        ELSIF rising_edge(i_clk) THEN
            CASE curr_state IS
                WHEN IDLE =>
                    IF (i_btn_pressed = '1') THEN
                        curr_state <= RUNNING;
                    ELSE
                        curr_state <= IDLE;
                        is_running <= '0';
                    END IF;

                WHEN RUNNING =>
                    IF (i_btn_pressed = '1') THEN
                        curr_state <= IDLE;
                    ELSE
                        curr_state <= RUNNING;
                        is_running <= '1';
                    END IF;
            END CASE;
        END IF;
    END PROCESS start_stop_FSM_process;

    -- concurrent assigment of is_running
    o_is_running <= is_running;
END rtl; -- end of the architecture