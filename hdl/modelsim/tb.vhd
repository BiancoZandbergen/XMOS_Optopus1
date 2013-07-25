-----------------------------------------------------------------
-- Module: Test Bench for XMOS Link Media Converter
-- Author: Bianco Zandbergen
--
-- Sends tokens with value 0 to 511 in both directions
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all; 

entity tb is
  generic (                                 
    token_delay       : time := 10000 ns;
    intertoken_delay  : time := 80000 ns;
    clk_period        : time := 20 ns; -- 50 MHz period
    div               : integer range 0 to 31 := 10;
    delay_cl          : integer := 20;                                          
    token_size        : integer := 8 -- token size. add 1 for first bit
    );
  port (
    rst       : out std_logic;
    clk       : out std_logic;
    b1        : out std_logic;
    b2        : out std_logic;
    a1        : out std_logic;
    a2        : out std_logic;
    a3        : out std_logic;
    a4        : out std_logic;
    b3        : out std_logic;
    b4        : out std_logic;
    rx_state0 : out std_logic_vector(3 downto 0)
    );
  end tb;  
  
  architecture tb of tb is  
    component toplevel is
      generic (
    div                 : integer range 0 to 31 := 10; -- clock divide ratio
    delay_cl_xlink_tx   : integer range 0 to 31 := 20; -- delay between transitions
    delay_cl_uart_tx    : integer range 0 to 31 := 16;
    reset_delay         : integer range 0 to 255 := 250;                                         
    token_size          : integer := 8 -- token size. (data bits only)
    );
  port (
    rst             : in  std_logic;
    clk             : in  std_logic;
    a3              : in  std_logic;
    a4              : in  std_logic;
    b1              : in  std_logic;
    b2              : in  std_logic;
    a1              : out std_logic;
    a2              : out std_logic;
    b3              : out std_logic;
    b4              : out std_logic;
    uart_tx0        : out std_logic;
    uart_tx1        : out std_logic;
    uart_rx_inv0    : in  std_logic; -- optics input is inverted
    uart_rx_inv1    : in  std_logic;
    -- Debug signals
    clk_en_o        : out std_logic;
    rx_state0       : out std_logic_vector(3 downto 0);
    rst_n_o         : out std_logic;
    data_rd_o       : out std_logic;
    uart_rx_o       : out std_logic
    );
      end component;
        
    signal rst_i          : std_logic;
    signal clk_i          : std_logic;
    signal b1_i           : std_logic;
    signal b2_i           : std_logic;
    signal a1_i           : std_logic;
    signal a2_i           : std_logic;
    signal pw0_i          : std_logic;
    signal pw1_i          : std_logic;
    signal a3_i           : std_logic;
    signal a4_i           : std_logic;
    signal b3_i           : std_logic;
    signal b4_i           : std_logic;
    signal rx_state0_i    : std_logic_vector(3 downto 0);
    signal clk_en_o_i     : std_logic;
    signal rst_n_o_i      : std_logic;
    signal data_rd_o      : std_logic;
    signal uart_rx_o      : std_logic;
    signal uart_tx0_i     : std_logic;
    signal uart_tx1_i     : std_logic;
    signal uart_rx_inv0_i : std_logic;
    signal uart_rx_inv1_i : std_logic;
    
    begin
      rst       <= rst_i      ;
      clk       <= clk_i      ;
      b1        <= b1_i       ;
      b2        <= b2_i       ;
      b3        <= b3_i       ;
      b4        <= b4_i       ;
      a1        <= a1_i       ;
      a2        <= a2_i       ;
      a3        <= a3_i       ;
      a4        <= a4_i       ;
      rx_state0 <= rx_state0_i;
      uart_rx_inv0_i <= not uart_tx0_i;
      uart_rx_inv1_i <= not uart_tx1_i;

      -- instance of top level
      i_top : toplevel                   
      generic map (                           
        div        => div       ,
        delay_cl_xlink_tx   => delay_cl  ,
        token_size => token_size       
       )                                     
      port map (           
        rst           => rst_i          ,     
        clk           => clk_i          ,
        a3            => a3_i           ,
        a4            => a4_i           ,
        b1            => b1_i           ,
        b2            => b2_i           ,
        a1            => a1_i           ,
        a2            => a2_i           ,
        b3            => b3_i           ,
        b4            => b4_i           ,
        uart_tx0      => uart_tx0_i     ,
        uart_tx1      => uart_tx1_i     ,
        uart_rx_inv0  => uart_rx_inv0_i ,
        uart_rx_inv1  => uart_rx_inv1_i ,
        rx_state0     => rx_state0_i    ,
        clk_en_o      => clk_en_o_i     ,          
        rst_n_o       => rst_n_o_i      ,
        data_rd_o     => data_rd_o      , 
        uart_rx_o     => uart_rx_o 
        );

  process
  begin
    clk_i <= '0';
    loop
      wait for (clk_period);
      clk_i <= not clk_i;
    end loop;
  end process;        

  process
  begin
    rst_i <= '0';
    wait for (1 ns);
    rst_i <= '1';
    wait for (100 ns);
    rst_i <= '0';
    wait for (2000 ns);
    rst_i <= not rst_i;
    wait;
  end process;

  process
  VARIABLE out_token : std_logic_vector(token_size downto 0);
  begin
    b1_i <= '0';
    b2_i <= '0';    
    wait for (10000 ns);
    
    -- output all tokens with value from 0 to 511 on wires B1 and B2    
    for i in 0 to 511 loop
        
        out_token := conv_std_logic_vector(i, 9);

        wait for (intertoken_delay);

        for j in 8 downto 0 loop
         
         if (out_token(8) = '0') then
           if (b2_i = '0') then
             b2_i <= '1';
           else
             b2_i <= '0';
           end if;
         else
           if (b1_i = '0') then
             b1_i <= '1';
           else
             b1_i <= '0';
           end if;
         end if;
         
         out_token(8 downto 0) := out_token(7 downto 0) & '0';
         wait for (token_delay);
         
       end loop;
       
       b1_i <= '0';
       b2_i <= '0';           
         
    end loop;
           
    wait;
  end process;
  
  process
  VARIABLE out_token : std_logic_vector(token_size downto 0);
  begin
    a3_i <= '0';
    a4_i <= '0';    
    wait for (10000 ns);
    
    -- output all tokens with value from 0 to 511 on wires B1 and B2    
    for i in 0 to 511 loop
        
        out_token := conv_std_logic_vector(i, 9);

        wait for (intertoken_delay);

        for j in 8 downto 0 loop
         
         if (out_token(8) = '0') then
           if (a3_i = '0') then
             a3_i <= '1';
           else
             a3_i <= '0';
           end if;
         else
           if (a4_i = '0') then
             a4_i <= '1';
           else
             a4_i <= '0';
           end if;
         end if;
         
         out_token(8 downto 0) := out_token(7 downto 0) & '0';
         wait for (token_delay);
         
       end loop;
       
       a3_i <= '0';
       a4_i <= '0';           
         
    end loop;
           
    wait;
  end process;
    
  end tb;