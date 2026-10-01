
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_DCC_TB is
end Top_DCC_TB;

architecture testbench of Top_DCC_TB is

    signal clk100M      : std_logic := '0';
    signal reset_n      : std_logic := '1';
    signal Interrupteur : std_logic_vector(7 downto 0) := (others => '0');
    signal Sortie_DCC   : std_logic;

    signal sim_done       : boolean := false;
    constant PERIODE_100M : time := 10 ns;
    
    signal Trame_Attendue : std_logic_vector(50 downto 0) := (others => '0');
    
    -- signal pour passer au test suivant
    signal frame_match    : std_logic := '0';

begin

    UUT : entity work.Top_DCC
        port map (
            clk100M      => clk100M,
            reset_n      => reset_n,
            Interrupteur => Interrupteur,
            Sortie_DCC   => Sortie_DCC
        );

    -- clk
    clk_process : process
    begin
        while not sim_done loop
            clk100M <= '0';
            wait for PERIODE_100M / 2;
            clk100M <= '1';
            wait for PERIODE_100M / 2;
        end loop;
        wait;
    end process;

    -- stimulis
    stim_process : process
    begin
        reset_n <= '0';
        wait for 10 us;
        reset_n <= '1';
        wait for 10 us;

        -- TEST 1 : Arrêt du train
        report "=== TEST 1 : Interrupteurs a 0 (Arret) ===";
        Interrupteur   <= "00000000";
        Trame_Attendue <= (22 downto 0 => '1') & '0' & "00000001" & '0' & "01100000" & '0' & "01100001" & '1';
        wait until frame_match = '1'; -- On attend que le décodeur valide
        wait for 2 ms; -- Petite marge visuelle avant de passer au test suivant

        -- TEST 2 : Marche avant
        report "=== TEST 2 : Interrupteur 7 a 1 (Marche avant) ===";
        Interrupteur   <= "10000000";
        Trame_Attendue <= (22 downto 0 => '1') & '0' & "00000001" & '0' & "01100010" & '0' & "01100011" & '1';
        wait until frame_match = '1';
        wait for 2 ms;

        -- TEST 3 : Phares
        report "=== TEST 3 : Interrupteur 5 a 1 (Phares) ===";
        Interrupteur   <= "00100000";
        Trame_Attendue <= (22 downto 0 => '1') & '0' & "00000001" & '0' & "10010000" & '0' & "10010001" & '1';
        wait until frame_match = '1';
        wait for 2 ms;

        report "=== FIN DES TESTS SYSTEME : TOUTES LES TRAMES SONT VALIDEES ===";
        sim_done <= true;
        wait;
    end process;

    -- decodeur DCC
    decoder_process : process
        variable t_rise      : time;
        variable pulse_width : time;
        variable frame_reg   : std_logic_vector(50 downto 0);
        variable bit_count   : integer := 50;
    begin
        wait until reset_n = '1';

        while not sim_done loop
            
            -- mesure de la longeur de l'impulsion -> déduction du bit
            wait until Sortie_DCC = '1' or sim_done;
            if sim_done then exit; end if;
            t_rise := now;

            wait until Sortie_DCC = '0' or sim_done;
            if sim_done then exit; end if;
            pulse_width := now - t_rise;

            -- déduction du bit
            if pulse_width < 75 us then
                frame_reg(bit_count) := '1';
            else
                frame_reg(bit_count) := '0';
            end if;

            -- gestion de fin de trame
            if bit_count = 0 then
                
                if frame_reg = Trame_Attendue then
                    report "TRAME OK";
                    
                    -- on passe au test suivant
                    frame_match <= '1', '0' after 1 ns;
                end if;
                
                -- on reset le compteur de bits
                bit_count := 50; 
            else
                -- on décrémente le compteur de bit
                bit_count := bit_count - 1;
            end if;
            
        end loop;
        wait;
    end process;

end testbench;