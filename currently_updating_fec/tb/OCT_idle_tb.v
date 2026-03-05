`timescale 1ns/1ps

module OCT_idle__tb;

reg clk;
reg rst_n;

reg start_frame;
reg payload_valid;
reg [8351:0] payload_data;
reg payload_length;
reg [1:0] FRAME_TYPE_i;

wire frame_valid;
wire [9471:0] frame_data;
wire data_out;
wire frame_done;
wire [1:0] FRAME_TYPE;
wire busy;

OCT dut(
.clk(clk),
.rst_n(rst_n),
.start_frame(start_frame),
.payload_valid(payload_valid),
.payload_data(payload_data),
.payload_length(payload_length),
.FRAME_TYPE_i(FRAME_TYPE_i),
.frame_valid(frame_valid),
.frame_data(frame_data),
.data_out(data_out),
.frame_done(frame_done),
.FRAME_TYPE(FRAME_TYPE),
.busy(busy)
);

// clock
always #5 clk = ~clk;

initial begin

clk = 0;
rst_n = 0;
start_frame = 0;
payload_valid = 0;
payload_data = 0;
payload_length = 0;

#20;
rst_n = 1;

/////////////////////////////
// Management Frame
/////////////////////////////

FRAME_TYPE_i = 2'b10;

start_frame = 1;
#10;
start_frame = 0;

wait(frame_done);

/////////////////////////////
// Payload Frame 1
/////////////////////////////

payload_valid = 1;
FRAME_TYPE_i = 2'b01;
payload_data = {8352{1'b1}};

start_frame = 1;
#10;
start_frame = 0;

wait(frame_done);

/////////////////////////////
// Payload Frame 2
/////////////////////////////

payload_data = {4176{2'b10}};

start_frame = 1;
#10;
start_frame = 0;

wait(frame_done);

/////////////////////////////
// Payload Frame 3
/////////////////////////////

payload_data = {2784{3'b101}};

start_frame = 1;
#10;
start_frame = 0;

wait(frame_done);

#20000;

$stop;

end

endmodule

