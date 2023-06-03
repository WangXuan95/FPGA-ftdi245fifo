
//--------------------------------------------------------------------------------------------------------
// Module  : fifo_async
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: asynchronous fifo
//--------------------------------------------------------------------------------------------------------

module fifo_async #(
    parameter   DW = 8,
    parameter   EA = 10
)(
    input  wire          i_rstn,
    input  wire          i_clk,
    output wire          i_tready,
    input  wire          i_tvalid,
    input  wire [DW-1:0] i_tdata,
    input  wire          o_rstn,
    input  wire          o_clk,
    input  wire          o_tready,
    output reg           o_tvalid,
    output reg  [DW-1:0] o_tdata
);



reg  [DW-1:0] buffer [(1<<EA)-1:0];  // may automatically synthesize to BRAM

reg  [EA:0] wptr=0, wq_wptr_grey=0, rq1_wptr_grey=0, rq2_wptr_grey=0;
reg  [EA:0] rptr=0, rq_rptr_grey=0, wq1_rptr_grey=0, wq2_rptr_grey=0;
wire [EA:0] rptr_next = (o_tvalid & o_tready) ? (rptr + {{EA{1'b0}}, 1'b1}) : rptr;

wire [EA:0] wptr_grey      = (wptr >> 1)      ^ wptr;
wire [EA:0] rptr_grey      = (rptr >> 1)      ^ rptr;
wire [EA:0] rptr_next_grey = (rptr_next >> 1) ^ rptr_next;

always @ (posedge i_clk or negedge i_rstn)
    if(~i_rstn)
        wq_wptr_grey <= 0;
    else
        wq_wptr_grey <= wptr_grey;

always @ (posedge o_clk or negedge o_rstn)
    if(~o_rstn)
        {rq2_wptr_grey, rq1_wptr_grey} <= 0;
    else
        {rq2_wptr_grey, rq1_wptr_grey} <= {rq1_wptr_grey, wq_wptr_grey};

always @ (posedge o_clk or negedge o_rstn)
    if(~o_rstn)
        rq_rptr_grey <= 0;
    else
        rq_rptr_grey <= rptr_grey;

always @ (posedge i_clk or negedge i_rstn)
    if(~i_rstn)
        {wq2_rptr_grey, wq1_rptr_grey} <= 0;
    else
        {wq2_rptr_grey, wq1_rptr_grey} <= {wq1_rptr_grey, rq_rptr_grey};

wire w_full  = (wq2_rptr_grey == {~wptr_grey[EA:EA-1], wptr_grey[EA-2:0]} );
wire r_empty = (rq2_wptr_grey == rptr_next_grey                           );

assign i_tready = ~w_full;



always @ (posedge i_clk or negedge i_rstn)
    if(~i_rstn) begin
        wptr <= 0;
    end else begin
        if(i_tvalid & ~w_full)
            wptr <= wptr + {{EA{1'b0}}, 1'b1};
    end

always @ (posedge i_clk)
    if(i_tvalid & ~w_full)
        buffer[wptr[EA-1:0]] <= i_tdata;



initial o_tvalid = 1'b0;

always @ (posedge o_clk or negedge o_rstn)
    if (~o_rstn) begin
        rptr    <= 0;
        o_tvalid <= 1'b0;
    end else begin
        rptr    <= rptr_next;
        o_tvalid <= ~r_empty;
    end

always @ (posedge o_clk)
    o_tdata <= buffer[rptr_next[EA-1:0]];


endmodule
