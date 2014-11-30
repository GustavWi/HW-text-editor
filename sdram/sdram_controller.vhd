library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.funcs_sdram.ALL;
use work.sdram_params.ALL;
use work.types_vhdl.ALL;
entity sdram_controller is
  port( -----User side------------------------------------------------
          clk_200Mhz : in std_logic; --input generated from pll in altera
          full_address : in vec_ASIZE; -- 25 address of a 64Mb memory
          data_in : in vec_D;
          read_en : in std_logic;
          write_en : in std_logic;
          cmd_ack : out std_logic;
          output_en : out std_logic;
          data_out : out vec_D;
          ready_for_cmd : out std_logic;
          address_data_out : out vec_ASIZE;          
          ------------------------------------
          rst : in std_logic;
          ---SDRAM SIDE---------------------------
          CLK : out std_logic; --System Clock Input 200 Mhz
          CKE : out std_logic; --Clock Enable
          Address : out vec_A; --Address out, A0-A12 row address, A0-A9 column address
          BA      : out vec2;-- Bank select address
          DQ      :  inout vec_D;--Data I/O
          CS : out std_logic;  --Chip Select
          DQML : out std_logic; --I/O controll LowByte
          DQMH : out std_logic; --I/O controll HighByte
          CMD : out vec3 --CMD(0) WE, CMD(1) CAS, CMD(2) RAS 
          --RAS out : std_logic; --command pin
          --WE out : std_logic;  -- command pin
          --CAS out : std_logic; --command pin
        );
          
end sdram_controller;

