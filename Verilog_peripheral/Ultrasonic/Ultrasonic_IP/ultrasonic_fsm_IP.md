# Ultrasonic_FSM IP 

- Using basys3 board , Microblaze process

<img width="927" height="622" alt="image" src="https://github.com/user-attachments/assets/00797c47-e11b-4534-a29a-f1d98a7f3694" />

<img width="923" height="626" alt="image" src="https://github.com/user-attachments/assets/b8b358f8-9f75-4abb-b922-81f61242975e" />

<img width="928" height="626" alt="image" src="https://github.com/user-attachments/assets/d3915474-ac3e-4105-a426-bc7cd9514bd5" />

---
## Block Design

<img width="1254" height="584" alt="image" src="https://github.com/user-attachments/assets/8b711b07-65c9-4ca4-aa0d-4f0ba798b8c2" />

---

## UltrasonicDistanceDisplay 모듈의 역할 대체 및 필요성

AXI IP를 개발하는 과정에서는 기존의 `UltrasonicDistanceDisplay` 모듈이 더 이상 필요하지 않을 수 있습니다.

*   **역할의 대체:**
    *   `UltrasonicDistanceDisplay` 모듈은 `UltrasonicDistanceFSM`과 `_4_DIGIT_DISPLAY`를 연결하는 단순한 래퍼(Wrapper) 역할을 했습니다.
    *   새로운 AXI IP (`myip_ultrasonic_fsm_v1_0_S00_AXI.v` 등) 파일이 이 래퍼 역할을 대신하며, 여기에 프로세서(MicroBlaze)와의 통신 기능까지 추가된 더 지능적인 래퍼가 됩니다.

*   **신호 접근성:**
    *   프로세서가 거리 값(`distance_cm_out`)을 읽으려면 이 신호에 직접 접근해야 합니다.
    *   `UltrasonicDistanceDisplay` 모듈을 통째로 사용하면 이 신호가 모듈 내부에 숨겨져 AXI IP가 값을 읽어올 수 없게 됩니다.
    *   따라서 AXI IP 파일 안에서 `UltrasonicDistanceFSM`과 `_4_DIGIT_DISPLAY` 두 하위 모듈을 직접 인스턴스화하고 연결해야 `distance_cm_out` 신호를 AXI 레지스터에 연결할 수 있습니다.

**결론:** 기존 `UltrasonicDistanceDisplay`는 '단순 포장지'였다면, 새로운 AXI IP는 '프로세서와 통신 기능이 추가된 스마트 포장지'이므로, AXI IP 제작 과정에서는 기존 모듈이 필요 없습니다. 단, MicroBlaze 없이 7-세그먼트에 거리만 표시하는 독립적인 프로젝트를 만들 때는 여전히 유용할 수 있습니다.

---
## Ultrasonic IP 

### myip_ultrasonic_fsm_v1_0_S00_AXI.v
- 실제 작동하는 모듈과 연결되는 중간

#### 설계 전략
1. 내부 모듈에 맞춰 port를 선언해준다.
2. 동작방식에 따라 reg에 데이터를 업데이트 시킨다.
3. 각 모듈을 연걸해 준다.
4. slv_reg0은 단순 데이터를 업데이트 (only read)
   
<img width="447" height="145" alt="image" src="https://github.com/user-attachments/assets/a3ee2af8-91b5-4761-b9ba-d4ac187e2011" /> </br>

<img width="485" height="264" alt="image" src="https://github.com/user-attachments/assets/c1e11220-c30d-447e-af9b-7b92a05f1536" /> </br>

<img width="750" height="402" alt="image" src="https://github.com/user-attachments/assets/bdc9e4d8-23d0-4bfe-b0eb-f6dee3f40878" />

<img width="823" height="141" alt="image" src="https://github.com/user-attachments/assets/7091b93a-2a64-4afa-8225-e094cc1d7207" />

- 기존 설계 전략 및 문제점
https://github.com/hjjk2688/Verilog/blob/main/Verilog_peripheral/Ultrasonic/Ultrasonic_IP/AXI_reg_connect.md

### myip_ultrasonic_fsm_v1_0.v
- my_ip_ultrasonic_fsm_v1_0.v 는 가장 외부 모듈로 외부 신호를 내부로 보내줌 (warrper)

<img width="414" height="115" alt="image" src="https://github.com/user-attachments/assets/2a8c0fe6-142b-4fd6-9603-5689294e1a18" />

<img width="404" height="122" alt="image" src="https://github.com/user-attachments/assets/c79ada60-700f-445f-ba5f-834dded9aa64" />


 
 ## 단순업데이트와 AXI write 의 차이

 # AXI-Lite 레지스터: 하드웨어 업데이트와 AXI 쓰기 동작의 차이점

이 문서는 AXI-Lite 슬레이브 IP에서 레지스터의 "하드웨어 업데이트"와 "AXI 버스를 통한 쓰기(Write)" 동작이 어떻게 다른지 설명합니다. 특히 `slv_reg0` 레지스터의 동작을 예시로 들어 설명합니다.

## 1. 하드웨어에 의한 레지스터 업데이트 (Verilog `always` 블록)

Verilog 코드 내 `always` 블록을 통해 레지스터(`reg` 타입 변수)의 값이 변경되는 것을 "하드웨어 업데이트"라고 합니다. 이는 FPGA 내부 로직에 의해 클럭 사이클마다 레지스터 값이 갱신되는 내부적인 동작입니다.

**예시 코드:**

