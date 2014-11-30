library IEEE;
library funcs;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.ALL;
use work.mylib.ALL;
use work.funcs.ALL;

entity VGA_discovery is
  Port(clk_in : in std_logic;
        red  :  out std_logic_vector(7 downto 0);
        green  :  out std_logic_vector(7 downto 0);
        blue  :  out std_logic_vector(7 downto 0);
        HS  :  out std_logic;
        VS  :  out std_logic;
        out_vga_sync  :  out std_logic;
        out_vga_blank  :  out std_logic;
        out_vga_clk  : out std_logic);
end entity;

architecture VGA of VGA_discovery is
  subtype vector8 is std_logic_vector(7 downto 0);
  subtype vector10 is std_logic_vector(9 downto 0);
------------internal 25Mhz clock--------------------------------
signal int_clock : std_logic := '0';
-----------------------------------------------------------------
--	Horizontal	Parameter
constant	H_FRONT : integer :=	16; --16
constant	H_SYNC	: integer :=	96;
constant	H_BACK	: integer :=	48; --48
constant	H_ACT	: integer :=	640;
constant	H_BLANK	: integer :=	H_FRONT+H_SYNC+H_BACK;
constant	H_TOTAL	: integer :=	H_FRONT+H_SYNC+H_BACK+H_ACT;
------------------------------------------------------------------
--	Vertical constant
constant	V_FRONT	: integer :=	11;--11
constant	V_SYNC	: integer :=	2;
constant	V_BACK	: integer :=	31;--31
constant	V_ACT		: integer :=	480;
constant	V_BLANK	: integer :=	V_FRONT+V_SYNC+V_BACK;
constant	V_TOTAL	: integer :=	V_FRONT+V_SYNC+V_BACK+V_ACT;
---------------Internal logic---------------------------------------
signal h_count : integer range 0 to 800 := 0;
signal v_count : integer range 0 to 524 := 0;
signal video_active : boolean;
------------------------------------------------------------------

signal int_HS : std_logic := '1';
signal int_VS : std_logic := '1';

signal pixel_width : integer range 0 to 7 := 7;
signal int_red : vector8 := (others => '1');
signal int_green : vector8 := (others => '0');
signal int_blue : vector8 := (others => '1');

begin
  --Outputs----------------------------------------------
  red <= int_red; 
  green <= int_green; 
  blue <= int_blue; 
  out_vga_blank <=  bool_to_stdl(not((h_count <= H_BLANK)or(v_count <= V_BLANK)));
  out_vga_clk <= not(int_clock);
  out_vga_sync <= '1';
  ----------------------Internal logic---------------------
  video_active <=  v_count >= V_BLANK and v_count < V_TOTAL;
  
  -------------------------------------------------------
  process(int_clock)
    begin
    if rising_edge(int_clock) then
      if h_count < H_TOTAL then
        h_count <= h_count + 1;
      else
        h_count <= 1;
      end if;
      if h_count = H_FRONT then
        int_HS <= '0';
      end if;
      if h_count = H_FRONT + H_SYNC then
        int_HS <= '1';
      end if;
    end if;
  end process;
  
    
  process(int_HS)
    begin
    if rising_edge(int_HS) then
      if v_count < V_TOTAL then
        v_count <= v_count + 1;
      else
        v_count <= 1;
      end if;
      if v_count = V_FRONT then
        int_VS <= '0';
      elsif v_count = V_FRONT + V_SYNC then
        int_VS <= '1';
      end if;      
    end if;
  end process;

  process(clk_in)
    begin
    if rising_edge(clk_in) then
      int_clock <= not(int_clock);
     end if;	 
  end process;
  
  process(int_HS)
    begin
    if rising_edge(int_HS) and video_active then 
      if pixel_width = 7 then
        pixel_width <= 0;
        int_red <= not(int_red);
        int_green <= not(int_green);
        int_blue <= not(int_blue);
      else
        pixel_width <= pixel_width + 1;
      end if;
    end if;
  end process;	 
--		else
--        pixel_width <= 7;
--		  int_red <= (others => '1');
--		  int_green <= (others => '0');
--  -      int_blue <=(others => '1');
--		end if;
 --   end if;
 -- end process;
  
  process(int_clock)
    begin
    if rising_edge(int_clock) then
	   HS <= int_HS;
      VS <= int_VS;
    end if;
  end process;
  
end VGA;






--entity VGA_discovery is
--  Port(clk_in : in std_logic;
--        set_freq : in std_logic;
--        new_freq : in std_logic_vector(31 downto 0);
--        clk_out : out std_logic);
			
	
--  end;
	
--Architecture VGA_Interface of VGA_discovery is
--  for clock1 : clock	use entity work.clock(rtl);
--  begin 
--    clock1 : clock port map(clk_in, set_freq, new_freq, clk_out);
	
--end VGA_Interface;	