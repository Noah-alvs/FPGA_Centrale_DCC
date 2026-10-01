----------------------------------------------------------------------------------
-- Module Name: DCC_bit_0_TB - Behavioral
-- Description: Testbench avec v�rification de marge (100 us) et affichage en ns
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DCC_bit_0_TB is
end DCC_bit_0_TB;

architecture testbench of DCC_bit_0_TB is

    signal clk100M : std_logic := '0';
    signal clk1M   : std_logic := '0';
    signal reset_n : std_logic := '1';
    signal go_0    : std_logic := '0';
    signal fin_0   : std_logic;
    signal dcc_0   : std_logic;

    -- contr�le simu
    signal sim_done : boolean := false;

    -- constantes de temps horloges
    constant PERIODE_100M : time := 10 ns;
    constant PERIODE_1M   : time := 1 us;

begin

    UUT : entity work.DCC_bit_0
        port map (
            clk100M => clk100M,
            clk1M   => clk1M,
            reset_n => reset_n,
            go_0    => go_0,
            fin_0   => fin_0,
            dcc_0   => dcc_0
        );

    -- clk100M
    clk100M_process : process
    begin
        while not sim_done loop
            clk100M <= '0';
            wait for PERIODE_100M / 2;
            clk100M <= '1';
            wait for PERIODE_100M / 2;
        end loop;
        wait;
    end process;

    -- clk 1M
    clk1M_process : process
    begin
        while not sim_done loop
            clk1M <= '0';
            wait for PERIODE_1M / 2;
            clk1M <= '1';
            wait for PERIODE_1M / 2;
        end loop;
        wait;
    end process;

    -- stimulis
    stim_process : process
    begin
        reset_n <= '0';
        wait for 5 us;
        reset_n <= '1';
        wait for 5 us;

        report "=== DEBUT DU TEST : Generation de deux bits '0' consecutifs ===";
        
        wait until rising_edge(clk100M);
        go_0 <= '1';
        wait until rising_edge(clk100M);
        go_0 <= '0';
        
        wait until fin_0 = '1';
        
        wait until rising_edge(clk100M);
        go_0 <= '1';
        wait until rising_edge(clk100M);
        go_0 <= '0';
        
        wait until fin_0 = '1';

        wait for 10 us;
        
        report "=== FIN DE SIMULATION ===";
        sim_done <= true;
        wait;
    end process;

    -- monitoring
    monitor_process : process
        -- Constantes de v�rification pour le bit '0'
        constant DUREE_IDEALE : time := 100 us;
        constant MARGE_ERREUR : time := 1 us; -- marge de tol�rance sur le protocole DCC

        variable t_start_0  : time;
        variable t_start_1  : time;
        variable duration_0 : time;
        variable duration_1 : time;
        variable delta_t    : time;

        variable dur_ns   : integer;
        variable delta_ns : integer;
    begin
        while not sim_done loop
            wait until go_0 = '1';
            
            wait until rising_edge(clk100M);
            t_start_0 := now;

            -- on attend la transi vers high
            wait until dcc_0 = '1';
            duration_0 := now - t_start_0;
            t_start_1 := now;

            -- calcul delta temps
            if duration_0 > DUREE_IDEALE then
                delta_t := duration_0 - DUREE_IDEALE;
            else
                delta_t := DUREE_IDEALE - duration_0;
            end if;

            -- conversion time -> entier en ns
            dur_ns   := duration_0 / 1 ns;
            delta_ns := delta_t / 1 ns;

            -- application de la marge pour prendre la d�cision
            if delta_t <= MARGE_ERREUR then
                report "SUCCES IMP_0 : Duree = " & integer'image(dur_ns) & " ns (Delta: " & integer'image(delta_ns) & " ns)";
            else
                assert false
                report "ERREUR IMP_0 : Mesure = " & integer'image(dur_ns) & " ns. Delta de " & integer'image(delta_ns) & " ns > Marge autorisee !"
                severity error;
            end if;

            -- on attend transi low
            wait until dcc_0 = '0';
            duration_1 := now - t_start_1;

            -- idem, calcul delta
            if duration_1 > DUREE_IDEALE then
                delta_t := duration_1 - DUREE_IDEALE;
            else
                delta_t := DUREE_IDEALE - duration_1;
            end if;

            -- idem
            dur_ns   := duration_1 / 1 ns;
            delta_ns := delta_t / 1 ns;

            -- application de la marge pour prendre la d�cision
            if delta_t <= MARGE_ERREUR then
                report "SUCCES IMP_1 : Duree = " & integer'image(dur_ns) & " ns (Delta: " & integer'image(delta_ns) & " ns)";
            else
                assert false
                report "ERREUR IMP_1 : Mesure = " & integer'image(dur_ns) & " ns. Delta de " & integer'image(delta_ns) & " ns > Marge autorisee !"
                severity error;
            end if;
            
        end loop;
        wait;
    end process;

end testbench;
