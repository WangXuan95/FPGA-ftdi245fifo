
//--------------------------------------------------------------------------------------------------------
// Module  : fifo_delay_submit
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: 
//--------------------------------------------------------------------------------------------------------

module fifo_delay_submit #(
    parameter            DW = 8      // AXI byte width is 1<<BW, bit width is 8<<BW
) (
    input  wire          rstn,
    input  wire          clk,
    // AXI-stream slave
    output wire          i_rdy,
    input  wire          i_en,
    input  wire [DW-1:0] i_data,
    // AXI-stream master
    input  wire          o_rdy,
    output reg           o_en,
    output reg  [DW-1:0] o_data
);


localparam [10:0] SUBMIT_CHUNK = 11'd128;


reg  [10:0] wptr           = 11'd0;
reg  [10:0] wptr_submit    = 11'd0;
reg  [10:0] wptr_submit_d  = 11'd0;
reg  [10:0] rptr           = 11'd0;
wire [10:0] rptr_next = (o_en & o_rdy) ? (rptr+11'd1) : rptr;

reg  [DW-1:0] buffer [1023:0];

reg  [10:0] count = 11'd0;

assign i_rdy = ( wptr != {~rptr[10], rptr[9:0]} );


always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        wptr_submit    <= 11'h0;
        wptr_submit_d  <= 11'h0;
        count          <= 11'd0;
    end else begin
        wptr_submit_d <= wptr_submit;
        if ( (wptr-wptr_submit) > SUBMIT_CHUNK ) begin
            wptr_submit <= wptr;
            count <= 11'd0;
        end else begin
            count <= (i_en & i_rdy) ? 11'd0 : (count+11'd1);
            if (count == 11'd2047)
                wptr_submit <= wptr;
        end
    end

always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        wptr <= 11'h0;
    end else begin
        if (i_en & i_rdy)
            wptr <= wptr + 11'h1;
    end

always @ (posedge clk)
    if (i_en & i_rdy)
        buffer[wptr[9:0]] <= i_data;



always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        rptr <= 11'h0;
        o_en <= 1'b0;
    end else begin
        rptr <= rptr_next;
        o_en <= (rptr_next != wptr_submit_d);
    end

always @ (posedge clk)
    o_data <= buffer[rptr_next[9:0]];


endmodule
