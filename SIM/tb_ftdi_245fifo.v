
//--------------------------------------------------------------------------------------------------------
// Module  : tb_ftdi_245fifo
// Type    : simulation, top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: top-level testbench for ftdi_245fifo_top
//--------------------------------------------------------------------------------------------------------

`timescale 1ps/1ps

module tb_ftdi_245fifo ();


// -----------------------------------------------------------------------------------------------------------------------------
// simulation control
// -----------------------------------------------------------------------------------------------------------------------------
initial $dumpvars(0, tb_ftdi_245fifo);

//initial #(1000 * 1000 * 1000 * 1000) $finish;
initial #(       100 * 1000 * 1000) $finish;
//        ms     us     ns     ps


// -----------------------------------------------------------------------------------------------------------------------------
// FTDI chip signals
// -----------------------------------------------------------------------------------------------------------------------------
localparam              CHIP_TYPE = "FTx232H";          // can be "FTx232H", "FT600", "FT601"

localparam              CHIP_EW   = (CHIP_TYPE=="FT601") ? 2 : (CHIP_TYPE=="FT600") ? 1 : 0;

wire                    ftdi_clk;
wire                    ftdi_rxf_n;
wire                    ftdi_txe_n;
wire                    ftdi_oe_n;
wire                    ftdi_rd_n;
wire                    ftdi_wr_n;
tri  [(8<<CHIP_EW)-1:0] ftdi_data;
tri  [(1<<CHIP_EW)-1:0] ftdi_be;



// -----------------------------------------------------------------------------------------------------------------------------
// user signals(loopback)
// -----------------------------------------------------------------------------------------------------------------------------
localparam              USER_EW = 0;

wire                    tready;
wire                    tvalid;
wire [(8<<USER_EW)-1:0] tdata;
wire [(1<<USER_EW)-1:0] tkeep;
wire                    tlast;



// -----------------------------------------------------------------------------------------------------------------------------
// user clock
// -----------------------------------------------------------------------------------------------------------------------------
reg rstn = 1'b0;
reg clk  = 1'b0;
always #5000 clk = ~clk;           // 100MHz
initial begin repeat(4) @(posedge clk); rstn<=1'b1; end



// -----------------------------------------------------------------------------------------------------------------------------
// generate a simple FT232H behavior
// -----------------------------------------------------------------------------------------------------------------------------
tb_ftdi_chip_model # (
    .CHIP_EW        ( CHIP_EW        )
) u_tb_ftdi_chip_model (
    .ftdi_clk       ( ftdi_clk       ),
    .ftdi_rxf_n     ( ftdi_rxf_n     ),
    .ftdi_txe_n     ( ftdi_txe_n     ),
    .ftdi_oe_n      ( ftdi_oe_n      ),
    .ftdi_rd_n      ( ftdi_rd_n      ),
    .ftdi_wr_n      ( ftdi_wr_n      ),
    .ftdi_data      ( ftdi_data      ),
    .ftdi_be        ( ftdi_be        )
);



// -----------------------------------------------------------------------------------------------------------------------------
// ftdi_245fifo_top module
// -----------------------------------------------------------------------------------------------------------------------------
ftdi_245fifo_top #(
    .TX_EW          ( USER_EW        ),
    .TX_EA          ( 10             ),
    .RX_EW          ( USER_EW        ),
    .RX_EA          ( 10             ),
    .CHIP_TYPE      ( CHIP_TYPE      ),
    .SIMULATION     ( 1              )
) u_ftdi_245fifo_top (
    .rstn_async     ( rstn           ),
    // user write interface, loopback connect to user read  interface
    .tx_clk         ( clk            ),
    .tx_tready      ( tready         ),
    .tx_tvalid      ( tvalid         ),
    .tx_tdata       ( tdata          ),
    .tx_tkeep       ( tkeep          ),
    .tx_tlast       ( tlast          ),
    // user read  interface, loopback connect to user write interface
    .rx_clk         ( clk            ),
    .rx_tready      ( tready         ),
    .rx_tvalid      ( tvalid         ),
    .rx_tdata       ( tdata          ),
    .rx_tkeep       ( tkeep          ),
    .rx_tlast       ( tlast          ),
    // FTDI USB interface, must connect to FT232H pins
    .ftdi_clk       ( ftdi_clk       ),
    .ftdi_rxf_n     ( ftdi_rxf_n     ),
    .ftdi_txe_n     ( ftdi_txe_n     ),
    .ftdi_oe_n      ( ftdi_oe_n      ),
    .ftdi_rd_n      ( ftdi_rd_n      ),
    .ftdi_wr_n      ( ftdi_wr_n      ),
    .ftdi_data      ( ftdi_data      ),
    .ftdi_be        ( ftdi_be        )
);



endmodule
