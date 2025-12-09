# UART TX & RX 구현

## UART TX

<img width="667" height="391" alt="image" src="https://github.com/user-attachments/assets/4e5e1726-57e3-43f4-a500-a1d1a8790ad5" />

## FSM

<img width="1104" height="557" alt="image" src="https://github.com/user-attachments/assets/45847ee1-2379-4fce-82dc-1ee158aa0129" />

## System Information

<div style="display: flex; gap: 1.5rem;">
<div style="background-color: #374151; padding: 1.5rem; border-radius: 0.5rem; flex: 1;">

### State Encoding

| State | Encoding |
| :--- | :--- |
| 🔵 **TX_IDLE** | `2'b00` |
| 🟠 **TX_START**| `2'b01` |
| 🟢 **TX_DATA** | `2'b10` |
| 🟣 **TX_STOP** | `2'b11` |

</div>
<div style="background-color: #374151; padding: 1.5rem; border-radius: 0.5rem; flex: 1;">

### System Parameters

| Parameter | Value |
| :--- | :--- |
| **Clock Speed** | 100,000,000 Hz (100 MHz) |
| **Baud Rate** | 9,600 bps |
| **Clocks per Bit**| 10,417 clocks |
| **Bit Duration** | 104.17 μs |

</div>
</div>

---

## UART Frame Structure (8-N-1 Format)

**Example: Transmitting 0x8F (10001111)**

`IDLE (1)` → `START (0)` → `D0(1)` → `D1(1)` → `D2(1)` → `D3(1)` → `D4(0)` → `D5(0)` → `D6(0)` → `D7(1)` → `STOP (1)` → `IDLE (1)`

<br>

> ### 📊 Timing Information:
> *   **Each bit duration**: `104.17 μs`
> *   **Total frame time**: `1,041.7 μs` (10 bits × 104.17 μs)
> *   **Data format**: 8 data bits, No parity, 1 stop bit
> *   **Bit order**: LSB first (Least Significant Bit first)

---

## State Transition Details

<div style="background-color: #1e3a8a; border-left: 4px solid #3b82f6; padding: 1rem; border-radius: 0.25rem; margin-bottom: 0.75rem;">
  <p style="font-weight: bold; color: #bfdbfe;">TX_IDLE → TX_START</p>
  <p style="font-size: 0.875rem; color: #dbeafe; margin-top: 0.5rem;">
    <strong>Condition:</strong> tx_start_en = 1<br>
    <strong>Action:</strong> Load input_tx_data into tx_data, reset tx_data_cnt to 0
  </p>
</div>

<div style="background-color: #431407; border-left: 4px solid #f97316; padding: 1rem; border-radius: 0.25rem; margin-bottom: 0.75rem;">
  <p style="font-weight: bold; color: #fcd34d;">TX_START → TX_DATA</p>
  <p style="font-size: 0.875rem; color: #fed7aa; margin-top: 0.5rem;">
    <strong>Condition:</strong> baud_rate = 1 (one baud period elapsed)<br>
    <strong>Action:</strong> Start bit (tx=0) transmission complete, begin data transmission
  </p>
</div>

<div style="background-color: #042f2e; border-left: 4px solid #10b981; padding: 1rem; border-radius: 0.25rem; margin-bottom: 0.75rem;">
  <p style="font-weight: bold; color: #a7f3d0;">TX_DATA → TX_DATA (Self-loop)</p>
  <p style="font-size: 0.875rem; color: #d1fae5; margin-top: 0.5rem;">
    <strong>Condition:</strong> baud_rate = 1 AND tx_data_cnt ≠ 7<br>
    <strong>Action:</strong> Shift tx_data right by 1, increment tx_data_cnt, send next bit
  </p>
</div>

