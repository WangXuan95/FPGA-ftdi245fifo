
//--------------------------------------------------------------------------------------------------------
// Module  : ftdi_245fifo_fsm
// Type    : synthesizable, IP's sub-module
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: FTDI USB chip's 245fifo mode's main control FSM, called by ftdi_245fifo_fsm
//--------------------------------------------------------------------------------------------------------

module ftdi_245fifo_fsm #(
    parameter  CHIP_EW               = 0,    // FTDI USB chip data width, 0=8bit, 1=16bit, 2=32bit. for FT232H is 0, for FT600 is 1, for FT601 is 2.
    parameter  CHIP_DRIVE_AT_NEGEDGE = 0
) ( 
    input  wire                    rstn,
    input  wire                    clk,
    output wire                    tx_tready,
    input  wire                    tx_tvalid,
    input  wire [(8<<CHIP_EW)-1:0] tx_tdata,
    input  wire [(1<<CHIP_EW)-1:0] tx_tkeep,
    input  wire                    rx_almost_full,
    output wire                    rx_tvalid,
    output wire [(8<<CHIP_EW)-1:0] rx_tdata,
    output wire [(1<<CHIP_EW)-1:0] rx_tkeep,
    output wire                    rx_tlast,
    // FTDI chip interface
    input  wire                    ftdi_rxf_n,
    input  wire                    ftdi_txe_n,
    output reg                     ftdi_oe_n,
    output reg                     ftdi_rd_n,
    output reg                     ftdi_wr_n,
    output reg                     ftdi_master_oe,   // 1:master (FPGA) drives DATA/BE    0:master (FPGA) release DATA/BE to High-Z
    output reg  [(8<<CHIP_EW)-1:0] ftdi_data_out,    // when ftdi_master_oe=1, this signal must be drive to DATA
    output reg  [(1<<CHIP_EW)-1:0] ftdi_be_out,      // when ftdi_master_oe=1, this signal must be drive to BE
    input  wire [(8<<CHIP_EW)-1:0] ftdi_data_in,
    input  wire [(1<<CHIP_EW)-1:0] ftdi_be_in
);


localparam [(8<<CHIP_EW)-1:0] DATA_ZERO  = {(8<<CHIP_EW){1'b0}};
localparam [(1<<CHIP_EW)-1:0] BE_ZERO    = {(1<<CHIP_EW){1'b0}};
localparam [(1<<CHIP_EW)-1:0] BE_ALL_ONE = ~BE_ZERO;


localparam [5:0] S_RX_IDLE = 6'b000011,
                 S_RX_OE   = 6'b000010,
                 S_RX_EN   = 6'b000000,
                 S_RX_WAIT = 6'b000111,
                 S_RX_END  = 6'b001011,
                 S_TX_IDLE = 6'b010011,
                 S_TX_EN   = 6'b100011;
                 
reg  [ 5:0]      state     = S_RX_IDLE;

wire             state_n_rx_oe_or_rx_en = state[0];             // ~(state == S_RX_OE || state == S_RX_EN)
wire             state_n_rx_en          = state[1];             // ~(state == S_RX_EN)
wire             state_rx_end           = state[3];             //   state == S_RX_END
wire             state_tx_en            = state[5];             //   state == S_TX_EN


assign           rx_tlast  = (state_rx_end & ftdi_rxf_n);
assign           rx_tvalid = (~state_n_rx_en & ~ftdi_rxf_n) | rx_tlast;
assign           rx_tdata  = state_n_rx_en ? DATA_ZERO : ftdi_data_in;
generate if (CHIP_EW==0)
    assign       rx_tkeep  = state_n_rx_en ? BE_ZERO   : BE_ALL_ONE;
else
    assign       rx_tkeep  = state_n_rx_en ? BE_ZERO   : ftdi_be_in;
endgenerate

assign           tx_tready = state_tx_en & ~ftdi_txe_n;


generate if (CHIP_DRIVE_AT_NEGEDGE) begin
    always @ (negedge clk) begin
        ftdi_oe_n      <= state_n_rx_oe_or_rx_en;
        ftdi_rd_n      <= state_n_rx_en;
        ftdi_wr_n      <= state_tx_en ? ~tx_tvalid : 1'b1;
        ftdi_master_oe <= state_tx_en;
        ftdi_data_out  <= tx_tdata;
        ftdi_be_out    <= tx_tkeep;
    end

end else begin
    always @ (*) begin
        ftdi_oe_n      = state_n_rx_oe_or_rx_en;
        ftdi_rd_n      = state_n_rx_en;
        ftdi_wr_n      = state_tx_en ? ~tx_tvalid : 1'b1;
        ftdi_master_oe = state_tx_en;
        ftdi_data_out  = tx_tdata;
        ftdi_be_out    = tx_tkeep;
    end
end endgenerate


always @ (posedge clk or negedge rstn)
    if (~rstn) begin
        state <= S_RX_IDLE;
    end else begin
        case (state)
            S_RX_IDLE :
                if (~ftdi_rxf_n & ~rx_almost_full)
                    state <= S_RX_OE;
                else
                    state <= S_TX_IDLE;
            
            S_RX_OE :
                state <= S_RX_EN;
            
            S_RX_EN :
                if (ftdi_rxf_n | rx_almost_full)
                    state <= S_RX_WAIT;
            
            S_RX_WAIT :
                state <= S_RX_END;
            
            S_RX_END :                                    // check whether there's no more RX data (ftdi_rxf_n==1) in this state, 
                state <= S_TX_IDLE;
            
            S_TX_EN :
                if (ftdi_txe_n || ~tx_tvalid || (tx_tkeep != BE_ALL_ONE))
                    state <= S_RX_IDLE;
            
            default : // S_TX_IDLE :
                if (~ftdi_txe_n & tx_tvalid)
                    state <= S_TX_EN;
                else
                    state <= S_RX_IDLE;
        endcase
    end

endmodule
