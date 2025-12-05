# Vivado IP : AXI-Lite, Verilog 포트, Tcl 스크립트 활용

이 문서는 Vivado를 활용한 IP 개발 시 고려해야 할 주요 사항들을 정리합니다. AXI-Lite IP 설계, Verilog 모듈의 입출력 포트 설정, 그리고 Tcl 스크립트를 이용한 프로젝트 관리 방법에 대해 다룹니다.

## 1. Verilog IP의 Input/Output 설정 기준

IP를 하나의 블랙박스(Black Box)로 간주할 때, 외부와의 신호 흐름을 명확히 정의하는 것이 중요합니다.

*   **`input` 포트:**
    *   IP 외부에서 IP 내부로 들어오는 신호입니다.
    *   **예시:** 물리적 핀(예: 초음파 센서의 `echo` 신호)에서 FPGA 핀을 통해 들어오는 신호, 또는 다른 IP의 출력을 받아야 하는 경우.

*   **`output` 포트:**
    *   IP 내부에서 IP 외부로 나가는 신호입니다.
    *   **예시:** 물리적 핀(예: 초음파 센서의 `trig` 신호, 7-세그먼트 디스플레이의 `AN`, `dec_out` 신호)으로 나가는 신호, 또는 이 IP의 결과를 다른 IP가 사용해야 하는 경우.

*   **내부 신호 (`wire`):**
    *   IP 내부의 하위 모듈끼리만 주고받는 신호로, IP 외부로 노출할 필요가 없습니다.
    *   **예시:** `distance_from_fsm` 신호는 FSM 인스턴스에서 생성되어 디스플레이 인스턴스와 AXI 읽기 로직에서만 사용되는 경우.

## 2. Verilog 포트 선언 시 `wire` vs. `reg`

Verilog에서 모듈의 포트를 선언할 때 `wire`와 `reg` 타입의 선택은 값을 할당하는 방식과 밀접하게 관련됩니다.

*   **`input` 포트:**
    *   항상 `wire` 타입이어야 합니다. `input` 포트는 외부에서 들어오는 신호를 받는 '통로' 역할을 하며, 스스로 값을 저장할 수 없습니다.

*   **`output` 포트:**
    *   `wire` 또는 `reg` 타입이 될 수 있으며, 값 할당 방식에 따라 결정됩니다.
    *   **`output wire` 사용 경우:**
        *   `assign` 문을 사용하여 값을 지속적으로 할당할 때.
        *   하위 모듈의 출력을 상위 모듈의 출력으로 직접 연결할 때.
        *   **예시:** `trig`, `AN`, `dec_out`과 같이 하위 모듈의 출력이 그대로 외부로 나가는 경우.
    *   **`output reg` 사용 경우:**
        *   `always` 블록 안에서 값을 할당할 때.
        *   `always` 블록은 특정 조건(예: 클럭 엣지)에서만 실행되므로, 그 외의 시간에는 값을 유지해야 합니다. 이 '유지/저장' 기능 때문에 `reg` 타입이 필요합니다.
        *   **예시:** `always @(posedge clk) out <= a + b;`와 같은 코드에서 `out`은 `output reg`로 선언되어야 합니다.

## 3. Vivado Tcl 스크립트 활용 및 소스 파일 관리

Vivado 프로젝트를 Tcl 스크립트로 관리하면 프로젝트의 이식성과 재현성을 높일 수 있습니다.

### 3.1 Tcl 스크립트 생성 방법 (Vivado GUI)

<img width="469" height="463" alt="image" src="https://github.com/user-attachments/assets/8da6e74c-8eda-49fb-aa73-d853605da977" />

<img width="532" height="445" alt="image" src="https://github.com/user-attachments/assets/7f29208e-6178-4d10-a876-78f82eaae221" />

