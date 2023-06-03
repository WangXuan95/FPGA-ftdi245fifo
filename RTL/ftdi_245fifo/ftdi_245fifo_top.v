
//--------------------------------------------------------------------------------------------------------
// Module  : ftdi_245fifo_top
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: FTDI USB chip's 245fifo mode controller
//           support FT232H, FT2232H, FT600, FT601. (and maybe FT245 (untested))
//           to realize USB communication
//--------------------------------------------------------------------------------------------------------

module ftdi_245fifo_top #(
    parameter  TX_EW      = 2 ,          // TX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit, 4=128bit ...
    parameter  TX_EA      = 10,          // TX FIFO depth = 2^TX_EA
    parameter  RX_EW      = 2 ,          // RX data stream width,  0=8bit, 1=16bit, 2=32bit, 3=64bit, 4=128bit ...
    parameter  RX_EA      = 10,          // RX FIFO depth = 2^RX_EA
    parameter  CHIP_TYPE  = "FTx232H",   // can be "FTx232H", "FT600", "FT601"
    parameter  SIMULATION = 0            // 0:for normal use    1:enable assert for simulation
) ( 
    // asynchronous reset, active low
    rstn_async,
    // user send interface (FPGA -> USB -> PC), AXI-stream slave.
    tx_clk,          // User-specified clock for send interface
    tx_tready,
    tx_tvalid,
    tx_tdata,
    tx_tkeep,
    tx_tlast,
    // user recv interface (PC -> USB -> FPGA), AXI-stream master.
    rx_clk,          // User-specified clock for recv interface
    rx_tready,
    rx_tvalid,
    rx_tdata,
    rx_tkeep,
    rx_tlast,
    // FTDI 245FIFO interface, connect these signals to FTDI USB chip
    ftdi_clk,
    ftdi_rxf_n,
    ftdi_txe_n,
    ftdi_oe_n,
    ftdi_rd_n,
    ftdi_wr_n,
    ftdi_data,
    ftdi_be          // only FT600&FT601 have BE signal, ignore it when the chip don't have this signal
);



localparam  CHIP_EW               = (CHIP_TYPE=="FT601") ? 2 : (CHIP_TYPE=="FT600") ? 1 : 0;
localparam  CHIP_DRIVE_AT_NEGEDGE = (CHIP_TYPE=="FT601") ? 0 : (CHIP_TYPE=="FT600") ? 0 : 0;


//-----------------------------------------------------------------------------------------------------------------------------
// in/out signals 
//-----------------------------------------------------------------------------------------------------------------------------
input  wire                    rstn_async;
input  wire                    tx_clk;
output wire                    tx_tready;
input  wire                    tx_tvalid;
input  wire   [(8<<TX_EW)-1:0] tx_tdata;
input  wire   [(1<<TX_EW)-1:0] tx_tkeep;
input  wire                    tx_tlast;
input  wire                    rx_clk;
input  wire                    rx_tready;
output wire                    rx_tvalid;
output wire   [(8<<RX_EW)-1:0] rx_tdata;
output wire   [(1<<RX_EW)-1:0] rx_tkeep;
output wire                    rx_tlast;
input  wire                    ftdi_clk;
input  wire                    ftdi_rxf_n;
input  wire                    ftdi_txe_n;
output wire                    ftdi_oe_n;
output wire                    ftdi_rd_n;
output wire                    ftdi_wr_n;
inout       [(8<<CHIP_EW)-1:0] ftdi_data;
inout       [(1<<CHIP_EW)-1:0] ftdi_be;



//-----------------------------------------------------------------------------------------------------------------------------
// tri-state driver for inout pins 
//-----------------------------------------------------------------------------------------------------------------------------
wire                    ftdi_master_oe;
wire [(8<<CHIP_EW)-1:0] ftdi_data_out;
wire [(1<<CHIP_EW)-1:0] ftdi_be_out;

