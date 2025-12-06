# IP Module tcounter 
* 이미 만들어진 외부 IP Module 사용하기
  - Project Settings → IP → Repository에서 생성된 IP가 있는 디렉터리를 추가

#### Block Design

<img width="1268" height="527" alt="image" src="https://github.com/user-attachments/assets/4d5c271b-532c-4c84-8418-06df17269587" />

*system clk = 100M Hz

<img width="1030" height="843" alt="image" src="https://github.com/user-attachments/assets/f2303cc3-9a42-4b1d-8d6f-24e270e243d9" />

<img width="593" height="232" alt="image" src="https://github.com/user-attachments/assets/4c4313a1-7a2f-4621-b381-635132cc7d8a" />

<img width="775" height="518" alt="image" src="https://github.com/user-attachments/assets/6b1c04f4-0278-4064-bdc1-a7899d18edf9" />

* IP Module code

- myip_tcounter2_v1_0_S00_AXI.v
<img width="426" height="89" alt="image" src="https://github.com/user-attachments/assets/333b302b-9fcc-45f7-946d-23d642540daa" />

<img width="574" height="168" alt="image" src="https://github.com/user-attachments/assets/078191bd-4ec2-414f-b39a-c0add47841c1" />

- myip_tcounter2_v1_0.v
<img width="429" height="83" alt="image" src="https://github.com/user-attachments/assets/596bf187-8667-40a7-bf07-4fe8d95b5bd2" />
<img width="402" height="63" alt="image" src="https://github.com/user-attachments/assets/fa52e52e-392c-4e48-947b-dc898f089f0e" />

- TCounter.v
```Verilog
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
                if(cnt >= top) begin
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


```
- C언어 포인트 배열
- 참고 : https://github.com/hjjk2688/Verilog/edit/main/Verilog_basic/c.md

### vitis code
```C
   unsigned int * tcReg = (unsigned int *)XPAR_MYIP_TCOUNTER2_0_S00_AXI_BASEADDR;
   tcReg[0] = (1 << 31) | (100000000 - 1);
   tcReg[1] = (100000000/2)-1;
```
- point 배열을 이용해 주소로 해석
- [0] => baseaddr
- [1] => basedaddr + 4
- 레지스터 주소 체계를 따름
  
```C

typedef struct _MYIP_TIMER {
	volatile uint32_t slv_reg0;
	volatile uint32_t slv_reg1;
	volatile uint32_t slv_reg2;
	volatile uint32_t slv_reg3;
	volatile uint32_t slv_reg4;
	volatile uint32_t slv_reg5;
	volatile uint32_t slv_reg6;
	volatile uint32_t slv_reg7;
	volatile uint32_t slv_reg8;
	volatile uint32_t slv_reg9;
	volatile uint32_t slv_reg10;
	volatile uint32_t slv_reg11;
}MYIP_TIMER;

// !-- 아래 내용 코드는 같음 --!

   MYIP_TIMER * myip_timer = (MYIP_TIMER *)XPAR_MYIP_TCOUNTER2_0_S00_AXI_BASEADDR;

   myip_timer->slv_reg2 = (1 << 31) | (100000000- 1);
   myip_timer->slv_reg3 = (80000000/2)-1; //duty : 40%
   myip_timer->slv_reg4 = (1 << 31) | (100000000 - 1);
   myip_timer->slv_reg5 = (60000000/2)-1; // duty : 30%
   myip_timer->slv_reg6 = (1 << 31) | (100000000 - 1);
   myip_timer->slv_reg7 = (40000000/2)-1; // duty : 20 %
   myip_timer->slv_reg8 = (1 << 31) | (100000000 - 1);
   myip_timer->slv_reg9 = (20000000/2)-1; // duty : 10 %
   myip_timer->slv_reg10 = (1 << 31) | (100000000 - 1);
   myip_timer->slv_reg11 = (10000000/2)-1; // duty : 5%
```
* 1 << 31 을 하는 이유

1. `wire cnt_en = top_in[31];`
  - C 코드에서 tcReg[0]으로 전달된 32비트 값(top_in)의 31번째 비트를 cnt_en이라는 신호로 사용하고 있습니다.
2. `else if(cnt_en)`
  - always 블록 안을 보면, 카운터 cnt가 1씩 증가하는 동작은 cnt_en 신호가 1일 때만 수행됩니다.
  - 만약 cnt_en이 0이라면, 카운터는 계속 0으로 리셋(else cnt<=0;)되어 멈춰있게 됩니다.

C 코드에서 1 << 31 연산을 하지 않으면, cnt_en이 항상 0이 되어 카운터가 전혀 동작하지 않게 됩니다.
1 << 31은 카운터를 '켜는(Enable)' 스위치 역할을 하는 필수적인 코드입니다.

<img width="602" height="449" alt="image" src="https://github.com/user-attachments/assets/b7a84d35-cde6-4348-8029-d95c9c9f63cb" />

- 할당된 LED가 duty에 따라서 스르륵 on/off 된다.

## 참고
PWM , C 포인트 배열
https://github.com/hjjk2688/Verilog/blob/main/Verilog_basic/c.md
