-----------------------------------------------------------------------------------
-- Company: ISAE
-- Engineer: Szymon Bogus
-- 
-- Create Date: 24.11.25
-- Design Name: 
-- Module Name: screen_utils_pkg
-- Project Name: drone_basys3
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Package declaring driver for the 7-segment embedded display.
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
-----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
PACKAGE screen_utils_pkg IS
    -- Types used to communicate the actual screen driver with the top module.
    -- The top module should not know the exact but encoding for neither t_digit_id,
    -- nor t_digit_val.

    -- t_digit_id represents which digit the top module wants to use
    -- most left [00][01][02][03] most right
    TYPE t_digit_id IS (DIGIT_ID_00, DIGIT_ID_01, DIGIT_ID_02, DIGIT_ID_03);

    -- t_digit_val is used to convey the information regarding the number to present
    -- on the selected display
    TYPE t_digit_val IS (DIGIT_00,
        DIGIT_01,
        DIGIT_02,
        DIGIT_03,
        DIGIT_04,
        DIGIT_05,
        DIGIT_06,
        DIGIT_07,
        DIGIT_08,
        DIGIT_09,
        DIGIT_10,
        DIGIT_11,
        DIGIT_12,
        DIGIT_13,
        DIGIT_14,
        DIGIT_15,
        DIGIT_OFF,
        DIGIT_ERR);

    -- t_segment represents segments (g, f, e, d, c, b, a),
    -- all signals are active low
    SUBTYPE t_segment IS STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- t_encoding_array is an array type to hold encodings 
    -- for Hex values 0-F
    TYPE t_encoding_array IS ARRAY (t_digit_val) OF t_segment;

    -- segment encoding table (active low)
    -- order: gfedcba
    CONSTANT C_HEX_TO_SEG : t_encoding_array := (
        -- 0: ABCDEF on (G off) -> "1000000"
        DIGIT_00 => "1000000",

        -- 1: BC on -> "1111001"
        DIGIT_01 => "1111001",

        -- 2: ABDEG on -> "0100100"
        DIGIT_02 => "0100100",

        -- 3: ABCDG on -> "0110000"
        DIGIT_03 => "0110000",

        -- 4: BCFG on -> "0011001"
        DIGIT_04 => "0011001",

        -- 5: ACDFG on -> "0010010"
        DIGIT_05 => "0010010",

        -- 6: ACDEFG on -> "0000010"
        DIGIT_06 => "0000010",

        -- 7: ABC on -> "1111000"
        DIGIT_07 => "1111000",

        -- 8: All on -> "0000000"
        DIGIT_08 => "0000000",

        -- 9: ABCDFG on -> "0010000"
        DIGIT_09 => "0010000",

        -- A: ABCEFG on -> "0001000"
        DIGIT_10 => "0001000",

        -- b: CDEFG on -> "0000011"
        DIGIT_11 => "0000011",

        -- C: ADEF on -> "1000110"
        DIGIT_12 => "1000110",

        -- d: BCDEG on -> "0100001"
        DIGIT_13 => "0100001",

        -- E: ADEFG on -> "0000110"
        DIGIT_14 => "0000110",

        -- F: AEFG on -> "0001110"
        DIGIT_15 => "0001110",

        -- all segments OFF
        DIGIT_OFF => "1111111",

        -- error
        -- DIGIT_ERR => "0000110"  -- repeats with E
    );

    CONSTANT C_ANODE_OFF : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1111";

    COMPONENT display_controller IS
        GENERIC (
            G_REFRESH_PER_DIGIT_MS : POSITIVE := 1; -- 1ms by default
            G_CLK_FREQ_HZ : POSITIVE := 100_000_000 -- 100 MHz by default
        );
        PORT (
            i_clk : IN STD_LOGIC;
            i_rst_n : IN STD_LOGIC;
            i_digit_0 : IN t_digit_val; -- rightmost digit
            i_digit_1 : IN t_digit_val;
            i_digit_2 : IN t_digit_val;
            i_digit_3 : IN t_digit_val; -- leftmost digit
            o_anodes : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); --f
            o_segments : OUT t_segment
        );
    END COMPONENT;

    -- Functions used to convert the encoded value for a display to present
    -- into an actual HEX representation required by the hardware
    FUNCTION get_segment_from_velocity(val : t_digit_val) RETURN t_segment;

END screen_utils_pkg;
PACKAGE BODY screen_utils_pkg IS

    FUNCTION get_segment_from_int(val : t_digit_val) RETURN t_segment IS
    BEGIN
        RETURN C_HEX_TO_SEG(val);
    END FUNCTION;

END screen_utils_pkg;