assign ftdi_data    = ftdi_master_oe ? ftdi_data_out : {(8<<CHIP_EW){1'bZ}};     // tri-state driver
assign ftdi_be      = ftdi_master_oe ? ftdi_be_out   : {(1<<CHIP_EW){1'bZ}};     // tri-state driver



//-----------------------------------------------------------------------------------------------------------------------------
// generate reset
//-----------------------------------------------------------------------------------------------------------------------------
wire                       rstn_ftdi;
wire                       rstn_tx;
wire                       rstn_rx;

resetn_sync u_resetn_sync_usb (rstn_async, ftdi_clk, rstn_ftdi);
resetn_sync u_resetn_sync_tx  (rstn_async,  tx_clk , rstn_tx );
resetn_sync u_resetn_sync_rx  (rstn_async,  rx_clk , rstn_rx );



//-----------------------------------------------------------------------------------------------------------------------------
// internal signals
//-----------------------------------------------------------------------------------------------------------------------------
localparam TX_FIFO_EW = (TX_EW > CHIP_EW) ? TX_EW : CHIP_EW;
localparam RX_FIFO_EW = (RX_EW > CHIP_EW) ? RX_EW : CHIP_EW;

wire                       tx_a_tready;
wire                       tx_a_tvalid;
wire      [(8<<TX_EW)-1:0] tx_a_tdata;
wire      [(1<<TX_EW)-1:0] tx_a_tkeep;
wire                       tx_a_tlast;

wire                       tx_b_tready;
wire                       tx_b_tvalid;
wire      [(8<<TX_EW)-1:0] tx_b_tdata;
wire      [(1<<TX_EW)-1:0] tx_b_tkeep;
wire                       tx_b_tlast;

wire                       tx_c_tready;
wire                       tx_c_tvalid;
wire [(8<<TX_FIFO_EW)-1:0] tx_c_tdata;
wire [(1<<TX_FIFO_EW)-1:0] tx_c_tkeep;

wire                       tx_d_tready;
wire                       tx_d_tvalid;
wire [(8<<TX_FIFO_EW)-1:0] tx_d_tdata;
wire [(1<<TX_FIFO_EW)-1:0] tx_d_tkeep;

wire                       tx_e_tready;
wire                       tx_e_tvalid;
wire [(8<<TX_FIFO_EW)-1:0] tx_e_tdata;
wire [(1<<TX_FIFO_EW)-1:0] tx_e_tkeep;

wire                       tx_f_tready;
wire                       tx_f_tvalid;
wire    [(8<<CHIP_EW)-1:0] tx_f_tdata;
wire    [(1<<CHIP_EW)-1:0] tx_f_tkeep;

wire                       tx_g_tready;
wire                       tx_g_tvalid;
wire    [(8<<CHIP_EW)-1:0] tx_g_tdata;
wire    [(1<<CHIP_EW)-1:0] tx_g_tkeep;

wire                       tx_h_tready;
wire                       tx_h_tvalid;
wire    [(8<<CHIP_EW)-1:0] tx_h_tdata;
wire    [(1<<CHIP_EW)-1:0] tx_h_tkeep;

wire                       rx_a_almost_full;
wire                       rx_a_tvalid;
wire    [(8<<CHIP_EW)-1:0] rx_a_tdata;
wire    [(1<<CHIP_EW)-1:0] rx_a_tkeep;
wire                       rx_a_tlast;

wire                       rx_b_tready;
wire                       rx_b_tvalid;
wire    [(8<<CHIP_EW)-1:0] rx_b_tdata;
wire    [(1<<CHIP_EW)-1:0] rx_b_tkeep;
wire                       rx_b_tlast;

wire                       rx_c_tready;
wire                       rx_c_tvalid;
wire    [(8<<CHIP_EW)-1:0] rx_c_tdata;
wire    [(1<<CHIP_EW)-1:0] rx_c_tkeep;
wire                       rx_c_tlast;

wire                       rx_d_tready;
wire                       rx_d_tvalid;
wire [(8<<RX_FIFO_EW)-1:0] rx_d_tdata;
wire [(1<<RX_FIFO_EW)-1:0] rx_d_tkeep;
wire                       rx_d_tlast;

wire                       rx_e_tready;
wire                       rx_e_tvalid;
wire [(8<<RX_FIFO_EW)-1:0] rx_e_tdata;
wire [(1<<RX_FIFO_EW)-1:0] rx_e_tkeep;
wire                       rx_e_tlast;

wire                       rx_f_tready;
wire                       rx_f_tvalid;
wire      [(8<<RX_EW)-1:0] rx_f_tdata;
wire      [(1<<RX_EW)-1:0] rx_f_tkeep;
wire                       rx_f_tlast;



//-----------------------------------------------------------------------------------------------------------------------------
// submodules
//-----------------------------------------------------------------------------------------------------------------------------
fifo2 # (
    .DW                  ( 1 + (1<<TX_EW) + (8<<TX_EW)           )
) u_tx_fifo2_1 (
    .rstn                ( rstn_tx                               ),
    .clk                 ( tx_clk                                ),
    .i_rdy               ( tx_tready                             ),
    .i_en                ( tx_tvalid                             ),
    .i_data              ( {tx_tlast, tx_tkeep, tx_tdata}        ),
    .o_rdy               ( tx_a_tready                           ),
    .o_en                ( tx_a_tvalid                           ),
    .o_data              ( {tx_a_tlast, tx_a_tkeep, tx_a_tdata}  )
);


axi_stream_packing #(
    .EW                  ( TX_EW                                 ),
    .SUBMIT_IMMEDIATE    ( TX_EW >= TX_FIFO_EW                   )
) u_tx_packing (
    .rstn                ( rstn_tx                               ),
    .clk                 ( tx_clk                                ),
    .i_tready            ( tx_a_tready                           ),
    .i_tvalid            ( tx_a_tvalid                           ),
    .i_tdata             ( tx_a_tdata                            ),
    .i_tkeep             ( tx_a_tkeep                            ),
    .i_tlast             ( tx_a_tlast                            ),
    .o_tready            ( tx_b_tready                           ),
    .o_tvalid            ( tx_b_tvalid                           ),
    .o_tdata             ( tx_b_tdata                            ),
    .o_tkeep             ( tx_b_tkeep                            ),
    .o_tlast             ( tx_b_tlast                            )
);


axi_stream_resizing #(
    .IEW                 ( TX_EW                                 ),
    .OEW                 ( TX_FIFO_EW                            )
) u_tx_upsizing (
    .rstn                ( rstn_tx                               ),
    .clk                 ( tx_clk                                ),
    .i_tready            ( tx_b_tready                           ),
    .i_tvalid            ( tx_b_tvalid                           ),
    .i_tdata             ( tx_b_tdata                            ),
    .i_tkeep             ( tx_b_tkeep                            ),
    .i_tlast             ( tx_b_tlast                            ),
    .o_tready            ( tx_c_tready                           ),
    .o_tvalid            ( tx_c_tvalid                           ),
    .o_tdata             ( tx_c_tdata                            ),
    .o_tkeep             ( tx_c_tkeep                            ),
    .o_tlast             (                                       )
);


fifo_async #(
    .DW                  ( (1<<TX_FIFO_EW) + (8<<TX_FIFO_EW)     ),
    .EA                  ( TX_EA                                 )
) u_tx_fifo_async (
    .i_rstn              ( rstn_tx                               ),
    .i_clk               ( tx_clk                                ),
    .i_tready            ( tx_c_tready                           ),
    .i_tvalid            ( tx_c_tvalid                           ),
    .i_tdata             ( {tx_c_tkeep, tx_c_tdata}              ),
    .o_rstn              ( rstn_ftdi                             ),
    .o_clk               ( ftdi_clk                              ),
    .o_tready            ( tx_d_tready                           ),
    .o_tvalid            ( tx_d_tvalid                           ),
    .o_tdata             ( {tx_d_tkeep, tx_d_tdata}              )
);