```verilog
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARESETN == 1'b0) begin
        slv_reg0 <= 0; // 리셋 시 초기화
    end else begin
        // distance_from_fsm 값을 slv_reg0에 계속 넣어줌 (32비트에 맞춰 상위 비트는 0으로 채움)
        slv_reg0 <= {22'b0, distance_from_fsm}; 
    end
end
```

위 코드에서 `slv_reg0`는 `distance_from_fsm` 신호의 값으로 클럭에 맞춰 지속적으로 업데이트됩니다. 이 동작은 프로세서의 개입 없이 IP 내부의 하드웨어 로직에 의해 자율적으로 수행됩니다.

## 2. AXI 버스를 통한 레지스터 쓰기 (AXI Write)

AXI 버스를 통한 쓰기(Write)는 MicroBlaze와 같은 외부 마스터(프로세서)가 AXI-Lite 인터페이스를 통해 슬레이브 IP 내부의 특정 레지스터에 값을 변경하도록 명령하는 외부적인 동작입니다.

프로세서는 다음 과정을 통해 레지스터에 값을 씁니다.
*   **주소 전송:** 프로세서가 쓰고자 하는 레지스터의 주소(`AWADDR`)를 AXI 버스를 통해 전송합니다.
*   **데이터 전송:** 해당 주소에 쓸 데이터(`WDATA`)를 AXI 버스를 통해 전송합니다.
*   **IP 내부 처리:** 슬레이브 IP의 AXI 인터페이스 로직(일반적으로 `slv_reg_wren` 신호와 `axi_awaddr`를 확인하는 `always` 블록)이 이 외부 데이터를 받아 해당 내부 레지스터(`slv_regX`)에 값을 저장합니다.

## 3. `slv_reg0` 동작 분석 (제공된 시나리오)

제공된 시나리오에서 `slv_reg0`는 다음과 같은 특성을 가집니다.

*   **하드웨어에 의한 업데이트:** `slv_reg0`는 위 예시 코드와 같이 `distance_from_fsm` 값으로 하드웨어 내부에서 지속적으로 업데이트됩니다.
*   **AXI 쓰기 경로 차단:** AXI Write 로직에서 `slv_reg0`에 해당하는 주소(`2'h0`) 부분이 주석 처리되거나 제거되어 있습니다. 이는 프로세서가 AXI 버스를 통해 `slv_reg0`에 직접 값을 쓸 수 없음을 의미합니다.

**결론:**

따라서, `slv_reg0`는 하드웨어 내부 로직에 의해 `distance_from_fsm` 값으로 계속 업데이트되지만, 프로세서는 AXI 버스를 통해 `slv_reg0`에 값을 쓸 수 없습니다. 이러한 구성은 `slv_reg0`를 프로세서에게는 **하드웨어 구동형 읽기 전용 레지스터**로 기능하게 합니다. 프로세서는 `slv_reg0`의 값을 읽을 수는 있지만, 변경할 수는 없습니다.

---
## Vitis

``` Verilog
#define ULTRASONIC_IP_BASEADDR XPAR_MYIP_ULTRASONIC_FSM_0_S00_AXI_BASEADDR
#define REG0_OFFSET 0
int main ()
{
	Xil_ICacheEnable();
	Xil_DCacheEnable();

	xil_printf("Program Start \r\n");
	u32 reg_value; // 레지스터에서 읽어온 32비트 전체 값
	u32 distance;  // 32비트 값에서 추출한 10비트 거리 값

	while(1){
		reg_value = Xil_In32(ULTRASONIC_IP_BASEADDR + REG0_OFFSET);
		distance = reg_value & 0x3FF;

		xil_printf("Measured Distance: %d cm\r\n", distance);

		sleep(1); // trig_En 1초마다 활성화 되기떄문에  1초 delay를 줘서 맞춰준다. 
	}



	Xil_ICacheDisable();
	Xil_DCacheDisable();
   return 0;
}
```
#### 캐시란?

캐시는 프로세서와 메인 메모리(예: DDR RAM) 사이에 위치하는 작고 빠른 메모리입니다. 자주 사용되는 명령어와 데이터를 캐시에 저장하여, 
프로세서가 메인 메모리까지 가지 않고도 빠르게 접근할 수 있도록 하여 전체 시스템의 성능을 크게 향상시킵니다.

- ICache : 명령어 캐시 (Instruction Cache)
- DCache : 데이터 캐시 (Data Cache)

#### 캐시 활성화 이유
캐시를 활성화하는 것은 임베디드 시스템, 특히 복잡한 소프트웨어나 운영체제를 실행할 때 성능에 매우 중요합니다. 
캐시가 없으면 프로세서는 매번 느린 메인 메모리에서 명령어와 데이터를 가져와야 하므로, 프로그램 실행 속도가 현저히 느려집니다.

## 프로그램 동작
- baud rate

<img width="472" height="428" alt="image" src="https://github.com/user-attachments/assets/82a9ea94-972f-4480-8221-a1cef6ace70a" />

<img width="774" height="578" alt="image" src="https://github.com/user-attachments/assets/bc09aef8-1ebc-4b49-9c12-31d66163bf04" />

<img width="818" height="501" alt="image" src="https://github.com/user-attachments/assets/7429f36b-61fc-406e-b8c3-02c11df08db3" />

---

### 개선 사항
1. reg 를 나눠 enable 신호를 write를 하는부분을 추가한다.
2. read 와 write 하는 부분을 나눔으로써 read / write 동작 원리를 확인한다

참고 자료:

https://github.com/hjjk2688/Verilog/blob/main/IP/AXI-Lite_R%26W.md
