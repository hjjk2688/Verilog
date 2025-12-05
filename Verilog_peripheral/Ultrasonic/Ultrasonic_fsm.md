# Ultrasonic FSM

## FSM 구현 단계

1. define state
2. current state logic
3. next state logic
4. output logic
5. timer logic
6. test bench

## FSM
- 각 상태 정의 및 TIMING 설계

<img width="963" height="589" alt="image" src="https://github.com/user-attachments/assets/9e411063-b9cb-4119-a2f2-4d5408d4532b" />
  
<img width="1885" height="1130" alt="image" src="https://github.com/user-attachments/assets/148c4a48-fda0-4174-88e3-539debecf461" />

1. RTL 주기는 1ms 가 보통이기때문에 18ms면 엄청 긴시간이다 이를 계속 기다릴수없기때문에 interrupt로 처리 해야 한다.
1GHz => 1G*4B => 4G => 4MB(1ms 일때 4M byte를 처리할수있다 => 예시로 확인한거처럼 18ms는 cpu에게 엄청 긴 시간이다.)

2. 각 상태별로 timer가 존재하며 총 4개가 필요하다.

3. echo 1 -> 0 으로 measure 구간을 정의하고 거리 계산에 이용한다.


- Using Oscilloscope 

<img width="1391" height="694" alt="image" src="https://github.com/user-attachments/assets/e2a77893-f4c8-4cc1-bfd0-4bcd6da72b2a" />

- TENMS 상태는 측정 완료 후 10ms 대기 상태입니다.

- TENMS 상태의 목적

1. 센서 안정화 시간 </br>
  a) Echo 신호가 끝난 직후 바로 다음 측정을 하면 안 됩니다 </br>
  b) 초음파가 완전히 사라질 때까지 기다려야 합니다 </br>
  c) 10ms 대기를 통해 센서를 안정화시킵니다 </br>

2. 간섭 방지 </br>
  a) 이전 측정의 잔향(echo)이 남아있을 수 있음 </br>
  b) 10ms 동안 기다려서 깨끗한 상태로 만듦 </br>
  c) 다음 측정의 정확도를 높입니다 </br>

```
FSM 흐름
MEASURE (echo 측정 완료) 
    ↓ echo=0
TENMS (10ms 대기)
    ↓ t10ms>=10ms
IDLE (1초 대기 후 다시 측정)
```
---
### FSM 상태 확인을 위한 Simulation

#### Testbench
```Verilog
module tb_simple();
    reg clk, rst, trigEn_ext, echo;
    wire trig;
    wire [9:0] distance_cm_out;
    wire [2:0] curr_state_out;
    wire led_1hz;
    
    UltrasonicDistanceFSM dut (
        .clk(clk),
        .rst(rst),
        .trigEn_ext(trigEn_ext),  // 외부 트리거
        .trig(trig),
        .echo(echo),
        .distance_cm_out(distance_cm_out),
        .curr_state_out(curr_state_out),
        .led_1hz(led_1hz)
    );
    
    initial begin
        clk = 0;
        rst = 1;
        trigEn_ext = 0;  // 초기값 0
        echo = 0;
        
        #100 rst = 0;
        
        #100 trigEn_ext = 1;  // 1 클럭만 HIGH
        // Echo 응답
        #462_0000 echo = 1;
        //  #25_000_100 echo = 0; // ns 기준 임 
        #18_000_000 echo = 0 ;   
        
        //#20000;
        // $finish;
    end
    
    always #5 clk = ~clk;
endmodule
```
```Verilgo
input trigEn_ext, // 테스트벤치용 시뮬레이션에서 trigEn 사용하기 위해 추가

assign trigEn = trigEn_ext | (cnt1s == (100_000_000 - 1)); // 테스트 벤치할떄 만 사용 
```
- trigEn 로 측정을 시작하고 echo 를 통해 측정하는 단계로 넘어감 echo 0 이되면 대기상태로 들어간다.

<img width="1465" height="927" alt="image" src="https://github.com/user-attachments/assets/b2e4a6ef-91a7-4c6e-a008-5eaca5764b95" />

<img width="1361" height="848" alt="image" src="https://github.com/user-attachments/assets/21d87f4d-a476-4b5c-99fe-f461bd1fd0cc" />



---
### 초음파 거리 측정 방법

- trigger에서 신호가 나간 후 echo 에 도달하는 시간 이용
- 우리는 위에서 정의한 상태: Measure 이용 ( echo 1 -> 0)
```
Echo 신호:  ______|‾‾‾‾‾‾‾‾‾‾|______
                 ↑          ↑
              echo=1    echo=0
              (시작)     (끝)
                 |__________|
                 이 시간을 측정!
```
```Verilog
    reg [21:0] cnt18ms;
    reg [21:0] distance_duration; // 이 값을 거리 계산에 이용 (구간 시간 측정)
    always @(posedge clk) begin
        if (rst ==1) begin
            cnt18ms <= 0;
            distance_duration <= 0;
        end
        else if(curr_state == MEASURE)begin
            cnt18ms <= cnt18ms +1;
            if(echo == 0) begin
                distance_duration <= cnt18ms;
            end
            if( cnt18ms >= (1800_000 - 1)) begin
                cnt18ms <= 0;
            end
        end
        else begin
            cnt18ms <= 0;
        end
    end
```
</br>

