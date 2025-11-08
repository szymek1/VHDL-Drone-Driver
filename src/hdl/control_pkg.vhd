-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 08.11.25
-- Design Name: 
-- Module Name: control_pkg
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: VHDL package defining control FMSs parameters.
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;


package control_pkg is 
    -- Start/Stop FSM
    component start_stop_FMS is
        port (
            i_clk        : in std_logic;
            i_rst_n      : in std_logic;
            i_btn_pressed: in std_logic;
            o_is_running : in std_logic
        );
    end component;
end package control_pkg; -- end of the package