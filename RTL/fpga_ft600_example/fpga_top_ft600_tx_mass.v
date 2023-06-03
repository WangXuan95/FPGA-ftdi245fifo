
//--------------------------------------------------------------------------------------------------------
// Module  : fpga_top_ft600_tx_mass
// Type    : synthesizable, FPGA's top, IP's example design
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: an example of ftdi_245fifo_top
//           the pins of this module should connect to FT600 chip
//           This design will receive 4 bytes from FTDI chip,
//           and then regard the 4 bytes as a length, send length of bytes to FTDI chip
//--------------------------------------------------------------------------------------------------------

module fpga_top_ft600_tx_mass (
    input  wire         clk,            // main clock, connect to on-board crystal oscillator
    
    output wire  [ 3:0] LED,
    
    // USB3.0 (FT600 chip) ------------------------------------------------------------
    //output wire         ftdi_resetn,    // to FT600's pin10 (RESET_N) , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
    //output wire         ftdi_wakeupn,   // to FT600's pin11 (WAKEUP_N), !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
    //output wire         ftdi_gpio0,     // to FT600's pin12 (GPIO0)   , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
    //output wire         ftdi_gpio1,     // to FT600's pin13 (GPIO1)   , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
    //output wire         ftdi_siwu,      // to FT600's pin6  (SIWU_N)  , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
    input  wire         ftdi_clk,       // to FT600's pin43 (CLK)
    input  wire         ftdi_rxf_n,     // to FT600's pin5  (RXF_N)
    input  wire         ftdi_txe_n,     // to FT600's pin4  (TXE_N)
    output wire         ftdi_oe_n,      // to FT600's pin9  (OE_N)
    output wire         ftdi_rd_n,      // to FT600's pin8  (RD_N)
    output wire         ftdi_wr_n,      // to FT600's pin7  (WR_N)
    inout        [15:0] ftdi_data,      // to FT600's pin56~53 (DATA_15~DATA_12) , pin48~45 (DATA_11~DATA_8) , pin42~39 (DATA_7~DATA4) and pin36~33 (DATA_3~DATA_0)
    inout        [ 1:0] ftdi_be         // to FT600's pin3 (BE_1) and pin2 (BE_0)
);



//assign ftdi_resetn = 1'b1;  // 1=normal operation          , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
//assign ftdi_wakeupn= 1'b0;  // 0=wake up                   , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
//assign ftdi_gpio0  = 1'b0;  // GPIO[1:0]=00 = 245fifo mode , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
//assign ftdi_gpio1  = 1'b0;  //                             , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!
//assign ftdi_siwu   = 1'b1;  // 1=send immidiently          , !!!!!! UnComment this line if this signal is connected to FPGA. !!!!!!




//-----------------------------------------------------------------------------------------------------------------------------
// user AXI-stream signals (loopback)
//-----------------------------------------------------------------------------------------------------------------------------
wire        rx_tready;
wire        rx_tvalid;
wire [ 7:0] rx_tdata;

wire        tx_tready;
wire        tx_tvalid;
wire [31:0] tx_tdata;
wire [ 3:0] tx_tkeep;
wire        tx_tlast;




//-----------------------------------------------------------------------------------------------------------------------------
// FTDI USB chip's 245fifo mode controller
//-----------------------------------------------------------------------------------------------------------------------------
ftdi_245fifo_top #(
    .TX_EW                 ( 2                  ),   // TX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit, 4=128bit ...
    .TX_EA                 ( 10                 ),   // TX FIFO depth = 2^TX_AEXP = 2^10 = 1024
    .RX_EW                 ( 0                  ),   // RX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit, 4=128bit ...
    .RX_EA                 ( 8                  ),   // RX FIFO depth = 2^RX_AEXP = 2^10 = 1024
    .CHIP_TYPE             ( "FT600"            )
) u_ftdi_245fifo_top (
    .rstn_async            ( 1'b1               ),
    .tx_clk                ( clk                ),
    .tx_tready             ( tx_tready          ),
    .tx_tvalid             ( tx_tvalid          ),
    .tx_tdata              ( tx_tdata           ),
    .tx_tkeep              ( tx_tkeep           ),
    .tx_tlast              ( tx_tlast           ),
    .rx_clk                ( clk                ),
    .rx_tready             ( rx_tready          ),
    .rx_tvalid             ( rx_tvalid          ),
    .rx_tdata              ( rx_tdata           ),
    .rx_tkeep              (                    ),
    .rx_tlast              (                    ),
    .ftdi_clk              ( ftdi_clk           ),
    .ftdi_rxf_n            ( ftdi_rxf_n         ),
    .ftdi_txe_n            ( ftdi_txe_n         ),
    .ftdi_oe_n             ( ftdi_oe_n          ),
    .ftdi_rd_n             ( ftdi_rd_n          ),
    .ftdi_wr_n             ( ftdi_wr_n          ),
    .ftdi_data             ( ftdi_data          ),
    .ftdi_be               ( ftdi_be            )
);




//-----------------------------------------------------------------------------------------------------------------------------
// 
//-----------------------------------------------------------------------------------------------------------------------------
tx_specified_len u_tx_specified_len (
    .rstn                  ( 1'b1               ),
    .clk                   ( clk                ),
    .i_tready              ( rx_tready          ),
    .i_tvalid              ( rx_tvalid          ),
    .i_tdata               ( rx_tdata           ),
    .o_tready              ( tx_tready          ),
    .o_tvalid              ( tx_tvalid          ),
    .o_tdata               ( tx_tdata           ),
    .o_tkeep               ( tx_tkeep           ),
    .o_tlast               ( tx_tlast           )
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
    .CLK_FREQ              ( 100000000          ),
    .BEAT_FREQ             ( 5                  )
) u_ftdi_clk_beat (
    .clk                   ( ftdi_clk           ),
    .beat                  ( LED[3]             )
);


endmodule
