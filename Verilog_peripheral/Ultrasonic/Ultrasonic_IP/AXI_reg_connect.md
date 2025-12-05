# AXI-Lite IP: 하드웨어 구동형 읽기 전용 레지스터 구현 상세

이 문서는 AXI-Lite IP에서 하드웨어(FPGA 로직)에 의해 지속적으로 업데이트되고, 프로세서(MicroBlaze)에게는 읽기 전용으로 제공되는 레지스터(`slv_reg0`)를 구현하는 방법에 대해 상세히 설명합니다.

## 1. `slv_reg0` 업데이트 방식에 대한 분석

`myip_ultrasonic_fsm_v1_0_S00_AXI.v` 파일의 AXI Write 로직(`always @(posedge S_AXI_ACLK)` 블록) 내 `if (slv_reg_wren)` 문의 `else` 브랜치에 `slv_reg0[13:0] <= digit_for_display;`와 같이 값을 할당하는 방식이 안좋은 이유

```verilog
// 코드 (예시)
always @( posedge S_AXI_ACLK )
begin
  // ...
  else begin
    if (slv_reg_wren) // AXI Write가 있을 때
      begin
        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          2'h0: // slv_reg0에 대한 AXI Write 로직
            // ...
        endcase
      end
    else begin // AXI Write가 없을 때
         slv_reg0[13:0] <= digit_for_display; // <--- 제안된 부분
    end
  end
end
```

### 1.1 문제점 분석

위 방식은 다음과 같은 문제점을 가집니다.

1.  **다중 드라이버 문제 (Multiple Driver Issue)**:
    *   `slv_reg0`는 이미 `always @(posedge S_AXI_ACLK)` 블록 안에서 AXI Write 로직(`if (slv_reg_wren)`)에 의해 값을 할당받을 수 있도록 설계되어 있습니다.
    *   여기에 `else` 브랜치에 `slv_reg0 <= ...`를 추가하면, `slv_reg_wren`이 `false`일 때 `slv_reg0`가 AXI Write 로직과 `else` 브랜치, 두 곳에서 동시에 값을 할당받으려 합니다.
    *   Verilog에서 `reg` 타입 신호는 **오직 하나의 `always` 블록 안에서만 값을 할당받아야 합니다.** 그렇지 않으면 합성 시 에러가 발생하거나, 시뮬레이션과 합성 결과가 달라지는 예측 불가능한 동작을 합니다.

2.  **읽기 전용 레지스터의 목적**:
    *   `slv_reg0`를 프로세서가 거리 값을 **읽어가는(Read-Only)** 레지스터로 사용하는 것이 목표입니다. 프로세서가 이 레지스터에 값을 **쓰는(Write)** 것은 원치 않습니다. 제안 방식은 `slv_reg0`를 AXI Write 로직에 의해 쓰여질 수도 있고, 하드웨어에 의해 쓰여질 수도 있는 복잡한 레지스터로 만듭니다.

## 2. 견고한 하드웨어 구동형 읽기 전용 레지스터 구현

`slv_reg0`를 하드웨어(예: `distance_from_fsm`)에 의해서만 업데이트되고, 프로세서에게는 읽기 전용인 레지스터로 만드는 가장 표준적이고 견고한 방식은 다음과 같습니다.

### 2.1 `slv_reg0`를 AXI Write 로직에서 제거 (프로세서 쓰기 방지)

프로세서가 `slv_reg0`에 값을 쓰지 못하도록, AXI Write 로직에서 `slv_reg0`에 대한 쓰기 케이스를 제거합니다.

**수정 전 (`myip_ultrasonic_fsm_v1_0_S00_AXI.v` 파일 내 AXI Write 로직):**

```verilog
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      slv_reg0 <= 0; // 리셋 시 초기화는 유지
      // ...
    end 
  else begin
    if (slv_reg_wren)
      begin
        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          2'h0: // <--- 이 부분을 삭제합니다.
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          2'h1:
            // ... (slv_reg1, slv_reg2, slv_reg3 케이스)
        endcase
      end
  end
end    
```