fifo2 # (
    .DW                  ( (1<<TX_FIFO_EW) + (8<<TX_FIFO_EW)     )
) u_tx_fifo2_2 (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_rdy               ( tx_d_tready                           ),
    .i_en                ( tx_d_tvalid                           ),
    .i_data              ( {tx_d_tkeep, tx_d_tdata}              ),
    .o_rdy               ( tx_e_tready                           ),
    .o_en                ( tx_e_tvalid                           ),
    .o_data              ( {tx_e_tkeep, tx_e_tdata}              )
);


axi_stream_resizing #(
    .IEW                 ( TX_FIFO_EW                            ),
    .OEW                 ( CHIP_EW                               )
) u_tx_downsizing (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_tready            ( tx_e_tready                           ),
    .i_tvalid            ( tx_e_tvalid                           ),
    .i_tdata             ( tx_e_tdata                            ),
    .i_tkeep             ( tx_e_tkeep                            ),
    .i_tlast             ( 1'b0                                  ),
    .o_tready            ( tx_f_tready                           ),
    .o_tvalid            ( tx_f_tvalid                           ),
    .o_tdata             ( tx_f_tdata                            ),
    .o_tkeep             ( tx_f_tkeep                            ),
    .o_tlast             (                                       )
);


fifo_delay_submit #(
    .DW                  ( (1<<CHIP_EW) + (8<<CHIP_EW)           )
) u_tx_fifo_delay_submit (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_rdy               ( tx_f_tready                           ),
    .i_en                ( tx_f_tvalid                           ),
    .i_data              ( {tx_f_tkeep, tx_f_tdata}              ),
    .o_rdy               ( tx_g_tready                           ),
    .o_en                ( tx_g_tvalid                           ),
    .o_data              ( {tx_g_tkeep, tx_g_tdata}              )
);


