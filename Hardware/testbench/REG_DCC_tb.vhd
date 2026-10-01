----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 11:00:41
-- Design Name: 
-- Module Name: DCC_bit_1_TB - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity REG_DCC_TB is
end REG_DCC_TB;

architecture testbench of REG_DCC_TB is

signal clk100M :  std_logic := '0';
signal reset_n : std_logic := '1';
signal Trame_DCC : std_logic_vector(50 downto 0) := (others => '0');
signal shift : std_logic := '0';
signal load : std_logic := '0';
signal msb : std_logic := '0';
signal end_shift : std_logic := '0';

begin

    
    UUT : entity work.REG_DCC
        port map (clk100M, reset_n,Trame_DCC,shift,load, msb, end_shift);
    
    clk100M <= not clk100M after 5 ns;
    
    process 
    begin 
    reset_n <= '0'; wait for 50 ns;
    reset_n <= '1'; wait for 500 ns;
    
    --Trame_DCC <= "111111111111110000000010111100000000011110101010101"; wait for 10 ns;
    Trame_DCC <= (others=> '1'); wait for 15 ns;
    
    load <= '1'; wait for 10 ns;
    load <= '0'; wait for 100 ns;
    
    shift <= '1'; wait for 600 ns;
    shift <= '0'; wait for 100 ns;
       
    end process;
 
end testbench;