1.  Tcl로 만들고 싶은 Vivado 프로젝트를 엽니다.
2.  상단 메뉴에서 `File` → `Project` → `Write Tcl...`을 클릭합니다.
3.  `Write Project to Tcl` 대화상자에서 다음을 설정합니다.
    *   **Tcl file name:** 생성할 Tcl 파일의 이름과 경로를 지정합니다 (예: `C:/Users/45/Desktop/create_my_project.tcl`).
    *   **`Copy sources to new project`:** 이 옵션을 선택하는 것을 강력히 권장합니다. 프로젝트에 사용된 모든 Verilog 소스 파일(.v), 제약 파일(.xdc), IP 설정 등을 Tcl 파일과 함께 `sources`라는 폴더에 복사해줍니다. 이 옵션을 통해 Tcl 스크립트와 `sources` 폴더만 있으면 어디서든 프로젝트를 완벽하게 복원할 수 있습니다.
    *   **`Recreate Block Design using Tcl`:** 반드시 체크해야 합니다. 이 옵션을 체크해야 MicroBlaze와 AXI IP 등을 연결한 Block Design을 스크립트로 복원할 수 있습니다.
4.  `OK` 버튼을 클릭하여 Tcl 스크립트를 생성합니다.

### 3.2 Tcl 스크립트 실행 시 "파일 없음" 오류 해결

Tcl 스크립트 실행 시 소스 파일을 찾지 못하는 오류는 주로 소스 파일 경로 문제로 발생합니다.

*   **`Copy sources...` 옵션 선택 시 동작:**
    *   Vivado는 Tcl 스크립트 생성 시, 프로젝트에 필요한 모든 `.v` 및 `.xdc` 파일들을 `sources_1` (또는 유사한 이름) 폴더 안에 복사합니다.
    *   생성된 Tcl 스크립트 안에는 이 `sources_1` 폴더 내의 파일들을 추가하라는 `add_files` 명령어가 **상대 경로**로 기록됩니다.
    *   **결과:** Tcl 스크립트 파일과 `sources_1` 폴더는 하나의 세트가 되며, 이 세트만 있으면 어디서든 프로젝트를 복원할 수 있습니다.

*   **`Copy sources...` 옵션 미선택 시 문제점:**
    *   Tcl 스크립트 안에 소스 파일들의 **절대 경로**가 기록됩니다 (예: `C:/Users/45/Desktop/my_project/src/a.v`).
    *   **문제:** 이 Tcl 스크립트를 다른 컴퓨터로 옮기거나, 원본 소스 파일들의 위치를 변경하면 Tcl 스크립트는 더 이상 파일들을 찾지 못하고 "파일이 없다"는 오류를 발생시킵니다.

*   **"파일 없음" 오류의 주요 원인:**
    *   가장 유력한 원인은 `write_project_tcl` 실행 시 `.tcl` 파일과 `sources_1` 폴더가 함께 생성되었으나, `.tcl` 파일만 다른 곳으로 옮기고 `sources_1` 폴더는 옮기지 않은 경우입니다. Tcl 스크립트는 약속된 위치에서 `sources_1` 폴더를 찾으려 하지만, 없으므로 오류가 발생합니다.
    *   다른 원인으로는 `Copy sources...` 옵션을 체크하지 않고 Tcl 스크립트를 생성한 후, 원본 파일들의 위치를 변경한 경우입니다.

*   **해결 방법:**
    *   가장 중요한 규칙은 "Tcl 스크립트 파일(.tcl)과 소스 폴더(`sources_1`)는 항상 함께 다녀야 한다"는 것입니다.
    *   이전에 `.tcl` 파일을 생성했던 폴더로 이동하여 `sources_1` (또는 `..._sources` 형태의) 폴더가 있는지 확인합니다.
    *   현재 Tcl 스크립트를 실행하려는 위치로 해당 `sources_1` 폴더를 통째로 복사하거나 이동합니다.

*   **올바른 폴더 구조 예시:**
    ```
    my_tcl_project/
    ├── create_project.tcl      <-- 실행하려는 Tcl 스크립트
    └── sources_1/              <-- Tcl 스크립트와 함께 있어야 하는 소스 폴더
        ├── hdl/
        │   ├── myip_ultrasonic_fsm_v1_0.v
        │   └── ...
        └── ip/
            └── ...
    ```
    위와 같이 구조를 맞춘 후, `my_tcl_project` 폴더로 이동해서 `source create_project.tcl` 명령을 다시 실행하면 하위 모듈 파일들을 정상적으로 찾아서 프로젝트를 생성할 것입니다.

