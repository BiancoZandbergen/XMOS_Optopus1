-----------------------------------------------------------------
-- Module: Reset Control
-- Author: Bianco Zandbergen
--
-- Delay and invert the reset signal
--
-- Input Signals:
--      clk         undivided clock (50MHz on DE0)
--      rst         reset active low
--
-- Output Signals:
--      rst_n       reset active high
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity reset_control is
  generic (
    delay  : integer range 0 to 255 := 250
    );
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    rst_n  : out std_logic
    );
end reset_control;

architecture behaviour of reset_control is
  signal counter : unsigned(7 downto 0);
  begin
    rst_process : process (clk, rst, counter)
      begin
        if rising_edge(clk) then
          if (rst = '0') then 
            counter <= (others=>'0');
            rst_n   <= '1';
          else
            if (counter = (delay)) then
              rst_n <= '0';
            else
              counter <= counter+1;
              rst_n <= '1';
            end if;
          end if;
        end if;
      end process;
  end behaviour;
