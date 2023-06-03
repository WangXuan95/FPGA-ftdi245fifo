
//--------------------------------------------------------------------------------------------------------
// Module  : fifo4
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: fifo with capacity=4, 
//           all outputs are register-out, which can be inserted into the stream chain to improve timing
//           it has a 'almost_full' pin to report half-full (already 2 data in the fifo)
//--------------------------------------------------------------------------------------------------------

module fifo4 # (
    parameter            DW = 8
) (
    input  wire          rstn,
    input  wire          clk,
    output wire          i_almost_full,
    output wire          i_rdy,
    input  wire          i_en,
    input  wire [DW-1:0] i_data,
    input  wire          o_rdy,
    output wire          o_en,
    output wire [DW-1:0] o_data
);


reg       data1_en   = 1'b0;                 // fifo data1 exist
reg       data2_en   = 1'b0;                 // fifo data2 exist
reg       data3_en   = 1'b0;                 // fifo data3 exist
reg       data4_en   = 1'b0;                 // fifo data4 exist
reg [DW-1:0] data1   = 0;                    // fifo data1
reg [DW-1:0] data2   = 0;                    // fifo data2
reg [DW-1:0] data3   = 0;                    // fifo data3
reg [DW-1:0] data4   = 0;                    // fifo data4

assign    i_rdy          = data4_en;
assign    i_almost_full  = data2_en;

assign    o_en           = data1_en;
assign    o_data         = data1;

always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        data1_en <= 1'b0;
        data2_en <= 1'b0;
        data3_en <= 1'b0;
        data4_en <= 1'b0;
        data1    <= 0;
        data2    <= 0;
        data3    <= 0;
        data4    <= 0;
    end else begin
        if          (data4_en) begin
            if (o_rdy) begin
                data4_en              <= 1'b0;
                {data1, data2, data3} <= {data2, data3, data4};
            end
            
        end else if (data3_en) begin
            if (o_rdy & i_en) begin
                {data1, data2, data3} <= {data2, data3, i_data};
            end else if (o_rdy) begin
                data3_en              <= 1'b0;
                {data1, data2}        <= {data2, data3};
            end else if (i_en) begin
                data4_en              <= 1'b1;
                data4                 <= i_data;
            end
            
        end else if (data2_en) begin
            if (o_rdy & i_en) begin
                {data1, data2}        <= {data2, i_data};
            end else if (o_rdy) begin
                data2_en              <= 1'b0;
                data1                 <= data2;
            end else if (i_en) begin
                data3_en              <= 1'b1;
                data3                 <= i_data;
            end
            
        end else if (data1_en) begin
            if (o_rdy & i_en) begin
                data1                 <= i_data;
            end else if (o_rdy) begin
                data1_en              <= 1'b0;
            end else if (i_en) begin
                data2_en              <= 1'b1;
                data2                 <= i_data;
            end
        
        end else begin
            if (i_en) begin
                data1_en              <= 1'b1;
                data1                 <= i_data;
            end
        end
    end

endmodule
