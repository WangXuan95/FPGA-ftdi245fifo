
//--------------------------------------------------------------------------------------------------------
// Module  : fpga_top_ft232h_loopback
// Type    : synthesizable, FPGA's top, IP's example design
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: an example of ftdi_245fifo_top
//           the pins of this module should connect to FT232H chip
//           This design only sends all data received from the FTDI chip back to the FTDI chip.
//           It is also known as 'loopback'
//--------------------------------------------------------------------------------------------------------

module fpga_top_ft232h_loopback (
    input  wire         clk,           // main clock, connect to on-board crystal oscillator
    
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
localparam              AXIS_EW = 2;
wire                    tready;
wire                    tvalid;
wire [(8<<AXIS_EW)-1:0] tdata;
wire [(1<<AXIS_EW)-1:0] tkeep;
wire                    tlast;




//-----------------------------------------------------------------------------------------------------------------------------
// FTDI USB chip's 245fifo mode controller
//-----------------------------------------------------------------------------------------------------------------------------
ftdi_245fifo_top #(
    .TX_EW                 ( AXIS_EW            ),   // TX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit, 4=128bit ...
    .TX_EA                 ( 10                 ),   // TX FIFO depth = 2^TX_AEXP = 2^10 = 1024
    .RX_EW                 ( AXIS_EW            ),   // RX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit, 4=128bit ...
    .RX_EA                 ( 10                 ),   // RX FIFO depth = 2^RX_AEXP = 2^10 = 1024
    .CHIP_TYPE             ( "FTx232H"          )
) u_ftdi_245fifo_top (
    .rstn_async            ( 1'b1               ),
    .tx_clk                ( clk                ),
    .tx_tready             ( tready             ),
    .tx_tvalid             ( tvalid             ),
    .tx_tdata              ( tdata              ),
    .tx_tkeep              ( tkeep              ),
    .tx_tlast              ( tlast              ),
    .rx_clk                ( clk                ),
    .rx_tready             ( tready             ),
    .rx_tvalid             ( tvalid             ),
    .rx_tdata              ( tdata              ),
    .rx_tkeep              ( tkeep              ),
    .rx_tlast              ( tlast              ),
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
// show the low 4-bit of the last received data on LED
//-----------------------------------------------------------------------------------------------------------------------------
reg  [2:0] tdata_d = 3'h0;

always @ (posedge clk)
    if (tvalid)
        tdata_d <= tdata[2:0];

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
