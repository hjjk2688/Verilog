module BCD_CNT(
    input CLK100MHz,// W5
    input RST,// U18, BTNC
    output LED,// U16, LD0
    output [3:0] AN,//W4,V4,U4,U2
    output [6:0] dec_out //W7,W6,U8,V8,U5,V5,U7
    );
    
    reg [26:0] Cnt100Mhz;
    reg [13:0] Cnt1Hz;
    wire En1Hz;
    wire [3:0] Digit1000, Digit100, Digit10, Digit1;
    wire [3:0] AN_en;
    // Cnt100Mhz
    wire D,C,B,A,a,b,c,d,e,f,g;


    always @(posedge CLK100MHz) begin
        if(RST==1) Cnt100Mhz <= 0;
        else begin
            Cnt100Mhz <= Cnt100Mhz+1;
            if(Cnt100Mhz==(100_000_000-1))
            Cnt100Mhz <= 0;
        end
    end
    assign En1Hz = (Cnt100Mhz==(100_000_000-1))?1:0;
    // Cnt1Hz
    always @(posedge CLK100MHz) begin
        if(RST==1) Cnt1Hz <= 0;
        else if(En1Hz==1) begin
            Cnt1Hz <= Cnt1Hz+1;
            if(Cnt1Hz==(10000-1))
            Cnt1Hz <= 0;
        end
    end
    // 4 digit Binary
    assign Digit1000 = Cnt1Hz/1000; // 1000자리
    assign Digit100  = Cnt1Hz%1000/100; // 100자리
    assign Digit10   = Cnt1Hz%1000%100/10; // 10자리
    assign Digit1    = Cnt1Hz%1000%100%10; // 1자리

    assign LED = Digit1[0];

    // FSM 추가
    reg [1:0] DigitState;
    wire En1000Hz;
    assign En1000Hz = (Cnt100Mhz%100_000==0)?1:0;
    always @(posedge CLK100MHz)
        if(RST==1) DigitState<=2'b00;
        else if(DigitState==2'b00 && En1000Hz==1)
            DigitState <= 2'b01;
        else if(DigitState==2'b01 && En1000Hz==1)
            DigitState <= 2'b10;
        else if(DigitState==2'b10 && En1000Hz==1)
            DigitState <= 2'b11;
        else if(DigitState==2'b11 && En1000Hz==1)
            DigitState <= 2'b00;

        assign AN_en = (DigitState==2'b11)? 4'b1000:
        (DigitState==2'b10)? 4'b0100:
        (DigitState==2'b01)? 4'b0010:4'b0001;

        reg [3:0] Digit_now;
        always @ *
            begin
                Digit_now = 4'bxxxx;
                case(AN_en)
                    4'b1000: Digit_now = Digit1000;
                    4'b0100: Digit_now = Digit100;
                    4'b0010: Digit_now = Digit10;
                    4'b0001: Digit_now = Digit1;
                endcase
            end

    assign {D,C,B,A} = Digit_now;
    assign dec_out = {a,b,c,d,e,f,g};

    BCD7SEG_4 bcd7seg_4_0(AN_en,D,C,B,A,AN,a,b,c,d,e,f,g);

endmodule
