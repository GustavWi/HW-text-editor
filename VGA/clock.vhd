Library ieee; -- importerar biblioteket
use ieee.std_logic_1164.all; --vilka funktioner i det package som ska användas
use ieee.numeric_std.ALL;

--Need 27 bits for 50 Mhz to 1 second
entity clock is
	port 
	(
      clk_in  : in std_logic;  	-- inputSignals
      set_freq : in std_logic;
      new_freq : in std_logic_vector(31 downto 0);
          
      clk_out	: out std_logic);
			
end entity;

architecture rtl of clock is
  subtype vector is std_logic_vector(31 downto 0);
  constant clk_in_freq  : vector :=  X"02FAF080"; --50Mhz
  
   -- constant identifier : subtype_indication := constant_expression;
  ---------USED FOR STANDARD CLOCK DIVIDER PART-------------------
  signal count : vector:= (others =>'0');
  signal int_clk_out : std_logic := '0';
  signal int_new_freq : vector:= clk_in_freq;
  -----------------decrement operator---------------------------------
  signal dcr: vector := (others =>'0');
  signal tmp_count  : vector  :=  (others =>'0');
  signal int_sub  :  vector  := (others =>'0');
  -----------------
begin
  clk_out <= int_clk_out;
  process(set_freq)
    begin
      if rising_edge(set_freq) then
        int_sub <= vector(signed(new_freq) - signed(clk_in_freq));
        int_new_freq <= new_freq;
      end if;
  end process;   
  
  process(count)
    begin
      if count(31) = '1' then --negative
        dcr <= int_new_freq;
      else
        dcr <= int_sub;
        int_clk_out <= not(int_clk_out);
      end if;
  end process;
  
  tmp_count <= vector(signed(count) + signed(dcr));
  
  process(clk_in)
    begin
      if rising_edge(clk_in) then
        count <= tmp_count;
      end if;
  end process;
  
end rtl;  
  