-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 04.11.25
-- Design Name: 
-- Module Name: PWM
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Module implementing generic PWM. In the project it is assumed
--              to generate two instances of pwm:
--              - pwm_right_motor
--              - pwm_left_motor
--
--              This implementation is based on the two counters approach.
--              The first counter, defined as an internal signal- clk_cnt, is used
--              to derive lower frequency control signal for the pwm_process.
--              Given we wish to have PWM module operating in 5kHz frequency and the
--              main clock is 100MHz we need to perform the following calculations:
--
--              100MHz/5kHz=20000 -> full PWM counting defined by resolution of G_PWM_BITS
--                                   must take 20000 cycles of 100MHz clock
--
--              20000/lenght(G_PWM_BITS = 256)=78 -> signle PWM counter step (o_pwm_cnt) happens
--                                                   every 78 100MHz clock cycles
--
--              The logic which decides when o_pwm_cnt increments and when PWM issues 
--              an impulse happens (as for the example above) every 78 100MHz clock cycles.
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


entity pwm is
    generic (
        G_PWM_BITS: integer;        -- specifies the resolution
                                    -- if equal to 8 bits the PWM counter will
                                    -- count from 0 to 255

        G_CLK_DIV : positive := 78  -- clock divider, it specifies how many
                                    -- "fast clk ticks" equal one "slow clk tick"
                                    -- set by default to the value allowing to 
                                    -- create 5kHz signal from 100MHz clock
    );
    port (
            i_clk           : in  std_logic;
            i_rst_n         : in  std_logic;
            i_enb           : in  std_logic; -- when set high the PWM signal will be generated
            i_duty_cycle    : in  unsigned(G_PWM_BITS - 1 downto 0);
            o_pwm           : out std_logic;
            o_pwm_cnt       : out unsigned(G_PWM_BITS - 1 downto 0)
        );
end; -- end of the entity


architecture rtl of pwm is
    signal clk_cnt: integer range 0 to G_CLK_DIV - 1;
begin
    clk_divider_process : process (i_clk, i_rst_n) is
    begin
        if (i_rst_n = '0') then
            clk_cnt <= 0;
        elsif rising_edge(i_clk) then
            if clk_cnt < G_CLK_DIV - 1 then
                clk_cnt <= clk_cnt + 1;
            else
                clk_cnt <= 0;
            end if;
        end if;
    end process clk_divider_process;

    pwm_process : process (i_clk, i_rst_n) is
        variable internal_pwm_cnt: unsigned(G_PWM_BITS - 1 downto 0);
    begin
        if (i_rst_n = '0') then
            o_pwm            <= '0';
            o_pwm_cnt        <= (others => '0');
            internal_pwm_cnt := (others => '0');
        elsif rising_edge(i_clk) then
            if (i_enb = '1') then
                if (G_CLK_DIV = 1 or clk_cnt = 0) then
                    o_pwm_cnt        <= internal_pwm_cnt + 1;
                    internal_pwm_cnt := internal_pwm_cnt + 1;
                    o_pwm            <= '0';

                    -- The if-conditions below solves the issues of PWM with duty cycle
                    -- of 100%. It checks for the second largest usigned value and effectively
                    -- it shortens the period.
                    -- Example:
                    -- G_PWM_BITS=8 bits -> max(o_pwm_cnt)=255 (11111111), 2nd largest is 254 (11111110)
                    -- the line unsigned(to_signed(-2, o_pwm_cnt'length) produces 8-bit long signed -2 but
                    -- interprets it as unsigned. -2 in binary is 11111110 and when interpreted as unsigned
                    -- it is exactly 254.
                    if internal_pwm_cnt = unsigned(to_signed(-2, o_pwm_cnt'length)) then
                        o_pwm_cnt <= (others => '0');
                    end if;

                    if (internal_pwm_cnt < i_duty_cycle) then
                        o_pwm     <= '1';
                    end if;
                end if;
            else
                o_pwm            <= '0';
                o_pwm_cnt        <= (others => '0');
                internal_pwm_cnt := (others => '0');
            end if;
        end if;
    end process pwm_process;

end rtl;