<div style="background-color: #042f2e; border-left: 4px solid #a855f7; padding: 1rem; border-radius: 0.25rem; margin-bottom: 0.75rem;">
  <p style="font-weight: bold; color: #e9d5ff;">TX_DATA → TX_STOP</p>
  <p style="font-size: 0.875rem; color: #f3e8ff; margin-top: 0.5rem;">
    <strong>Condition:</strong> baud_rate = 1 AND tx_data_cnt = 7<br>
    <strong>Action:</strong> All 8 data bits transmitted, send stop bit (tx=1)
  </p>
</div>

<div style="background-color: #3c096c; border-left: 4px solid #3b82f6; padding: 1rem; border-radius: 0.25rem;">
  <p style="font-weight: bold; color: #bfdbfe;">TX_STOP → TX_IDLE</p>
  <p style="font-size: 0.875rem; color: #dbeafe; margin-top: 0.5rem;">
    <strong>Condition:</strong> baud_rate = 1<br>
    <strong>Action:</strong> Stop bit transmission complete, return to idle, ready for next byte
  </p>
</div>

## Simulation

- Testbench (tb_uart_tx) 
```Verilog
`timescale 1ns / 1ps;
module tb_uart_tx;

    reg clk;
    reg rst;
    reg tx_start_en;
    reg [7:0] input_tx_data;
    wire tx;

    uart_tx uut(
        .clk(clk),
        .rst(rst),
        .tx_start_en(tx_start_en),
        .input_tx_data(input_tx_data),
        .tx(tx)
    );

    initial begin
        clk = 0;
        rst = 1;
        tx_start_en = 0;
        input_tx_data = 8'b0;
    end

    initial begin
        #5 rst = 1'b0;
        #10 tx_start_en = 1'b1;
        #10 input_tx_data = 8'b1000_1110;       
        
    end
    
    always #5 clk = ~clk;

