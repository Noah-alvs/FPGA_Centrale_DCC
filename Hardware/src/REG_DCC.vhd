----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.03.2026 09:07:26
-- Design Name: 
-- Module Name: REG_DCC - Behavioral
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

entity REG_DCC is
    Port (  clk100M : in std_logic;
            reset_n : in std_logic;
            Trame_DCC : in std_logic_vector(50 downto 0);
            shift : in std_logic;
            load : in std_logic;
            msb : out std_logic;
            end_shift : out std_logic
          );
end REG_DCC;

architecture Behavioral of REG_DCC is

--signaux 
signal reg : std_logic_vector(50 downto 0) := (others => '0');
signal cpt : integer range 0 to 50;


begin

process(clk100M, reset_n) 
begin 
    if reset_n = '0' then 
        reg <= (others => '0');
        cpt <= 50;
        
     elsif rising_edge(clk100M) then 
        if load = '1' then
            reg <= Trame_DCC;
            cpt <= 50;
        end if;
        
        if shift = '1' then 
            reg <= reg(49 downto 0) & '0'; --Décalage de 1 bit vers la gauche.
            cpt <= cpt - 1; 
        end if;
        
     end if;
end process; 

msb <= reg(50);
end_shift <= '1' when cpt = 0 else '0';

end Behavioral;
