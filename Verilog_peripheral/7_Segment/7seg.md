# 7 Segment

<img width="589" height="339" alt="image" src="https://github.com/user-attachments/assets/234f9e6d-cf2a-4162-8a7a-6098ae0785f8" />

```Verilog
module BCD_CNT(
    input CLK100MHz,// W5
    input RST,// U18, BTNC
    output LED// U16, LD0
    );

    reg [26:0] Cnt100Mhz;
    reg [13:0] Cnt1Hz;
    wire En1Hz;
    wire [3:0] Digit1000, Digit100, Digit10, Digit1;
    // Cnt100Mhz
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

endmodule
```

