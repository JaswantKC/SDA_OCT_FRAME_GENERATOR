module crc32_payload (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,      // payload bit (MSB-first)
    input  wire enable,       // active during payload bits
    input  wire clear,        // reset before payload
    input  wire crc_valid,    // pulse when payload finished
    output reg  [31:0] crc_out
);

    reg [31:0] crc;
    wire feedback;

    assign feedback = data_in ^ crc[31];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            crc <= 32'd0;

        else if (clear)
            crc <= 32'd0;

        else if (enable && !crc_valid) begin
            crc[31] <= crc[30];
            crc[30] <= crc[29];
            crc[29] <= crc[28];
            crc[28] <= crc[27];
            crc[27] <= crc[26];
            crc[26] <= crc[25] ^ feedback;  // tap
            crc[25] <= crc[24];
            crc[24] <= crc[23];
            crc[23] <= crc[22] ^ feedback;  // tap
            crc[22] <= crc[21] ^ feedback;  // tap
            crc[21] <= crc[20];
            crc[20] <= crc[19];
            crc[19] <= crc[18];
            crc[18] <= crc[17];
            crc[17] <= crc[16];
            crc[16] <= crc[15] ^ feedback;  // tap
            crc[15] <= crc[14];
            crc[14] <= crc[13];
            crc[13] <= crc[12];
            crc[12] <= crc[11] ^ feedback;  // tap
            crc[11] <= crc[10] ^ feedback;  // tap
            crc[10] <= crc[9];
            crc[9]  <= crc[8];
            crc[8]  <= crc[7]  ^ feedback;  // tap
            crc[7]  <= crc[6]  ^ feedback;  // tap
            crc[6]  <= crc[5];
            crc[5]  <= crc[4]  ^ feedback;  // tap
            crc[4]  <= crc[3]  ^ feedback;  // tap
            crc[3]  <= crc[2];
            crc[2]  <= crc[1]  ^ feedback;  // tap
            crc[1]  <= crc[0]  ^ feedback;  // tap
            crc[0]  <= feedback;            // tap
        end
    end

    always @(posedge clk) begin
        if (crc_valid)
            crc_out <= crc;
    end

endmodule