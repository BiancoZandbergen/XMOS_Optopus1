# Modelsim transcript file for XMOS Link Media Converter
vlib work
vmap work work
vcom clock_divider.vhd
vcom reset_control.vhd
vcom xlink_2w_rx_phy.vhd
vcom xlink_2w_tx_phy.vhd
vcom uart_tx.vhd
vcom uart_rx.vhd
vcom toplevel.vhd
vcom tb.vhd
vsim tb
log -r /*
                            
add wave \
{sim:/tb/rst } \
{sim:/tb/i_top/rst_n } \
{sim:/tb/clk } \
{sim:/tb/i_top/clk_en }
 
add wave \
{sim:/tb/rx_state0} \
{sim:/tb/b1 } \
{sim:/tb/b2 } \
{sim:/tb/uart_tx0_i } \
{sim:/tb/a1 } \
{sim:/tb/a2 }

add wave \
{sim:/tb/a3 } \
{sim:/tb/a4} \
{sim:/tb/uart_tx1_i } \
{sim:/tb/b3} \
{sim:/tb/b4}

run 10 ms
