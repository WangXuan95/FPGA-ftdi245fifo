
//--------------------------------------------------------------------------------------------------------
// Module  : fpga_top_ft232h_rx_crc
// Type    : synthesizable, FPGA's top, IP's example design
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: an example of ftdi_245fifo_top
//           the pins of this module should connect to FT600 chip
//           This design will receive a data block from FTDI chip, and calculate its CRC.
//           When meeting 0xFF, it thinks that the data block ends, and then send the block's CRC to FTDI chip.
//--------------------------------------------------------------------------------------------------------

module fpga_top_ft232h_rx_crc (
    input  wire         clk,            // main clock, connect to on-board crystal oscillator
    
    output wire  [ 3:0] LED,
    
    // USB2.0 HS (FT232H chip) ------------------------------------------------------------
    //output wire         ftdi_resetn,    // to FT232H's pin34 (RESET#) , !!!!!! UnComment this line if this signal is connected to FPGA !!!!!!
    //output wire         ftdi_pwrsav,    // to FT232H's pin31 (PWRSAV#), !!!!!! UnComment this line if this signal is connected to FPGA !!!!!!
    //output wire         ftdi_siwu,      // to FT232H's pin28 (SIWU#)  , !!!!!! UnComment this line if this signal is connected to FPGA !!!!!!
    input  wire         ftdi_clk,       // to FT232H's pin29 (CLKOUT)
    input  wire         ftdi_rxf_n,     // to FT232H's pin21 (RXF#)
    input  wire         ftdi_txe_n,     // to FT232H's pin25 (TXE#)
    output wire         ftdi_oe_n,      // to FT232H's pin30 (OE#)
    output wire         ftdi_rd_n,      // to FT232H's pin26 (RD#)
    output wire         ftdi_wr_n,      // to FT232H's pin27 (WR#)
    inout        [ 7:0] ftdi_data       // to FT232H's pin20~13 (ADBUS7~ADBUS0)
);



//assign ftdi_resetn = 1'b1;  // 1=normal operation , !!!!!! UnComment this line if this signal is connected to FPGA !!!!!!
//assign ftdi_pwrsav = 1'b1;  // 1=normal operation , !!!!!! UnComment this line if this signal is connected to FPGA !!!!!!
//assign ftdi_siwu   = 1'b1;  // 1=send immidiently , !!!!!! UnComment this line if this signal is connected to FPGA !!!!!!




//-----------------------------------------------------------------------------------------------------------------------------
// user AXI-stream signals (loopback)
//-----------------------------------------------------------------------------------------------------------------------------
localparam                 RX_AXIS_EW = 1;

wire                       rx_tready;
wire                       rx_tvalid;
wire [(8<<RX_AXIS_EW)-1:0] rx_tdata;
wire [(1<<RX_AXIS_EW)-1:0] rx_tkeep;

wire                       tx_tready;
wire                       tx_tvalid;
wire               [ 31:0] tx_tdata;




//-----------------------------------------------------------------------------------------------------------------------------
// FTDI USB chip's 245fifo mode controller
//-----------------------------------------------------------------------------------------------------------------------------
ftdi_245fifo_top #(
    .TX_EW                 ( 2                  ),   // TX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit, 4=128bit ...
    .TX_EA                 ( 8                  ),   // TX FIFO depth = 2^TX_AEXP = 2^10 = 1024
    .RX_EW                 ( RX_AXIS_EW         ),   // RX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit, 4=128bit ...
    .RX_EA                 ( 10                 ),   // RX FIFO depth = 2^RX_AEXP = 2^10 = 1024
    .CHIP_TYPE             ( "FTx232H"          )
) u_ftdi_245fifo_top (
    .rstn_async            ( 1'b1               ),
    .tx_clk                ( clk                ),
    .tx_tready             ( tx_tready          ),
    .tx_tvalid             ( tx_tvalid          ),
    .tx_tdata              ( tx_tdata           ),
    .tx_tkeep              ( 4'b1111            ),
    .tx_tlast              ( 1'b1               ),
    .rx_clk                ( clk                ),
    .rx_tready             ( rx_tready          ),
    .rx_tvalid             ( rx_tvalid          ),
    .rx_tdata              ( rx_tdata           ),
    .rx_tkeep              ( rx_tkeep           ),
    .rx_tlast              (                    ),
    .ftdi_clk              ( ftdi_clk           ),
    .ftdi_rxf_n            ( ftdi_rxf_n         ),
    .ftdi_txe_n            ( ftdi_txe_n         ),
    .ftdi_oe_n             ( ftdi_oe_n          ),
    .ftdi_rd_n             ( ftdi_rd_n          ),
    .ftdi_wr_n             ( ftdi_wr_n          ),
    .ftdi_data             ( ftdi_data          ),
    .ftdi_be               (                    )    // FT232H do not have BE signals
);




//-----------------------------------------------------------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------------------------------------------------------
rx_calc_crc #(
    .IEW                   ( RX_AXIS_EW         )
) u_rx_calc_crc (
    .rstn                  ( 1'b1               ),
    .clk                   ( clk                ),
    .i_tready              ( rx_tready          ),
    .i_tvalid              ( rx_tvalid          ),
    .i_tdata               ( rx_tdata           ),
    .i_tkeep               ( rx_tkeep           ),
    .o_tready              ( tx_tready          ),
    .o_tvalid              ( tx_tvalid          ),
    .o_tdata               ( tx_tdata           )
);




//-----------------------------------------------------------------------------------------------------------------------------
// show the low 3-bit of the last received data on LED
//-----------------------------------------------------------------------------------------------------------------------------
reg  [2:0] tdata_d = 3'h0;

always @ (posedge clk)
    if (rx_tvalid)
        tdata_d <= rx_tdata[2:0];

assign LED[2:0] = tdata_d;




//-----------------------------------------------------------------------------------------------------------------------------
// if ftdi_clk continuous run, then beat will blink. The function of this module is to observe whether ftdi_clk is running
//-----------------------------------------------------------------------------------------------------------------------------
clock_beat # (
    .CLK_FREQ              ( 60000000           ),
    .BEAT_FREQ             ( 5                  )
) u_ftdi_clk_beat (
    .clk                   ( ftdi_clk           ),
    .beat                  ( LED[3]             )
);


endmodule
