--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	component thunderbird_fsm is 
	  port(
		 i_clk, i_reset  : in    std_logic;
            i_left, i_right : in    std_logic;
            o_lights_L      : out    std_logic_vector(2 downto 0); --RA(LSB)
            o_lights_R      : out    std_logic_vector(2 downto 0)
	  );
	end component thunderbird_fsm;

	--Inputs
    signal w_left : std_logic := '0';
    signal w_right : std_logic := '0';
    signal w_reset : std_logic := '0';
    signal w_clk : std_logic := '0';
    
    --Outputs -prob gonna have to change
    signal w_lights_L : std_logic_vector(2 downto 0) := "000";
    signal w_lights_R : std_logic_vector(2 downto 0) := "000";
    
	-- constants - clock period
	constant k_clk_period : time := 10 ns;
	--is off/on a constant??
	
begin
	-- PORT MAPS ----------------------------------------
	-- Instantiate the Unit Under Test (UUT)
       uut: thunderbird_fsm port map (
              i_reset => w_reset,
              i_clk => w_clk,
              i_left => w_left,
              i_right => w_right,
              o_lights_L => w_lights_L, 
              o_lights_R => w_lights_R
            );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc : process
        begin
            w_clk <= '0';
            wait for k_clk_period/2;
            w_clk <= '1';
            wait for k_clk_period/2;
        end process;
        
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	-- Simulation process
        -- Use 220 ns for simulation
        sim_proc: process
        begin       
            w_reset <= '1'; wait for k_clk_period*1;
              assert w_lights_L = "000" report "bad reset" severity failure;
              assert w_lights_R = "000" report "bad reset" severity failure;
            w_reset <= '0'; wait for k_clk_period*1;
              
            --hazards
            w_right <= '1'; w_left <= '1'; wait for k_clk_period;
               assert w_lights_L = "111" report "hazards - all Ls should be lit" severity failure;
               assert w_lights_R = "111" report "hazards - all Rs should be lit" severity failure;
            wait for k_clk_period;
               assert w_lights_L = "000" report "hazards - L lights should be off" severity failure;
               assert w_lights_R = "000" report "hazards - R lights should be off" severity failure;
                  
            --off
            w_right <= '0'; w_left <= '0'; wait for k_clk_period;
               assert w_lights_L = "000" report "L lights should be off when neither blinker is on" severity failure;
               assert w_lights_R = "000" report "R lights should be off when neither blinker is on" severity failure;
                             
            -- right turn signal
            w_right <= '1'; wait for k_clk_period;
                assert w_lights_R = "001" report "only RA should be lit" severity failure;
                assert w_lights_L = "000" report "L lights should be off" severity failure;
            wait for k_clk_period * 1; -- next light 
                assert w_lights_R = "011" report "RA&B should be lit" severity failure;
                assert w_lights_L = "000" report "L lights should be off" severity failure;
            wait for k_clk_period * 1; -- next light
                assert w_lights_R = "111" report "all Rs should be lit" severity failure;
                assert w_lights_L = "000" report "L lights should be off" severity failure;
            wait for k_clk_period * 1; -- auto reset
                assert w_lights_R = "000" report "should reset after cycling thru" severity failure;
                assert w_lights_L = "000" report "L lights should be off" severity failure;
            wait for k_clk_period;  --next light
                assert w_lights_R = "001" report "didn't repeat cycle(R turn signal still on)" severity failure;
                assert w_lights_L = "000" report "L lights should be off" severity failure;
            w_right <= '0'; wait for k_clk_period * 1; -- next light even tho turn signal off
                assert w_lights_R = "011" report "cycle stopped when turn signal turned off" severity failure;
                assert w_lights_L = "000" report "L lights should be off" severity failure;
                                      
            -- reset & left turn signal
            w_reset <= '1'; wait for k_clk_period;
                assert w_lights_L = "000" report "bad reset" severity failure;
                assert w_lights_L = "000" report "bad reset" severity failure;
            w_reset <= '0'; w_left <= '1'; wait for k_clk_period*1;           
                assert w_lights_L = "001" report "only LA should be lit" severity failure;
                assert w_lights_R = "000" report "R lights should be off" severity failure;
            wait for k_clk_period * 1; -- next light
                assert w_lights_L = "011" report "LA&B should be lit" severity failure;
                assert w_lights_R = "000" report "R lights should be off" severity failure;
            wait for k_clk_period * 1; -- next light
                assert w_lights_L = "111" report "all Ls should be lit" severity failure;
                assert w_lights_R = "000" report "R lights should be off" severity failure;
            wait for k_clk_period * 1; -- auto reset
                assert w_lights_L = "000" report "should reset after cycling thru" severity failure;
                assert w_lights_R = "000" report "R lights should be off" severity failure;
            wait for k_clk_period; -- next light
                assert w_lights_L = "001" report "didn't repeat cycle(L turn signal still on)" severity failure;
                assert w_lights_R = "000" report "R lights should be off" severity failure;
            w_left <= '0'; wait for k_clk_period * 1; -- next light even tho turn signal off
                assert w_lights_L = "011" report "cycle stopped when turn signal turned off" severity failure;
                assert w_lights_R = "000" report "R lights should be off" severity failure;
                                                  
        wait;
                end process;    
	-----------------------------------------------------	
	
end test_bench;
