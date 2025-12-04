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
--              - U_PWM_LEFT: left motor
--              - U_PWM_RIGHT: right motor
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY pwm IS
    GENERIC (
        G_PWM_BITS : INTEGER; -- specifies the resolution
        -- if equal to 8 bits the PWM counter will
        -- count from 0 to 255

        G_CLK_DIV : POSITIVE := 78 -- clock divider, it specifies how many
        -- "fast clk ticks" equal one "slow clk tick"
        -- set by default to the value allowing to 
        -- create 5kHz signal from 100MHz clock
    );
    PORT (
        i_clk : IN STD_LOGIC;
        i_rst_n : IN STD_LOGIC;
        i_enb : IN STD_LOGIC; -- when set high the PWM signal will be generated
        i_duty_cycle : IN unsigned(G_PWM_BITS - 1 DOWNTO 0);
        o_pwm : OUT STD_LOGIC;
        o_pwm_cnt : OUT unsigned(G_PWM_BITS - 1 DOWNTO 0)
    );
END; -- end of the entity
ARCHITECTURE rtl OF pwm IS
    SIGNAL clk_cnt : INTEGER RANGE 0 TO G_CLK_DIV - 1;
BEGIN
    clk_divider_process : PROCESS (i_clk, i_rst_n) IS
    BEGIN
        IF (i_rst_n = '0') THEN
            clk_cnt <= 0;
        ELSIF rising_edge(i_clk) THEN
            IF clk_cnt < G_CLK_DIV - 1 THEN
                clk_cnt <= clk_cnt + 1;
            ELSE
                clk_cnt <= 0;
            END IF;
        END IF;
    END PROCESS clk_divider_process;

    pwm_process : PROCESS (i_clk, i_rst_n) IS
        VARIABLE internal_pwm_cnt : unsigned(G_PWM_BITS - 1 DOWNTO 0); -- added to comply
        -- Vivado VHDL 2001, which doesn't allow for 
        -- reading from out port, thus this variable was created
        -- to mitgate that
    BEGIN
        IF (i_rst_n = '0') THEN
            o_pwm <= '0';
            o_pwm_cnt <= (OTHERS => '0');
            internal_pwm_cnt := (OTHERS => '0');
        ELSIF rising_edge(i_clk) THEN
            IF (i_enb = '1') THEN
                IF (G_CLK_DIV = 1 OR clk_cnt = 0) THEN
                    o_pwm_cnt <= internal_pwm_cnt + 1;
                    internal_pwm_cnt := internal_pwm_cnt + 1;
                    o_pwm <= '0';

                    -- The if-conditions below solves the issues of PWM with duty cycle
                    -- of 100%. It checks for the second largest usigned value and effectively
                    -- it shortens the period.
                    -- Example:
                    -- G_PWM_BITS=8 bits -> max(o_pwm_cnt)=255 (11111111), 2nd largest is 254 (11111110)
                    -- the line unsigned(to_signed(-2, o_pwm_cnt'length) produces 8-bit long signed -2 but
                    -- interprets it as unsigned. -2 in binary is 11111110 and when interpreted as unsigned
                    -- it is exactly 254.
                    IF internal_pwm_cnt = unsigned(to_signed(-2, o_pwm_cnt'length)) THEN
                        o_pwm_cnt <= (OTHERS => '0');
                    END IF;

                    IF (internal_pwm_cnt < i_duty_cycle) THEN
                        o_pwm <= '1';
                    END IF;
                END IF;
            ELSE
                o_pwm <= '0';
                o_pwm_cnt <= (OTHERS => '0');
                internal_pwm_cnt := (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS pwm_process;

END rtl;