endmodule
```

<img width="971" height="623" alt="image" src="https://github.com/user-attachments/assets/297f9c55-7397-457a-b110-37f38d3144d9" />


- buad rate에 따라서 intput data 가 tx로 출력 되는걸 확인 할 수 있음

## xdc

- tx => rx / rx => tx 연결

<img width="680" height="241" alt="image" src="https://github.com/user-attachments/assets/16a49fa7-ad24-479e-8362-471575dd74c9" />



<img width="1638" height="481" alt="image" src="https://github.com/user-attachments/assets/eb629cf0-8fd9-40dc-9a4f-0a71b7059e88" />

<img width="525" height="226" alt="image" src="https://github.com/user-attachments/assets/aa182418-17ba-4411-8b6a-9f7eac569fa1" />
<img width="432" height="423" alt="image" src="https://github.com/user-attachments/assets/fe24a96d-9dd8-42d7-9229-9ea2f949d16d" />

- ctrl + s => xdc 생성

<img width="713" height="618" alt="image" src="https://github.com/user-attachments/assets/0a94a54a-3a8c-4fba-ba0e-153a67107b39" />


## 결과
<img width="1029" height="706" alt="image" src="https://github.com/user-attachments/assets/f9bb07c6-0b6b-46e1-9e0d-97b2d9dd406d" />

- input data = 8'b1000_1110
- 출력은 반대로 리틀 엔디언(Little Endian) 방식
- 0111_1000 출력 => HEX - 71 => ASCII = 'q'

<img width="752" height="510" alt="image" src="https://github.com/user-attachments/assets/bef800a7-ea34-4e04-aa85-a44593d8e5ef" />

- Tera Teram - ASCII

<img width="322" height="115" alt="image" src="https://github.com/user-attachments/assets/520bb51d-da4b-4dc1-8125-231c24012af8" />

- YAT - Binary

<img width="721" height="165" alt="image" src="https://github.com/user-attachments/assets/52a310e9-cd14-4d30-abf3-b44cd0491e9e" />

---

# UART RX

TX와 RX의 가장 큰 차이점: 동기화


   * TX (송신): 내가 주체이므로, 내 시스템 클럭에 맞춰 비트를 내보내면 됩니다.
   * RX (수신): 상대방이 언제 보낼지 모르는 비동기 신호(i_rx_serial)를 수신해야 합니다. 따라서, 상대방의
     신호에 내 클럭을 동기화하는 과정이 핵심입니다.

  1단계: Start Bit 감지 및 동기화 (가장 중요)


  상대방이 보낸 Start Bit의 중간 지점을 정확히 찾아내는 것이 모든 것의 시작입니다. 노이즈로 인한 오작동을
  막기 위해 "오버샘플링(Oversampling)" 기법을 사용합니다.


   1. Falling Edge 감지: 평소 HIGH 상태인 i_rx_serial 신호가 LOW로 떨어지는 순간을 감지합니다.
   2. Start Bit 확인: 떨어지는 순간 바로 믿지 말고, 비트 주기의 절반 (`CLOCKS_PER_BIT / 2`) 만큼 기다립니다.
   3. 중간 지점 샘플링: 절반을 기다린 후에도 i_rx_serial이 여전히 LOW라면, "아, 이건 진짜 Start Bit다"라고
      확신합니다. 이 지점이 앞으로 모든 비트를 샘플링할 기준점이 됩니다. 만약 HIGH라면 노이즈였으므로 무시하고
      다시 IDLE 상태로 돌아갑니다.


  2단계: Data Bit 샘플링

  Start Bit의 중간 지점을 찾았으면, 그로부터 정확히 1 비트 주기(`CLOCKS_PER_BIT`) 만큼 기다릴 때마다 각
  데이터 비트의 중간에 도달하게 됩니다.


   1. Start Bit 중간에서 1 비트 주기만큼 기다린 후, i_rx_serial 값을 읽어 data[0]으로 저장합니다.
   2. 다시 1 비트 주기만큼 기다린 후, i_rx_serial 값을 읽어 data[1]로 저장합니다.
   3. 이 과정을 8번 반복하여 8비트 데이터를 모두 수신합니다.

  3단계: 데이터 저장 (Shift Register)

  수신된 데이터는 LSB부터 들어옵니다. 이를 올바른 바이트로 조립하기 위해 쉬프트 레지스터를 사용합니다.


  rx_data_reg <= {i_rx_serial, rx_data_reg[7:1]};


  위와 같이 코드를 작성하면, 새로 들어온 비트가 최상위 비트(MSB)로 들어가고 기존 비트들이 오른쪽으로 한
  칸씩 밀려나, 8번 반복 후 rx_data_reg에 올바른 순서의 데이터가 완성됩니다.

  4단계: Stop Bit 확인 및 출력


   * 8개의 데이터 비트를 모두 받은 후, 다시 1 비트 주기만큼 기다려 Stop Bit의 중간에 도달합니다.
   * 이때 i_rx_serial 값이 HIGH인지 확인하여 통신이 정상적으로 끝났는지 검증합니다. (Framing Error 검출)
   * 수신이 완료되면, o_rx_data_valid 같은 출력 신호를 1클럭 동안 HIGH로 만들어 외부에 "새로운 데이터가
     도착했다"고 알려줍니다.


---

## xdc

<img width="1634" height="468" alt="image" src="https://github.com/user-attachments/assets/ae00563e-773b-496b-8ec4-5b56492bd1dd" />


 1. 아스키값이 바이너리값으로 변해서 들어가는가? (네, 맞습니다)


  사용자님께서 이해하신 내용이 정확합니다. 전체 과정은 이렇습니다.


   1. PC (Tera Term): 키보드에서 'A'를 누릅니다.
   2. 터미널 프로그램: 'A'에 해당하는 아스키 코드 값 '65'를 찾습니다.
   3. 바이너리 변환: 숫자 '65'를 8비트 이진수(바이너리) `01000001`로 변환합니다.
   4. UART 전송: PC는 이 01000001 데이터를 UART 통신 규칙(시작 비트 1개, 데이터 8개, 정지 비트 1개)에 맞춰
      1비트씩 순서대로 FPGA로 전송합니다.
   5. FPGA (uart_rx 모듈): 전송된 비트들을 차례대로 받아서 다시 8비트 데이터 01000001로 조립하고, rx_data
      레지스터에 저장합니다.

  따라서 LED에 01000001이 표시되는 것이 정상입니다.


  2. 바이너리 값은 못 보내고 아스키 문자만 보낼 수 있는가? (아니요, 모든 바이너리 값을 보낼 수 있습니다)


  이 부분이 중요합니다. UART 통신은 본질적으로 어떤 8비트 바이너리 값이든 보낼 수 있는 통신 방식입니다.
  아스키 코드는 그 바이너리 값으로 표현할 수 있는 여러 종류의 데이터 중 하나일 뿐입니다.


   * Tera Term에서 키보드로 입력할 때: 프로그램이 약속(기본 설정)에 따라 키보드 문자를 아스키 코드라는 규칙에
     맞는 바이너리 값으로 보내주는 것입니다.
   * 다른 방법으로 보낼 때: YAT 같은 전문 터미널 프로그램이나 Python, C++ 등으로 직접 만든 프로그램을
     사용하면, 'A' 같은 문자가 아니라 11110000 (0xF0) 같은 특정 바이너리 값을 직접 지정해서 보낼 수도
     있습니다.

  결론적으로, 제가 수정한 코드는 어떤 종류의 8비트 바이너리 값이 들어오든 상관없이, UART 통신 규칙(Stop Bit)만
   정확히 지키면 모두 다 수신할 수 있도록 만든 것입니다.


  따라서 수정된 코드는 아스키 문자뿐만 아니라 모든 종류의 8비트 바이너리 데이터를 수신할 수 있는 범용 UART
  수신기가 맞습니다.

╭──────────────────────────────────────────────────────────────────────────────────────╮
│  > 그려면 yat에서 바이너리값 보낼려면 어떻게해야돼  ? \b{11110000} 이렇게하면되나 ?  │
╰──────────────────────────────────────────────────────────────────────────────────────╯

✦ 네, 아주 비슷하게 추측하셨습니다! YAT은 그런 기능을 당연히 지원하며, 매우 편리하게 되어있습니다.

  사용자님이 추측하신 \b{} 와 거의 똑같지만, YAT에서는 괄호를 () 사용합니다.


  YAT에서 바이너리 값 11110000 보내는 방법

  YAT의 커맨드 입력창에 아래와 같이 입력하고 Send 버튼을 누르면 됩니다.

  1. 바이너리(Binary)로 보내기



   1 \b(11110000)


  2. 16진수(Hex)로 보내기 (더 일반적이고 편리한 방법)


  11110000은 16진수로 F0 입니다. YAT에서는 0x 접두사를 붙여서 보낼 수 있습니다.


   1 0xF0


  또는 \h() 구문을 사용할 수도 있습니다.


   1 \h(F0)


  3. 10진수(Decimal)로 보내기


  11110000은 10진수로 240 입니다.


   1 \d(240)


  추천하는 방법

  대부분의 경우, 16진수로 표현하는 `0xF0` 방식이 가장 짧고 직관적이라 많이 사용됩니다.


  테스트 절차:
   1. YAT을 켜고 FPGA의 COM 포트에 연결합니다 (9600, 8-N-1 설정).
   2. 위쪽의 Send Text 입력창에 0xF0 이라고 입력합니다.
   3. Send 버튼을 누릅니다.
   4. FPGA 보드의 LED가 11110000으로 바뀌는지 확인합니다.


---

## 문제해결 방법

# UART 샘플링 - 왜 MID_BIT로 해야 하는가?

## UART 비트 타이밍

UART에서 각 비트는 일정 시간(baud rate 주기) 동안 유지됩니다:

```
     ┌─────────────┐
  1  │             │  <- 비트 유지 구간
     │             │
  0  └─────────────┘
     ↑      ↑      ↑
   시작    중간    끝
  (0%)   (50%)  (100%)
