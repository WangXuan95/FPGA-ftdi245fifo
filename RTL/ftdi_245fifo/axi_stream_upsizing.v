
//--------------------------------------------------------------------------------------------------------
// Module  : axi_stream_upsizing
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: AXI-stream upsizing or downsizing,
//           see AMBA 4 AXI4-stream Protocol Version: 1.0 Specification -> 2.3.3 -> upsizing considerations
//--------------------------------------------------------------------------------------------------------

module axi_stream_upsizing #(
    parameter IEW = 0,                       // input width,  0=1Byte, 1=2Byte, 2=4Byte, 3=8Bytes, 4=16Bytes, ...
    parameter OEW = 0                        // output width, 0=1Byte, 1=2Byte, 2=4Byte, 3=8Bytes, 4=16Bytes, ...
                                             // OEW must > IEW
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
    output reg                 o_tvalid,
    output reg  [(8<<OEW)-1:0] o_tdata,
    output reg  [(1<<OEW)-1:0] o_tkeep,
    output reg                 o_tlast
);



localparam DIFF_EW = (OEW>IEW) ? (OEW-IEW) : 1;

localparam [DIFF_EW-1:0] IDX_ONE   = 1;
localparam [DIFF_EW-1:0] IDX_FIRST = {DIFF_EW{1'b0}};
localparam [DIFF_EW-1:0] IDX_LAST  = ~IDX_FIRST;

reg        [DIFF_EW-1:0] idx       = IDX_FIRST;

reg                      tmp_full  = 1'b0;
reg       [(8<<OEW)-1:0] tmp_data  = {(8<<OEW){1'b0}};
reg       [(1<<OEW)-1:0] tmp_keep  = {(1<<OEW){1'b0}};
reg                      tmp_last  = 1'b0;


initial                   o_tvalid = 1'b0;
initial                   o_tdata  = {(8<<OEW){1'b0}};
initial                   o_tkeep  = {(1<<OEW){1'b0}};
initial                   o_tlast  = 1'b0;


always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        idx      <= IDX_FIRST;
        
        tmp_full <= 1'b0;
        tmp_data <= {(8<<OEW){1'b0}};
        tmp_keep <= {(1<<OEW){1'b0}};
        tmp_last <= 1'b0;
        
        o_tvalid <= 1'b0;
        o_tdata  <= {(8<<OEW){1'b0}};
        o_tkeep  <= {(1<<OEW){1'b0}};
        o_tlast  <= 1'b0;
        
    end else begin
            
        if (tmp_full) begin                                           // enough for commit a output
            if (o_tready | ~o_tvalid) begin
                idx      <= IDX_FIRST;
                
                tmp_full <= 1'b0;
                tmp_data <= {(8<<OEW){1'b0}};
                tmp_keep <= {(1<<OEW){1'b0}};
                tmp_last <= 1'b0;
                
                o_tvalid <= 1'b1;
                o_tdata  <= tmp_data;
                o_tkeep  <= tmp_keep;
                o_tlast  <= tmp_last;
            end
        
        end else if (idx == IDX_LAST) begin                           // enough for commit a output
            if (o_tready)                                             // output handshake success, deassert o_tvalid
                o_tvalid <= 1'b0;
                
            if (o_tready | ~o_tvalid) begin
                if (i_tvalid) begin
                    idx      <= IDX_FIRST;
                    
                    tmp_full <= 1'b0;
                    tmp_data <= {(8<<OEW){1'b0}};
                    tmp_keep <= {(1<<OEW){1'b0}};
                    tmp_last <= 1'b0;
                    
                    o_tvalid <= 1'b1;
                    o_tdata  <= tmp_data;
                    o_tdata[idx*(8<<IEW) +: (8<<IEW)] <= i_tdata;
                    o_tkeep  <= tmp_keep;
                    o_tkeep[idx*(1<<IEW) +: (1<<IEW)] <= i_tkeep;
                    o_tlast  <= tmp_last | i_tlast;
                end
            end
            
        end else begin
            if (o_tready)                                             // output handshake success, deassert o_tvalid
                o_tvalid <= 1'b0;
            
            if (i_tvalid) begin
                idx      <= idx + IDX_ONE;
                
                tmp_full                           <= i_tlast;
                tmp_data[idx*(8<<IEW) +: (8<<IEW)] <= i_tdata;
                tmp_keep[idx*(1<<IEW) +: (1<<IEW)] <= i_tkeep;
                tmp_last                           <= tmp_last | i_tlast;
            end
        end
    end


assign i_tready = tmp_full         ? 1'b0                   :
                 (idx == IDX_LAST) ? (o_tready | ~o_tvalid) :
                                     1'b1                   ;


endmodule