- 동작 순서

1. WAIT 상태: Echo 신호 기다림
2. echo = 1: MEASURE 상태로 전환, 카운터 시작
3. MEASURE 상태: 카운터 계속 증가
4. echo = 0: 카운터 값을 distance_duration에 저장
5. TENMS 상태: 10ms 대기 후 IDLE로

### 거리 계산

```Verilog
    // Distance Calculation
    // v = 340m/s, d = 170m * t (round trip)
    // 100us -> 1.7cm

    wire [9:0] distance_cm = distance_duration * 17 / 100_000;
    assign distance_cm_out = distance_cm;
```
* distance_duration: Echo가 HIGH였던 시간 (10ns 단위)
* 음속: 340m/s → 왕복 시간 고려

# Verilog 초음파 센서 거리 계산 공식 분석

## 개요

본 문서는 100MHz 클럭을 사용하는 FPGA 환경에서 Verilog로 구현된 초음파 센서 모듈의 거리 계산 공식을 분석하고, 최대 측정 가능 거리를 계산하는 것을 목표로 한다. 분석에 사용된 음속은 340m/s를 기준으로 한다.

## 1. 거리 계산 공식

모듈에 사용된 거리 계산 Verilog 코드는 다음과 같다.

```verilog
wire [9:0] distance_cm = distance_duration * 17 / 100_000;
```

- `distance_duration`: 초음파 센서의 `echo` 핀이 `HIGH` 상태를 유지하는 동안의 클럭 사이클 수.

## 2. 공식 유도 과정

해당 공식이 음속 340m/s와 100MHz 클럭 주파수를 기반으로 어떻게 도출되었는지 과정은 다음과 같다.

#### 기본 원리

- 초음파는 목표물까지 갔다가 돌아오는 왕복 거리를 이동한다.
- **거리 = (속력 × 시간) / 2**

#### 변수 정의

- **음속 (Speed of Sound)**: 340 m/s = **34,000 cm/s**
- **클럭 주파수 (Clock Frequency)**: 100 MHz = 100,000,000 Hz
- **클럭 주기 (Clock Period)**: 1 / 100,000,000 초 = 10 ns
- **Echo 시간 (Time)**: `distance_duration` (클럭 사이클 수) × 클럭 주기
  - `Time (s) = distance_duration / 100,000,000`

#### 수식 전개

위 변수들을 기본 원리 공식에 대입하여 `cm` 단위의 거리를 계산한다.

1.  **기본 공식에 변수 대입**
    ```
    거리(cm) = (34,000 cm/s * (distance_duration / 100,000,000 s)) / 2
    ```

2.  **상수 정리**
    ```
    거리(cm) = (34,000 * distance_duration) / (100,000,000 * 2)
    거리(cm) = (17,000 * distance_duration) / 100,000,000
    ```

3.  **Verilog 정수 연산을 위한 약분**
    분자와 분모를 `1,000`으로 나누어 연산을 간소화한다.
    ```
    거리(cm) = (17 * distance_duration) / 100,000
    ```
    이 결과는 코드에 사용된 수식과 정확히 일치한다.

## 3. 최대 측정 가능 거리 계산

최대 측정 거리는 `echo` 신호를 기다리는 최대 시간(Timeout)에 의해 결정된다. `echo`의 최대 대기 시간을 **25ms**로 가정했을 때 최대 측정 거리는 다음과 같다.

1.  **최대 대기 시간을 클럭 사이클로 변환**
    - `최대 클럭 사이클 수 = 최대 대기 시간 / 클럭 주기`
    - `25ms / 10ns = (25 * 10^-3 s) / (10 * 10^-9 s) = 2,500,000` 사이클

2.  **최대 거리에 적용**
    계산된 최대 클럭 사이클 수를 거리 공식에 대입한다.
    - `최대 거리(cm) = (2,500,000 * 17) / 100,000`
    - `최대 거리(cm) = 25 * 17 = 425 cm`

따라서, 해당 설계에서 측정 가능한 최대 거리는 **4.25미터**이다.

## 결론

- Verilog 코드의 `distance_duration * 17 / 100_000` 공식은 **100MHz 클럭**과 **음속 340m/s** 환경에서 거리를 `cm` 단위로 계산하는 **정확한 수식**이다.
- `echo` 신호의 최대 대기 시간을 25ms로 설정할 경우, 측정 가능한 **최대 거리는 4.25m**이다.


---

## Problme & Solution

#### Problme 
- 초음파가 일정 시간이 지나면 멈춰 버리는 현상 발생

#### Solution

1. 타이머 리셋 조건 불일치 (== vs >=)

2. 상태 전환 시 타이밍 이슈

- 수정 사항

✅ 모든 타이머의 리셋 조건을 ==로 통일

✅ 상태 전환 조건도 ==로 통일


---

## Operation

<img width="551" height="416" alt="image" src="https://github.com/user-attachments/assets/f4b57bf8-3f29-466d-b584-ec9777312517" />

