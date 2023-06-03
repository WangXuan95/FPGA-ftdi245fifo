
//--------------------------------------------------------------------------------------------------------
// Module  : axi_stream_downsizing
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: AXI-stream upsizing or downsizing,
//           see AMBA 4 AXI4-stream Protocol Version: 1.0 Specification -> 2.3.3 -> downsizing considerations
//--------------------------------------------------------------------------------------------------------

module axi_stream_downsizing #(
    parameter IEW = 0,                       // input width,  0=1Byte, 1=2Byte, 2=4Byte, 3=8Bytes, 4=16Bytes, ...
    parameter OEW = 0                        // output width, 0=1Byte, 1=2Byte, 2=4Byte, 3=8Bytes, 4=16Bytes, ...
                                             // OEW must < IEW
) (
    input  wire                rstn,
    input  wire                clk,
    // AXI-stream slave
    output wire                i_tready,
    input  wire                i_tvalid,
    input  wire [(8<<IEW)-1:0] i_tdata,
    input  wire [(1<<IEW)-1:0] i_tkeep,
    input  wire                i_tlast,
    // AXI-stream master
    input  wire                o_tready,
    output wire                o_tvalid,
    output wire [(8<<OEW)-1:0] o_tdata,
    output wire [(1<<OEW)-1:0] o_tkeep,
    output wire                o_tlast
);



reg  [(8<<IEW)-1:0] tmp_data = {(8<<IEW){1'b0}};
reg  [(1<<IEW)-1:0] tmp_keep = {(1<<IEW){1'b0}};
reg                 tmp_last = 1'b0;

wire [(8<<IEW)-1:0] tmp_data_next;
wire [(1<<IEW)-1:0] tmp_keep_next;

assign {tmp_data_next, o_tdata} = {{(8<<OEW){1'b0}}, tmp_data};
assign {tmp_keep_next, o_tkeep} = {{(1<<OEW){1'b0}}, tmp_keep};
assign                 o_tlast  = ( tmp_keep_next == {(1<<IEW){1'b0}} ) ? tmp_last : 1'b0;
assign                 o_tvalid = (|o_tkeep);

assign                 i_tready = ( tmp_keep      == {(1<<IEW){1'b0}} )  ?  1'b1     :
                                  ( tmp_keep_next == {(1<<IEW){1'b0}} )  ?  o_tready :
                                                                            1'b0     ;


always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        tmp_data <= {(8<<IEW){1'b0}};
        tmp_keep <= {(1<<IEW){1'b0}};
        tmp_last <= 1'b0;
    end else begin
        if          ( tmp_keep      == {(1<<IEW){1'b0}} ) begin           // no data in tmp
            // i_tready = 1
            if (i_tvalid) begin
                tmp_data <= i_tdata;
                tmp_keep <= i_tkeep;
                tmp_last <= i_tlast;
            end
        end else if ( tmp_keep_next == {(1<<IEW){1'b0}} ) begin           // only one data in tmp
            if (o_tready) begin
                // i_tready = 1
                if (i_tvalid) begin
                    tmp_data <= i_tdata;
                    tmp_keep <= i_tkeep;
                    tmp_last <= i_tlast;
                end else begin
                    tmp_data <= tmp_data_next;
                    tmp_keep <= tmp_keep_next;
                end
            end
        end else if (o_tready | ~o_tvalid) begin
            tmp_data <= tmp_data_next;
            tmp_keep <= tmp_keep_next;
        end
    end


endmodule