fifo2 # (
    .DW                  ( (1<<CHIP_EW) + (8<<CHIP_EW)           )
) u_tx_fifo2_3 (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_rdy               ( tx_g_tready                           ),
    .i_en                ( tx_g_tvalid                           ),
    .i_data              ( {tx_g_tkeep, tx_g_tdata}              ),
    .o_rdy               ( tx_h_tready                           ),
    .o_en                ( tx_h_tvalid                           ),
    .o_data              ( {tx_h_tkeep, tx_h_tdata}              )
);


ftdi_245fifo_fsm #(
    .CHIP_EW             ( CHIP_EW                               ),
    .CHIP_DRIVE_AT_NEGEDGE ( CHIP_DRIVE_AT_NEGEDGE               )
) u_ftdi_245fifo_fsm (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .tx_tready           ( tx_h_tready                           ),
    .tx_tvalid           ( tx_h_tvalid                           ),
    .tx_tdata            ( tx_h_tdata                            ),
    .tx_tkeep            ( tx_h_tkeep                            ),
    .rx_almost_full      ( rx_a_almost_full                      ),
    .rx_tvalid           ( rx_a_tvalid                           ),
    .rx_tdata            ( rx_a_tdata                            ),
    .rx_tkeep            ( rx_a_tkeep                            ),
    .rx_tlast            ( rx_a_tlast                            ),
    .ftdi_rxf_n          ( ftdi_rxf_n                            ),
    .ftdi_txe_n          ( ftdi_txe_n                            ),
    .ftdi_oe_n           ( ftdi_oe_n                             ),
    .ftdi_rd_n           ( ftdi_rd_n                             ),
    .ftdi_wr_n           ( ftdi_wr_n                             ),
    .ftdi_master_oe      ( ftdi_master_oe                        ),
    .ftdi_data_out       ( ftdi_data_out                         ),
    .ftdi_be_out         ( ftdi_be_out                           ),
    .ftdi_data_in        ( ftdi_data                             ),
    .ftdi_be_in          ( ftdi_be                               )
);


