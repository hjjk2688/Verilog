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
</br>
</br>

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

- 거리 계산

```Verilog
    // Distance Calculation
    // v = 340m/s, d = 170m * t (round trip)
    // 100us -> 1.7cm

    wire [9:0] distance_cm = distance_duration * 17 / 100_000;
    assign distance_cm_out = distance_cm;
```
* distance_duration: Echo가 HIGH였던 시간 (10ns 단위)
* 음속: 340m/s → 왕복 시간 고려

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

