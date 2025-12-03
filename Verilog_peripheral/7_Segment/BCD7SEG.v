module BCD7SEG(
    input ANSel,D,C,B,A,//W19,W17,W16,V16,V17
    output ANout,a,b,c,d,e,f,g//U2,W7,W6,U8,V8,U5,V5,U7
    );
    wire [3:0] binary_inputs;
    wire [6:0] decoder_outputs;

    assign ANout = ~ANSel;
    assign binary_inputs={D,C,B,A};
    assign decoder_outputs =
    (binary_inputs==4'b0000)? 7'b1111110:
    (binary_inputs==4'b0001)? 7'b0110000:
    (binary_inputs==4'b0010)? 7'b1101101:
    (binary_inputs==4'b0011)? 7'b1111001:
    (binary_inputs==4'b0100)? 7'b0110011:
    (binary_inputs==4'b0101)? 7'b1011011:
    (binary_inputs==4'b0110)? 7'b1011111:
    (binary_inputs==4'b0111)? 7'b1110000:
    (binary_inputs==4'b1000)? 7'b1111111:
    (binary_inputs==4'b1001)? 7'b1111011:7'b0000000;

    assign {a,b,c,d,e,f,g} = ~decoder_outputs;
endmodule

module BCD7SEG_4(
    input [3:0] ANSel,//W19,T17,T18,U17
    input D,C,B,A,//W17,W16,V16,V17
    output [3:0] ANout,//W4,V4,U4,U2
    output a,b,c,d,e,f,g//W7,W6,U8,V8,U5,V5,U7
    );

    wire [6:0] S;
    wire [6:0] S3, S2, S1, S0;

    assign {a,b,c,d,e,f,g} = S;

    assign S = (ANSel==4'b1000)? S3:
    (ANSel==4'b0100)? S2:
    (ANSel==4'b0010)? S1:
    (ANSel==4'b0001)? S0:7'b1111111;

    BCD7SEG _7seg3(ANSel[3],D,C,B,A,ANout[3],S0[6],S0[5],S0[4],S0[3],S0[2],S0[1],S0[0]);
    BCD7SEG _7seg2(ANSel[2],D,C,B,A,ANout[2],S1[6],S1[5],S1[4],S1[3],S1[2],S1[1],S1[0]);
    BCD7SEG _7seg1(ANSel[1],D,C,B,A,ANout[1],S2[6],S2[5],S2[4],S2[3],S2[2],S2[1],S2[0]);
    BCD7SEG _7seg0(ANSel[0],D,C,B,A,ANout[0],S3[6],S3[5],S3[4],S3[3],S3[2],S3[1],S3[0]);

endmodule

module _7SEG_TEST(
    input SW0, // V17
    input SW1, // V16
    output _U2,
    output _V7
    );
    assign _U2 = SW0;
    assign _V7 = SW1;
endmodule

//////////////////////////////
// switch

`timescale 1ns / 1ps

    //input ANSel,D,C,B,A,//W19,W17,W16,V16,V17
    input ANSel,
    input [3:0] binary_inputs,
    //output ANout,a,b,c,d,e,f,g//U2,W7,W6,U8,V8,U5,V5,U7
    output ANout,
    output [6:0] decoder_outputs

    );
    //wire [3:0] binary_inputs;
    //wire [6:0] decoder_outputs;

    assign ANout = ~ANSel;
    //assign binary_inputs={D,C,B,A};
    assign decoder_outputs =
    (binary_inputs==4'b0000)? ~7'b1111110:
    (binary_inputs==4'b0001)? ~7'b0110000:
    (binary_inputs==4'b0010)? ~7'b1101101:
    (binary_inputs==4'b0011)? ~7'b1111001:
    (binary_inputs==4'b0100)? ~7'b0110011:
    (binary_inputs==4'b0101)? ~7'b1011011:
    (binary_inputs==4'b0110)? ~7'b1011111:
    (binary_inputs==4'b0111)? ~7'b1110000:
    (binary_inputs==4'b1000)? ~7'b1111111:
    (binary_inputs==4'b1001)? ~7'b1111011:~7'b0000000;

    //assign {a,b,c,d,e,f,g} = ~decoder_outputs;
endmodule

module BCD7SEG_4(
    input [3:0] ANSel,//W19,T17,T18,U17
    //input D,C,B,A,//W17,W16,V16,V17
    input [3:0] binary_inputs,
    output [3:0] ANout,//W4,V4,U4,U2
    output a,b,c,d,e,f,g//W7,W6,U8,V8,U5,V5,U7
    );

    wire [6:0] S;
    wire [6:0] S3, S2, S1, S0;

    assign {a,b,c,d,e,f,g} = S;

     assign S = (ANSel[3])? S3:
    (ANSel[2])? S2:
    (ANSel[1])? S1:
    (ANSel[0])? S0:7'b1111111;

    BCD7SEG _7seg3(ANSel[3],binary_inputs,ANout[3],S3);
    BCD7SEG _7seg2(ANSel[2],binary_inputs,ANout[2],S2);
    BCD7SEG _7seg1(ANSel[1],binary_inputs,ANout[1],S1);
    BCD7SEG _7seg0(ANSel[0],binary_inputs,ANout[0],S0);

endmodule
