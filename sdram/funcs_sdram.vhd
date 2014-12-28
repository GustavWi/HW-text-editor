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
  function get_column(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector;
  function get_8_aligned(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector;
  function right_shift(register_t : in std_logic_vector)
    return std_logic_vector;
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
  
  function get_column(full_address : in std_logic_vector(ASIZE-1 downto 0))
    return std_logic_vector is
  begin
    -- address_out(A10-1 downto 0) <= full_address(COLSIZE + COLSTART -2 downto COLSTART);
    -- address_out(A10) <= '0';
    -- address_out(COLSIZE downto A10+1) <= full_address(COLSIZE + COLSTART -1);
    return "000" & full_address(COLSIZE + COLSTART -1 downto COLSTART);
  end get_column;
  
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

  
end funcs_sdram;  





	