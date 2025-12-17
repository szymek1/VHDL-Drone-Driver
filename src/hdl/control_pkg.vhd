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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
PACKAGE control_pkg IS
    -- Start/Stop FSM
    COMPONENT start_stop_FSM IS
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst_n : IN STD_LOGIC;
            i_btn_pressed : IN STD_LOGIC;
            o_is_running : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Movement FSM
    TYPE t_pwm_duty_cycle IS (DUTY_CYCLE_0, DUTY_CYCLE_15, DUTY_CYCLE_50, DUTY_CYCLE_90);
    COMPONENT movement_FSM IS
        GENERIC (
            G_BLACK_LINE : STD_LOGIC := '1' -- specify the value which color sensors
            -- provide when the black color is detected.
            -- logic 1 by default 
        );
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst_n : IN STD_LOGIC;
            i_is_running : IN STD_LOGIC;
            i_sensor_l : IN STD_LOGIC;
            i_sensor_r : IN STD_LOGIC;
            o_pwm_enb : OUT STD_LOGIC;
            o_motor_l_pwm : OUT t_pwm_duty_cycle;
            o_motor_r_pwm : OUT t_pwm_duty_cycle
        );
    END COMPONENT;
END PACKAGE control_pkg; -- end of the package