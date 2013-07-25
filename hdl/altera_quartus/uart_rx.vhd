-----------------------------------------------------------------
-- Module: Serial Receiver
-- Author: Bianco Zandbergen
--
-- Expects the baud rate to be 1/16 of the divided clock frequency
--
-- Input Signals:
--      clk         undivided clock (50MHz on DE0)
--      clk_en      divided clock
--      rst         reset active high
--      rx          serial input
--
-- Output Signals:
--      data        received data
--      data_rd     data ready signal
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity uart_rx is
  generic (
    token_size : integer := 8 -- token size. (data bits only)
    );
  port (
    clk          : in  std_logic;
    clk_en       : in  std_logic;
    rst          : in  std_logic;
    rx           : in  std_logic;
    data         : out std_logic_vector(token_size downto 0);
    data_rd      : out std_logic
    );
  end uart_rx;
  
architecture behaviour of uart_rx is
  signal rx_r        : std_logic;
  signal data_r      : std_logic_vector(token_size downto 0);
  signal data_rd_r   : std_logic;
  signal latch_r     : unsigned(3 downto 0);
  signal state_t     : unsigned(3 downto 0);
  signal delay_t     : unsigned(4 downto 0);

  begin
    -- buffer input
    buf_process : process (clk, clk_en, rst, rx_r, rx)
      begin
        if rising_edge(clk) then
          if (rst = '1') then -- Sync reset
            rx_r  <= '1';
          elsif (clk_en = '1') then -- use clock enable for clk division
            rx_r  <= rx;    -- register the data on the lines for signal integrete
          end if;
        end if;
      end process;
      
      data        <= data_r;
      data_rd     <= data_rd_r; 
                
      -- Main logic
      rx_process : process (clk, clk_en, rst, latch_r, data_r, state_t, rx_r)
        begin
          if rising_edge(clk) then
            if (rst='1') then
              latch_r     <= (others=>'0');
              state_t     <= (others=>'0');
              data_r      <= (others=>'0');
              delay_t     <= (others=>'0');
              data_rd_r   <= '0'; 
            elsif (clk_en = '1') then
              
              if (state_t = 0) then
                if (delay_t  = 0) then
                  if (rx_r = '0') then -- falling edge of start bit
                    delay_t <= delay_t + 1;
                  end if;
                else
                  delay_t <= delay_t + 1;
                end if;
              
                -- center of start bit
                -- reset counter and wait for center of first data bit
                if (delay_t = 7) then
                  delay_t <= (others=>'0');
                  latch_r <=  latch_r + 1;
                  state_t <=  state_t + 1;
                end if;
              else
                -- data bits
                if (delay_t = 15) then
                  
                  if (state_t = 10) then -- center of stop bit
                    state_t <= (others=>'0');
                  else -- center of data bit 
                    if (rx_r = '1') then
                      data_r(token_size downto 0) <= data_r(token_size-1 downto 0) & '1';
                    else
                      data_r(token_size downto 0) <= data_r(token_size-1 downto 0) & '0';
                    end if;
                  
                    latch_r <= latch_r + 1;
                    state_t <= state_t + 1;
                    delay_t  <= (others=>'0');
                  end if;
                else
                  delay_t <= delay_t + 1;           
                end if;      
               
              end if;
              
              if (latch_r = token_size+2) then
                latch_r     <= (others=>'0');
                data_rd_r <= '1'; -- high for one cycle
              else
                data_rd_r <= '0';
              end if;
              
            end if;
          end if;
        end process;
    end behaviour;
