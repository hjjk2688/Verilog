# AXI-Lite IP: 레지스터 읽기/쓰기 및 하드웨어 제어 구현

본 문서는 AXI-Lite IP에서 프로세서(MicroBlaze)가 하드웨어(FPGA 로직)의 레지스터에 접근하여 값을 읽고 쓰는 일반적인 방법과, 이를 통해 하드웨어 동작을 제어하고 상태를 읽어오는 구현 방식에 대해 상세히 설명합니다.

## 1. AXI-Lite Read/Write 메커니즘 이해

AXI-Lite 프로토콜은 프로세서와 슬레이브 IP 간의 통신을 위해 별도의 읽기(Read) 및 쓰기(Write) 채널을 사용합니다.

*   **쓰기 (Write) 동작:**
    *   프로세서는 `S_AXI_AWADDR` (Write Address) 채널을 통해 쓰고자 하는 레지스터의 주소를 보냅니다.
    *   `S_AXI_WDATA` (Write Data) 채널을 통해 해당 주소에 쓸 데이터를 보냅니다.
    *   `S_AXI_WSTRB` (Write Strobe)를 통해 어떤 바이트를 쓸지 지정할 수 있습니다.
    *   슬레이브 IP는 쓰기 완료 후 `S_AXI_BVALID` (Write Response) 채널을 통해 응답을 보냅니다.
    *   슬레이브 IP 내부에서는 `slv_reg_wren` 신호가 활성화될 때 `S_AXI_AWADDR`에 해당하는 레지스터에 `S_AXI_WDATA` 값을 저장합니다.

*   **읽기 (Read) 동작:**
    *   프로세서는 `S_AXI_ARADDR` (Read Address) 채널을 통해 읽고자 하는 레지스터의 주소를 보냅니다.
    *   슬레이브 IP는 `S_AXI_ARADDR`에 해당하는 레지스터의 값을 `S_AXI_RDATA` (Read Data) 채널을 통해 프로세서로 보냅니다.
    *   슬레이브 IP는 읽기 데이터와 함께 `S_AXI_RVALID` (Read Valid) 신호를 활성화하여 데이터가 유효함을 알립니다.
    *   슬레이브 IP 내부에서는 `axi_araddr`에 따라 `reg_data_out` 신호에 해당 레지스터의 값을 할당합니다.

이러한 메커니즘을 통해 프로세서는 특정 주소에 값을 쓰거나 읽음으로써 슬레이브 IP 내부의 다양한 레지스터에 접근할 수 있습니다.

## 2. 제어 레지스터 (Writeable) 및 데이터 레지스터 (Readable) 구현 예시

초음파 센서 제어 시나리오를 예로 들어, 프로세서가 `enable` 신호를 써서 측정을 시작하고, 측정된 거리 값을 읽어오는 방식을 구현해 보겠습니다.

*   **`slv_reg0`: 제어 레지스터 (Control Register) - `ultrasonic_control`**
    *   프로세서가 이 레지스터에 값을 써서 초음파 측정 FSM의 동작을 제어합니다.
    *   예를 들어, `slv_reg0`의 특정 비트(예: `slv_reg0[0]`)를 '1'로 쓰면 측정을 시작하고, '0'으로 쓰면 중지할 수 있습니다.

*   **`slv_reg1`: 데이터 레지스터 (Data Register) - `measured_distance`**
    *   초음파 측정 FSM이 측정한 거리 값을 이 레지스터에 업데이트합니다.
    *   프로세서는 이 레지스터의 값을 읽어서 현재 측정된 거리를 알 수 있습니다.

### 2.1 AXI Write 로직 수정: `slv_reg0`를 제어 레지스터로 사용

프로세서가 `slv_reg0`에 값을 쓸 수 있도록 AXI Write 로직을 유지합니다. `slv_reg0`에 쓰여진 값은 하드웨어의 제어 신호로 사용됩니다.

**`myip_ultrasonic_fsm_v1_0_S00_AXI.v` 파일 내 AXI Write 로직:**

```verilog
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      slv_reg0 <= 0; // 리셋 시 초기화
      slv_reg1 <= 0; // 리셋 시 초기화
      // ... 다른 레지스터들도 초기화
    end 
  else begin
    if (slv_reg_wren)
      begin
        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          2'h0: // slv_reg0 (제어 레지스터)에 대한 AXI Write
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          2'h1: // slv_reg1 (데이터 레지스터)는 프로세서가 쓰지 않으므로, 이 케이스는 제거하거나 비워둡니다.
                // 만약 프로세서가 slv_reg1에 쓸 필요가 없다면 이 케이스를 제거합니다.
                // 여기서는 slv_reg1을 하드웨어 전용 쓰기 레지스터로 가정합니다.
            ; // No operation for slv_reg1 write by processor
          // ... (slv_reg2, slv_reg3 등 다른 레지스터 케이스)
          default : begin
                      // 다른 레지스터들은 현재 값을 유지
                      slv_reg0 <= slv_reg0;
                      slv_reg1 <= slv_reg1;
                      slv_reg2 <= slv_reg2;
                      slv_reg3 <= slv_reg3;
                    end
        endcase
      end
    else begin // AXI Write가 없을 때, 레지스터들은 현재 값을 유지
        slv_reg0 <= slv_reg0;
        slv_reg1 <= slv_reg1;
        slv_reg2 <= slv_reg2;
        slv_reg3 <= slv_reg3;
    end
  end
end    
```

