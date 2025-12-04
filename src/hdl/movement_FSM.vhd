-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 09.11.25
-- Design Name: 
-- Module Name: movement_FSM
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Movement FSM module. This FSM controls in which direction the robot
--              is moving based on the inputs from color sensors: i_sensor_l and i_sensor_r.
--              It does so by moving between states, where each state issues different 
--              PWM duty cycle command to both left and right engine.
--              There are four states:
--              -> IDLE: robot is not moving, o_pwm_enb == '0' it disables the movment;
--                       transition to FORWARD happens when start_stop_FSM issues
--                       i_is_running == '1', if i_is_running == '0' robot immediately
--                       stops. 
--              -> FORWARD: robot is moving forward, it issues to both o_motor_l_pwm and
--                          o_motor_r_pwm DUTY_CYCLE_90.
--              -> T_LEFT: robot is turning to the left. It issues
--                         o_motor_l_pwm == DUTY_CYCLE_50 & o_motor_r_pwm == DUTY_CYCLE_15
--              -> T_RIGHT: robot is turning to the right. It issues
--                          o_motor_l_pwm == DUTY_CYCLE_15 & o_motor_r_pwm == DUTY_CYCLE_50
-- 
-- Dependencies: control_pkg, start_stop_FMS (input provider)
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY work;
USE work.control_pkg.ALL;
ENTITY movement_FSM IS
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
END; -- end of the entity
ARCHITECTURE rtl OF movement_FSM IS
    -- type t_pwm_duty_cycle is (DUTY_CYCLE_0, DUTY_CYCLE_15, DUTY_CYCLE_50, DUTY_CYCLE_90);
    TYPE t_state IS (IDLE, FORWARD, T_LEFT, T_RIGHT);

    SIGNAL curr_state : t_state;
    -- metastability protection for asynchornous signals coming from sensors
    SIGNAL s_sensor_l_d_flipflop : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL s_sensor_r_d_flipflop : STD_LOGIC_VECTOR(1 DOWNTO 0);

    ALIAS safe_sensor_l : STD_LOGIC IS s_sensor_l_d_flipflop(1);
    ALIAS safe_sensor_r : STD_LOGIC IS s_sensor_r_d_flipflop(1);
BEGIN

    sensors_acq_process : PROCESS (i_clk, i_rst_n) IS
    BEGIN
        IF (i_rst_n = '0') THEN
            s_sensor_l_d_flipflop <= (OTHERS => '0');
            s_sensor_r_d_flipflop <= (OTHERS => '0');
        ELSIF rising_edge(i_clk) THEN
            -- capture values from left and right sensors
            s_sensor_l_d_flipflop(0) <= i_sensor_l;
            s_sensor_l_d_flipflop(1) <= s_sensor_l_d_flipflop(0);

            s_sensor_r_d_flipflop(0) <= i_sensor_r;
            s_sensor_r_d_flipflop(1) <= s_sensor_r_d_flipflop(0);
        END IF;
    END PROCESS sensors_acq_process;

    movement_state_process : PROCESS (i_clk, i_rst_n) IS
        CONSTANT BLACK : STD_LOGIC := G_BLACK_LINE;
        CONSTANT WHITE : STD_LOGIC := NOT G_BLACK_LINE;
    BEGIN
        IF (i_rst_n = '0') THEN
            curr_state <= IDLE;
        ELSIF rising_edge(i_clk) THEN
            CASE curr_state IS
                WHEN IDLE =>
                    -- o_pwm_enb      <= '0';
                    IF (i_is_running = '1') THEN
                        curr_state <= FORWARD;
                    ELSE
                        curr_state <= IDLE;
                    END IF;

                WHEN FORWARD =>
                    IF (i_is_running = '1') THEN
                        IF (safe_sensor_l = WHITE) AND (safe_sensor_r = BLACK) THEN
                            curr_state <= T_LEFT;
                        ELSIF (safe_sensor_l = BLACK) AND (safe_sensor_r = WHITE) THEN
                            curr_state <= T_RIGHT;
                        ELSE -- "00"
                            curr_state <= FORWARD; -- stay moving forward
                        END IF;
                    ELSE
                        curr_state <= IDLE;
                    END IF;

                WHEN T_LEFT =>
                    IF (i_is_running = '1') THEN
                        IF (safe_sensor_l = WHITE) AND (safe_sensor_r = WHITE) THEN
                            curr_state <= FORWARD;
                        ELSIF (safe_sensor_l = BLACK) AND (safe_sensor_r = WHITE) THEN
                            curr_state <= T_RIGHT;
                        ELSE -- "10"
                            curr_state <= T_LEFT; -- stay turning to the left
                        END IF;
                    ELSE
                        curr_state <= IDLE;
                    END IF;

                WHEN T_RIGHT =>
                    IF (i_is_running = '1') THEN
                        IF (safe_sensor_l = WHITE) AND (safe_sensor_r = WHITE) THEN
                            curr_state <= FORWARD;
                        ELSIF (safe_sensor_l = WHITE) AND (safe_sensor_r = BLACK) THEN
                            curr_state <= T_LEFT;
                        ELSE -- "01"
                            curr_state <= T_RIGHT; -- stay turning to the right
                        END IF;
                    ELSE
                        curr_state <= IDLE;
                    END IF;
            END CASE;
        END IF;
    END PROCESS movement_state_process;

    pwm_control_process : PROCESS (curr_state) IS
    BEGIN
        CASE curr_state IS
            WHEN IDLE =>
                o_pwm_enb <= '0';
                o_motor_l_pwm <= DUTY_CYCLE_0;
                o_motor_r_pwm <= DUTY_CYCLE_0;

            WHEN FORWARD =>
                o_pwm_enb <= '1';
                o_motor_l_pwm <= DUTY_CYCLE_50;
                o_motor_r_pwm <= DUTY_CYCLE_50;

            WHEN T_LEFT =>
                o_pwm_enb <= '1';
                o_motor_l_pwm <= DUTY_CYCLE_90;
                o_motor_r_pwm <= DUTY_CYCLE_15;

            WHEN T_RIGHT =>
                o_pwm_enb <= '1';
                o_motor_l_pwm <= DUTY_CYCLE_15;
                o_motor_r_pwm <= DUTY_CYCLE_90;
        END CASE;
    END PROCESS pwm_control_process;

END rtl;