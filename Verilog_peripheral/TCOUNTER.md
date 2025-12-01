# TCOUNTER
- Using zyboz720 board
- ZYNQ7 
---
## TCOUNTER Module 

<img width="800" height="400" alt="image" src="https://github.com/user-attachments/assets/c0663004-ef8f-4464-b61b-b79b36f16e33" />

<img width="800" height="400" alt="image" src="https://github.com/user-attachments/assets/d3e85cd4-f9d2-4eeb-9edb-7a3c055c6eba" />

<img width="436" height="163" alt="image" src="https://github.com/user-attachments/assets/045d6359-96fe-4ac9-80e6-460bba18f6bd" />

<img width="917" height="619" alt="image" src="https://github.com/user-attachments/assets/a5e240cd-7238-4d61-a08f-fcefdc62b5c2" />

<img width="917" height="624" alt="image" src="https://github.com/user-attachments/assets/ea653526-6664-402d-907e-9833d9d4b716" />

<img width="772" height="524" alt="image" src="https://github.com/user-attachments/assets/c57fdef4-a375-4bb7-8dcd-fef10d937b8f" />

- Slave mode : cpu에서 시작되는 명령에 따라 동작함 (DMA - LW SW:짐꾼)
- motor 500Hz / sub 50Hz (pwm)
- counter, top, compare register 사용 설계 - 12 register
### PWM
1. ARR (Auto-Reload Register) - 주기(주파수) 결정


   - 역할: 카운터가 0부터 시작해서 얼마까지 카운트할지를 정하는 최댓값 또는 주기(Period) 값입니다. (카운터의
     "천정값")
   - 동작: 타이머 카운터(CNT)는 0부터 1씩 증가하다가 ARR 레지스터에 설정된 값에 도달하면, 다음 클럭에 0으로
     리셋되고 '업데이트 이벤트(Update Event)'를 발생시킵니다. 이 한 사이클이 PWM의 한 주기가 됩니다.
   - 주파수 결정: 이 주기가 반복되는 속도가 바로 주파수입니다. 따라서 ARR 값은 PWM 신호의 주파수를
     결정합니다. (정확히는 시스템 클럭과 분주비(Prescaler)와 함께 결정됩니다.)

 
    ```
    PWM 주파수 = Timer 클럭 / ((Prescaler + 1) * (ARR + 1))
    ```
   
    ### 2. CCR (Capture/Compare Register) - 듀티비(Duty Cycle) 결정
   

   - 역할: PWM 모드에서는 비교(Compare) 값으로 사용됩니다. 0부터 ARR까지 증가하는 카운터(CNT) 값과 CCR 값을
     실시간으로 비교하는 역할을 합니다.
   - 동작:
       - 카운터(CNT) 값이 CCR 값보다 작을 때는 출력 신호를 HIGH로 유지하고,
       - 카운터(CNT) 값이 CCR 값보다 커지면 LOW로 변경합니다. (이는 PWM 모드 설정에 따라 반대일 수도
         있습니다.)
   - 듀티비 결정: 결국 ARR이라는 전체 주기 중에서 CCR 값만큼의 시간 동안만 HIGH 신호가 나가게 됩니다. 이것이
     바로 듀티비(Duty Cycle)입니다.
  
     ```
     듀티비(%) = (CCR 값 / ARR 값) * 100
     ```
  
    ### 요약 및 비유
   

   - ARR: "오늘 하루는 총 100분이야" 라고 전체 시간을 정하는 것 (주기).
   - CCR: "그 100분 중에서 30분까지만 불을 켜둘 거야" 라고 특정 시점을 정하는 것 (듀티비).


    ### 결론: 
   - ARR로 주파수를 설정하고, CCR로 그 주파수 내에서 HIGH 신호의 폭(듀티비)을 조절합니다.
