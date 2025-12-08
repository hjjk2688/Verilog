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




