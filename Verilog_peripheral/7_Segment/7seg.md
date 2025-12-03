# 7 Segment

<img width="495" height="217" alt="image" src="https://github.com/user-attachments/assets/e2699cb8-f50d-4465-8269-7ac115d92662" />

<img width="589" height="339" alt="image" src="https://github.com/user-attachments/assets/234f9e6d-cf2a-4162-8a7a-6098ae0785f8" />

- `seg` (모양): 공통 애노드(+3.3V)에 연결되어 있으므로, 반대쪽에서 0을 줘야 켜진다. (common anode)
-  `an` (자리): 0을 줘야 켜지는 전자 스위치(트랜지스터)를 제어하므로, 0을 줘야 해당 자리가 선택된다. (active low)
* Common anode, Common Cathode 설명 참조 : https://github.com/hjjk2688/Verilog/blob/main/Verilog_peripheral/7_Segment/common_source.md

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
- 카운터에 따라 led가 깜빡 거림
---
7segment

```Verilog
// 극성 테스트 : 스위치로 바로 연결해서 회로 검증
module _7SEG_TEST(
    input SW0, // V17
    input SW1, // V16
    output _U2,
    output _V7
    );
    assign _U2 = SW0;
    assign _V7 = SW1;
endmodule
```

```
set_property -dict { PACKAGE_PIN U2   IOSTANDARD LVCMOS33 } [get_ports {ANout[3]}]
set_property -dict { PACKAGE_PIN U4   IOSTANDARD LVCMOS33 } [get_ports {ANout[2]}]
set_property -dict { PACKAGE_PIN V4   IOSTANDARD LVCMOS33 } [get_ports {ANout[1]}]
set_property -dict { PACKAGE_PIN W4   IOSTANDARD LVCMOS33 } [get_ports {ANout[0]}]
```
- ANout 값으로 seg 자릿수를 선택한다.

---

## code
- 출력을 반전 시키는 이유
```text
assign {a,b,c,d,e,f,g} = ~decoder_outputs;
```
- Basys3 보드는 Common Anode 방식이라 실제로는 0을 주어야 LED가 켜집니다. 그래서 마지막 줄에서 ~ 연산자를 사용해 1단계에서 만든 모든 신호를 한꺼번에 뒤집어 주는 것입니다.

* 예시 (숫자 '1' 출력):
1. decoder_outputs (Active-High) = 7'b0110000
2. ~decoder_outputs (Active-Low) = 7'b1001111
3. 최종적으로 {a,b,c,d,e,f,g} 에는 7'b1001111이 출력되어, b와 c에만 0이 인가되므로 숫자 '1'이 정상적으로 표시됩니다.

**사람이 보기 쉽게 active high(1)로 표시 하지만 실제로는 active low(0) 이기 때문에 헷갈릴수있다. 위에 진리표에서도 1일때 켜진다고 되어있지만 회로적으로 0일때 켜진다.**
