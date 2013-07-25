-----------------------------------------------------------------
-- Module: XMOS Link Two-wire Receiver
-- Author: Bianco Zandbergen
--
-- Input Signals:
--      clk         undivided clock (50MHz on DE0)
--      clk_en      divided clock
--      rst         reset active high
--      w0          XMOS Link Wire 0
--      w1          XMOS Link Wire 1
--
-- Output Signals:
--      data        received data
--      data_rd     data ready signal
--      rx_state    internal state for debug only
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity xlink_2w_rx_phy is
  generic (
    token_size : integer := 8 -- token size (data bits only)
    );
  port (
    clk          : in  std_logic;
    clk_en       : in  std_logic;
    rst          : in  std_logic;
    w0           : in  std_logic;
    w1           : in  std_logic;
    data         : out std_logic_vector(token_size downto 0);
    data_rd      : out std_logic;
    -- Debug signals
    rx_state     : out std_logic_vector(3 downto 0)
    );
  end xlink_2w_rx_phy;
  
architecture behaviour of xlink_2w_rx_phy is
  signal w0_r        : std_logic; -- captured value of Wire 0
  signal w1_r        : std_logic; -- captured value of Wire 1
  signal pw0_r       : std_logic; -- Value of Wire 0 on previous clock cycle
  signal pw1_r       : std_logic; -- Value of Wire 1 on previous clock cycle
  signal data_r      : std_logic_vector(token_size downto 0); -- data signal
  signal data_rd_r   : std_logic; -- data ready signal
  signal state_t     : unsigned(3 downto 0); -- state keeper
  signal latch_r     : unsigned(3 downto 0); -- data latch state
  signal xor_w0      : std_logic; -- XOR of previous and current value of Wire 0
  signal xor_w1      : std_logic; -- XOR of previous and current value of Wire 1
  
  begin
    -- Buffer inputs and update previous inputs
    buf_process : process (clk, clk_en, rst, w0, w1)
      begin
        if rising_edge(clk) then
          if (rst = '1') then -- Sync reset
            w0_r  <= '0';
            w1_r  <= '0';
            pw0_r <= '0';
            pw1_r <= '0';
            xor_w0<= '0';
            xor_w1<= '0';
          elsif (clk_en = '1') then -- use clock enable for clk division
            w0_r  <= w0;   
            w1_r  <= w1;
            pw0_r <= w0_r;
            pw1_r <= w1_r;
            xor_w0<= w0_r xor pw0_r;
            xor_w1<= w1_r xor pw1_r;
          end if;
        end if;
      end process;
      
      data        <= data_r;
      data_rd     <= data_rd_r;           
      rx_state    <= std_logic_vector(state_t);
      
      -- Main logic 
      rx_process : process (clk, clk_en, rst, latch_r, data_r, w0_r, w1_r, pw0_r, pw1_r, state_t)
        begin
          if rising_edge(clk) then
            if (rst='1') then
              latch_r     <= (others=>'0');
              state_t     <= (others=>'0');
              data_r      <= (others=>'0');
              data_rd_r   <= '0';

            elsif (clk_en = '1') then

              if (xor_w0 = '1') then
               if (state_t = (token_size+1)) then 
                state_t <= (others=>'0'); 
               else
                state_t <= state_t + 1;
                latch_r <= latch_r + 1;
                data_r(token_size downto 0) <= data_r(token_size-1 downto 0) & '0';
               end if;
              end if;
              
              if (xor_w1 = '1') then
               if (state_t = (token_size+1)) then 
                state_t <= (others=>'0'); 
               else
                state_t <= state_t + 1;
                latch_r <= latch_r + 1;
                data_r(token_size downto 0) <= data_r(token_size-1 downto 0) & '1';
               end if;
              end if;

              if (latch_r = token_size+1) then
                latch_r     <= (others=>'0');
                data_rd_r <= '1'; -- high for one cycle
              else
                data_rd_r <= '0';
              end if;
              
            end if;
          end if;
        end process;
    end behaviour;
