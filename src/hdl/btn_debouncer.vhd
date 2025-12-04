-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 08.11.25
-- Design Name: 
-- Module Name: btn_debouncer
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Module implementing button debouncer. The module requires
--              a value in ms which specifies a delay in checking for the button
--              debouncing.
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
ENTITY btn_debouncer IS
    GENERIC (
        G_DEBOUNCE_TIMEOUT_MS : POSITIVE := 20; -- button debounce time delay (by default 20ms)
        G_CLK_FREQ_HZ : POSITIVE := 100_000_000 -- for this project it is assumed 100MHz
    );
    PORT (
        i_clk : IN STD_LOGIC;
        i_rst_n : IN STD_LOGIC;
        i_btn : IN STD_LOGIC;
        o_btn_debounced : OUT STD_LOGIC
    );
END; -- end of the entity
ARCHITECTURE rtl OF btn_debouncer IS
    SIGNAL s_btn_flipflop : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN

    button_debounce_process : PROCESS (i_clk, i_rst_n) IS
        CONSTANT C_DEBOUNCE_TIMEOUT_CLK_TICKS : POSITIVE := (G_CLK_FREQ_HZ / 1000) * G_DEBOUNCE_TIMEOUT_MS;
        VARIABLE debounce_cnt : NATURAL RANGE 0 TO C_DEBOUNCE_TIMEOUT_CLK_TICKS := C_DEBOUNCE_TIMEOUT_CLK_TICKS;
    BEGIN
        IF (i_rst_n = '0') THEN
            debounce_cnt := C_DEBOUNCE_TIMEOUT_CLK_TICKS;
            o_btn_debounced <= '0';
            s_btn_flipflop <= (OTHERS => '0');
        ELSIF rising_edge(i_clk) THEN
            s_btn_flipflop(0) <= i_btn;
            s_btn_flipflop(1) <= s_btn_flipflop(0);
            IF (s_btn_flipflop(1) = '1') THEN
                IF (debounce_cnt = 0) THEN
                    o_btn_debounced <= '1';
                ELSE
                    debounce_cnt := debounce_cnt - 1;
                END IF;
            ELSE
                o_btn_debounced <= '0';
                debounce_cnt := C_DEBOUNCE_TIMEOUT_CLK_TICKS;
            END IF;
        END IF;
    END PROCESS button_debounce_process;

END rtl; -- end of the architecture