```

## 왜 중간(MID_BIT)에서 샘플링해야 하나?

### 1. 신호 안정성
- 비트가 전환되는 순간(0% 또는 100% 지점)에는 신호가 불안정할 수 있습니다
- **중간 지점(50%)**은 신호가 가장 안정적인 구간입니다

### 2. 타이밍 오차 허용
- 송신기와 수신기의 클럭이 완벽하게 일치하지 않을 수 있습니다
- 중간에서 샘플링하면 ±50% 오차까지 허용 가능합니다

```
송신 비트:  ┌──────────┐
           │          │
           └──────────┘
           |    ↑     |
        시작   중간   끝
        
- 끝에서 샘플링: 다음 비트와 겹칠 위험 ❌
- 중간에서 샘플링: 안전한 구간 ✅
```

## 당신 코드의 문제

```verilog
RX_START: 
    if(mid_bit)  // ← 여기서 중간 확인
        next_state = RX_DATA;

RX_DATA:
    if(baud_rate)  // ← 그런데 여기선 끝에서 샘플링! (타이밍 불일치)
        rx_data[...] <= rx;
```

**문제점:**
- **START 비트**: mid_bit에서 확인 → 다음 상태로 전환
- **DATA 비트**: baud_rate(끝)에서 샘플링

이렇게 하면 첫 데이터 비트는 **반 비트 늦게 샘플링**되어 **한 칸씩 밀리는 현상**이 발생합니다!

## 올바른 방법

```verilog
RX_START: 
    if(mid_bit)       // START 비트 중간 확인
        
