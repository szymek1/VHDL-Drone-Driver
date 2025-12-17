-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 17.12.25
-- Design Name: 
-- Module Name: display_controller_tb
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Testbench for 7-segment display controller
-- 
-- Dependencies: screen_utils_pkg
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.env.finish;

LIBRARY work;
USE work.screen_utils_pkg.ALL;
USE work.drone_utils_pkg.ALL;

ENTITY display_controller_tb IS
END; -- end of entity
ARCHITECTURE testbench OF display_controller_tb IS
    -- DUV signals
    SIGNAL i_clk : STD_LOGIC := '0';
    SIGNAL i_rst_n : STD_LOGIC := '0';
    SIGNAL i_digit_0 : t_digit_val;
    SIGNAL i_digit_1 : t_digit_val;
    SIGNAL i_digit_2 : t_digit_val;
    SIGNAL i_digit_3 : t_digit_val;
    SIGNAL o_anodes : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL o_segments : t_segment;
BEGIN

    display_controller_duv : display_controller
    PORT MAP(
        i_clk => i_clk,
        i_rst_n => i_rst_n,
        i_digit_0 => i_digit_0,
        i_digit_1 => i_digit_1,
        i_digit_2 => i_digit_2,
        i_digit_3 => i_digit_3,
        o_anodes => o_anodes,
        o_segments => o_segments
    );

    i_clk <= NOT i_clk AFTER C_BASYS3_SYSCLK_NS/2;
    i_rst_n <= '0', '1' AFTER 3 * C_BASYS3_SYSCLK_NS;

    test_process : PROCESS IS
    BEGIN
        WAIT UNTIL i_rst_n = '1';

        -- Test 1: display set to 1, 2, 3, 4
        i_digit_0 <= DIGIT_01;
        i_digit_1 <= DIGIT_02;
        i_digit_2 <= DIGIT_03;
        i_digit_3 <= DIGIT_04;
        WAIT FOR 4 ms;

        -- Test 2: change display plus some off
        i_digit_0 <= DIGIT_00;
        i_digit_1 <= DIGIT_OFF;
        i_digit_2 <= DIGIT_OFF;
        i_digit_3 <= DIGIT_09;
        WAIT FOR 4 ms;

        -- end of the simulation
        WAIT FOR 5 * C_BASYS3_SYSCLK_NS;
        REPORT "Simulaiton has finished";
        finish;

    END PROCESS test_process;

END testbench; -- end of the architecture