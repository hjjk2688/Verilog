# Ultrasonic

<img width="947" height="404" alt="image" src="https://github.com/user-attachments/assets/dc57dcaa-0928-4397-b260-9811fefc0860" />

- Pmod Header JXADC사용
- trigger - J3 , echo - L3 

### pin mod

<img width="1639" height="330" alt="image" src="https://github.com/user-attachments/assets/59a3ae1d-c40f-438b-b620-5433a87b2a98" />

<img width="1631" height="386" alt="image" src="https://github.com/user-attachments/assets/02029666-b715-4262-b8fb-7f00e10723a6" />

---
## code
- ultrasonic.v를 사용
  - TOP Module : UltrasonicDistanceDisplay 
- 7_Segment code는 4_digit_display 사용

## 결과

<img width="629" height="469" alt="image" src="https://github.com/user-attachments/assets/027e81d1-6fde-43d4-9adb-6e61c8df191d" />

- state 에 따라 LED가 켜진다.
- count 즉 1초 초음파 시작을 위한 eanble 활성화 시간에 맞춰 led가 on / off 된다.

## 문제점
- 초음파가 일정 시간 측정후 멈춰 버리는 현상 발생

#### 해결 방법
ultrasonic_fsm을 만들떄 해결: 각 상태 counter(timer)을 일치 시켜줌 (= / >= ,<=)
