
//--------------------------------------------------------------------------------------------------------
// Module  : axi_stream_resizing
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: AXI-stream upsizing or downsizing,
//           see AMBA 4 AXI4-stream Protocol Version: 1.0 Specification -> 2.3.3 -> downsizing considerations / upsizing considerations
//--------------------------------------------------------------------------------------------------------

module axi_stream_resizing #(
    parameter IEW = 0,                       // input width,  0=1Byte, 1=2Byte, 2=4Byte, 3=8Bytes, 4=16Bytes, ...
    parameter OEW = 0                        // output width, 0=1Byte, 1=2Byte, 2=4Byte, 3=8Bytes, 4=16Bytes, ...
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


generate if (IEW < OEW) begin
    
    axi_stream_upsizing #(
        .IEW             ( IEW                ),
        .OEW             ( OEW                )
    ) u_axi_stream_upsizing (
        .rstn            ( rstn               ),
        .clk             ( clk                ),
        .i_tready        ( i_tready           ),
        .i_tvalid        ( i_tvalid           ),
        .i_tdata         ( i_tdata            ),
        .i_tkeep         ( i_tkeep            ),
        .i_tlast         ( i_tlast            ),
        .o_tready        ( o_tready           ),
        .o_tvalid        ( o_tvalid           ),
        .o_tdata         ( o_tdata            ),
        .o_tkeep         ( o_tkeep            ),
        .o_tlast         ( o_tlast            )
    );
    
end else if (IEW > OEW) begin

    axi_stream_downsizing #(
        .IEW             ( IEW                ),
        .OEW             ( OEW                )
    ) u_axi_stream_downsizing (
        .rstn            ( rstn               ),
        .clk             ( clk                ),
        .i_tready        ( i_tready           ),
        .i_tvalid        ( i_tvalid           ),
        .i_tdata         ( i_tdata            ),
        .i_tkeep         ( i_tkeep            ),
        .i_tlast         ( i_tlast            ),
        .o_tready        ( o_tready           ),
        .o_tvalid        ( o_tvalid           ),
        .o_tdata         ( o_tdata            ),
        .o_tkeep         ( o_tkeep            ),
        .o_tlast         ( o_tlast            )
    );

end else begin // (IEW==OEW)
    
    assign i_tready = o_tready;
    assign o_tvalid = i_tvalid;
    assign o_tdata  = i_tdata;
    assign o_tkeep  = i_tkeep;
    assign o_tlast  = i_tlast;
    
end endgenerate


endmodule