fifo4 # (
    .DW                  ( 1 + (1<<CHIP_EW) + (8<<CHIP_EW)       )
) u_rx_fifo4 (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_almost_full       ( rx_a_almost_full                      ),
    .i_rdy               (                                       ),
    .i_en                ( rx_a_tvalid                           ),
    .i_data              ( {rx_a_tlast, rx_a_tkeep, rx_a_tdata}  ),
    .o_rdy               ( rx_b_tready                           ),
    .o_en                ( rx_b_tvalid                           ),
    .o_data              ( {rx_b_tlast, rx_b_tkeep, rx_b_tdata}  )
);


axi_stream_packing #(
    .EW                  ( CHIP_EW                               )
) u_rx_packing (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_tready            ( rx_b_tready                           ),
    .i_tvalid            ( rx_b_tvalid                           ),
    .i_tdata             ( rx_b_tdata                            ),
    .i_tkeep             ( rx_b_tkeep                            ),
    .i_tlast             ( rx_b_tlast                            ),
    .o_tready            ( rx_c_tready                           ),
    .o_tvalid            ( rx_c_tvalid                           ),
    .o_tdata             ( rx_c_tdata                            ),
    .o_tkeep             ( rx_c_tkeep                            ),
    .o_tlast             ( rx_c_tlast                            )
);


axi_stream_resizing #(
    .IEW                 ( CHIP_EW                               ),
    .OEW                 ( RX_FIFO_EW                            )
) u_rx_upsizing (
    .rstn                ( rstn_ftdi                             ),
    .clk                 ( ftdi_clk                              ),
    .i_tready            ( rx_c_tready                           ),
    .i_tvalid            ( rx_c_tvalid                           ),
    .i_tdata             ( rx_c_tdata                            ),
    .i_tkeep             ( rx_c_tkeep                            ),
    .i_tlast             ( rx_c_tlast                            ),
    .o_tready            ( rx_d_tready                           ),
    .o_tvalid            ( rx_d_tvalid                           ),
    .o_tdata             ( rx_d_tdata                            ),
    .o_tkeep             ( rx_d_tkeep                            ),
    .o_tlast             ( rx_d_tlast                            )
);


fifo_async #(
    .DW                  ( 1 + (1<<RX_FIFO_EW) + (8<<RX_FIFO_EW) ),
    .EA                  ( RX_EA                                 )
) u_rx_fifo_async (
    .i_rstn              ( rstn_ftdi                             ),
    .i_clk               ( ftdi_clk                              ),
    .i_tready            ( rx_d_tready                           ),
    .i_tvalid            ( rx_d_tvalid                           ),
    .i_tdata             ( {rx_d_tlast, rx_d_tkeep, rx_d_tdata}  ),
    .o_rstn              ( rstn_rx                               ),
    .o_clk               ( rx_clk                                ),
    .o_tready            ( rx_e_tready                           ),
    .o_tvalid            ( rx_e_tvalid                           ),
    .o_tdata             ( {rx_e_tlast, rx_e_tkeep, rx_e_tdata}  )
);


axi_stream_resizing #(
    .IEW                 ( RX_FIFO_EW                            ),
    .OEW                 ( RX_EW                                 )
) u_rx_downsizing (
    .rstn                ( rstn_rx                               ),
    .clk                 ( rx_clk                                ),
    .i_tready            ( rx_e_tready                           ),
    .i_tvalid            ( rx_e_tvalid                           ),
    .i_tdata             ( rx_e_tdata                            ),
    .i_tkeep             ( rx_e_tkeep                            ),
    .i_tlast             ( rx_e_tlast                            ),
    .o_tready            ( rx_f_tready                           ),
    .o_tvalid            ( rx_f_tvalid                           ),
    .o_tdata             ( rx_f_tdata                            ),
    .o_tkeep             ( rx_f_tkeep                            ),
    .o_tlast             ( rx_f_tlast                            )
);


