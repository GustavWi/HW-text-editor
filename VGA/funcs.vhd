library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;
package funcs is
  function bool_to_stdl(value : in boolean)
    return std_logic;
end funcs;

package body funcs is
  function bool_to_stdl(value:in boolean)
    return std_logic is
  begin
    if value then
      return '1';
    else
      return '0';
    end if;
  end bool_to_stdl;
end funcs;  
	