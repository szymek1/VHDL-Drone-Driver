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


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.control_pkg.all;


entity movement_FSM is
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
        o_motor_r_pwm: out t_pwm_duty_cycle
    );
end; -- end of the entity


architecture rtl of movement_FSM is
    -- type t_pwm_duty_cycle is (DUTY_CYCLE_0, DUTY_CYCLE_15, DUTY_CYCLE_50, DUTY_CYCLE_90);
    type t_state is (IDLE, FORWARD, T_LEFT, T_RIGHT);

    signal curr_state           : t_state;
    -- metastability protection for asynchornous signals coming from sensors
    signal s_sensor_l_d_flipflop: std_logic_vector(1 downto 0);
    signal s_sensor_r_d_flipflop: std_logic_vector(1 downto 0);

    alias safe_sensor_l         : std_logic is s_sensor_l_d_flipflop(1);
    alias safe_sensor_r         : std_logic is s_sensor_r_d_flipflop(1);
begin

    sensors_acq_process : process (i_clk, i_rst_n) is
    begin
        if (i_rst_n = '0') then
            s_sensor_l_d_flipflop <= (others => '0');
            s_sensor_r_d_flipflop <= (others => '0');
        elsif rising_edge(i_clk) then
            -- capture values from left and right sensors
            s_sensor_l_d_flipflop(0) <= i_sensor_l;
            s_sensor_l_d_flipflop(1) <= s_sensor_l_d_flipflop(0);

            s_sensor_r_d_flipflop(0) <= i_sensor_r;
            s_sensor_r_d_flipflop(1) <= s_sensor_r_d_flipflop(0);
        end if;
    end process sensors_acq_process;

    movement_state_process : process (i_clk, i_rst_n) is
        constant BLACK : std_logic := G_BLACK_LINE;
        constant WHITE : std_logic := not G_BLACK_LINE;
    begin
        if (i_rst_n = '0') then
            curr_state <= IDLE;
        elsif rising_edge(i_clk) then
            case curr_state is
                when IDLE    =>
                    -- o_pwm_enb      <= '0';
                    if (i_is_running = '1') then
                        curr_state <= FORWARD;
                    else 
                        curr_state <= IDLE;
                    end if;

                when FORWARD =>
                    if (i_is_running = '1') then 
                        if (safe_sensor_l = WHITE) and (safe_sensor_r = BLACK) then
                            curr_state <= T_LEFT;
                        elsif (safe_sensor_l = BLACK) and (safe_sensor_r = WHITE) then
                            curr_state <= T_RIGHT;
                        else -- "00"
                            curr_state <= FORWARD; -- stay moving forward
                        end if;
                    else
                        curr_state     <= IDLE;
                    end if;

                when T_LEFT   =>
                    if (i_is_running = '1') then
                        if (safe_sensor_l = WHITE) and (safe_sensor_r = WHITE) then
                            curr_state <= FORWARD;
                        elsif (safe_sensor_l = BLACK) and (safe_sensor_r = WHITE) then
                            curr_state <= T_RIGHT;
                        else -- "10"
                            curr_state <= T_LEFT; -- stay turning to the left
                        end if;
                    else
                        curr_state     <= IDLE;
                    end if;

                when T_RIGHT   =>
                    if (i_is_running = '1') then
                        if (safe_sensor_l = WHITE) and (safe_sensor_r = WHITE) then
                            curr_state <= FORWARD;
                        elsif (safe_sensor_l = WHITE) and (safe_sensor_r = BLACK) then
                            curr_state <= T_LEFT;
                        else -- "01"
                            curr_state <= T_RIGHT; -- stay turning to the right
                        end if;
                    else
                        curr_state     <= IDLE;
                    end if;
                end case;
        end if;
    end process movement_state_process;

    pwm_control_process : process (curr_state) is
    begin
        case curr_state is
            when IDLE    =>
                o_pwm_enb     <= '0';
                o_motor_l_pwm <= DUTY_CYCLE_0;
                o_motor_r_pwm <= DUTY_CYCLE_0;
            
            when FORWARD =>
                o_pwm_enb     <= '1';
                o_motor_l_pwm <= DUTY_CYCLE_50;
                o_motor_r_pwm <= DUTY_CYCLE_50;

            when T_LEFT  =>
                o_pwm_enb     <= '1';
                o_motor_l_pwm <= DUTY_CYCLE_90;
                o_motor_r_pwm <= DUTY_CYCLE_15;

            when T_RIGHT =>
                o_pwm_enb     <= '1';
                o_motor_l_pwm <= DUTY_CYCLE_15;
                o_motor_r_pwm <= DUTY_CYCLE_90;
        end case;
    end process pwm_control_process;

end rtl;
