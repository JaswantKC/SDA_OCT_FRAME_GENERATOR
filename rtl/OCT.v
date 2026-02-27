`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.02.2026 11:13:21
// Design Name: 
// Module Name: OCT
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


module OCT(
    clk,
    rst_n,
    start_frame,
    payload_valid,
    payload_data,
    FRAME_TYPE_i,
    payload_length, //not used as of now
    frame_valid,
    frame_data,
    data_out,
    frame_done,
    FRAME_TYPE,
    busy
    );
    
    input clk;
    input rst_n;
    input start_frame;
    input payload_valid;
    input[8351:0] payload_data;     //without payload CRC
    input payload_length;
    input [1:0]FRAME_TYPE_i; 
    

    
    output frame_valid;
    output [9471:0]frame_data;
    output reg data_out;  //with preamble and header and payload data +payload CRC 
    output frame_done;
    output busy;
    
    parameter [63:0]Preamble = 64'h 53225b1d0d73df03; 
    //header
    reg [127:0] Header_data;
    reg [15:0]TXFN;         //would be incremented every frame cycle
    reg [15:0]ACK_START_FN;
    localparam [2:0]ACK_SPAN = 3'b101;
    reg ACK_valid;
    localparam ACK = 1'b1;
    reg [2:0] TX_NUM;
    localparam [7:0] ARQ_NFRAMES = 3'b000;
    localparam [2:0]ARQ_MAX_RETX = 3'b101;
    //Header FEC Part
    localparam [3:0]PLRATE = 4'b0;        //for Parity
    //Header MAC Part
    output reg [1:0]FRAME_TYPE ;      //if Frame_type = 00(idle),01(data),10(Management), 11 Reserved
    //Header Transmit TimeStamp
    localparam [39:0]TX_TS = 40'd1000000000;
    localparam [5:0] TOD_seconds = 6'd50;
    localparam [2:0]TS_applies = 3'b0;
    //Header Fast Control Channel
    localparam [5:0] FCCH_OPCODE = 6'b1;
    localparam [15:0]FCCH_PL = 16'b0;
    //Header CRC
    //Header Zero Tail
    reg [15:0]ZT = 16'd0;
    reg data_s;
    
    
    reg[7:0] n = 8'b0; 
    reg [8:0] i = 9'b0;
    reg [13:0]j = 14'b0;
    reg [13:0]k = 14'b0;
    reg [13:0]p = 14'b0;
    reg [13:0]t = 14'b0;
    reg start_frame_num;
    //control signals
    reg frame_type_check;
    reg Frame_confirm;
    reg payload_frame_cons;
    reg payload_done_idle;
    reg SCRAMB_DONE;
    reg idle_lfsr_a;
    reg idle_frame_valid = 1'b0;
    reg payload_done_mgmt;
    reg payload_done;
    //CRC_16_Module
    reg data_crc;
    reg crc_valid;
    wire [15:0]crc_16;
    reg crc_enable_16;
    reg crc_clear_16;
   //payload
   reg [14:0]idle_lfsr;
   //crc_32_module
   reg data_crc_32;
   reg crc_32_valid;
   wire [31:0]crc_32;
   reg crc_enable_32;
   reg crc_clear_32;
    
   //SCRAMBLER
   reg [14:0]SCRAMB = 15'b000011011011100;
   
   //MANAGEMENT FRAME
    reg [8415:0]MGMT_FRAME;
    localparam [127:0]Field_valid = {5'b11111,123'b0};
    localparam [6009:0]ETWTT_DATA = {16'd1,16'd6010,8'd7,184'd40,184'd41,184'd42,184'd43,184'd44,184'd45,184'd46,4682'd0};      //7 segments used
    localparam [375:0]TWTT_DATA = {94'b0,94'b0,94'b0,94'b0};    //{t1,t2,t3,t4}
    localparam [1901:0]PVTR_DATA_STRUCTURE = {1856'b0,TX_TS,TOD_seconds}; // used for COORDINATES
    
    //PAYLOAD
    reg [8415:0]payload;
    reg [9:0]seq_num;
    localparam [13:0]Length = 14'd8352;
    localparam [1:0]reserved_pl = 2'b00;
    
    parameter IDLE = 0, PREAMBLE= 1,Header = 2,Payload = 4;
    reg [2:0] State;
    
    
    assign busy = (State !=IDLE);
    assign frame_done = (State == IDLE && SCRAMB_DONE);
    
    crc16_header A1(.clk(clk),
               .rst_n(rst_n),
               .data_in(data_crc),
               .enable(crc_enable_16),
               .clear(crc_clear_16),
               .crc_valid(crc_valid),
               .crc_out(crc_16)
               );
     
     
     crc32_payload u_crc32 (
    .clk       (clk),
    .rst_n     (rst_n),
    .data_in   (data_crc_32),
    .enable    (crc_enable_32),
    .clear     (crc_clear_32),
    .crc_valid (crc_32_valid),
    .crc_out   (crc_32)
);
    
    always @(posedge clk)               //Control Module
      begin
         if (rst_n == 1'b0)
         begin
            State <= IDLE; //basically frame =0;
            
         end
         else
            case (State)
               IDLE:
                  begin                 //initialisation of some simple terms
                     //RandomBitValid <= 1'b0;
                     //BitCount <= 0;
                     if (start_frame_num == 1'b1 || idle_frame_valid == 1'b1)
                        begin
                            State <= PREAMBLE;
                        end                    
                  end
                PREAMBLE: 
                    begin
                        if(frame_type_check) begin
                            State <=Header;
                        end
                    end  
              Header: 
                    begin
                        if(payload_frame_cons) begin
                            State <=Payload;
                        end
                    end  
              Payload: 
                    begin
                        if((payload_done_idle&&SCRAMB_DONE)||(payload_done_mgmt&&SCRAMB_DONE)||(payload_done&&SCRAMB_DONE)) begin     //add multuple state conditions for different frames
                            State <=IDLE;
                        end
                    end  
              
               default :
                  State <= IDLE;
            endcase
      end
      
      //DATA Module
      
      always @(posedge clk) begin
        if(rst_n == 1'b0) 
            begin
                ACK_valid <= 1'b0;
                ACK_START_FN <= 16'b0;
                TXFN <= 16'b0;
                TX_NUM <= 3'b0;
                start_frame_num<=0;
            end
           
        
            
            
        if (start_frame == 1'b1)
            begin
                start_frame_num<=1'b1;
                FRAME_TYPE <=FRAME_TYPE_i; 
                if(ACK == 1'b1)
                    begin
                        ACK_valid <= 1'b1;
                       if(ACK_START_FN != 16'b0)
                        ACK_START_FN<= ACK_START_FN+1;
                    end
                else   
                    begin
                        ACK_valid <= 1'b0;
                        TX_NUM <= TX_NUM+1;
                    end
                    end
         else if(start_frame_num==1'b0 && busy!=1) begin
            FRAME_TYPE <= 2'b00;
            idle_frame_valid <= 1'b1;
         end
         if(State == IDLE) begin
            n<=63;
            j<=0;
            k<=0;
            p<=0;
            Frame_confirm<=1'b0;
            frame_type_check<=1'b0;
            payload_frame_cons<=1'b0;
            payload_done_idle<=1'b0;
            SCRAMB_DONE<=1'b0;
            idle_lfsr_a<=1'b0;
            crc_clear_16<=1'b1;
            payload_done_mgmt<=1'b0;
            payload_done<=1'b0;
         end
         if(State == PREAMBLE) begin     
            crc_clear_16<=1'b0;
            idle_frame_valid <= 1'b0;
            data_out<=Preamble[n];     
            if(n == 1) begin
                frame_type_check <= 1'b1;
                i<=0;
            end
            else begin
                n<=n-1;
            end 
          end
                
           if(State == Header) begin
                if(FRAME_TYPE == 2'b00&& i<1)  //IDLE FRAME and safe condition
                    begin
                         data_out<=Preamble[0];
                         Header_data<={TXFN,ACK_START_FN,ACK_SPAN,ACK_valid,ACK,TX_NUM,ARQ_NFRAMES,ARQ_MAX_RETX,PLRATE,FRAME_TYPE,TX_TS,TOD_seconds,TS_applies,FCCH_OPCODE,FCCH_PL};
                         Frame_confirm <= 1'b1;
                         data_s<=Header_data[i];
                         i<=i+1;
                         start_frame_num<=start_frame_num-1;
                         crc_enable_16 <=1'b1; 
                    end
                 if(FRAME_TYPE == 2'b01&& i<1)  //IDLE FRAME and safe condition
                    begin
                         data_out<=Preamble[0];
                         Header_data<={TXFN,ACK_START_FN,ACK_SPAN,ACK_valid,ACK,TX_NUM,ARQ_NFRAMES,ARQ_MAX_RETX,PLRATE,FRAME_TYPE,TX_TS,TOD_seconds,TS_applies,FCCH_OPCODE,FCCH_PL};
                         Frame_confirm <= 1'b1;
                         data_s<=Header_data[i];
                         i<=i+1;
                         start_frame_num<=start_frame_num-1;
                         crc_enable_16 <=1'b1; 
                    end
                    if(FRAME_TYPE == 2'b10&& i<1)  //IDLE FRAME and safe condition
                    begin
                         data_out<=Preamble[0];
                         Header_data<={TXFN,ACK_START_FN,ACK_SPAN,ACK_valid,ACK,TX_NUM,ARQ_NFRAMES,ARQ_MAX_RETX,PLRATE,FRAME_TYPE,TX_TS,TOD_seconds,TS_applies,FCCH_OPCODE,FCCH_PL};
                         Frame_confirm <= 1'b1;
                         data_s<=Header_data[i];
                         i<=i+1;
                         start_frame_num<=start_frame_num-1;
                         crc_enable_16 <=1'b1; 
                    end   
                 if(Frame_confirm == 1'b1) begin
                    if(i<127) begin
                        data_s<=Header_data[127-i];
                        data_crc<=Header_data[127-i];       // for CRC Module
                        i<=i+1; 
                     end
                     else if(i ==128) 
                        begin
                            crc_valid<= 1'b1;
                            data_s<=crc_16[143-i];
                            i<=i+1;
                            crc_enable_16<=1'b0;                  
                        end
                     else if(i>128 && i<144)
                        begin
                            data_s<=crc_16[143-i];
                            i<=i+1;
                            crc_valid<=1'b0;
                        end
                     else if(i == 144) 
                        begin
                            data_s<=ZT[15];
                            i<=i+1;
                        end
                      else if(i>144&&i<159)
                        begin
                            data_s<=ZT[159-i];
                            i<=i+1;
                        end
                      else if(i==159)
                        begin
                            payload_frame_cons <= 1'b1;
                            Frame_confirm<=1'b0;
                            data_s<=ZT[0];
                            crc_clear_32<=1'b1;
                        end
                       else
                            i<=i+1;
                           
                 end   
            end
            if(State==Payload) 
                begin
                    crc_clear_32<=1'b0;
                    if(FRAME_TYPE == 2'b00)         //IDLE PAYLOAD GENERATION
                        begin
                            if(TXFN == 16'b0&&idle_lfsr_a<1)begin
                                idle_lfsr<= TXFN[14:0]+16'd9;
                                idle_lfsr_a <= 1'b1;
                            end
                            else if(idle_lfsr_a<1)
                                begin
                                idle_lfsr<=TXFN[14:0];
                                idle_lfsr_a <= 1'b1;
                                end
                            if(idle_lfsr_a ==1'b1)begin    
                                crc_enable_32 <=1'b1;
                                idle_lfsr<={idle_lfsr[14]^idle_lfsr[13],idle_lfsr[13:0]};//lfsr for idle payoad gen
                                data_s<=idle_lfsr[14];
                                data_crc_32<=idle_lfsr[14];
                                j<=j+1;
                                if(j==8416)
                                    begin
                                        crc_enable_32<=1'b0;
                                        crc_32_valid <= 1'b1;
                                        data_s<=crc_32[31];
                                        j<=j+1;
                                    end
                                else if(j==8417) begin
                                    crc_32_valid <= 1'b0;
                                    data_s<=crc_32[8447-j];
                                    j<=j+1;
                                end
                                   
                                else if(j>8417&&j<8447)
                                    begin

                                        data_s<=crc_32[8447-j];
                                        j<=j+1;
                                    end
                                else if(j==8447) 
                                    begin
                                        payload_done_idle <= 1'b1;
                                        data_s<=crc_32[0];
                                        frame_type_check<=1'b0;    
                                    end    
                                            
                            end
                    end
                    end
                    if(FRAME_TYPE == 2'b10)     //Management FRAME GENERATION
                        begin
                                crc_enable_32 <=1'b1;
                                MGMT_FRAME<={Field_valid,TWTT_DATA,PVTR_DATA_STRUCTURE,ETWTT_DATA};
                                data_s<=MGMT_FRAME[p];
                                data_crc_32<=MGMT_FRAME[p];
                                p<=p+1;
                                if(p==8416)
                                    begin
                                        crc_enable_32<=1'b0;
                                        crc_32_valid <= 1'b1;
                                        data_s<=crc_32[31];
                                        p<=p+1;
                                    end
                                else if(p==8417) begin
                                    crc_32_valid <= 1'b0;
                                    data_s<=crc_32[8447-p];
                                    p<=p+1;
                                end
                                   
                                else if(p>8417&&p<8447)
                                    begin

                                        data_s<=crc_32[8447-p];
                                        p<=p+1;
                                    end
                                else if(p==8447) 
                                    begin
                                        payload_done_mgmt <= 1'b1;
                                        data_s<=crc_32[0];
                                        frame_type_check<=1'b0;    
                                    end    
                                            
                                            
                         
                        end
                        if(FRAME_TYPE == 2'b01&& payload_valid==1'b1)     //PAYLOAD FRAME
                        begin
                                crc_enable_32 <=1'b1;
                                payload<={8'hAB,seq_num,Length,16'hCDEF,reserved_pl,Length,payload_data};
                                data_s<=payload[t];
                                data_crc_32<=payload[t];
                                t<=t+1;
                                if(t==8416)
                                    begin
                                        crc_enable_32<=1'b0;
                                        crc_32_valid <= 1'b1;
                                        data_s<=crc_32[31];
                                        t<=t+1;
                                    end
                                else if(t==8417) begin
                                    crc_32_valid <= 1'b0;
                                    data_s<=crc_32[8447-t];
                                    t<=t+1;
                                end
                                   
                                else if(t>8417&&t<8447)
                                    begin
                                        data_s<=crc_32[8447-t];
                                        t<=t+1;
                                    end
                                else if(t==8447) 
                                    begin
                                        payload_done <= 1'b1;
                                        data_s<=crc_32[0];
                                        frame_type_check<=1'b0;    
                                    end    
                                            
                                            
                         
                        end
       
      end
      
      always @(posedge clk)               //SCRAMBLER
      begin
        if (State == Header || State == Payload)begin
            SCRAMB<={SCRAMB[14]^SCRAMB[13],SCRAMB[13:0]};
            data_out<=data_s^SCRAMB[14];
            k<=k+1;
            if(k==8671)begin
                SCRAMB_DONE <=1'b1;
            end
      end
      end
      
endmodule

