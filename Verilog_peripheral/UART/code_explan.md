# UART 인터럽트 구현 가이드

> **환경**: Basys3 보드 + MicroBlaze Processor + Vitis 2022.2

## 📋 목차
1. [프로젝트 개요](#프로젝트-개요)
2. [하드웨어 구성](#하드웨어-구성)
3. [코드 구조 분석](#코드-구조-분석)
4. [인터럽트 동작 원리](#인터럽트-동작-원리)
5. [주요 함수 설명](#주요-함수-설명)
6. [트러블슈팅](#트러블슈팅)

---

## 프로젝트 개요

UART 통신을 **인터럽트 방식**으로 구현하여 문자열을 수신하고, 수신된 명령어에 따라 LED와 PWM 타이머를 제어하는 프로젝트입니다.

### 주요 기능
- ✅ UART 인터럽트 기반 문자열 수신
- ✅ 줄바꿈 문자(`\r`, `\n`) 감지 시 완전한 문자열 처리
- ✅ 명령어 `w`: LED 및 Custom IP LED 켜기
- ✅ 명령어 `s`: LED 및 Custom IP LED 끄기
- ✅ PWM 타이머를 이용한 다중 출력 제어

---

## 하드웨어 구성

### Vivado Block Design 구성요소

| IP 블록 | 역할 |
|--------|------|
| **MicroBlaze** | 메인 프로세서 |
| **AXI Interrupt Controller** | 인터럽트 중재 |
| **AXI UART Lite** | UART 통신 (115200 baud) |
| **AXI GPIO** | LED 제어 |
| **Custom IP (myip_led4)** | 사용자 정의 LED 컨트롤러 |
| **Custom IP (myip_tcounter2)** | PWM 타이머 (6채널) |
| **Local Memory (BRAM)** | 프로그램 메모리 (최소 64KB 권장) |

### 연결 구조
```
UART RX → AXI UART Lite → Interrupt → AXI INTC → MicroBlaze
                                                     ↓
                                            ISR (UartIntrHandler)
```

---

## 코드 구조 분석

### 전역 변수

```c
// UART 및 인터럽트 컨트롤러 인스턴스
static XUartLite g_uart_inst;      // UART 드라이버 구조체
static XIntc g_intc_inst;          // 인터럽트 컨트롤러 드라이버

// 수신 버퍼 관련
volatile char g_rx_buffer[100];    // 수신된 문자열 저장 (최대 99자 + NULL)
volatile int g_rx_index = 0;       // 현재 버퍼 인덱스
volatile int g_new_data_received = 0; // 완전한 문자열 수신 플래그
```

**📌 왜 `volatile`을 사용할까?**
- 인터럽트 핸들러(ISR)와 메인 루프에서 동시에 접근하는 변수
- 컴파일러 최적화로 인한 데이터 불일치 방지
- 메모리에서 항상 최신 값을 읽도록 보장

---

## 인터럽트 동작 원리

### 1️⃣ 인터럽트 발생 조건

UART 수신 버퍼에 데이터가 들어오면 자동으로 인터럽트 발생:

```c
XUL_SR_RX_FIFO_VALID_DATA  // UART 상태 레지스터 플래그
```

### 2️⃣ 인터럽트 서비스 루틴 (ISR)

```c
void UartIntrHandler(void *CallBackRef) {
    // 1. UART 수신 버퍼에 데이터가 있는지 확인
    if(XUartLite_GetStatusReg(g_uart_inst.RegBaseAddress) & 
       XUL_SR_RX_FIFO_VALID_DATA) {
        
        // 2. 한 바이트 읽기
        char rx_char = Xil_In32(g_uart_inst.RegBaseAddress + 
                                XUL_RX_FIFO_OFFSET);
        
        // 3. 줄바꿈 문자 확인 (Enter 키)
        if(rx_char == '\r' || rx_char == '\n') {
            g_rx_buffer[g_rx_index] = '\0';  // NULL 종료 문자
            g_new_data_received = 1;         // 플래그 설정
            g_rx_index = 0;                  // 인덱스 초기화
        }
        // 4. 일반 문자는 버퍼에 저장
        else {
            if(g_rx_index < (sizeof(g_rx_buffer) - 1)) {
                g_rx_buffer[g_rx_index++] = rx_char;
            }
        }
    }
}
```

**동작 흐름:**
```
문자 입력 → ISR 호출 → 버퍼에 저장 → Enter 입력 시 플래그 설정
```

### 3️⃣ 버퍼 오버플로우 방지

```c
if(g_rx_index < (sizeof(g_rx_buffer) - 1))
```
- 버퍼 크기: 100바이트
- 실제 저장 가능: 99자 (마지막 1바이트는 NULL 문자용)
- 초과 문자는 자동으로 무시됨

---

## 주요 함수 설명

### SetupInterruptSystem()

인터럽트 시스템 초기화 및 설정

```c
int SetupInterruptSystem() {
    int status;
    
    // 1단계: UART 초기화
    status = XUartLite_Initialize(&g_uart_inst, 
                                   XPAR_AXI_UARTLITE_0_DEVICE_ID);
    if(status != XST_SUCCESS) return XST_FAILURE;
    
    // 2단계: 인터럽트 컨트롤러 초기화
    status = XIntc_Initialize(&g_intc_inst, 
                              XPAR_MICROBLAZE_0_AXI_INTC_DEVICE_ID);
    if(status != XST_SUCCESS) return XST_FAILURE;
    
    // 3단계: UART 인터럽트를 컨트롤러에 연결
    status = XIntc_Connect(&g_intc_inst, 
                           XPAR_MICROBLAZE_0_AXI_INTC_AXI_UARTLITE_0_INTERRUPT_INTR,
                           (XInterruptHandler)UartIntrHandler, 
                           (void *)0);
    if(status != XST_SUCCESS) return XST_FAILURE;
    
    // 4단계: 인터럽트 컨트롤러 시작
    status = XIntc_Start(&g_intc_inst, XIN_REAL_MODE);
    if(status != XST_SUCCESS) return XST_FAILURE;
    
    // 5단계: UART 인터럽트 활성화
    XIntc_Enable(&g_intc_inst, 
                 XPAR_MICROBLAZE_0_AXI_INTC_AXI_UARTLITE_0_INTERRUPT_INTR);
    
    // 6단계: MicroBlaze 예외 처리 활성화
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, 
                                  (Xil_ExceptionHandler)XIntc_InterruptHandler, 
                                  &g_intc_inst);
    Xil_ExceptionEnable();
    
    // 7단계: UART 인터럽트 최종 활성화
    XUartLite_EnableInterrupt(&g_uart_inst);
    
    return XST_SUCCESS;
}
```

**초기화 순서가 중요한 이유:**
1. 하드웨어 초기화 → 연결 설정 → 활성화 순서 준수
2. 순서가 바뀌면 인터럽트가 제대로 동작하지 않음

---

### main() 함수

```c
int main() {
    // 캐시 활성화 (성능 향상)
    Xil_ICacheEnable();
    Xil_DCacheEnable();
    
    printf("---uart interrupt example ---\r\n");
    
    // 인터럽트 시스템 설정
    int status = SetupInterruptSystem();
    if(status != XST_SUCCESS) {
        print("Interrupt Setup FAILED\r\n");
        return XST_FAILURE;
    }
    
    // 메인 루프
    while(1) {
        // 완전한 문자열 수신 확인
        if(g_new_data_received) {
            xil_printf("Received: %s \r\n", (char*)g_rx_buffer);
            
            // 명령어 'w': LED 켜기
            if(strcmp((const char*)g_rx_buffer, "w") == 0) {
                *(unsigned int *)XPAR_AXI_GPIO_0_BASEADDR = 0xf;
                *(unsigned int *)XPAR_MYIP_LED4_0_S00_AXI_BASEADDR = 0xf;
            }
            // 명령어 's': LED 끄기
            else if(strcmp((const char*)g_rx_buffer, "s") == 0) {
                *(unsigned int *)XPAR_AXI_GPIO_0_BASEADDR = 0x0;
                *(unsigned int *)XPAR_MYIP_LED4_0_S00_AXI_BASEADDR = 0x0;
            }
            
            g_new_data_received = 0;  // 플래그 리셋
        }
        else {
            // PWM 타이머 설정 (6채널)
            unsigned int *tcReg = (unsigned int *)XPAR_MYIP_TCOUNTER2_0_S00_AXI_BASEADDR;
            
            // 채널 0: 1초 주기, 50% Duty
            tcReg[0] = (1 << 31) | (100000000 - 1);  // Period + Enable
            tcReg[1] = (100000000/2) - 1;            // Duty Cycle
            
            // 구조체 방식으로도 접근 가능
            MYIP_TIMER *myip_timer = (MYIP_TIMER *)XPAR_MYIP_TCOUNTER2_0_S00_AXI_BASEADDR;
            
            // 채널 1: 0.8초 주기
            myip_timer->slv_reg2 = (1 << 31) | (100000000 - 1);
            myip_timer->slv_reg3 = (80000000/2) - 1;
            
            // 채널 2: 0.6초 주기
            myip_timer->slv_reg4 = (1 << 31) | (100000000 - 1);
            myip_timer->slv_reg5 = (60000000/2) - 1;
            
            // 채널 3: 0.4초 주기
            myip_timer->slv_reg6 = (1 << 31) | (100000000 - 1);
            myip_timer->slv_reg7 = (40000000/2) - 1;
            
            // 채널 4: 0.2초 주기
            myip_timer->slv_reg8 = (1 << 31) | (100000000 - 1);
            myip_timer->slv_reg9 = (20000000/2) - 1;
            
            // 채널 5: 0.1초 주기
            myip_timer->slv_reg10 = (1 << 31) | (100000000 - 1);
            myip_timer->slv_reg11 = (10000000/2) - 1;
        }
    }
    
    // 프로그램 종료 시 캐시 비활성화
    Xil_DCacheDisable();
    Xil_ICacheDisable();
    return 0;
}
```

---

## PWM 타이머 레지스터 구조

### 레지스터 맵

| 레지스터 | 기능 | 비트 구성 |
|---------|------|----------|
| `slv_reg0` | CH0 Period | `[31]: Enable`, `[30:0]: Period` |
| `slv_reg1` | CH0 Duty | `[30:0]: Duty Cycle` |
| `slv_reg2` | CH1 Period | `[31]: Enable`, `[30:0]: Period` |
| `slv_reg3` | CH1 Duty | `[30:0]: Duty Cycle` |
| ... | ... | ... |

### Period 값 계산

```c
// 클럭: 100MHz, 원하는 주파수: 1Hz
Period = (Clock / Frequency) - 1
       = (100,000,000 / 1) - 1
       = 99,999,999
```

### Duty Cycle 계산

```c
// 50% Duty Cycle
Duty = (Period / 2)
     = 99,999,999 / 2
     = 49,999,999
```

### Enable 비트 설정

```c
(1 << 31) | Period  // MSB를 1로 설정하여 타이머 활성화
```

---


## 트러블슈팅

### 1. 메모리 부족 오류

```
error: region 'microblaze_0_local_memory' overflowed by XXXX bytes
```

**원인:** BRAM 크기가 프로그램 크기보다 작음

**해결방법:**
1. Vivado에서 Local Memory 크기를 64KB 이상으로 증가
2. Hardware Export → Vitis에서 Platform 업데이트
3. Clean & Rebuild

### 2. 인터럽트가 동작하지 않음

**체크리스트:**
- [ ] Vivado에서 UART 인터럽트가 INTC에 연결되어 있는가?
- [ ] `SetupInterruptSystem()` 반환값이 성공인가?
- [ ] UART Baud Rate 설정이 일치하는가? (115200)
- [ ] 터미널 프로그램에서 줄바꿈 설정이 `CR+LF`인가?

### 3. 문자가 깨져서 수신됨

**원인:** Baud Rate 불일치

**해결:**
- Vivado: UART Lite IP 설정에서 Baud Rate 확인
- 터미널: 115200, 8N1 설정 확인

### 4. `strcmp()` 함수가 항상 실패

**원인:** NULL 종료 문자가 없거나 줄바꿈 문자 포함

**해결:**
```c
// ISR에서 명확히 NULL 종료
g_rx_buffer[g_rx_index] = '\0';

// 또는 줄바꿈 문자 제거
g_rx_buffer[strcspn(g_rx_buffer, "\r\n")] = '\0';
```

---

## 성능 최적화 팁

### 1. 캐시 활성화
```c
Xil_ICacheEnable();  // 명령어 캐시
Xil_DCacheEnable();  // 데이터 캐시
```
- 성능 향상: 약 2~10배
- 메모리 액세스 속도 개선

### 2. 컴파일 최적화
- **Project Properties → C/C++ Build → Settings**
- **Optimization Level**: `-O2` (속도) 또는 `-Os` (크기)

### 3. 버퍼 크기 조정
```c
volatile char g_rx_buffer[100];  // 필요에 따라 조정
```
- 작은 버퍼: 메모리 절약
- 큰 버퍼: 긴 명령어 수신 가능

---

**개발 환경:** Basys3, Vivado 2022.2, Vitis 2022.2  
**프로세서:** MicroBlaze
