
//--------------------------------------------------------------------------------------------------------
// Module  : tb_ftdi_245fifo
// Type    : simulation
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: simple FT232H / FT600 / FT601 chip model
//--------------------------------------------------------------------------------------------------------

`timescale 1ps/1ps

module tb_ftdi_chip_model #(
    parameter                CHIP_EW = 0        // FTDI USB chip data width, 0=8bit, 1=16bit, 2=32bit. for FT232H is 0, for FT600 is 1, for FT601 is 2.
) (
    output reg               ftdi_clk,
    output reg               ftdi_rxf_n,
    output reg               ftdi_txe_n,
    input  wire              ftdi_oe_n,
    input  wire              ftdi_rd_n,
    input  wire              ftdi_wr_n,
    inout [(8<<CHIP_EW)-1:0] ftdi_data,
    inout [(1<<CHIP_EW)-1:0] ftdi_be
);



//---------------------------------------------------------------------------------------------------------------------------------------------------------------
// function : generate random unsigned integer
//---------------------------------------------------------------------------------------------------------------------------------------------------------------
function  [31:0] randuint;
    input [31:0] min;
    input [31:0] max;
begin
    randuint = $random;
    if ( min != 0 || max != 'hFFFFFFFF )
        randuint = (randuint % (1+max-min)) + min;
end
endfunction




wire       [(8<<CHIP_EW)-1:0] DATA_HIGHZ = {(8<<CHIP_EW){1'bz}};
localparam [(8<<CHIP_EW)-1:0] DATA_ZERO  = {(8<<CHIP_EW){1'b0}};
wire       [(1<<CHIP_EW)-1:0] BE_HIGHZ   = {(1<<CHIP_EW){1'bz}};
localparam [(1<<CHIP_EW)-1:0] BE_ZERO    = {(1<<CHIP_EW){1'b0}};
localparam [(1<<CHIP_EW)-1:0] BE_ALL_ONE = ~BE_ZERO;



initial ftdi_clk = 1'b0;                    // generate FTDI chip clock
always #8333 ftdi_clk = ~ftdi_clk;          // approximately 60MHz. 




reg [(8<<CHIP_EW)-1:0] ftdi_r_data = DATA_ZERO;
reg [(1<<CHIP_EW)-1:0] ftdi_r_be   = BE_ZERO;

reg [(8<<CHIP_EW)-1:0] tmp_data = DATA_ZERO;
reg [(8<<CHIP_EW)-1:0] tmp_be   = (CHIP_EW==0) ? 1     : BE_ZERO;
reg              [7:0] rxbyte   = (CHIP_EW==0) ? 8'h01 : 8'h00;

integer i;


always @ (posedge ftdi_clk)                    // data from FTDI-Chip to FPGA (read from FTDI-Chip)
    if (~ftdi_rd_n & ~ftdi_rxf_n) begin
        tmp_data = ftdi_r_data;
        tmp_be   = (CHIP_EW==0) ? BE_ALL_ONE : randuint(0, 'hFFFFFFFF);
    
        for (i=0; i<(1<<CHIP_EW); i=i+1) begin
            if (tmp_be[i]) begin
                //$write(" %02X", rxbyte);
                tmp_data[8*i +: 8] = rxbyte;
                rxbyte = rxbyte + 1;
            end
        end
        
        ftdi_r_data <= tmp_data;
        ftdi_r_be   <= tmp_be;
    end




reg              [7:0] txbyte   = 8'h00;

always @ (posedge ftdi_clk)                    // data from FPGA to FTDI-Chip (write to FTDI-Chip)
    if (~ftdi_wr_n & ~ftdi_txe_n) begin
        for (i=0; i<(1<<CHIP_EW); i=i+1) begin
            if (ftdi_be[i]) begin
                $write(" %02X", ftdi_data[8*i +: 8] );
                if (txbyte !== ftdi_data[8*i +: 8]) begin $display("*** error : data incorrect"); $stop; end
                txbyte = txbyte + 1;
            end
        end
    end


assign  ftdi_data = ftdi_oe_n ? DATA_HIGHZ : ftdi_r_data;
assign  ftdi_be   = ftdi_oe_n ? BE_HIGHZ   : ftdi_r_be;




initial begin
    ftdi_rxf_n <= 1'b1;
    while (1) begin
        repeat (randuint(1, 100)) @ (posedge ftdi_clk);
        ftdi_rxf_n <= 1'b0;
        repeat (randuint(1, 100)) @ (posedge ftdi_clk);
        ftdi_rxf_n <= 1'b1;
    end
end


initial begin
    ftdi_txe_n <= 1'b1;
    while (1) begin
        repeat (randuint(1, 100)) @ (posedge ftdi_clk);
        ftdi_txe_n <= 1'b0;
        repeat (randuint(1, 100)) @ (posedge ftdi_clk);
        ftdi_txe_n <= 1'b1;
    end
end


endmodule

