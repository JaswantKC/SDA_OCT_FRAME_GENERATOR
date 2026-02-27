`timescale 1ns/1ps

module OCT_idle_tb;

    reg clk;
    reg rst_n;

    // Inputs 
    reg start_frame;
    reg payload_valid;
    reg [8351:0] payload_data;
    reg payload_length;
    reg [1:0] FRAME_TYPE_i;

    // Outputs
    wire frame_valid;
    wire [9471:0] frame_data;
    
    wire data_out;
    wire frame_done;
    wire [1:0]FRAME_TYPE;
    wire busy;

    //--------------------------------------------------
    // Instantiate DUT
    //--------------------------------------------------
    OCT dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_frame(start_frame),
        .payload_valid(payload_valid),
        .payload_data(payload_data),
        .payload_length(payload_length),
        .frame_valid(frame_valid),
        .frame_data(frame_data),
        .FRAME_TYPE_i(FRAME_TYPE_i),
        .data_out(data_out),
        .frame_done(frame_done),
        .FRAME_TYPE(FRAME_TYPE),
        .busy(busy)
    );

    //--------------------------------------------------
    // Clock 100 MHz
    //--------------------------------------------------
    always #5 clk = ~clk;

    //--------------------------------------------------
    // Test sequence
    //--------------------------------------------------
    initial begin
        clk = 0;
        rst_n = 0;
        start_frame = 0;
        payload_valid = 0;
        payload_data = 0;
        payload_length = 0;

        // remove reset
        #20;
        rst_n = 1;
        
        #8692;
        payload_data  = {8352{1'b1}};
        payload_valid = 1'b1;      // Tell DUT payload is ready
        start_frame   = 1'b1;
        FRAME_TYPE_i = 2'b10;
        
        #10
        start_frame =1'b0;
        
        #17364
        FRAME_TYPE_i = 2'b01;
        start_frame = 1'b1;
        
        #10
        start_frame = 1'b0;
       
        #200000;   

        $stop;
    end

    //--------------------------------------------------
    // Monitor serial transmission
    //--------------------------------------------------
    integer bit_count = 0;

    always @(posedge clk) begin
        if (busy) begin
            bit_count = bit_count + 1;
        end
        else begin
            bit_count = 0;
        end
    end

endmodule