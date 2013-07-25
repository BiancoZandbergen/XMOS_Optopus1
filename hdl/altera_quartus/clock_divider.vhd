-----------------------------------------------------------------
-- Module: Clock Divider
-- Author: Bianco Zandbergen
--
-- Input Signals:
--      clk         undivided clock (50MHz on DE0)
--      rst         reset active high
--
-- Output Signals:
--      clk_en      divided clock
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity clock_divider is
  generic (
    div    : integer range 0 to 31 := 10
    );
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    clk_en : out std_logic
    );
end clock_divider;

architecture behaviour of clock_divider is
  signal counter : unsigned(4 downto 0);
  begin
    Clk_process : process (clk, rst, counter)
      begin
        if rising_edge(clk) then
          if (rst = '1') then 
            counter <= (others=>'0');
            clk_en  <= '0';
          else
            if (counter = (div-1)) then
              clk_en <= '1';
              counter <= (others=>'0');
            else
              clk_en <= '0';
              counter <= counter+1;
            end if;
          end if;
        end if;
        end process;
  end behaviour;
