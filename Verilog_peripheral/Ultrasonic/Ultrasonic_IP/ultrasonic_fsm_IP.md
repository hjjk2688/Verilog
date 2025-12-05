# Ultrasonic_FSM IP 

- Using basys3 board , Microblaze process

<img width="927" height="622" alt="image" src="https://github.com/user-attachments/assets/00797c47-e11b-4534-a29a-f1d98a7f3694" />

<img width="923" height="626" alt="image" src="https://github.com/user-attachments/assets/b8b358f8-9f75-4abb-b922-81f61242975e" />

<img width="928" height="626" alt="image" src="https://github.com/user-attachments/assets/d3915474-ac3e-4105-a426-bc7cd9514bd5" />

---
### Block Design

<img width="1254" height="584" alt="image" src="https://github.com/user-attachments/assets/8b711b07-65c9-4ca4-aa0d-4f0ba798b8c2" />



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
 2. IP의 Input/Output 설정 기준


