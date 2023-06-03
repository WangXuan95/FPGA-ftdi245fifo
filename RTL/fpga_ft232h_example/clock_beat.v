
//--------------------------------------------------------------------------------------------------------
// Module  : clock_beat
// Type    : synthesizable, FPGA's top, IP's example design
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: When clk runs, beat signal will blink
//--------------------------------------------------------------------------------------------------------

module clock_beat # (
    parameter  CLK_FREQ = 50000000,    // Unit:Hz
    parameter BEAT_FREQ = 5            // Unit:Hz
) (
    input  wire clk,
    output reg  beat
);

localparam CYCLES = (CLK_FREQ / 2 / BEAT_FREQ);

reg [31:0] count = 0;

initial    beat = 1'b0;

always @ (posedge clk)
    if ( count < (CYCLES-1) ) begin
        count <= count + 1;
    end else begin
        count <= 0;
        beat  <= ~beat;
    end

endmodule
