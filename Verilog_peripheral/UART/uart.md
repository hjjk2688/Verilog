# UART
- Using basys3 board

## Uart Address

<img width="470" height="201" alt="image" src="https://github.com/user-attachments/assets/dd71ddcf-32ad-4b3c-9a97-a0dfb97e5ec8" />

<img width="1010" height="360" alt="image" src="https://github.com/user-attachments/assets/39f7baab-4fd1-47fe-9416-d8ee1bb2c0a5" />

<img width="488" height="310" alt="image" src="https://github.com/user-attachments/assets/e44f014c-1e09-47ce-8fcb-3ac38590b60c" />

* /* Definitions for peripheral AXI_UARTLITE_0 */
  - AXI_UARTLITE_0라는 특정 IP 하나의 하드웨어 정보를 소프트웨어에서 사용할 수 있도록 매크로 상수를 정의합니다.
  - XPAR_AXI_UARTLITE_0_DEVICE_ID: 시스템에 여러 장치가 있을 때 이 장치를 식별하기 위한 ID
  - XPAR_AXI_UARTLITE_0_BASEADDR: 해당 장치의 AXI 메모리 맵 시작 주소
  - XPAR_AXI_UARTLITE_0_HIGHADDR: 해당 장치의 AXI 메모리 맵 끝 주소
  -  UART가 2개 (AXI_UARTLITE_0, AXI_UARTLITE_1) 있다면, 이 섹션도 각 IP에 대해 별도로 2개가 생성

* /* Canonical definitions for peripheral AXI_UARTLITE_0 */
  - Canonical"은 "표준적인", "대표적인"이라는 의미를 가집니다. 이 섹션은 여러 개의 동일한 IP 중에서 표준 입출력(stdin, stdout) 등으로 사용될 대표 IP를 지정하는 역할을 합니다.
  - 목적: 특정 IP 인스턴스(AXI_UARTLITE_0)의 매크로를 더 일반적인 이름(별칭)으로 한 번 더 정의하여 코드의 이식성과 가독성을 높입니다.
  - 내용: BSP(Board Support Package) 설정에서 AXI_UARTLITE_0를 표준 출력(stdout)으로 지정했다면, 다음과 같은 매크로가 정의될 수 있습니다.
  - XPAR_UARTLITE_0_DEVICE_ID (Canonical 이름)  -> XPAR_AXI_UARTLITE_0_DEVICE_ID (실제 IP의 이름)
  - STDOUT_BASEADDRESS (Canonical 이름) -> XPAR_AXI_UARTLITE_0_BASEADDR (실제 IP의 주소)
 ---

### uart rx tx 
1. printf가 표준 출력(stdout)을 사용하듯, scanf는 표준 입력(stdin)을 사용
  - 문제점 : scanf는 블로킹(Blocking) 함수입니다. 즉, 사용자가 터미널에 값을 입력하고 Enter 키를 누를 때까지 프로그램의 모든 동작이 그 자리에서 멈춥니다.
2. 인터럽트(Interrupt) 기반의 비동기 수신
  - 참고: `sscanf`는 문자열로부터 형식화된 입력을 읽는 함수로, 블로킹되지 않기 때문에 인터럽트 방식과 함께 사용하기에 매우 좋습니다.
