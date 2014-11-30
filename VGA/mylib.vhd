Library IEEE;
Use ieee.std_logic_1164.ALL;


package	mylib is

component clock	-- defining the componets portmap
		port( clk_in,set_freq : in	std_logic;
    new_freq : in std_logic_vector(31 downto 0);
    clk_out : out std_logic);
    
end component;

end mylib;
