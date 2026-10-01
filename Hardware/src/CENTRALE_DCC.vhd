library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CENTRALE_DCC is 
    port(
            clk100M: in std_logic;
            reset_n: in std_logic;
            Sortie_DCC: out std_logic
        );
 end CENTRALE_DCC;

architecture archi of CENTRALE_DCC is
begin
-- recevoir la trame qui provient du bus AXI et la pr�senter au reg DCC
end archi;

-- Faire la suite du TP3 pour finir l'int�gration de l'IP