architecture RTL of sdram_controller is

  signal timer_init  : integer range 0 to t_WAIT_INIT + t_EXTRA_INIT + t_SETUP_INIT:= 0;
  signal INI_DONE : std_logic := '0';
  signal SET_MODE_INI : std_logic := '0';
  signal PRE_ALL_INI : std_logic := '0';
  
  signal exe_state : integer range 0 to EXE_STATES_MAX := idle_state;
  signal next_state : integer range 0 to EXE_STATES_MAX;
  
  signal command_delay : vec10 := (others => '1'); --1111111111  Cycles 
  signal read_8_count : std_logic_vector(7 downto 0) := (others => '1');
  signal refresh_counter : integer range 0 to 1600 := 0;
  signal cas_delay  : vec3 := (others => '1');
  -------------------------------------------------
  -------------------Internal outputs--------------
  signal int_CLK : std_logic;
  signal int_CKE: std_logic;
  signal int_Address: vec_A;
  signal int_BA: vec2;
  signal int_DQ: vec_D;
  signal int_CS: std_logic;
  signal int_DQM: vec2;
  signal int_CMD: vec3 := t_NOP;
  signal int_DQ_in : vec_D; -- Used for reading the output from sdram
  signal int_DQ_out : vec_D; -- Used for writing data on the DQ line of the sdram
  signal DQ_set : std_logic; -- High Z during initialization bidirectional bus 0 means that the controller drives the wire, 1 means that the sdram drives the wire
  signal set_address_usr : vec_A;
  signal select_bank : vec2;
  signal int_output_en : std_logic := '0';
  signal int_ready_for_cmd : std_logic;
  ----------------------------------------------------------------
  ---------------Internal outputs for initialization--------------
  signal INI_CMD : vec3;
  signal SET_MODE_Init : std_logic;    
  ----------------------------------------------------------------
  signal write_data : vec_D := (others => '0');
  signal tmp_full_address : vec_ASIZE;
  signal int_full_address : vec_ASIZE := (others => '0');
  signal read_cmd : std_logic; --if true the current cmd is a read cmd else a write cmd
  signal banks_activated : std_logic_vector(BANKS_NUMBER -1 downto 0) := "0000";-- banks being activated
  signal bank_active_rows : rows;-- (others =>(others=>'0'));
  signal output_delay : vec12 := (others => '0');
  begin  
  -----------Internal signals---------
  int_CLK <= clk_200Mhz;
  int_CS <= '0';
  ------------------------------------
  ----------Output signals------------
  CLK <= int_CLK;
  CKE <= int_CKE;
  CMD <= int_CMD when INI_DONE = '1' else INI_CMD;
  CS  <= int_CS;
  DQML <= int_DQM(0);
  DQMH <= int_DQM(1);
  Address  <= int_Address;
  BA <= int_BA;
  data_out <= int_DQ_in;
  int_DQ_in <= DQ;
  DQ <= int_DQ_out when DQ_set = '0' else (others => 'Z');
  ready_for_cmd <= int_ready_for_cmd;
  output_en <= int_output_en;
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  DQ_set <= '0' when exe_state = write_state else '1';
  int_DQ_out <= write_data;
  int_DQM <= "00" when (exe_state = read_state
  or exe_state = write_state) else "11";
  
  int_CKE <= '0' when rst = '0' else '1';
  
  int_BA <= select_bank when (exe_state = precharge_state
  or exe_state = row_act
  or exe_state = read_state
  or exe_state = write_state) else "00";      
  
  process(rst, int_CLK)
    begin
    if rst = '0' then
      cas_delay <= (others => '1');
    elsif rising_edge(int_CLK) then
      if exe_state = cas_delay_state then
        cas_delay <= right_shift(cas_delay);
      else 
        cas_delay <= (others => '1');
      end if;
    end if;
  end process;
  
  process(exe_state, INI_DONE,command_delay,refresh_counter, next_state)
    begin
    if INI_DONE = '0' or refresh_counter > refresh_intervall then
      int_ready_for_cmd <= '0';
    else 
      case exe_state is
        when write_state => int_ready_for_cmd <= '1';
        when cmd_delay_state =>
          if command_delay(1) = '0' and next_state = idle_state then
            int_ready_for_cmd <= '1';
          else
            int_ready_for_cmd <= '0';
          end if;
        when idle_state => int_ready_for_cmd <= '1';
        when others => int_ready_for_cmd <= '0';
      end case;
    end if;
  end process;
  
  process(read_8_count)
    variable tmp : vec3;
    begin
    tmp := (others => '0');
    for I in read_8_count'high downto 0 loop
      if read_8_count(I) = '0' then
        tmp := std_logic_vector(unsigned(tmp) + 1);
      end if;
    end loop;
    address_data_out <= int_full_address(int_full_address'high downto tmp'high+1) & tmp;
    -- if exe_state = read_state then
      -- address_data_out <= int_full_address(int_full_address'high downto tmp'high+1) & tmp;
    -- else
      -- address_data_out <= (others => '0');
    -- end if;
  end process;
  
  process(exe_state, rst, next_state,INI_DONE, SET_MODE_INI, PRE_ALL_INI)
    begin
    if rst = '0' or INI_DONE = '0' then
      int_Address <= (others => '0');
    else
      case exe_state is
        when row_act =>         int_Address <= set_address_usr;
        when read_state =>      int_Address <= set_address_usr;
        when write_state =>     int_Address <= set_address_usr;
        when set_mode =>        int_Address <= exe_mode;
        when precharge_state =>
          if next_state = auto_refresh then
            int_Address <= (others => '1'); 
          else
            int_Address <= (others =>'0');
          end if;
        when idle_state =>
          if SET_MODE_INI = '1' then
            int_Address <= exe_mode;
          elsif PRE_ALL_INI = '1' then
            int_Address <= (others => '1');
          else
            int_Address <= (others => '0');
          end if;
        when others =>          int_Address <= (others =>'0');
      end case;
    end if;
  end process;
    
  process(exe_state, rst)
    begin
    if rst = '0' then
      banks_activated <= (others => '0');
    else
      case exe_state is
        when row_act => banks_activated <= banks_activated or bank_pin(select_bank); 
        when precharge_state => 
          if next_state = auto_refresh then
            banks_activated <= (others => '0');
          else
            banks_activated <= banks_activated xor bank_pin(select_bank);
          end if;
        when others => banks_activated <= banks_activated;
      end case;
    end if;
  end process;

  --New read output
  int_output_en <= output_delay(0);
  
  process(int_CLK,rst, INI_DONE)
  begin
    if rst = '0' or INI_DONE = '0' then
      refresh_counter <= 0;
    elsif rising_edge(int_CLK) then
      if exe_state = auto_refresh then
        refresh_counter <= 0;
      else
        refresh_counter <= refresh_counter + 1;
      end if;
    end if;
  end process;
  
  process(int_CLK, rst)
  begin
    if rst = '0' then
      output_delay <= (others=>'0');
    elsif rising_edge(int_CLK) then
      if exe_state = read_state then
        output_delay <= output_sequence;
      else
        output_delay <= right_shift(output_delay);
      end if;
    end if;
  end process;
  
  process(exe_state, rst)
    begin      
    case exe_state is
      when idle_state =>      int_CMD <= t_NOP;
      when precharge_state => int_CMD <= t_PRE;
      when auto_refresh =>    int_CMD <= t_REF;
      when set_mode =>        int_CMD <= t_MRS;
      when row_act =>         int_CMD <= t_ACT;
      when read_state =>      int_CMD <= t_READ;
      when write_state =>     int_CMD <= t_WRITE;
      when cmd_delay_state => int_CMD <= t_NOP;
      when cas_delay_state => int_CMD <= t_NOP;
      when others =>          int_CMD <= t_NOP;
    end case;
  end process;
  
  process(exe_state)
    begin
      if exe_state = row_act then
        bank_active_rows(get_bank_index(select_bank)) <= get_row_address(int_full_address);
      end if;
  end process;
  
  process(int_CLK, rst)
    begin
    if rst = '0' then
      int_full_address <= (others => '0');
      write_data <= (others => '0');
    elsif rising_edge(int_CLK) then
      if exe_state = idle_state or exe_state = write_state or next_state = idle_state then
        if read_en = '1' then
          int_full_address <= get_8_aligned(full_address);
        else
          int_full_address <= full_address;
        end if;
        write_data <= data_in;
      end if;
    end if;
  end process;
 
  select_bank <= get_bank(int_full_address); --when exe_state = idle_state else select_bank;
  set_address_usr <= get_row_address(int_full_address) when exe_state = row_act else
  set_column_def(int_full_address) when exe_state = read_state or exe_state = write_state else
  (others => '0');
  --write_data <= data_in when exe_state = idle_state else write_data;
  read_cmd <= read_en when int_ready_for_cmd = '1' else read_cmd;
  cmd_ack <= '0' when exe_state = idle_state else '1';
  --cmd delay
  process(int_CLK, rst)
    begin
    if rst = '0' then 
      command_delay <= (others => '1');
    elsif rising_edge(int_CLK) then
      case exe_state is
        when precharge_state => command_delay <= PRECHARGE_LATENCY;
        when auto_refresh =>    command_delay <= AUTO_REFRESH_DELAY;
        when set_mode =>        command_delay <= SET_MODE_DELAY;
        when row_act =>         command_delay <= ACT_LATENCY;
        when read_state =>      command_delay <= CAS_LATENCY;
        when cas_delay_state => command_delay <= NUM_OF_READS;
        when cmd_delay_state => command_delay <= right_shift(command_delay);
        when others =>          command_delay <= (others => '1');
      end case;
    end if;
  end process;
  
  process(int_CLK, rst)
    begin
    if rst = '1' then
      read_8_count <= (others => '1');
    elsif rising_edge(int_CLK) then
      case exe_state is
        when read_state =>      read_8_count <= (others => '1');
        when cas_delay_state => read_8_count <= (others => '1');
        when cmd_delay_state => read_8_count <= right_shift(read_8_count);
        when others =>      read_8_count <= (others => '1');
      end case;
    end if;
  end process;
  
  process(int_CLK, rst, INI_DONE)
    begin
    if (rst = '0' or INI_DONE = '0') then
      exe_state <= idle_state;
      next_state <= idle_state;
    elsif rising_edge(int_CLK) then
      case exe_state is
        when idle_state => --load in next cmd
          next_instruction(refresh_counter,
                          read_en, write_en,
                          full_address, banks_activated,
                          bank_active_rows,
                          exe_state, next_state);    
        when precharge_state =>
          exe_state <= cmd_delay_state;
          next_state <= next_state;
        when auto_refresh =>  
          exe_state <= cmd_delay_state;
          next_state <= idle_state;
        when set_mode =>
          exe_state <= cmd_delay_state;
          next_state <= idle_state;
        when row_act =>
          exe_state <= cmd_delay_state;
          next_state <= next_state;
        when read_state =>
          exe_state <= cas_delay_state;
          next_state <= idle_state;
          -- if read_8_count(1) = '1' then 
            -- exe_state <= read_state;
            -- next_state <= read_state;
          -- else -- only one read left
            -- exe_state <= cmd_delay_state;
            -- next_state <= idle_state;
          -- end if;
        when cas_delay_state =>
          if cas_delay(2) = '0' then
            exe_state <= cmd_delay_state;
          else
            exe_state <= cas_delay_state;
          end if;
          next_state <= idle_state;
        when write_state =>
          next_instruction(refresh_counter,
                          read_en, write_en,
                          full_address, banks_activated,
                          bank_active_rows, 
                          exe_state, next_state);
        when cmd_delay_state =>
          if command_delay(1) = '0' then -- next clock cycle the sdram will be ready for a new cmd
            if next_state = idle_state then
              next_instruction(refresh_counter,
                read_en, write_en,
                full_address, banks_activated,
                bank_active_rows,
                exe_state, next_state);
            else
              exe_state <= next_state;
              next_state <= idle_state;
            end if;
          else        
            exe_state <= exe_state;
            next_state <= next_state;
          end if;
        when others =>
          exe_state <= idle_state;
          next_state <= idle_state;
      end case;
    end if;
  end process;