### 2.2 하드웨어 로직 추가: `slv_reg0`로 `enable` 제어 및 `slv_reg1`에 거리 값 업데이트

`slv_reg0`의 특정 비트(예: `slv_reg0[0]`)를 `ultrasonic_enable` 신호로 사용하고, 초음파 FSM에서 측정된 `distance_from_fsm` 값을 `slv_reg1`에 업데이트합니다.

**`myip_ultrasonic_fsm_v1_0_S00_AXI.v` 파일 내 `// Add user logic here` 블록 주변:**

```verilog
// AXI-Lite IP의 출력 포트로 ultrasonic_enable 신호를 추가 (FSM으로 전달)
output wire ultrasonic_enable;

// slv_reg0의 최하위 비트를 enable 신호로 사용
assign ultrasonic_enable = slv_reg0[0];

// 초음파 FSM에서 측정된 거리 값을 slv_reg1에 업데이트하는 로직
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARESETN == 1'b0) begin
        slv_reg1 <= 0; // 리셋 시 초기화
    end else begin
        // distance_from_fsm 값을 slv_reg1에 계속 넣어줌 (32비트에 맞춰 상위 비트는 0으로 채움)
        // 이 로직은 초음파 FSM이 distance_from_fsm을 업데이트할 때마다 slv_reg1에 반영됩니다.
        slv_reg1 <= {22'b0, distance_from_fsm}; 
    end
end

// ... (여기에 초음파 FSM 인스턴스화 및 연결)
// ultrasonic_fsm_inst (
//    .clk(S_AXI_ACLK),
//    .reset_n(S_AXI_ARESETN),
//    .enable(ultrasonic_enable), // slv_reg0[0]에 의해 제어
//    .distance_out(distance_from_fsm)
// );
```

### 2.3 AXI Read 로직 수정: `slv_reg0` 및 `slv_reg1` 읽기

프로세서가 `slv_reg0` (제어 상태 확인)와 `slv_reg1` (측정된 거리 값)을 읽을 수 있도록 AXI Read 로직을 구성합니다.

**`myip_ultrasonic_fsm_v1_0_S00_AXI.v` 파일 내 AXI Read 로직:**

```verilog
always @(*)
begin
      // 기본값 설정 (읽기 주소가 유효하지 않을 경우)
      reg_data_out = 0; 

      // Address decoding for reading registers
      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
        2'h0   : reg_data_out = slv_reg0; // slv_reg0 (제어 레지스터) 읽기
        2'h1   : reg_data_out = slv_reg1; // slv_reg1 (거리 데이터 레지스터) 읽기
        // ... (slv_reg2, slv_reg3 등 다른 레지스터 케이스)
        default: reg_data_out = 0; // 정의되지 않은 주소는 0 반환
      endcase
end
```

### 2.4 Vitis (소프트웨어)에서의 접근 예시

프로세서 코드에서는 다음과 같이 레지스터에 접근할 수 있습니다.

```c
#define ULTRASONIC_IP_BASEADDR XPAR_MYIP_ULTRASONIC_FSM_0_S00_AXI_BASEADDR
#define CONTROL_REG_OFFSET 0  // slv_reg0
#define DISTANCE_REG_OFFSET 4 // slv_reg1 (32비트 레지스터이므로 4바이트 오프셋)

int main ()
{
    // ... 캐시 활성화 등 초기화

    xil_printf("--- Ultrasonic Control and Measurement Program Started ---\r\n");

    // 1. 초음파 측정 시작 (slv_reg0의 0번 비트를 1로 설정)
    Xil_Out32(ULTRASONIC_IP_BASEADDR + CONTROL_REG_OFFSET, 0x1); // 0x1 = 00...01b

    while(1){
        u32 control_status;
        u32 measured_distance;

        // 2. slv_reg0 (제어 레지스터)의 현재 상태 읽기 (선택 사항)
        control_status = Xil_In32(ULTRASONIC_IP_BASEADDR + CONTROL_REG_OFFSET);
        xil_printf("Control Register Status: 0x%08X (Enable: %d)\r\n", control_status, control_status & 0x1);

        // 3. slv_reg1 (거리 데이터 레지스터)에서 측정된 거리 값 읽기
        measured_distance = Xil_In32(ULTRASONIC_IP_BASEADDR + DISTANCE_REG_OFFSET);
        xil_printf("Measured Distance: %d cm\r\n", measured_distance);

        sleep(1); // 1초 대기
    }

    // ... 캐시 비활성화 등 정리
    return 0;
}
```

### 결론

이러한 방식으로 AXI-Lite IP 내의 여러 레지스터를 제어 레지스터, 상태 레지스터, 데이터 레지스터 등으로 구분하여 사용할 수 있습니다. 프로세서는 특정 주소에 대한 쓰기/읽기 동작을 통해 하드웨어의 동작을 시작시키거나, 하드웨어의 현재 상태 및 결과를 얻어올 수 있습니다. 이는 유연하고 강력한 하드웨어-소프트웨어 인터페이스를 구축하는 핵심적인 방법입니다.
