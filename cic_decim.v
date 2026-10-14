`timescale 1ns / 1ps

module cic_decim #(
    parameter N    = 3,                      // CIC order
    parameter R    = 2048,                   // decimation factor 
    parameter BIN  = 2,                      // input width (signed)
    parameter BMAX = N*$clog2(R) + BIN     // M = 1  ->  35 bits for N=3,R=2048,BIN=2  
)(
    input  wire                     clk,
    input  wire                     rst,     // synchronous, active high
    input  wire                     en,
    input  wire signed [BIN-1:0]    din,
    output reg  signed [BMAX-1:0]   dout,    // full-precision comb output (DC gain R^N)
    output reg                      dvalid   // 1-cycle strobe, once every R input clocks
);
    localparam CW = $clog2(R);

   
    reg signed [BIN-1:0] din_s;
    always @(negedge clk) din_s<= din;     //to avoid race conditions
   

    reg signed [BMAX-1:0] integ  [0:N-1];    // integrator accumulators
    reg signed [BMAX-1:0] comb_d [0:N-1];    // comb delay registers 
    reg        [CW-1:0]   cnt;

    integer i;
    reg signed [BMAX-1:0] t_in, t_out;       // blocking temporaries for the comb chain

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                integ[i]  <= {BMAX{1'b0}};
                comb_d[i] <= {BMAX{1'b0}};
            end
            cnt    <= {CW{1'b0}};
            dout   <= {BMAX{1'b0}};
            dvalid <= 1'b0;
        end else if (en) begin
            // integrators (high rate)
            integ[0] <= integ[0] + {{(BMAX-BIN){din_s[BIN-1]}}, din_s};
            for (i = 1; i < N; i = i + 1)
                integ[i] <= integ[i] + integ[i-1];

            // decimate + combs (low rate)
            dvalid <= 1'b0;
            if (cnt == R-1) begin
                cnt  <= {CW{1'b0}};
                t_in = integ[N-1];
                for (i = 0; i < N; i = i + 1) begin
                    t_out    = t_in - comb_d[i];
                    comb_d[i] <= t_in;
                    t_in     = t_out;
                end
                dout   <= t_in;
                dvalid <= 1'b1;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end
endmodule
