`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.02.2026 04:53:50
// Design Name: 
// Module Name: crc16_header
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module crc16_header (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,     // header bit (MSB-first)
    input  wire enable,      // active during header bits
    input  wire clear,       // pulse at start of header
    input  wire crc_valid,   // pulse when header finished
    output reg  [15:0] crc_out
);

    reg [15:0] crc;
    wire feedback;

    assign feedback = data_in ^ crc[15];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            crc <= 16'd0;

        else if (clear)
            crc <= 16'd0;

        else if (enable && !crc_valid) begin
            crc[15] <= crc[14];
            crc[14] <= crc[13];
            crc[13] <= crc[12];
            crc[12] <= crc[11] ^ feedback;   // tap x^12
            crc[11] <= crc[10];
            crc[10] <= crc[9];
            crc[9]  <= crc[8];
            crc[8]  <= crc[7];
            crc[7]  <= crc[6];
            crc[6]  <= crc[5];
            crc[5]  <= crc[4] ^ feedback;    // tap x^5
            crc[4]  <= crc[3];
            crc[3]  <= crc[2];
            crc[2]  <= crc[1];
            crc[1]  <= crc[0];
            crc[0]  <= feedback;             // tap x^0
        end
    end

    always @(posedge clk) begin
        if (crc_valid)
            crc_out <= crc;
    end

endmodule
