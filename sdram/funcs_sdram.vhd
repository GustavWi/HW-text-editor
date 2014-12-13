library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;
use work.sdram_params.ALL;
use work.types_vhdl.ALL;
package funcs_sdram is
  
  function get_row_address(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector;
  function get_bank(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector;
  function get_bank_index(bank_bin : in std_logic_vector(BANKSIZE-1 downto 0))
    return integer;
  function get_bank_as_int(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return integer;
  function bank_pin(bank_bin : in std_logic_vector(BANKSIZE-1 downto 0))
    return std_logic_vector;
  function set_column_def(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector;
  function get_8_aligned(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector;
  function right_shift(register_t : in std_logic_vector)
    return std_logic_vector;
  procedure next_instruction (signal refresh_counter : in  integer;
                            signal read_en, write_en : in std_logic;
                            signal full_address, banks_activated : in std_logic_vector;
                            signal bank_active_rows : in rows;
                            signal exe_state, next_state : out integer);
end funcs_sdram;

package body funcs_sdram is
  
  function get_row_address(full_address : in vec_ASIZE)
    return std_logic_vector is
  begin
    return full_address(ROWSIZE + ROWSTART -1 downto ROWSTART);
  end get_row_address;
  
  function get_bank(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector is
  begin
    return full_address(BANKSIZE + BANKSTART -1 downto BANKSTART);
  end get_bank;

  function get_bank_index(bank_bin : in std_logic_vector(BANKSIZE-1 downto 0))
    return integer is
  begin
    return to_integer(unsigned(bank_bin));
  end get_bank_index;
  
  function get_bank_as_int(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return integer is
  begin
    return get_bank_index(get_bank(full_address));
  end get_bank_as_int;

  function bank_pin(bank_bin : in std_logic_vector(BANKSIZE-1 downto 0))
    return std_logic_vector is
  begin
    case bank_bin is
      when "00" => return "0001";
      when "01" => return "0010";
      when "10" => return "0100";
      when "11" => return "1000";
    when others => return "1111";
    end case;
  end bank_pin;
  
  function set_column_def(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector is
  begin
    -- address_out(A10-1 downto 0) <= full_address(COLSIZE + COLSTART -2 downto COLSTART);
    -- address_out(A10) <= '0';
    -- address_out(COLSIZE downto A10+1) <= full_address(COLSIZE + COLSTART -1);
    return "000" & full_address(COLSIZE + COLSTART -1 downto COLSTART);
  end set_column_def;
  
  function get_8_aligned(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector is
  begin
    -- address_out(ASIZE-1 downto 3) <= full_address(ASIZE-1 downto 3);
    -- address_out(2 downto 0) <= (others => '0');
    return full_address(ASIZE-1 downto 3) & "000";
  end get_8_aligned;
  
  function right_shift(register_t : in std_logic_vector)
    return std_logic_vector is
  begin
    return '0' & register_t(register_t'high downto register_t'low +1); 
  end right_shift;  
  

procedure next_instruction (signal refresh_counter : in  integer range 0 to 1600;
                            signal read_en, write_en : in std_logic;
                            signal full_address, banks_activated : in std_logic_vector;
                            signal bank_active_rows : in rows;
                            signal exe_state, next_state : out integer range 0 to EXE_STATES_MAX) is
  begin
  if refresh_counter > refresh_intervall then
    exe_state <= precharge_state;
    next_state <= auto_refresh;
  elsif (read_en = '1' or write_en = '1') then
    if banks_activated(get_bank_index(get_bank(full_address))) = '1' then
      if bank_active_rows(get_bank_index(get_bank(full_address))) = get_row_address(full_address) then
        if read_en = '1' then                 
          exe_state <= read_state;
          next_state <= read_state;
        else
          exe_state <= write_state;
          next_state <= idle_state;          
        end if;
      else
        exe_state <= precharge_state;
        next_state <= row_act;
      end if;
    else
      exe_state <= row_act;
      if read_en = '1' then
        next_state <= read_state;
      else
        next_state <= write_state;
      end if;
    end if;
  else
    exe_state <= idle_state;
    next_state <= idle_state;
  end if;
end procedure next_instruction;

  
end funcs_sdram;  





	