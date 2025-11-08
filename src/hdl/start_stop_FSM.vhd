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


library ieee;
use ieee.std_logic_1164.all;


entity start_stop_FSM is
    port (
        i_clk        : in  std_logic;
        i_rst_n      : in  std_logic;
        i_btn_pressed: in  std_logic; -- provided by edge_detector
        o_is_running : out std_logic
        );
end; -- end of the entity


architecture rtl of start_stop_FSM is 
    type t_state is (IDLE, RUNNING);
    signal curr_state: t_state;
    signal is_running: std_logic; -- internal value for indicating that the machine is running
begin
    start_stop_FSM_process : process (i_clk, i_rst_n) is
    begin
        if (i_rst_n = '0') then
            curr_state <= IDLE;
            is_running <= '0';
        elsif rising_edge(i_clk) then
            case curr_state is 
                when IDLE   =>
                    if (i_btn_pressed = '1') then
                        curr_state <= RUNNING;
                    else 
                        curr_state <= IDLE;
                        is_running <= '0';
                    end if;

                when RUNNING =>
                    if (i_btn_pressed = '1') then
                        curr_state <= IDLE;
                    else 
                        curr_state <= RUNNING;
                        is_running <= '1';
                    end if;
            end case;
        end if;
    end process start_stop_FSM_process;

    -- concurrent assigment of is_running
    o_is_running <= is_running;
end rtl; -- end of the architecture