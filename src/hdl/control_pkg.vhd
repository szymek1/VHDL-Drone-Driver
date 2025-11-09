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
    component start_stop_FSM is
        port (
            i_clk        : in  std_logic;
            i_rst_n      : in  std_logic;
            i_btn_pressed: in  std_logic;
            o_is_running : out std_logic
        );
    end component;

    -- Movement FSM
    type t_pwm_duty_cycle is (DUTY_CYCLE_0, DUTY_CYCLE_15, DUTY_CYCLE_50, DUTY_CYCLE_90);
    component movement_FSM is
        generic (
            G_BLACK_LINE: std_logic := '1' -- specify the value which color sensors
                                           -- provide when the black color is detected.
                                           -- logic 1 by default 
        );
        port (
            i_clk        : in  std_logic;
            i_rst_n      : in  std_logic;
            i_is_running : in  std_logic;
            i_sensor_l   : in  std_logic;
            i_sensor_r   : in  std_logic;
            o_pwm_enb    : out std_logic;
            o_motor_l_pwm: out t_pwm_duty_cycle;
            o_motor_r_pwm: out t_pwm_duty_cycle;
        );
    end component;
end package control_pkg; -- end of the package