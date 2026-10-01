----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.03.2026 10:27:00
-- Design Name: 
-- Module Name: MAE_DCC - Behavioral
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

entity MAE_DCC is
    Port ( 
        clk100M : in std_logic;
        reset_n : in std_logic;
        Fin_Tempo : in std_logic;
        fin_0 : in std_logic;
        fin_1 : in std_logic;
        msb : in std_logic;
        end_shift : in std_logic;
        go_0 : out std_logic;
        go_1 : out std_logic;
        Start_Tempo : out std_logic;
        load : out std_logic;
        shift : out std_logic
    );
end MAE_DCC;

architecture Behavioral of MAE_DCC is

-- Etats MAE
type ETAT is (
				INIT,		-- Etat d'Initialisation
				LOAD_DCC,		-- Chargement du registre DCC
				WAIT_LOAD,
				GO_0_L, 	-- GO après le premier load
				GO_1_L,		-- GO après le premier load
				SHIFT_DCC,		 -- Décalage du registre DCC
				WAIT_SHIFT,
				GO_0_S,      -- GO après les shift
				GO_1_S,      -- GO après les shift
				TEMPO       -- Temporisation entre  2 trames
			);

signal EP,EF: ETAT; -- Etat présent/futur de la MAE


begin
-- MACHINE A ETATS
process(clk100M,reset_n)
begin
	if reset_n='0' then EP <= INIT;
	elsif rising_edge(clk100M) then EP <= EF;
	end if;
end process;


process(EP, Fin_Tempo, fin_0, fin_1, msb, end_shift)
begin 
    case(EP) is 
        when INIT => 
            EF <= LOAD_DCC; 
            -- sorties
            go_0 <= '0';
            go_1 <= '0';
            Start_Tempo <= '0';
            load <= '0';
            shift <= '0';
        
        when LOAD_DCC =>
            EF <= WAIT_LOAD;
            -- sorties
            go_0 <= '0';
            go_1 <= '0';
            Start_Tempo <= '0';
            load <= '1';
            shift <= '0';
            
        when WAIT_LOAD =>
            EF <= GO_0_L;
            if msb = '1' then 
                EF <= GO_1_L;
            end if;
            -- sorties
            go_0 <= '0';
            go_1 <= '0';
            Start_Tempo <= '0';
            load <= '0';
            shift <= '0';
            
        when GO_0_L =>
            EF <= GO_0_L;
            if fin_0 = '1' then 
                EF <= SHIFT_DCC;
            end if;
            -- sorties
            go_0 <= '1';
            go_1 <= '0';
            Start_Tempo <= '0';
            load <= '0';
            shift <= '0';
        
        when GO_1_L =>
            EF <= GO_1_L;
            if fin_1 = '1' then 
                EF <= SHIFT_DCC;
            end if;
            -- sorties
            go_0 <= '0';
            go_1 <= '1';
            Start_Tempo <= '0';
            load <= '0';
            shift <= '0';
            
        when SHIFT_DCC =>
            EF <= WAIT_SHIFT;
            -- sorties
            go_0 <= '0';
            go_1 <= '0';
            Start_Tempo <= '0';
            load <= '0';
            shift <= '1';
            
        when WAIT_SHIFT =>
            EF <= GO_0_S;
            if msb = '1' then 
                EF <= GO_1_S;
            end if;
            -- sorties
            go_0 <= '0';
            go_1 <= '0';
            Start_Tempo <= '0';
            load <= '0';
            shift <= '0';
            
        when GO_0_S =>
            EF <= GO_0_S;
            if end_shift = '0' and fin_0 = '1' then 
                EF <= SHIFT_DCC;
            elsif end_shift = '1' and fin_0 = '1' then 
                EF <= TEMPO;
            end if;
            -- sorties
            go_0 <= '1';
            go_1 <= '0';
            Start_Tempo <= '0';
            load <= '0';
            shift <= '0';
            
        when GO_1_S =>
            EF <= GO_1_S;
            if end_shift = '0' and fin_1 = '1' then 
                EF <= SHIFT_DCC;
            elsif end_shift = '1' and fin_1 = '1' then 
                EF <= TEMPO;
            end if;
            -- sorties
            go_0 <= '0';
            go_1 <= '1';
            Start_Tempo <= '0';
            load <= '0';
            shift <= '0';
            
        when TEMPO =>
            EF <= TEMPO;
            if Fin_Tempo = '1' then 
                EF <= LOAD_DCC;
            end if;
            -- sorties
            go_0 <= '0';
            go_1 <= '0';
            Start_Tempo <= '1';
            load <= '0';
            shift <= '0';
     end case;
end process;
            
end Behavioral;


