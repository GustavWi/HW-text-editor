library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.types_vhdl.ALL;
package sdram_params is
--Vector Size-------------------------------------------------------------------------------
  constant ASIZE 		: integer := 25;
  constant DSIZE 		: integer := 16;
  constant ROWSIZE 	: integer := 13;
  constant COLSIZE 	: integer := 10;
  constant BANKSIZE 	: integer := 2;
  constant ROWSTART 	: integer := 10;         -- Starting position of the row address within ADDR   
  constant COLSTART 	: integer := 0;         -- Starting position of the column address within ADDR
  constant BANKSTART 	: integer := 23;		-- Starting position of the bank address within ADDR
  constant BANKS_NUMBER : integer := 4;
  constant NUM_STATES : integer := 15;
  constant A10 : integer := 10;
  
  subtype vec_A is std_logic_vector(ROWSIZE-1 downto 0);
  subtype vec_D is std_logic_vector(DSIZE-1 downto 0);
  subtype vec_ASIZE is std_logic_vector(ASIZE-1 downto 0);
  type rows is array(BANKS_NUMBER-1 downto 0) of vec_A;  
---------------------------------------------------------------------------------------------    
----------------------------------------------------------------------------------------------  
  constant t_NOP : vec3 := "111"; -- 111 No operation
  constant t_BST : vec3 := "110"; -- 110 Burst stop
  constant t_READ : vec3 := "101"; -- 101 Read, with A10 high -> auto precharge
  constant t_WRITE : vec3 := "100"; -- 100 Write, with A10 high -> auto precharge
  constant t_ACT  : vec3 := "011"; -- Bank activate (open row)
  constant t_PRE  : vec3 := "010"; -- precharge select bank , A10 high -> precharge all banks (close row)
  constant t_REF  : vec3 := "001"; -- Auto refresh refreshes a 1/8192 part of the mem (one row) selected by an onship refresh counter
  constant t_MRS  : vec3 := "000"; -- Mode register set BA0-1 set to 0 as well
  --------------INITIALIZE----------------------------
  constant t_WAIT_INIT : integer := 200000; -- 200Mhz cycles to achieve 100 us
  constant t_EXTRA_INIT : integer := 100000; -- 50 us extra
  constant t_SETUP_INIT : integer := 300;

  -----------------EXECUTION-------------------------
  constant output_sequence : vec12 := "011111111000"; --read output
  constant refresh_intervall : integer := 1500; --(64ms/200Mhz)*8192    
  ----------------------------------------------------
  ----------------Execution states-------------------
  constant idle_state : integer := 0;    
  constant precharge_state : integer := 1;
  constant auto_refresh : integer := 2;
  constant set_mode : integer := 3;
  constant new_command : integer := 4;
  constant row_act : integer := 5;
  constant read_state : integer := 6;
  constant write_state : integer := 7;
  constant cmd_delay_state : integer := 8;
  constant cas_delay_state : integer := 9;
  constant EXE_STATES_MAX : integer := 9;
--------------------------------------------------------------------------------------  
  constant full_page : vec3 := "011"; -- 8 burst length bit M0-M2
  constant sequential : std_logic := '0'; --sequential bit M3;
  constant caslatency : vec3 := "011"; -- cas latency bit M4-M6 has to be 3 cycles for 200 Mhz clock
  constant operating_mode : vec2 := "00"; --operating mode all other states are reserved
  constant write_burst_mode : std_logic := '1'; --Single access write mode
  constant reserved_bits : vec3 := "000";
  constant exe_mode : vec_A := reserved_bits & write_burst_mode & operating_mode & caslatency & sequential & full_page;
  -- When a cmd is preformed other than NOP, then exe_state is set to cmd_delay_state and sends NOPs til the command is done.    
  ---------------------------------------------------
  -------------------SDRAM device specifications-----
  --------------------200 Mhz------------------------
  ----------Internal control variables--------------
  --------------------Cycles-------------------------
  constant CAS_LATENCY : vec10 := "0000000111"; --0111
  constant PRECHARGE_LATENCY : vec10 := "0000001111";
  constant SET_MODE_DELAY : vec10 := "0000000111";
  constant AUTO_REFRESH_DELAY : vec10 := "1111111111";
  constant ACT_LATENCY : vec10 := "0000000111"; --0111
  constant NUM_OF_READS : vec10 := "0011111111";
  
end sdram_params;