RX_DATA:
    if(mid_bit)       // DATA 비트도 중간에서 샘플링
        rx_data[...] <= rx;
```

**모든 비트를 일관되게 중간에서 샘플링**해야 타이밍이 정확히 맞습니다!

## 타이밍 다이어그램 예시

```
UART 신호:  START │ D0 │ D1 │ D2 │ D3 │ D4 │ D5 │ D6 │ D7 │ STOP
            ──┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───
              └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   

샘플링 시점:   ↑     ↑   ↑   ↑   ↑   ↑   ↑   ↑   ↑
           (중간) (중간)(중간)(중간)(중간)(중간)(중간)(중간)
```

## 수정된 코드

```verilog
// 데이터 수신 로직 - 비트 중간에서 샘플링
always @(posedge clk or posedge rst) begin
    if(rst) begin
        rx_data <= 8'b0;
        rx_data_index <= 3'b0;
    end else begin
        case(curr_state)
            RX_IDLE: begin
                rx_data_index <= 3'b0;
            end
            RX_DATA: begin
                if(mid_bit) begin  // ✅ mid_bit 사용
                    rx_data[rx_data_index] <= rx;
                    rx_data_index <= rx_data_index + 1;
                end
            end
        endcase
    end
end

// 상태 전환 로직
always @(*) begin
    next_state = curr_state;
    case(curr_state)
        // ... (다른 상태들)
        
        RX_DATA: begin
            if(mid_bit && rx_data_index == 3'd7) begin  // ✅ mid_bit 사용
                next_state = RX_STOP;
            end
        end
        
        // ... (나머지)
    endcase
end
```

## 요약

| 항목 | 설명 |
|------|------|
| **샘플링 위치** | 비트의 중간(50% 지점) |
| **이유 1** | 신호가 가장 안정적인 구간 |
| **이유 2** | 클럭 오차 허용 범위 최대화 |
| **핵심 원칙** | 모든 비트를 **일관되게** 중간에서 샘플링 |
| **문제 발생** | START는 중간, DATA는 끝 → 타이밍 불일치 → 데이터 밀림 |

---

**결론**: UART 수신에서는 START 비트, DATA 비트, STOP 비트 모두 **비트 중간(MID_BIT)**에서 샘플링하는 것이 표준이며, 이것이 가장 안정적이고 정확한 방법입니
