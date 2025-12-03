`timescale 1ns / 1ps
module TCounter(
    input CLK,
    input RSTn,
    input [31:0] top_in, // en, 4bit reserved, 27bit top
    input [31:0] cmp_in, // 5bit reserved, 27bit cmp
    output PWM
    );
    reg [26:0] cnt; // 27비트
    wire [26:0] top = top_in[26:0];
    wire [26:0] cmp = cmp_in[26:0];
    wire cnt_en = top_in[31];
    always @(posedge CLK) begin
        begin : CNT_MOD
            if(RSTn==0) cnt<=0;
            else if(cnt_en) begin
                if (cnt >= top) begin
                    cnt <= 0;
                end
                else begin
                    cnt<=cnt+1;
                end
            end
            else cnt<=0;
        end
    end
    assign PWM = (cnt < cmp)?1:0;
endmodule