----Initialize-------------------------------------------------------    
  process(int_CLK, rst)
    begin
    if (rst = '0') then
      INI_DONE <= '0';
      INI_CMD <= t_NOP;
      SET_MODE_INI <= '0';
      PRE_ALL_INI <= '0';
      timer_init <= 0;
    elsif rising_edge(int_CLK) then
      if timer_init < t_WAIT_INIT + t_EXTRA_INIT + t_SETUP_INIT then
        timer_init <= timer_init + 1;
        INI_DONE <= '0';
      else
        timer_init <= t_WAIT_INIT + t_EXTRA_INIT + t_SETUP_INIT;
        INI_DONE <= '1';
      end if;
      case timer_init is
        when t_WAIT_INIT + t_EXTRA_INIT =>      INI_CMD <= t_PRE;
        when t_WAIT_INIT + t_EXTRA_INIT + 20 => INI_CMD <= t_REF;
        when t_WAIT_INIT + t_EXTRA_INIT + 40 => INI_CMD <= t_REF;
        when t_WAIT_INIT + t_EXTRA_INIT + 60 => INI_CMD <= t_REF;
        when t_WAIT_INIT + t_EXTRA_INIT + 80 => INI_CMD <= t_REF;
        when t_WAIT_INIT + t_EXTRA_INIT + 100 =>INI_CMD <= t_REF;
        when t_WAIT_INIT + t_EXTRA_INIT + 120 =>INI_CMD <= t_REF;
        when t_WAIT_INIT + t_EXTRA_INIT + 140 =>INI_CMD <= t_REF;
        when t_WAIT_INIT + t_EXTRA_INIT + 160 =>INI_CMD <= t_REF;
        when t_WAIT_INIT + t_EXTRA_INIT + 180 =>INI_CMD <= t_MRS;
        when others =>                          INI_CMD <= t_NOP;
      end case;
      if timer_init = t_WAIT_INIT + t_EXTRA_INIT + 180 then
        SET_MODE_INI <= '1';
      else
        SET_MODE_INI <= '0';
      end if;
      if timer_init = t_WAIT_INIT + t_EXTRA_INIT then
        PRE_ALL_INI <= '1';
      else
        PRE_ALL_INI <= '0';
      end if;
    end if;
  end process;
  
end RTL;

  
  