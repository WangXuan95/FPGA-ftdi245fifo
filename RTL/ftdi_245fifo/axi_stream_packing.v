
//--------------------------------------------------------------------------------------------------------
// Module  : axi_stream_packing
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: AXI-stream packing,
//           see AMBA 4 AXI4-stream Protocol Version: 1.0 Specification -> 2.3.3 -> packing
//--------------------------------------------------------------------------------------------------------

module axi_stream_packing #(
    parameter                 EW = 2,     // AXI byte width is 1<<BW, bit width is 8<<BW
    parameter   SUBMIT_IMMEDIATE = 0      // if SUBMIT_IMMEDIATE=0, This module may retain data (even if there is enough bytes to submit). It will only completely clear retained data when encountering a tlast. The purpose is to correctly pack tlast into the tail of the packet, even if tkeep=0 when tlast=1.
                                          // if SUBMIT_IMMEDIATE=1, This module will not retain data, once there is enough bytes to submit, it will output. However, o_tlast will be not avaiable (stuck to 1)
) (
    input  wire               rstn,
    input  wire               clk,
    // AXI-stream slave
    output wire               i_tready,
    input  wire               i_tvalid,
    input  wire [(8<<EW)-1:0] i_tdata,
    input  wire [(1<<EW)-1:0] i_tkeep,
    input  wire               i_tlast,
    // AXI-stream master
    input  wire               o_tready,
    output reg                o_tvalid,
    output reg  [(8<<EW)-1:0] o_tdata,
    output reg  [(1<<EW)-1:0] o_tkeep,
    output wire               o_tlast
);



localparam      [(1<<EW)-1:0] TKEEP_ALL_ZERO = 0;
localparam      [(1<<EW)-1:0] TKEEP_ALL_ONE  = ~TKEEP_ALL_ZERO;



localparam [EW  :0] COUNT_ONE = 1;
localparam [EW+1:0] COUNT_MAX = {1'b1, {(EW+1){1'b0}}};           // equal to 1<<(1+EW)
localparam [EW+1:0] POW_EW_W  = COUNT_MAX >> 1;                   // equal to 1<<EW
localparam [EW  :0] POW_EW    = POW_EW_W[EW:0];                   // equal to 1<<EW



reg  [(8<<EW)-1:0] i_bytes;                                       // not real register : input packed bytes
reg  [    EW   :0] i_count;                                       // not real register : input byte count, range : 0 ~ (1<<EW)

integer i;

always @ (*) begin                                                // (i_tkeep, i_tdata) -> (i_count, i_bytes)
    i_bytes = 0;
    i_count = 0;
    for (i=0; i<(1<<EW); i=i+1)
        if (i_tkeep[i]) begin
            i_bytes[i_count*8 +: 8] = i_tdata[i*8 +: 8];
            i_count = i_count + COUNT_ONE;
        end
end





reg  [      EW   :0] r_count = 0;                                 // range : 0 ~ (1<<EW)
reg  [  (8<<EW)-1:0] r_bytes; 

wire [      EW+1 :0] t_count = {1'b0,i_count} + {1'b0,r_count};   // range : 0 ~ (2<<EW)
reg  [2*(8<<EW)-1:0] t_bytes;                                     // not real register

always @ (*) begin
    t_bytes = i_bytes;
    t_bytes = t_bytes << (8*r_count);
    t_bytes = t_bytes | r_bytes;
end


//always @ (posedge clk) if (r_count > POW_EW) begin $display("***error : axi_stream_packing_imm"); $stop; end




reg                  unflushed = 1'b0;
reg                  r_tlast   = 1'b0;

always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        unflushed <= 1'b0;
        r_count <= 0;
        r_bytes <= 0;
        o_tvalid <= 1'b0;
        r_tlast  <= 1'b0;
        o_tdata  <= 0;
        o_tkeep  <= TKEEP_ALL_ZERO;
    end else begin
        if (o_tready)
            o_tvalid <= 1'b0;
        if (o_tready | ~o_tvalid) begin                                  // o_tready=1 or o_tvalid=0, then it is available to put a new data to output
            if (unflushed) begin
                unflushed <= 1'b0;
                r_count <= 0;
                r_bytes <= 0;
                o_tvalid <= 1'b1;
                r_tlast  <= 1'b1;
                o_tdata  <= r_bytes;
                o_tkeep  <= ~(TKEEP_ALL_ONE << r_count);                 // r_count of bytes is available, so there will be r_count of '1' on tkeep
            end else begin
                if (i_tvalid) begin
                    if (t_count > POW_EW_W) begin                        // More than (1<<EW) bytes have been saved, so we must submit
                        unflushed <= i_tlast;                            // if meet tlast, the remain bytes must also be submitted, so let unflushed=1, to submit it next cycle
                        r_count  <= t_count[EW:0] - POW_EW;              // Equivalent to : r_count <= t_count - (1<<EW)
                        {r_bytes, o_tdata} <= t_bytes;
                        o_tvalid <= 1'b1;
                        r_tlast  <= 1'b0;
                        o_tkeep  <= TKEEP_ALL_ONE;                       // all bytes valid
                    end else if (i_tlast ||                              // not enough bytes for submit, but meet i_tlast, may also need to submit
                                 (SUBMIT_IMMEDIATE & (t_count == POW_EW_W)) ) begin  // if SUBMIT_IMMEDIATE=1 and just have enough bytes, also submit
                        r_count  <= 0;
                        r_bytes  <= 0;
                        o_tvalid <= (t_count != 0);                      // for a spectcial case of zero-bytes packet, omit this packet (do not submit), otherwise submit
                        r_tlast  <= (t_count != 0) & i_tlast;
                        o_tdata  <= t_bytes[(8<<EW)-1:0];
                        o_tkeep  <= ~(TKEEP_ALL_ONE << t_count);         // t_count bytes valid
                    end else begin                                       // not enough bytes, and not meet i_tlast, dont submit
                        r_count  <= t_count[EW:0];
                        r_bytes  <= t_bytes[(8<<EW)-1:0];
                        o_tvalid <= 1'b0;
                        r_tlast  <= 1'b0;
                        o_tdata  <= 0;
                        o_tkeep  <= TKEEP_ALL_ZERO;
                    end
                end
                // assign i_tready = 1;
            end
        end
    end


initial o_tvalid = 1'b0;
initial o_tdata  = 0;
initial o_tkeep  = TKEEP_ALL_ZERO;

assign  o_tlast  = SUBMIT_IMMEDIATE ? 1'b1 : r_tlast;

assign  i_tready = (o_tready | ~o_tvalid) & (~unflushed);


endmodule