fifo2 #(
    .DW                  ( 1 + (1<<RX_EW) + (8<<RX_EW)           )
) u_rx_fifo2 (
    .rstn                ( rstn_rx                               ),
    .clk                 ( rx_clk                                ),
    .i_rdy               ( rx_f_tready                           ),
    .i_en                ( rx_f_tvalid                           ),
    .i_data              ( {rx_f_tlast, rx_f_tkeep, rx_f_tdata}  ),
    .o_rdy               ( rx_tready                             ),
    .o_en                ( rx_tvalid                             ),
    .o_data              ( {rx_tlast, rx_tkeep, rx_tdata}        )
);






//-----------------------------------------------------------------------------------------------------------------------------
// simulation asserts
//-----------------------------------------------------------------------------------------------------------------------------

generate if (SIMULATION) begin
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_in"          ),
        .BW                                              ( 1<<TX_EW              ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 0                     )
    ) u_axis_assert_tx_in (
        .clk                                             ( tx_clk                ),
        .tready                                          ( tx_tready             ),
        .tvalid                                          ( tx_tvalid             ),
        .tdata                                           ( tx_tdata              ),
        .tkeep                                           ( tx_tkeep              ),
        .tlast                                           ( tx_tlast              )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_a"           ),
        .BW                                              ( 1<<TX_EW              ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 0                     )
    ) u_axis_assert_tx_a (
        .clk                                             ( tx_clk                ),
        .tready                                          ( tx_a_tready           ),
        .tvalid                                          ( tx_a_tvalid           ),
        .tdata                                           ( tx_a_tdata            ),
        .tkeep                                           ( tx_a_tkeep            ),
        .tlast                                           ( tx_a_tlast            )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_b"           ),
        .BW                                              ( 1<<TX_EW              ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_tx_b (
        .clk                                             ( tx_clk                ),
        .tready                                          ( tx_b_tready           ),
        .tvalid                                          ( tx_b_tvalid           ),
        .tdata                                           ( tx_b_tdata            ),
        .tkeep                                           ( tx_b_tkeep            ),
        .tlast                                           ( tx_b_tlast            )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_c"           ),
        .BW                                              ( 1<<TX_FIFO_EW         ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_tx_c (
        .clk                                             ( tx_clk                ),
        .tready                                          ( tx_c_tready           ),
        .tvalid                                          ( tx_c_tvalid           ),
        .tdata                                           ( tx_c_tdata            ),
        .tkeep                                           ( tx_c_tkeep            ),
        .tlast                                           ( 1'b1                  )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_d"           ),
        .BW                                              ( 1<<TX_FIFO_EW         ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_tx_d (
        .clk                                             ( ftdi_clk              ),
        .tready                                          ( tx_d_tready           ),
        .tvalid                                          ( tx_d_tvalid           ),
        .tdata                                           ( tx_d_tdata            ),
        .tkeep                                           ( tx_d_tkeep            ),
        .tlast                                           ( 1'b1                  )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_e"           ),
        .BW                                              ( 1<<TX_FIFO_EW         ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_tx_e (
        .clk                                             ( ftdi_clk              ),
        .tready                                          ( tx_e_tready           ),
        .tvalid                                          ( tx_e_tvalid           ),
        .tdata                                           ( tx_e_tdata            ),
        .tkeep                                           ( tx_e_tkeep            ),
        .tlast                                           ( 1'b1                  )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_f"           ),
        .BW                                              ( 1<<CHIP_EW            ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_tx_f (
        .clk                                             ( ftdi_clk              ),
        .tready                                          ( tx_f_tready           ),
        .tvalid                                          ( tx_f_tvalid           ),
        .tdata                                           ( tx_f_tdata            ),
        .tkeep                                           ( tx_f_tkeep            ),
        .tlast                                           ( 1'b1                  )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_g"           ),
        .BW                                              ( 1<<CHIP_EW            ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_tx_g (
        .clk                                             ( ftdi_clk              ),
        .tready                                          ( tx_g_tready           ),
        .tvalid                                          ( tx_g_tvalid           ),
        .tdata                                           ( tx_g_tdata            ),
        .tkeep                                           ( tx_g_tkeep            ),
        .tlast                                           ( 1'b1                  )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_tx_h"           ),
        .BW                                              ( 1<<CHIP_EW            ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 0                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_tx_h (
        .clk                                             ( ftdi_clk              ),
        .tready                                          ( tx_h_tready           ),
        .tvalid                                          ( tx_h_tvalid           ),
        .tdata                                           ( tx_h_tdata            ),
        .tkeep                                           ( tx_h_tkeep            ),
        .tlast                                           ( 1'b1                  )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_rx_b"           ),
        .BW                                              ( 1<<CHIP_EW            ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 0                     ),
        .ASSERT_PACKED                                   ( 0                     )
    ) u_axis_assert_rx_b (
        .clk                                             ( ftdi_clk              ),
        .tready                                          ( rx_b_tready           ),
        .tvalid                                          ( rx_b_tvalid           ),
        .tdata                                           ( rx_b_tdata            ),
        .tkeep                                           ( rx_b_tkeep            ),
        .tlast                                           ( rx_b_tlast            )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_rx_c"           ),
        .BW                                              ( 1<<CHIP_EW            ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_rx_c (
        .clk                                             ( ftdi_clk              ),
        .tready                                          ( rx_c_tready           ),
        .tvalid                                          ( rx_c_tvalid           ),
        .tdata                                           ( rx_c_tdata            ),
        .tkeep                                           ( rx_c_tkeep            ),
        .tlast                                           ( rx_c_tlast            )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_rx_d"           ),
        .BW                                              ( 1<<RX_FIFO_EW         ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_rx_d (
        .clk                                             ( ftdi_clk              ),
        .tready                                          ( rx_d_tready           ),
        .tvalid                                          ( rx_d_tvalid           ),
        .tdata                                           ( rx_d_tdata            ),
        .tkeep                                           ( rx_d_tkeep            ),
        .tlast                                           ( rx_d_tlast            )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_rx_e"           ),
        .BW                                              ( 1<<RX_FIFO_EW         ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_rx_e (
        .clk                                             ( rx_clk                ),
        .tready                                          ( rx_e_tready           ),
        .tvalid                                          ( rx_e_tvalid           ),
        .tdata                                           ( rx_e_tdata            ),
        .tkeep                                           ( rx_e_tkeep            ),
        .tlast                                           ( rx_e_tlast            )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_rx_f"           ),
        .BW                                              ( 1<<RX_EW              ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 1                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_rx_f (
        .clk                                             ( rx_clk                ),
        .tready                                          ( rx_f_tready           ),
        .tvalid                                          ( rx_f_tvalid           ),
        .tdata                                           ( rx_f_tdata            ),
        .tkeep                                           ( rx_f_tkeep            ),
        .tlast                                           ( rx_f_tlast            )
    );
    
    axi_stream_assert #(
        .NAME                                            ( "axis_rx_out"         ),
        .BW                                              ( 1<<RX_EW              ),
        .ASSERT_SLAVE_NOT_CHANGE_WHEN_HANDSHAKE_FAILED   ( 0                     ),
        .ASSERT_PACKED                                   ( 1                     )
    ) u_axis_assert_rx_out (
        .clk                                             ( rx_clk                ),
        .tready                                          ( rx_tready             ),
        .tvalid                                          ( rx_tvalid             ),
        .tdata                                           ( rx_tdata              ),
        .tkeep                                           ( rx_tkeep              ),
        .tlast                                           ( rx_tlast              )
    );
end endgenerate



endmodule
