module fec_header (
    input  wire clk,
    input  wire rst_n,
    input  wire bit_in,
    output reg  [5:0] fec_out
);

reg [6:0] shift;

// shift register
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        shift <= 7'b0;
    else
        shift <= {bit_in, shift[6:1]};
end

// generator polynomials
always @(*) begin
    // 0175 = 1111101
    fec_out[0] = shift[0] ^ shift[2] ^ shift[3] ^ shift[4] ^ shift[5] ^ shift[6];

    // 0171 = 1111001
    fec_out[1] = shift[0] ^ shift[3] ^ shift[4] ^ shift[5] ^ shift[6];

    // 0151 = 1101001
    fec_out[2] = shift[0] ^ shift[3] ^ shift[5] ^ shift[6];

    // 0133 = 1011011
    fec_out[3] = shift[0] ^ shift[1] ^ shift[3] ^ shift[4] ^ shift[6];

    // 0127 = 1010111
    fec_out[4] = shift[0] ^ shift[1] ^ shift[2] ^ shift[4] ^ shift[6];

    // 0117 = 1001111
    fec_out[5] = shift[0] ^ shift[1] ^ shift[2] ^ shift[3] ^ shift[6];
end

endmodule