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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.drone_utils_pkg.all;


entity pwm_tb is 
end; -- end of entity


architecture testbench of pwm_tb is
    -- Utilities
    function compute_duty_cycle (
        percentage_value : integer;
        bits             : integer
    ) return unsigned is
        variable max_val   : real;
        variable duty_real : real; 
        variable duty_int  : integer; 
    begin
        max_val := (2.0**real(bits)) - 1.0;
        duty_real := (real(percentage_value) / 100.0) * max_val;
        duty_int := integer(round(duty_real));
        return to_unsigned(duty_int, bits);
        
    end function compute_duty_cycle;
    -- Constants
    constant C_PWM_BITS_TEST : integer  := 8;
    constant C_PWM_G_CLK_DIV : positive := 78;
    constant DUTY_CYCLE_15_PROC: unsigned(C_PWM_BITS_TEST - 1 downto 0) := compute_duty_cycle(15, C_PWM_BITS_TEST);
    constant DUTY_CYCLE_50_PROC: unsigned(C_PWM_BITS_TEST - 1 downto 0) := compute_duty_cycle(50, C_PWM_BITS_TEST);
    constant DUTY_CYCLE_90_PROC: unsigned(C_PWM_BITS_TEST - 1 downto 0) := compute_duty_cycle(90, C_PWM_BITS_TEST);
    
    -- DUV signals
    signal i_clk       : std_logic := '0';
    signal i_rst_n     : std_logic := '0';
    signal i_enb       : std_logic := '0';
    signal i_duty_cycle: unsigned(C_PWM_BITS_TEST - 1 downto 0);
    signal o_pwm       : std_logic;
    signal o_pwm_cnt   : unsigned(C_PWM_BITS_TEST - 1 downto 0);
begin

    duv: pwm 
        generic map (
            G_PWM_BITS   => C_PWM_BITS_TEST,
            G_CLK_DIV    => C_PWM_G_CLK_DIV
        )

        port map (
            i_clk        => i_clk,
            i_rst_n      => i_rst_n,
            i_enb        => i_enb,
            i_duty_cycle => i_duty_cycle,
            o_pwm        => o_pwm,
            o_pwm_cnt    => o_pwm_cnt
        );

    i_clk   <= not i_clk after C_BASYS3_SYSCLK_NS/2;
    i_rst_n <= '0', '1' after 3 * C_BASYS3_SYSCLK_NS;

    test_process: process is
    begin
        wait until i_rst_n = '1';
        -- Simulation begins here
        i_enb <= '1';
        wait for C_BASYS3_SYSCLK_NS;

        report "Duty cycle of 15%";
        i_duty_cycle <= DUTY_CYCLE_15_PROC;
        wait for 20000 * C_BASYS3_SYSCLK_NS;

        report "Duty cycle of 50%";
        i_duty_cycle <= DUTY_CYCLE_50_PROC;
        wait for 20000 * C_BASYS3_SYSCLK_NS;

        report "Duty cycle of 90%";
        i_duty_cycle <= DUTY_CYCLE_90_PROC;
        wait for 20000 * C_BASYS3_SYSCLK_NS;

        -- end of the simulation
        wait for 5 * C_BASYS3_SYSCLK_NS;
        assert false report "Simulation has finished" severity failure;

    end process test_process;

end testbench;