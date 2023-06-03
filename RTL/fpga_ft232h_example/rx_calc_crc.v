
//--------------------------------------------------------------------------------------------------------
// Module  : rx_calc_crc
// Type    : synthesizable
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: receive data block from AXI-stream slave, calculate its CRC simultaneously
//           when meeting 0xFF, End accepting the current data block,
//           and then send the CRC value of that block through AXI-stream master
//           this module will called by fpga_top_ft600_rx_crc.v or fpga_top_ft232h_rx_crc.v
//--------------------------------------------------------------------------------------------------------

module rx_calc_crc #(
    parameter                  IEW = 2      // AXI byte width is 1<<BW, bit width is 8<<BW
) (
    input  wire                rstn,
    input  wire                clk,
    // AXI-stream slave
    output wire                i_tready,
    input  wire                i_tvalid,
    input  wire [(8<<IEW)-1:0] i_tdata,
    input  wire [(1<<IEW)-1:0] i_tkeep,
    // AXI-stream master
    input  wire                o_tready,
    output wire                o_tvalid,
    output wire         [31:0] o_tdata
);



function  [31:0] calculate_crc;
    input [31:0] crc;
    input [ 7:0] inbyte;
    reg   [31:0] TABLE_CRC [15:0];
begin
    TABLE_CRC[0] = 'h00000000;    TABLE_CRC[1] = 'h1db71064;    TABLE_CRC[2] = 'h3b6e20c8;    TABLE_CRC[3] = 'h26d930ac;
    TABLE_CRC[4] = 'h76dc4190;    TABLE_CRC[5] = 'h6b6b51f4;    TABLE_CRC[6] = 'h4db26158;    TABLE_CRC[7] = 'h5005713c;
    TABLE_CRC[8] = 'hedb88320;    TABLE_CRC[9] = 'hf00f9344;    TABLE_CRC[10]= 'hd6d6a3e8;    TABLE_CRC[11]= 'hcb61b38c;
    TABLE_CRC[12]= 'h9b64c2b0;    TABLE_CRC[13]= 'h86d3d2d4;    TABLE_CRC[14]= 'ha00ae278;    TABLE_CRC[15]= 'hbdbdf21c;
    calculate_crc = crc ^ {24'h0, inbyte};
    calculate_crc = TABLE_CRC[calculate_crc[3:0]] ^ (calculate_crc >> 4);
    calculate_crc = TABLE_CRC[calculate_crc[3:0]] ^ (calculate_crc >> 4);
end
endfunction


reg         state = 1'b0;             // 0:inputting stream, 1:outputting CRC
reg  [31:0] crc   = 'hFFFFFFFF;
reg  [31:0] len   = 0;

reg  [31:0] crc_tmp;                  // not real register
reg  [31:0] len_tmp;                  // not real register

integer i;

always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        state <= 1'b0;
        crc   <= 'hFFFFFFFF;
        len   <= 0;
    end else begin
        if (state == 1'b0) begin      // inputting stream
            if (i_tvalid) begin
                crc_tmp = crc;
                len_tmp = len;
                for (i=0; i<(1<<IEW); i=i+1) begin
                    if (i_tkeep[i]) begin
                        len_tmp = len_tmp + 1;
                        crc_tmp = calculate_crc(crc_tmp, i_tdata[8*i +: 8] );
                        if ( i_tdata[8*i +: 8] == 8'hFF )                              // when meet byte=0xFF
                            state <= 1'b1;
                    end
                end
                len <= len_tmp;
                crc <= crc_tmp;
            end
        end else begin                // outputting CRC
            if (o_tready) begin
                state <= 1'b0;
                crc   <= 'hFFFFFFFF;
                len   <= 0;
            end
        end
    end


assign i_tready = (state == 1'b0);
assign o_tvalid = (state == 1'b1);
assign o_tdata  = crc;


endmodule
