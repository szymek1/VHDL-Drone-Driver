-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 17.11.25
-- Design Name: 
-- Module Name: drone_top
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Top module of the project.
-- 
-- Dependencies: control_pkg, drone_utils_pkg
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.drone_utils_pkg.ALL;
USE work.control_pkg.ALL;
USE work.screen_utils_pkg.ALL;
ENTITY drone_top IS
    PORT (
        Clock : IN STD_LOGIC;
        BP_start_stop : IN STD_LOGIC;
        -- btnU          : in std_logic;  -- reset
        Bumper_G : IN STD_LOGIC; -- left sensor
        Bumper_D : IN STD_LOGIC; -- right sensor
        PWM_G_pos : OUT STD_LOGIC; -- left motor PWM output +
        PWM_G_neg : OUT STD_LOGIC; -- left motor PWM output -
        PWM_D_pos : OUT STD_LOGIC; -- right motor PWM output +
        PWM_D_neg : OUT STD_LOGIC; -- right motor PWM output -
        seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END; -- end of the entity
ARCHITECTURE rtl OF drone_top IS
    -- Constants 
    -- PWM
    CONSTANT C_PWM_ENB : STD_LOGIC := '1';
    CONSTANT C_PWM_RESOLUTION_BITS : POSITIVE := 8;
    CONSTANT C_DUTY_0_PCNT : unsigned(C_PWM_RESOLUTION_BITS - 1 DOWNTO 0) := compute_duty_cycle(0, C_PWM_RESOLUTION_BITS);
    CONSTANT C_DUTY_15_PCNT : unsigned(C_PWM_RESOLUTION_BITS - 1 DOWNTO 0) := compute_duty_cycle(15, C_PWM_RESOLUTION_BITS);
    CONSTANT C_DUTY_50_PCNT : unsigned(C_PWM_RESOLUTION_BITS - 1 DOWNTO 0) := compute_duty_cycle(50, C_PWM_RESOLUTION_BITS);
    CONSTANT C_DUTY_90_PCNT : unsigned(C_PWM_RESOLUTION_BITS - 1 DOWNTO 0) := compute_duty_cycle(90, C_PWM_RESOLUTION_BITS);
    -- RST_N: assume no internal reset
    CONSTANT C_RST_N : STD_LOGIC := '1';

    -- Signals
    -- Button debouncer and edge detector
    SIGNAL s_btn_debounced : STD_LOGIC;
    SIGNAL s_edge_detected : STD_LOGIC;
    -- FSMs
    SIGNAL s_is_running : STD_LOGIC;
    SIGNAL s_fsm_cmd_left : t_pwm_duty_cycle;
    SIGNAL s_fsm_cmd_right : t_pwm_duty_cycle;
    -- Display controller
    SIGNAL s_digit_0 : t_digit_val;
    SIGNAL s_digit_1 : t_digit_val;
    SIGNAL s_digit_2 : t_digit_val;
    SIGNAL s_digit_3 : t_digit_val;
    -- PWM decoder
    SIGNAL s_pwm_duty_left : unsigned(C_PWM_RESOLUTION_BITS - 1 DOWNTO 0);
    SIGNAL s_pwm_duty_right : unsigned(C_PWM_RESOLUTION_BITS - 1 DOWNTO 0);
    SIGNAL s_pwm_out_left : STD_LOGIC;
    SIGNAL s_pwm_out_right : STD_LOGIC;
BEGIN

    U_BTN_DEBOUNCER : ENTITY work.btn_debouncer
        GENERIC MAP(
            G_DEBOUNCE_TIMEOUT_MS => C_DEBOUNCE_TIMEOUT_MS,
            G_CLK_FREQ_HZ => C_BASYS3_SYSCLK_HZ
        )
        PORT MAP(
            i_clk => Clock,
            i_rst_n => C_RST_N,
            i_btn => BP_start_stop,
            o_btn_debounced => s_btn_debounced
        );

    U_EDGE_DETECT : ENTITY work.edge_detector
        GENERIC MAP(
            G_RISING_EDGE => true
        )
        PORT MAP(
            i_clk => Clock,
            i_rst_n => C_RST_N,
            i_signal => s_btn_debounced,
            o_edge => s_edge_detected
        );

    U_START_STOP_FSM : ENTITY work.start_stop_FSM
        PORT MAP(
            i_clk => Clock,
            i_rst_n => C_RST_N,
            i_btn_pressed => s_edge_detected,
            o_is_running => s_is_running
        );

    U_MOVEMENT_FSM : ENTITY work.movement_FSM
        GENERIC MAP(
            G_BLACK_LINE => '1'
        )
        PORT MAP(
            i_clk => Clock,
            i_rst_n => C_RST_N,
            i_is_running => s_is_running,
            i_sensor_l => Bumper_G, -- 'G' (gauche) to 'left'
            i_sensor_r => Bumper_D, -- 'D' (droit) to 'right'
            o_pwm_enb => OPEN,
            o_motor_l_pwm => s_fsm_cmd_left,
            o_motor_r_pwm => s_fsm_cmd_right
        );

    U_DISPLAY_CONTROLLER : ENTITY work.display_controller
        PORT MAP(
            i_clk => Clock,
            i_rst_n => C_RST_N,
            i_digit_0 => s_digit_0,
            i_digit_1 => s_digit_1,
            i_digit_2 => s_digit_2,
            i_digit_3 => s_digit_3,
            o_anodes => an,
            o_segments => seg
        );

    p_display_decoder : PROCESS (s_fsm_cmd_left, s_fsm_cmd_right)
    BEGIN
        -- left motor (digits 3 & 2)
        CASE s_fsm_cmd_left IS
            WHEN DUTY_CYCLE_0 =>
                s_digit_3 <= DIGIT_00;
                s_digit_2 <= DIGIT_00;

            WHEN DUTY_CYCLE_15 =>
                s_digit_3 <= DIGIT_01;
                s_digit_2 <= DIGIT_05;

            WHEN DUTY_CYCLE_50 =>
                s_digit_3 <= DIGIT_05;
                s_digit_2 <= DIGIT_00;

            WHEN DUTY_CYCLE_90 =>
                s_digit_3 <= DIGIT_09;
                s_digit_2 <= DIGIT_00;

            WHEN OTHERS =>
                s_digit_3 <= DIGIT_OFF;
                s_digit_2 <= DIGIT_OFF;
        END CASE;

        -- right motor (digits 1 & 0)
        CASE s_fsm_cmd_right IS
            WHEN DUTY_CYCLE_0 =>
                s_digit_1 <= DIGIT_00;
                s_digit_0 <= DIGIT_00;

            WHEN DUTY_CYCLE_15 =>
                s_digit_1 <= DIGIT_01;
                s_digit_0 <= DIGIT_05;

            WHEN DUTY_CYCLE_50 =>
                s_digit_1 <= DIGIT_05;
                s_digit_0 <= DIGIT_00;

            WHEN DUTY_CYCLE_90 =>
                s_digit_1 <= DIGIT_09;
                s_digit_0 <= DIGIT_00;

            WHEN OTHERS =>
                s_digit_1 <= DIGIT_OFF;
                s_digit_0 <= DIGIT_OFF;
        END CASE;
    END PROCESS p_display_decoder;

    -- Decoding FSM commands and generating the final PWM signal
    p_pwm_decoder : PROCESS (s_fsm_cmd_left, s_fsm_cmd_right) IS
    BEGIN
        -- left motor command
        CASE s_fsm_cmd_left IS
            WHEN DUTY_CYCLE_0 => s_pwm_duty_left <= C_DUTY_0_PCNT;
            WHEN DUTY_CYCLE_15 => s_pwm_duty_left <= C_DUTY_15_PCNT;
            WHEN DUTY_CYCLE_50 => s_pwm_duty_left <= C_DUTY_50_PCNT;
            WHEN DUTY_CYCLE_90 => s_pwm_duty_left <= C_DUTY_90_PCNT;
        END CASE;

        -- right motor command
        CASE s_fsm_cmd_right IS
            WHEN DUTY_CYCLE_0 => s_pwm_duty_right <= C_DUTY_0_PCNT;
            WHEN DUTY_CYCLE_15 => s_pwm_duty_right <= C_DUTY_15_PCNT;
            WHEN DUTY_CYCLE_50 => s_pwm_duty_right <= C_DUTY_50_PCNT;
            WHEN DUTY_CYCLE_90 => s_pwm_duty_right <= C_DUTY_90_PCNT;
        END CASE;
    END PROCESS p_pwm_decoder;

    U_PWM_LEFT : ENTITY work.pwm
        GENERIC MAP(
            G_PWM_BITS => C_PWM_RESOLUTION_BITS,
            G_CLK_DIV => 78 -- ~5kHz from 100MHz / 255 steps
        )
        PORT MAP(
            i_clk => Clock,
            i_rst_n => C_RST_N,
            i_enb => s_is_running, -- PWMs are only on when FSM is running
            i_duty_cycle => s_pwm_duty_left,
            o_pwm => s_pwm_out_left,
            o_pwm_cnt => OPEN -- debug port, not needed here
        );

    U_PWM_RIGHT : ENTITY work.pwm
        GENERIC MAP(
            G_PWM_BITS => C_PWM_RESOLUTION_BITS,
            G_CLK_DIV => 78
        )
        PORT MAP(
            i_clk => Clock,
            i_rst_n => C_RST_N,
            i_enb => s_is_running,
            i_duty_cycle => s_pwm_duty_right,
            o_pwm => s_pwm_out_right,
            o_pwm_cnt => OPEN
        );

    -- left Motor
    PWM_G_pos <= s_pwm_out_left;
    PWM_G_neg <= '0';

    -- right Motor
    PWM_D_pos <= s_pwm_out_right;
    PWM_D_neg <= '0';
END rtl;
