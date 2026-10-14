`timescale 1ns / 1ps

module cic_top #(
    parameter N = 3,
    parameter R = 2048,
    parameter BIN = 2,
    parameter BMAX = N*$clog2(R) + BIN             
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   en,
    input  wire signed [BIN-1:0]  din,
    output reg  signed [19:0]     dout,
    output reg                    dvalid
);
    wire signed [BMAX-1:0] y;
    wire                   y_valid;

    cic_decim #(.N(N), .R(R), .BIN(BIN)) u_cic (
        .clk(clk), .rst(rst), .en(en), .din(din), .dout(y), .dvalid(y_valid)
    );

    // 7*y = (y<<3) - y     (BMAX+3 bits is enough)
    wire signed [BMAX+3:0] y7   = ({{3{y[BMAX-1]}}, y} <<< 3) - {{4{y[BMAX-1]}}, y};
    localparam SH = 15;
    wire signed [BMAX+3:0] ysh  = y7 >>> SH;

    localparam signed [BMAX+3:0] MAXV =  (1 <<< 19) - 1;
    localparam signed [BMAX+3:0] MINV = -(1 <<< 19);

    always @(posedge clk) begin
        if (rst) begin
            dout <= 20'sd0; dvalid <= 1'b0;
        end else begin
            dvalid <= y_valid;
            if (y_valid)
                dout <= (ysh > MAXV) ? MAXV[19:0] : (ysh < MINV) ? MINV[19:0] : ysh[19:0];
        end
    end
endmodule