**수정 후 (2'h0 케이스 삭제):**

```verilog
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      slv_reg0 <= 0; // 리셋 시 초기화는 유지
      // ...
    end 
  else begin
    if (slv_reg_wren)
      begin
        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          // 2'h0 케이스를 삭제하여 프로세서가 slv_reg0에 쓰지 못하게 함
          2'h1: // slv_reg1부터 시작
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          // ... (slv_reg2, slv_reg3 케이스 유지)
          default : begin
                      // slv_reg0는 이제 AXI Write에 의해 업데이트되지 않으므로,
                      // default 케이스에서 slv_reg0 <= slv_reg0; 라인은 필요 없습니다.
                      slv_reg1 <= slv_reg1;
                      slv_reg2 <= slv_reg2;
                      slv_reg3 <= slv_reg3;
                    end
        endcase
      end
  end
end    
```

### 2.2 `slv_reg0`에 하드웨어 값 지속 업데이트 로직 추가

`slv_reg0` 변수 자체에 `distance_from_fsm` 값을 계속 넣어주는 `always` 블록을 추가합니다.

**추가할 코드 (`myip_ultrasonic_fsm_v1_0_S00_AXI.v` 파일 내 `// Add user logic here` 블록 바로 위에 추가):**

```verilog
// slv_reg0를 distance_from_fsm 값으로 계속 업데이트하는 로직
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARESETN == 1'b0) begin
        slv_reg0 <= 0; // 리셋 시 초기화
    end else begin
        // distance_from_fsm 값을 slv_reg0에 계속 넣어줌 (32비트에 맞춰 상위 비트는 0으로 채움)
        slv_reg0 <= {22'b0, distance_from_fsm}; 
    end
end
```

### 2.3 AXI Read 로직에서 `slv_reg0` 직접 읽기

`slv_reg0` 변수 자체가 `distance_from_fsm` 값을 가지고 있으므로, AXI Read 로직은 `slv_reg0`를 직접 읽도록 구성합니다.

**수정 전 (`myip_ultrasonic_fsm_v1_0_S00_AXI.v` 파일 내 AXI Read 로직):**

```verilog
always @(*)
begin
      // Address decoding for reading registers
      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
        2'h0   : reg_data_out <= {22'b0, distance_from_fsm}; // <--- 이 부분을 수정
        // ...
      endcase
end
```

**수정 후:**

```verilog
always @(*)
begin
      // Address decoding for reading registers
      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
        2'h0   : reg_data_out <= slv_reg0; // <--- slv_reg0 변수 자체를 읽도록 되돌림
        // ...
      endcase
end
```

### 결론

이러한 수정들을 통해 `slv_reg0`는 하드웨어(`distance_from_fsm`)에 의해 지속적으로 업데이트되고, 프로세서는 이 값을 읽기만 할 수 있는 견고한 읽기 전용 레지스터로 기능하게 됩니다. 이 방식은 `slv_reg0`의 역할을 명확히 합니다.

## 3. `slv_reg0`의 최종 동작 요약 (Final Operation Summary of `slv_reg0`)

위에서 설명된 수정 사항들을 적용한 후, `slv_reg0` 레지스터의 동작은 다음과 같이 요약할 수 있습니다.

*   **하드웨어에 의한 쓰기 (Write by Hardware):**
    *   `slv_reg0`는 `distance_from_fsm` 값에 의해 **지속적으로 업데이트**됩니다. 이는 `myip_ultrasonic_fsm_v1_0_S00_AXI.v` 파일에 추가된 별도의 `always @(posedge S_AXI_ACLK)` 블록에 의해 제어됩니다.
    *   프로세서(MicroBlaze)는 AXI Write 로직에서 `slv_reg0`에 대한 쓰기 케이스(`2'h0`)가 제거되었으므로, `slv_reg0`에 직접 값을 **쓸 수 없습니다.**

*   **프로세서에 의한 읽기 (Read by Processor):**
    *   프로세서는 AXI Read 인터페이스를 통해 주소 `2'h0`에 접근하여 `slv_reg0`의 현재 값을 **읽을 수 있습니다.**
    *   이때 읽는 값은 하드웨어(`distance_from_fsm`)에 의해 가장 최근에 업데이트된 값입니다.

결론적으로, `slv_reg0`는 하드웨어 로직에 의해 값이 결정되고, 프로세서는 그 값을 모니터링(읽기)만 할 수 있는 **하드웨어 구동형 읽기 전용 레지스터**로 동작합니다.
