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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity btn_debouncer is
    generic (
        G_DEBOUNCE_TIMEOUT_MS: positive := 20;         -- button debounce time delay (by default 20ms)
        G_CLK_FREQ_HZ        : positive := 100_000_000 -- for this project it is assumed 100MHz
    );
    port (
        i_clk          : in std_logic;
        i_rst_n        : in std_logic;
        i_btn          : in std_logic;
        o_btn_debounced: out std_logic;
    );
end; -- end of the entity


architecture rtl of btn_debouncer is
    signal s_btn_flipflop: std_logic_vector(1 downto 0);
begin

    button_debounce_process : process (i_clk, i_rst_n) is
        constant C_DEBOUNCE_TIMEOUT_CLK_TICKS: positive := (G_CLK_FREQ_HZ / 1000) * G_DEBOUNCE_TIMEOUT_MS;
        variable debounce_cnt                : natural range 0 to C_DEBOUNCE_TIMEOUT_CLK_TICKS := C_DEBOUNCE_TIMEOUT_CLK_TICKS;
    begin
        if (i_rst_n = '0') then
            debounce_cnt    := C_DEBOUNCE_TIMEOUT_CLK_TICKS;
            o_btn_debounced <= '0';
            s_btn_flipflop  <= (others => '0');
        elsif rising_edge(i_clk) then
            s_btn_flipflop(0) <= i_btn;
            s_btn_flipflop(1) <= s_btn_flipflop(0);
            if (s_btn_flipflop(1) = '1') then
                if (debounce_cnt = 0) then
                    o_btn_debounced <= '1';
                else
                    debounce_cnt := debounce_cnt - 1;
                end if;
            else
                o_btn_debounced <= '0';
                debounce_cnt    := C_DEBOUNCE_TIMEOUT_CLK_TICKS;
            end if;
        end if;
    end process button_debounce_process;

end rtl; -- end of the architecture