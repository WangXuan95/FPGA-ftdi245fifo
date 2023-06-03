
//--------------------------------------------------------------------------------------------------------
// Module  : fifo2
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: fifo with capacity=2, 
//           all outputs are register-out, which can be inserted into the stream chain to improve timing
//--------------------------------------------------------------------------------------------------------

module fifo2 # (
    parameter            DW = 8
) (
    input  wire          rstn,
    input  wire          clk,
    output wire          i_rdy,
    input  wire          i_en,
    input  wire [DW-1:0] i_data,
    input  wire          o_rdy,
    output wire          o_en,
    output wire [DW-1:0] o_data
);


reg       data1_en   = 1'b0;                 // fifo data1 exist
reg       data2_en_n = 1'b1;                 // fifo data2 exist (n)
reg [DW-1:0] data1   = 0;                    // fifo data1
reg [DW-1:0] data2   = 0;                    // fifo data2

assign    i_rdy  = data2_en_n;               // input ready when not full
assign    o_en   = data1_en;                 // output valid when not empty
assign    o_data = data1;

always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        data1_en   <= 1'b0;
        data2_en_n <= 1'b1;
        data1      <= 0;
        data2      <= 0;
    end else begin
        if          (~data2_en_n) begin      // full (data2 exist)
            if (o_rdy) begin                 // allow output
                data2_en_n <= 1'b1;          // set data2 to not exist
                data1      <= data2;         // data2 -> data1
            end
        end else if (data1_en) begin         // half full (data1 exist, but data2 not exist)
            if (o_rdy & i_en) begin          // allow both output and input simultaneously
                data1      <= i_data;        // i_data -> data1
            end else if (o_rdy) begin        // only allow output
                data1_en   <= 1'b0;          // set data1 to not exist
            end else if (i_en) begin         // only allow input
                data2_en_n <= 1'b0;          // set data1 to exist
                data2      <= i_data;        // i_data -> data2
            end
        end else begin                       // empty (both data1 & data2 not exist)
            if (i_en) begin                  // allow input
                data1_en   <= 1'b1;          // set data1 to exist
                data1      <= i_data;        // i_data -> data1
            end
        end
    end

endmodule
