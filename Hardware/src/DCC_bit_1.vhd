----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 10:30:40
-- Design Name: 
-- Module Name: DCC_bit_1 - Behavioral
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

entity DCC_bit_1 is
    Port (  clk100M : in std_logic;
            clk1M : in std_logic;
            reset_n : in std_logic;
            go_1 : in std_logic;
            fin_1 : out std_logic;
            dcc_1 : out std_logic
          );
end DCC_bit_1;

architecture Behavioral of DCC_bit_1 is

-- Etats MAE
type ETAT is (
				INIT,		-- Etat d'Initialisation
				IMP_0,		-- Impulsion 0
				TRANSI, 	-- Transition entre impulsion 0 et impulsion 1
				IMP_1,		-- Impulsion 1
				FIN		    -- signal de fin 
			);

signal EP,EF: ETAT; -- Etat présent/futur de la MAE

signal cpt : integer range 0 to 58 := 0;
signal reset_cpt_n : std_logic := '1';
signal timeout : std_logic := '0';
signal start : std_logic := '0';

begin


-- MACHINE A ETATS
process(clk100M, reset_n)
begin
	if reset_n='0' then EP <= INIT;
	elsif rising_edge(clk100M) then EP <= EF;
	end if;
end process;


process(EP,go_1,timeout)
begin 
    case(EP) is 
        when INIT => 
            EF <= INIT; 
            if (go_1 = '1') then EF <= IMP_0; end if;
            -- sorties
            dcc_1 <= '0';
            fin_1 <= '0';
            start <= '0';
            reset_cpt_n <= '1';
    
        when IMP_0 =>
            EF <= IMP_0;
            if(timeout = '1') then EF <= TRANSI; end if;
            -- sorties
            start <= '1';
            dcc_1 <= '0';
            fin_1 <= '0';
            reset_cpt_n <= '1';
            
        when TRANSI => 
            EF <= IMP_1;
            -- sorties
            start <= '0';
            dcc_1 <= '1';
            fin_1 <= '0';
            reset_cpt_n <= '0';
       
        when IMP_1 => 
            EF <= IMP_1;
            if(timeout = '1') then EF <= FIN; end if;
            -- sorties
            start <= '1';
            dcc_1 <= '1';
            fin_1 <= '0';
            reset_cpt_n <= '1';
           
       when FIN => 
            EF <= INIT;
            -- sorties 
            start <= '0';
            dcc_1 <= '0';
            fin_1 <= '1';
            reset_cpt_n <= '0';
    end case;
end process;


process(clk1M, reset_n, reset_cpt_n)
begin 
	if (reset_cpt_n='0' or reset_n='0') then cpt <= 0;
	elsif rising_edge(clk1M) 
	   then if start = '1' then cpt <= cpt + 1;
	   else cpt <= 0;
	   end if; 
	
	end if;
	
end process;

timeout <= '1' when cpt = 58 else '0';  

end Behavioral;
