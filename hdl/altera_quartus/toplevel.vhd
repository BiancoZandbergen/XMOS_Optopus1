-----------------------------------------------------------------
-- Module: Top Level of XMOS Link Media Converter
-- Author: Bianco Zandbergen
--
-- XMOS Link Wire Map (pins and directions and 0/1)
-- 
-- Node 0                           Node 1
-- A1 <<--------[ Wire 1 ] -------- B1
-- A2 <<--------[ Wire 0 ] -------- B2
-- A3 ----------[ Wire 0 ] ------>> B3
-- A4 ----------[ Wire 1 ] ------>> B4
--
-- Full Media Converter Chain:
--
-- w0/w1-->[xlink_2w_rx_phy]-->[uart_rx]-->[uart_tx]-->[xlink_2w_tx_phy]-->w0/w1
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity toplevel is
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
  end toplevel;
  
  architecture toplevel of toplevel is
    component clock_divider is
      generic (
        div    : integer range 0 to 31 := 10
        );
      port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        clk_en : out std_logic
        );
      end component;
      
    component reset_control is
      generic (
        delay  : integer range 0 to 255 := 255
        );
      port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        rst_n  : out std_logic
        );
     end component;
    
    component xlink_2w_tx_phy is
      generic (
        delay_cl   : integer range 0 to 31 := 5;
        token_size : integer := 8 -- token size. add 1 for first bit
        );
      port (
        clk          : in  std_logic;
        clk_en       : in  std_logic;
        rst          : in  std_logic;
        data         : in  std_logic_vector(token_size downto 0);
        data_rd      : in  std_logic;
        w0           : out std_logic;
        w1           : out std_logic
        );
      end component;

    component xlink_2w_rx_phy is
      generic (
        token_size : integer := 8 -- token size. add 1 for first bit
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
      end component;
      
    component uart_tx is
	  generic (
        delay_cl   : integer range 0 to 31 := 5;
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
    end component;
  
    component uart_rx is
    generic (
      token_size : integer := 8 -- token size. add 1 for first bit
      );
    port (
      clk          : in  std_logic;
      clk_en       : in  std_logic;
      rst          : in  std_logic;
      rx           : in  std_logic;
      data         : out std_logic_vector(token_size downto 0);
      data_rd      : out std_logic
      );
    end component;
            
      signal clk_en  : std_logic;  -- divided clock
      signal rst_n    : std_logic; -- inverted reset
      
      -- use these signals only to internally
      -- loop back the UARTs
      --signal uart_wire0 : std_logic;
      --signal uart_wire1 : std_logic;
      
      -- signals for one direction
      signal xlink_data0    : std_logic_vector(token_size downto 0);
      signal xlink_data_rd0 : std_logic;
      signal uart_data0     : std_logic_vector(token_size downto 0);
      signal uart_data_rd0  : std_logic;     
      signal uart_rx0       : std_logic;
      
      -- signals for the opposite direction
      signal xlink_data1    : std_logic_vector(token_size downto 0);
      signal xlink_data_rd1 : std_logic;
      signal uart_data1     : std_logic_vector(token_size downto 0);
      signal uart_data_rd1  : std_logic;     
      signal uart_rx1       : std_logic;
      signal rx_state1      : std_logic_vector(3 downto 0); -- keep this debug signal internal

    begin

      --a1 <= b1;
      --a2 <= b2;
      --b3 <= a3;
      --b4 <= a4;

      -- passing out debug signals
      data_rd_o <= xlink_data_rd0;     
      clk_en_o <= clk_en;      
      uart_rx_o <= uart_rx0;      
      rst_n_o <= rst_n;

      -- invert the incoming serial data      
      uart_rx0 <= NOT uart_rx_inv0;
      uart_rx1 <= NOT uart_rx_inv1;
      
      i_clk : clock_divider 
      generic map (
        div    => div
        )
      port map (                              
        clk    => clk       ,                        
        rst    => rst_n     ,                        
        clk_en => clk_en                      
        );
        
      i_reset : reset_control 
      generic map (
        delay => reset_delay
        )
      port map (
        clk    => clk,
        rst    => rst,
        rst_n  => rst_n
        );                                    

      -- instances for one direction

      i_xlink_rx0 : xlink_2w_rx_phy 
      generic map (
        token_size => token_size
        )
      port map (
        clk        => clk               ,
        clk_en     => clk_en            , 
        rst        => rst_n             ,
        w0         => b2                ,
        w1         => b1                ,
        data       => xlink_data0       ,
        data_rd    => xlink_data_rd0    ,
        rx_state   => rx_state0  
        );
                                              
      i_xlink_tx0 : xlink_2w_tx_phy                   
      generic map (                           
        token_size => token_size,             
        delay_cl   => delay_cl_xlink_tx                
        )                                     
      port map (                              
        clk      => clk             ,                 
        clk_en   => clk_en          ,                 
        rst      => rst_n           ,                 
        w0       => a2              ,                 
        w1       => a1              ,
        data     => uart_data0      ,
        data_rd  => uart_data_rd0 
        );

      i_uart_rx0 : uart_rx 
      generic map (
        token_size => token_size
        )
      port map (
        clk        => clk           ,
        clk_en     => clk_en        , 
        rst        => rst_n         ,
        rx         => uart_rx0      ,
        data       => uart_data0    ,
        data_rd    => uart_data_rd0   
        );
       
      i_uart_tx0 : uart_tx                   
      generic map (                           
        token_size => token_size,             
        delay_cl   => delay_cl_uart_tx                
        )                                     
      port map (                              
        clk      => clk             ,                 
        clk_en   => clk_en          ,                 
        rst      => rst_n           ,                 
        tx       => uart_tx0        ,                 
        data     => xlink_data0     ,
        data_rd  => xlink_data_rd0 
        );
        
      -- instances for the opposite direction

      i_xlink_rx1 : xlink_2w_rx_phy 
      generic map (
        token_size => token_size
        )
      port map (
        clk        => clk               ,
        clk_en     => clk_en            , 
        rst        => rst_n             ,
        w0         => a3                ,
        w1         => a4                ,
        data       => xlink_data1       ,
        data_rd    => xlink_data_rd1    ,
        rx_state   => rx_state1  
        );
                                              
      i_xlink_tx1 : xlink_2w_tx_phy                   
      generic map (                           
        token_size => token_size,             
        delay_cl   => delay_cl_xlink_tx                
        )                                     
      port map (                              
        clk      => clk             ,                 
        clk_en   => clk_en          ,                 
        rst      => rst_n           ,                 
        w0       => b3              ,                 
        w1       => b4              ,
        data     => uart_data1      ,
        data_rd  => uart_data_rd1 
        );

      i_uart_rx1 : uart_rx 
      generic map (
        token_size => token_size
        )
      port map (
        clk        => clk           ,
        clk_en     => clk_en        , 
        rst        => rst_n         ,
        rx         => uart_rx1      ,
        data       => uart_data1    ,
        data_rd    => uart_data_rd1   
        );
       
      i_uart_tx1 : uart_tx                   
      generic map (                           
        token_size => token_size,             
        delay_cl   => delay_cl_uart_tx                
        )                                     
      port map (                              
        clk      => clk             ,                 
        clk_en   => clk_en          ,                 
        rst      => rst_n           ,                 
        tx       => uart_tx1        ,                 
        data     => xlink_data1     ,
        data_rd  => xlink_data_rd1 
        );  
   
  end toplevel;
