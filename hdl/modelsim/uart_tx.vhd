-----------------------------------------------------------------
-- Module: Serial Transmitter
-- Author: Bianco Zandbergen
--
-- Input Signals:
--      clk         undivided clock (50MHz on DE0)
--      clk_en      divided clock
--      rst         reset active high
--      data        input data
--      data_rd     data ready signal
--
-- Output Signals:
--      tx          serial output
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity uart_tx is
  generic (
    delay_cl   : integer range 0 to 31 := 16;
    token_size : integer := 8 -- token size. add 1 for first bit
    );
  port (
    clk          : in  std_logic;
    clk_en       : in  std_logic;
    rst          : in  std_logic;
    data         : in  std_logic_vector(token_size downto 0);
    data_rd      : in  std_logic;
    tx           : out std_logic
    );
  end uart_tx;
  
  architecture behaviour of uart_tx is
    signal tx_r       : std_logic; -- serial output
    signal data_r     : std_logic_vector(token_size downto 0); -- buffered data input
    signal data_rd_r  : std_logic;                             -- buffered data ready input
    signal state      : unsigned(3 downto 0);                  -- state
    signal tx_data    : std_logic_vector(token_size downto 0); -- transmit shift register
    signal tx_data_rd : std_logic;                             -- has data to transmit?
    signal delay_t    : unsigned(4 downto 0); -- can hold up to 2^8-1 delay cycles
    begin
      -- Buffer incoming signals
        buf_process : process (clk, clk_en, rst, data, data_rd)
        begin
          if rising_edge(clk) then
            if (rst = '1') then -- Sync reset
              data_r    <= (others=>'0');
              data_rd_r <= '0';
            elsif (clk_en = '1') then -- use clock enable for clk division
                data_r    <= data;
                data_rd_r <= data_rd;              
            end if;
          end if;
        end process;
        
        tx <= tx_r;

        tx_process : process (clk, clk_en, rst, data_r, data_rd_r, state, tx_data, tx_data_rd, delay_t, tx_r)
          begin
            if rising_edge(clk) then
              if (rst = '1') then -- Sync reset
                state   <= (others=>'0');
                tx_data <= (others=>'0');
                tx_data_rd <= '0';
                delay_t <= (others=>'0');
                tx_r <= '1';
              elsif (clk_en = '1') then -- use clock enable for clk division
                -- if we have a data ready then latch the data and send start bit
                if ((data_rd_r = '1') and (state = 0) and (tx_data_rd='0')) then
                  tx_data    <= data_r;
                  tx_data_rd <= '1';
                  delay_t    <= (others=>'0');
                  tx_r <= '0'; -- start bit
                end if;
                -- if we have data to send 
                if (tx_data_rd = '1') then
                  -- Wait for delay cycles
                  if (delay_t=(delay_cl-1)) then                     
                    -- output serial data
                    if (tx_data(token_size) = '0') then
                      tx_r <= '0';
                    else
                      tx_r <= '1';
                    end if;
                    -- reset delay cycles
                    delay_t <= (others=>'0');
                    -- shift data
                    tx_data(token_size downto 0) <= tx_data(token_size-1 downto 0) & '0';
                    -- if we have send it all then reset state and output stop bit
                    -- the current implementation does not wait to complete the transmission of the stop bit
                    if (state = (token_size+1)) then
                      state      <= (others=>'0');
                      tx_data_rd <= '0';
                      tx_r <= '1'; -- stop bit                      
                    else
                      state <= state + 1;
                    end if;
                  else
                    delay_t <= delay_t + 1; -- wait for cycles
                  end if;
                end if;
              end if;
            end if;      
          end process;
  end behaviour;
