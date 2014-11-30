library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.funcs_sdram.ALL;
use work.sdram_params.ALL;
use work.types_vhdl.ALL;

entity sdram_test is
  port(
    clk_200Mhz : in std_logic;
    full_address : out vec_ASIZE;
    data_to_write: out vec_D;
    read_en : out std_logic;
    write_en : out std_logic;
    cmd_ack : in std_logic; -- the sdram controller has accepted the command
    output_en : in std_logic; --sdram has no read data at data_out
    data_in : in vec_D;
    address_in : in vec_ASIZE;
    ready_for_cmd : in std_logic;
    --------------
    rst : in std_logic;
    --------------
    -----Hex out--
    data_0 : out vec4;
    data_1 : out vec4;
    data_2 : out vec4;
    data_3 : out vec4;
    data_4 : out vec4;
    data_5 : out vec4    
    
  );
end sdram_test;

architecture RTL of sdram_test is
  signal int_clk : std_logic;
  signal timer : integer range 0 to 100;
  signal state : integer range 0 to 10 := 0;
  constant address : std_logic_vector(22 downto 0) := (others => '0');
  constant data0 : vec_D := X"ABCD";
  constant data1 : vec_D := X"DEAD";
  constant data2 : vec_D := X"BEEF";
  constant data3 : vec_D := X"8BAD";
  constant addr0 : vec_ASIZE := "00" & address;
  constant addr1 : vec_ASIZE := "01" & address;
  constant addr2 : vec_ASIZE := "10" & address;
  constant addr3 : vec_ASIZE := "11" & address;
  
  signal int_data0_0 : vec8 := (others => '0');
  signal int_data0_1 : vec8 := (others => '0');
  signal int_data1_0 : vec8 := (others => '0');
  signal int_data1_1 : vec8 := (others => '0');
  signal int_data2_0 : vec8 := (others => '0');
  signal int_data2_1 : vec8 := (others => '0');  
   
  
  begin
  data_0 <= int_data0_0(3 downto 0);
  data_1 <= int_data0_0(7 downto 4);
  data_2 <= int_data0_1(3 downto 0);
  data_3 <= int_data0_1(7 downto 4);
  data_4 <= int_data1_0(3 downto 0);
  data_5 <= int_data1_0(7 downto 4);
  
  
  int_clk <= clk_200Mhz;
  
  process(rst, int_clk)
    begin
    if rising_edge(int_clk) then
      if output_en = '1' then
        case address_in is
          when addr0 =>
            int_data0_0 <= data_in(7 downto 0);
            int_data0_1 <= data_in(15 downto 8);
          when addr1 =>
            int_data1_0 <= data_in(7 downto 0);
            int_data1_1 <= data_in(15 downto 8);
          when addr2 =>
            int_data2_0 <= data_in(7 downto 0);
            int_data2_1 <= data_in(15 downto 8);      
          when others => 
        end case;
      end if;
    end if;
  end process;
    
  process(rst, int_clk)
    begin
    if rising_edge(int_clk) then
      if ready_for_cmd = '1' then
        case state is
          when 0 =>
            full_address <= addr0;
            write_en <= '1';
            read_en <= '0';
            data_to_write <= data0;
          when 1 =>
            full_address <= addr1;
            write_en <= '1';
            read_en <= '0';
            data_to_write <= data1;
          when 2 =>
            full_address <= addr2;
            write_en <= '1';
            read_en <= '0';
            data_to_write <= data2;
          when 3 =>
            full_address <= addr3;
            write_en <= '1';
            read_en <= '0';
            data_to_write <= data3;
          when 4 => --read
            full_address <= addr0;
            write_en <= '0';
            read_en <= '1';
            data_to_write <= (others => '0');
          when 5 => --read
            full_address <= addr1;
            write_en <= '0';
            read_en <= '1';
            data_to_write <= (others => '0');
          when 6 => --read
            full_address <= addr2;
            write_en <= '0';
            read_en <= '1';
            data_to_write <= (others => '0');
          when 7 => --read
            full_address <= addr3;
            write_en <= '0';
            read_en <= '1';
            data_to_write <= (others => '0');
          when others =>
            state <= state;
            full_address <= (others => '0');
            read_en <= '0';
            write_en <= '0';
            data_to_write <= (others => '0');
        end case;
        if state < 10 then
          state <= state + 1;
        end if;
      else
        state <= state;
        full_address <= (others => '0');
        read_en <= '0';
        write_en <= '0';
        data_to_write <= (others => '0');
      end if;
    end if;
  end process;
  
end RTL;