-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 08.11.25
-- Design Name: 
-- Module Name: pwm_tb
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Testbench for PWM
-- 
-- Dependencies: drone_utils_pkg
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.finish;

LIBRARY work;
USE work.drone_utils_pkg.ALL;
ENTITY pwm_tb IS
END; -- end of entity
ARCHITECTURE testbench OF pwm_tb IS
    -- Constants
    CONSTANT C_PWM_BITS_TEST : INTEGER := 8;
    CONSTANT C_PWM_G_CLK_DIV : POSITIVE := 78;
    CONSTANT DUTY_CYCLE_15_PROC : unsigned(C_PWM_BITS_TEST - 1 DOWNTO 0) := compute_duty_cycle(15, C_PWM_BITS_TEST);
    CONSTANT DUTY_CYCLE_50_PROC : unsigned(C_PWM_BITS_TEST - 1 DOWNTO 0) := compute_duty_cycle(50, C_PWM_BITS_TEST);
    CONSTANT DUTY_CYCLE_90_PROC : unsigned(C_PWM_BITS_TEST - 1 DOWNTO 0) := compute_duty_cycle(90, C_PWM_BITS_TEST);

    -- DUV signals
    SIGNAL i_clk : STD_LOGIC := '0';
    SIGNAL i_rst_n : STD_LOGIC := '0';
    SIGNAL i_enb : STD_LOGIC := '0';
    SIGNAL i_duty_cycle : unsigned(C_PWM_BITS_TEST - 1 DOWNTO 0);
    SIGNAL o_pwm : STD_LOGIC;
    SIGNAL o_pwm_cnt : unsigned(C_PWM_BITS_TEST - 1 DOWNTO 0);
BEGIN

    duv : pwm
    GENERIC MAP(
        G_PWM_BITS => C_PWM_BITS_TEST,
        G_CLK_DIV => C_PWM_G_CLK_DIV
    )

    PORT MAP(
        i_clk => i_clk,
        i_rst_n => i_rst_n,
        i_enb => i_enb,
        i_duty_cycle => i_duty_cycle,
        o_pwm => o_pwm,
        o_pwm_cnt => o_pwm_cnt
    );

    i_clk <= NOT i_clk AFTER C_BASYS3_SYSCLK_NS/2;
    i_rst_n <= '0', '1' AFTER 3 * C_BASYS3_SYSCLK_NS;

    test_process : PROCESS IS
    BEGIN
        WAIT UNTIL i_rst_n = '1';
        -- Simulation begins here
        i_enb <= '1';
        WAIT FOR C_BASYS3_SYSCLK_NS;

        REPORT "Duty cycle of 15%";
        i_duty_cycle <= DUTY_CYCLE_15_PROC;
        WAIT FOR 20000 * C_BASYS3_SYSCLK_NS;

        REPORT "Duty cycle of 50%";
        i_duty_cycle <= DUTY_CYCLE_50_PROC;
        WAIT FOR 20000 * C_BASYS3_SYSCLK_NS;

        REPORT "Duty cycle of 90%";
        i_duty_cycle <= DUTY_CYCLE_90_PROC;
        WAIT FOR 20000 * C_BASYS3_SYSCLK_NS;

        -- end of the simulation
        WAIT FOR 5 * C_BASYS3_SYSCLK_NS;

        REPORT "Simulaiton has finished";
        finish;

    END PROCESS test_process;

END testbench;
