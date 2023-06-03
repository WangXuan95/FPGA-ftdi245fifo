
//--------------------------------------------------------------------------------------------------------
// Module  : resetn_sync
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: Synchronize the asynchronous reset signal to the local clock domain (asynchronous reset, synchronous release)
//           called by ftdi_245fifo.v
//--------------------------------------------------------------------------------------------------------

module resetn_sync (
    input  wire  rstn_async,
    input  wire  clk,
    output wire  rstn
);

reg [3:0] rstn_shift = 4'd0;

always @ (posedge clk or negedge rstn_async)
    if (~rstn_async)
        rstn_shift <= 4'd0;
    else
        rstn_shift <= {1'b1, rstn_shift[3:1]};

assign rstn = rstn_shift[0];

endmodule
