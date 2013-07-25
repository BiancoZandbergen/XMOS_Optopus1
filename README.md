Optopus 1
=========

XMOS xCONNECT Link over optical fibre using FPGA
------------------------------------------------

The XMOS xCONNECT Link processor bus is very latency tolerant,
which allows it to be transported over a wide range
of media such as wireless networks and ethernet.
This project aims to transport the xCONNECT Link over cheap optical fibre
from Avago Technologies (Versatile Link).
This is achieved by using an FPGA to convert the xCONNECT Link to a format
that can be transported over the optical link.
The FPGA receives tokens from one of the XMOS chips over a
standard xCONNECT Link (2 wire) and transmits the received tokens
over a standard serial link (9n1). The other side (also implemented in the FPGA)
receives the serial data and sends them to the destination XMOS chip
through a standard XMOS Link. There is no additional buffering.
This means that the serial link speed must be fast enough to transfer the tokens,
otherwise it will result in data loss.

The project is implemented using two XMOS XK-1 boards and a Altera DE0 FPGA board.
The FPGA board has two extension connectors.

One of them connects to a custom PCB called the adapter board.
The two XK-1 boards fit into the adapter board.
The JTAG signals are connected to a standard XTAG2 header.
The xCONNECT Links of the two boards are connected to the FPGA (and not to each other).

The other extension header of the FPGA board connects to a custom PCB
which houses the optic transmitters and receivers.

The ultimate goal is to eventually run multiple XMOS links at full speed
using fibre optics used in telecom and networking,
such as affordable GBIC Media Converters commonly used in
professional network and router appliances.

The project name is suffixed with '1' to leave room for future projects.
