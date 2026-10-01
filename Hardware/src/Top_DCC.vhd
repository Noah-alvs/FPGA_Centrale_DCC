----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.03.2026 11:15:41
-- Design Name: 
-- Module Name: Top_DCC - Behavioral
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

entity Top_DCC is
  Port ( 
        clk100M : in std_logic;
        reset_n : in std_logic; 
        Trame_DCC : in std_logic_vector(50 downto 0);
        Sortie_DCC : out std_logic
        );
end Top_DCC;

architecture Behavioral of Top_DCC is

signal clk1M : std_logic := '0';

signal start_tempo : std_logic := '0';
signal fin_tempo : std_logic := '0';

signal go_1 : std_logic := '0';
signal go_0 : std_logic := '0';
signal fin_1 : std_logic := '0';
signal fin_0 : std_logic := '0';
signal dcc_1 : std_logic := '0';
signal dcc_0 : std_logic := '0';

signal load : std_logic := '0';
signal shift : std_logic := '0';
signal msb : std_logic := '0';
signal end_shift : std_logic := '0';

begin

CLK_DIV : entity work.CLK_DIV
         port map(reset_n, clk100M, clk1M);

REGISTRE_DCC : entity work.REG_DCC
        port map(clk100M, reset_n, Trame_DCC, shift, load, msb, end_shift);

TEMPO : entity work.COMPTEUR_TEMPO
        port map(clk100M, reset_n, clk1M, start_tempo, fin_tempo);

DCC_BIT_0 : entity work.DCC_bit_0
        port map(clk100M, clk1M, reset_n, go_0, fin_0, dcc_0);
        
DCC_BIT_1 : entity work.DCC_bit_1
        port map(clk100M, clk1M, reset_n, go_1, fin_1, dcc_1);
         
MAE_DCC : entity work.MAE_DCC
        port map(clk100M, reset_n, fin_tempo, fin_0, fin_1, msb, end_shift, go_0, go_1, start_tempo, load, shift);
        
Sortie_DCC <= dcc_0 or dcc_1;

end Behavioral;
