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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.drone_utils_pkg.all;
use work.control_pkg.all;


entity drone_top is 
    port (
        Clock         : in std_logic;
        BP_start_stop : in std_logic;
        -- btnU          : in std_logic;  -- reset
        Bumper_G      : in std_logic;  -- left sensor
        Bumper_D      : in std_logic;  -- right sensor
        PWM_G_pos     : out std_logic; -- left motor PWM output +
        PWM_G_neg     : out std_logic; -- left motor PWM output -
        PWM_D_pos     : out std_logic; -- right motor PWM output +
        PWM_D_neg     : out std_logic -- right motor PWM output -
    );
end; -- end of the entity


architecture rtl of drone_top is
    -- Constants 
    -- PWM
    constant C_PWM_ENB             : std_logic := '1';
    constant C_PWM_RESOLUTION_BITS : positive := 8;
    constant C_DUTY_0_PCNT         : unsigned(C_PWM_RESOLUTION_BITS - 1 downto 0) := compute_duty_cycle(0,   C_PWM_RESOLUTION_BITS);
    constant C_DUTY_15_PCNT        : unsigned(C_PWM_RESOLUTION_BITS - 1 downto 0) := compute_duty_cycle(15,  C_PWM_RESOLUTION_BITS);
    constant C_DUTY_50_PCNT        : unsigned(C_PWM_RESOLUTION_BITS - 1 downto 0) := compute_duty_cycle(50,  C_PWM_RESOLUTION_BITS);
    constant C_DUTY_90_PCNT        : unsigned(C_PWM_RESOLUTION_BITS - 1 downto 0) := compute_duty_cycle(90,  C_PWM_RESOLUTION_BITS);
    -- RST_N: assume no internal reset
    constant C_RST_N               : std_logic := '1';

    -- Signals
    -- Button debouncer and edge detector
    signal s_btn_debounced  : std_logic;
    signal s_edge_detected  : std_logic;
    -- FSMs
    signal s_is_running     : std_logic;
    signal s_fsm_cmd_left   : t_pwm_duty_cycle;
    signal s_fsm_cmd_right  : t_pwm_duty_cycle;
    -- PWM decoder
    signal s_pwm_duty_left  : unsigned(C_PWM_RESOLUTION_BITS - 1 downto 0);
    signal s_pwm_duty_right : unsigned(C_PWM_RESOLUTION_BITS - 1 downto 0);
    signal s_pwm_out_left   : std_logic;
    signal s_pwm_out_right  : std_logic;
begin

    U_BTN_DEBOUNCER : entity work.btn_debouncer
        generic map (
            G_DEBOUNCE_TIMEOUT_MS => C_DEBOUNCE_TIMEOUT_MS,
            G_CLK_FREQ_HZ         => C_BASYS3_SYSCLK_HZ
        )
        port map (
            i_clk           => Clock,
            i_rst_n         => C_RST_N,
            i_btn           => BP_start_stop,
            o_btn_debounced => s_btn_debounced
        );

    U_EDGE_DETECT : entity work.edge_detector
        generic map (
            G_RISING_EDGE => true
        )
        port map (
            i_clk     => Clock,
            i_rst_n   => C_RST_N,
            i_signal  => s_btn_debounced,
            o_edge    => s_edge_detected
        );

    U_START_STOP_FSM : entity work.start_stop_FSM
        port map (
            i_clk         => Clock,
            i_rst_n       => C_RST_N,
            i_btn_pressed => s_edge_detected,
            o_is_running  => s_is_running
        );

    U_MOVEMENT_FSM : entity work.movement_FSM
        generic map (
            G_BLACK_LINE => '1'
        )
        port map (
            i_clk         => Clock,
            i_rst_n       => C_RST_N,
            i_is_running  => s_is_running,
            i_sensor_l    => Bumper_G, -- 'G' (gauche) to 'left'
            i_sensor_r    => Bumper_D, -- 'D' (droit) to 'right'
            o_pwm_enb     => open,
            o_motor_l_pwm => s_fsm_cmd_left,
            o_motor_r_pwm => s_fsm_cmd_right
        );

    -- Decoding FSM commands and generating the final PWM signal
    p_pwm_decoder : process (s_fsm_cmd_left, s_fsm_cmd_right) is
    begin
        -- left motor command
        case s_fsm_cmd_left is
            when DUTY_CYCLE_0   => s_pwm_duty_left <= C_DUTY_0_PCNT;
            when DUTY_CYCLE_15  => s_pwm_duty_left <= C_DUTY_15_PCNT;
            when DUTY_CYCLE_50  => s_pwm_duty_left <= C_DUTY_50_PCNT;
            when DUTY_CYCLE_90  => s_pwm_duty_left <= C_DUTY_90_PCNT;
        end case;
        
        -- right motor command
        case s_fsm_cmd_right is
            when DUTY_CYCLE_0   => s_pwm_duty_right <= C_DUTY_0_PCNT;
            when DUTY_CYCLE_15  => s_pwm_duty_right <= C_DUTY_15_PCNT;
            when DUTY_CYCLE_50  => s_pwm_duty_right <= C_DUTY_50_PCNT;
            when DUTY_CYCLE_90  => s_pwm_duty_right <= C_DUTY_90_PCNT;
        end case;
    end process p_pwm_decoder;

    U_PWM_LEFT : entity work.pwm
        generic map (
            G_PWM_BITS => C_PWM_RESOLUTION_BITS,
            G_CLK_DIV  => 78 -- ~5kHz from 100MHz / 255 steps
        )
        port map (
            i_clk        => Clock,
            i_rst_n      => C_RST_N,
            i_enb        => s_is_running, -- PWMs are only on when FSM is running
            i_duty_cycle => s_pwm_duty_left,
            o_pwm        => s_pwm_out_left,
            o_pwm_cnt    => open          -- debug port, not needed here
        );
        
    U_PWM_RIGHT : entity work.pwm
        generic map (
            G_PWM_BITS => C_PWM_RESOLUTION_BITS,
            G_CLK_DIV  => 78
        )
        port map (
            i_clk        => Clock,
            i_rst_n      => C_RST_N,
            i_enb        => s_is_running,
            i_duty_cycle => s_pwm_duty_right,
            o_pwm        => s_pwm_out_right,
            o_pwm_cnt    => open
        );

    -- left Motor
    PWM_G_pos <= s_pwm_out_left;
    PWM_G_neg <= '0';
    
    -- right Motor
    PWM_D_pos <= s_pwm_out_right;
    PWM_D_neg <= '0';
end rtl;