# Ultrasonic_FSM IP 

- Using basys3 board , Microblaze process

<img width="927" height="622" alt="image" src="https://github.com/user-attachments/assets/00797c47-e11b-4534-a29a-f1d98a7f3694" />

<img width="923" height="626" alt="image" src="https://github.com/user-attachments/assets/b8b358f8-9f75-4abb-b922-81f61242975e" />

<img width="928" height="626" alt="image" src="https://github.com/user-attachments/assets/d3915474-ac3e-4105-a426-bc7cd9514bd5" />

---
 2. IP의 Input/Output 설정 기준


  IP를 하나의 검은 상자(Black Box)라고 생각하면 쉽습니다.


   - `input`: IP 외부에서 IP 안으로 들어와야 하는 신호입니다.
       - 물리적 핀에서 들어오는 신호: echo 신호는 외부 초음파 센서로부터 FPGA 핀을 통해 들어오므로 IP의
         input이 되어야 합니다.
       - 다른 IP에서 들어오는 신호: 만약 다른 IP의 출력을 받아야 한다면 input으로 설정합니다.


   - `output`: IP 내부에서 IP 밖으로 나가야 하는 신호입니다.
       - 물리적 핀으로 나가는 신호: trig 신호는 FPGA 핀을 통해 외부 센서로 나가야 합니다. AN, dec_out
         신호들도 7-세그먼트 부품으로 나가야 합니다. 따라서 이들은 모두 IP의 output이 되어야 합니다.
       - 다른 IP로 전달하는 신호: 만약 이 IP의 결과를 다른 IP가 사용해야 한다면 output으로 설정합니다.


   - 내부 신호 (`wire`): IP 내부의 하위 모듈끼리만 주고받는 신호는 밖으로 내보낼 필요가 없습니다.
       - distance_from_fsm 신호는 fsm_inst에서 생성되어 display_inst와 AXI 읽기 로직(reg_data_out)에서만
         사용됩니다. IP 밖에서는 알 필요가 없으므로, 이는 input이나 output이 아닌 내부 wire로 선언하는 것이
         맞습니다.

  ---

  3. 포트 선언 시 wire vs. reg

  이것은 Verilog의 매우 중요한 규칙과 관련이 있습니다.


   - `input` 포트: 모듈의 input 포트는 항상 `wire` 타입이어야 합니다. 외부에서 들어오는 신호를 받는 '통로'
     역할만 하기 때문입니다. reg는 값을 저장하는 '저장 공간'인데, 입력 포트가 스스로 값을 저장할 수는
     없습니다.


   - `output` 포트: output 포트는 wire 또는 reg가 될 수 있으며, 어떻게 값을 할당하는지에 따라 결정됩니다.


       - `output wire`를 쓰는 경우 (연결 통로)
           - assign 문을 사용해 값을 지속적으로 할당할 때.
           - 하위 모듈의 출력을 상위 모듈의 출력으로 바로 연결할 때.
           - 지금 만드신 IP의 trig, AN, dec_out은 모두 하위 모듈(fsm_inst, display_inst)의 출력이 그대로
             밖으로 나가는 것이므로 output wire로 선언하는 것이 정확합니다.


       - `output reg`를 쓰는 경우 (저장 공간)
           - always 블록 안에서 값을 할당할 때.
           - always 블록은 특정 조건(예: 클럭 엣지)에서만 실행되므로, 그 외의 시간에는 값을 유지해야 합니다.
             이 '유지/저장' 기능 때문에 reg 타입이 반드시 필요합니다.
           - 예시: always @(posedge clk) out <= a + b; 와 같은 코드에서 out은 output reg로 선언되어야 합니다.


  요약하자면, 모듈의 포트는 외부와의 '연결'을 정의하는 것이므로, 대부분의 경우 `wire`를 사용해 '통로'를
  만들어주고, `always` 블록을 통해 직접 출력을 제어해야 할 때만 예외적으로 `output reg`를 사용한다고
  생각하시면 됩니다.



---

AXI IP를 만드는 현재 상황에서는 UltrasonicDistanceDisplay 모듈이 더 이상 필요하지 않습니다.

  그 이유는 다음과 같습니다.


   1. 역할의 대체:
       - 기존의 UltrasonicDistanceDisplay 모듈의 역할은 UltrasonicDistanceFSM과 _4_DIGIT_DISPLAY라는 두
         부품을 가져와서 서로 연결해주는 단순한 껍데기(Wrapper) 였습니다.
       - 이제는 myip_ultrasonic_fsm_v1_0_S00_AXI.v 파일이 그 역할을 대신하게 되었습니다. 이 새로운 AXI IP
         파일이 두 부품을 가져와 연결하고, 거기에 더해 프로세서(MicroBlaze)와의 통신 기능까지 추가한 더
         똑똑하고 기능이 많은 껍데기가 된 것입니다.


   2. 신호 접근성:
       - 프로세서가 거리 값을 읽으려면 distance_cm_out 신호에 직접 접근해야 합니다.
       - UltrasonicDistanceDisplay 모듈을 통째로 사용하면 이 신호가 모듈 내부에 숨겨지게 되므로, AXI IP가 이
         값을 읽어올 수 없습니다.
       - 따라서 AXI IP 파일 안에서 두 하위 모듈을 직접 불러와야 distance_cm_out 신호를 AXI 레지스터에 연결할
         수 있습니다.


  ---

  요약:


  기존의 UltrasonicDistanceDisplay는 '단순 포장지'였다면, 새로운 AXI IP(..._S00_AXI.v)는 '프로세서와 통신
  기능이 추가된 스마트 포장지'가 된 셈입니다. 따라서 더 좋은 포장지가 생겼으니 기존의 단순 포장지는 이번 IP
  제작 과정에서는 필요가 없습니다.


  다만, 나중에 MicroBlaze 없이 그냥 7-세그먼트에 거리만 표시하는 독립적인 프로젝트를 다시 만들고 싶다면,
  그때는 UltrasonicDistanceDisplay.v 파일이 유용하게 쓰일 수 있습니다.

---

  <img width="909" height="416" alt="image" src="https://github.com/user-attachments/assets/e3a6d7c1-98f0-42d0-bfb6-963347707274" />
