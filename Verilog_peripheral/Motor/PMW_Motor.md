# PWM Motor

## motor IP Module
* Motor 제어 pin을 위한 PWM IP Module 샌성

<img width="1018" height="381" alt="image" src="https://github.com/user-attachments/assets/ddab1d0e-01e8-427e-8c1c-f07377875f59" />

- 모터4개 제어를 위해 PWM - 8개 필요 -> register 16

#### myip_motor_v1_0_S00_AXI.v

<img width="476" height="89" alt="image" src="https://github.com/user-attachments/assets/2d645b44-abcf-4928-8f49-410fb5eeebd4" />
<img width="600" height="226" alt="image" src="https://github.com/user-attachments/assets/900ac348-857e-499c-adf9-db61cc27f77f" />

#### myip_motor_v1_0.v
<img width="433" height="92" alt="image" src="https://github.com/user-attachments/assets/a151e1b3-cfbd-401a-a315-2a7b6eff4f4c" />
<img width="397" height="44" alt="image" src="https://github.com/user-attachments/assets/dd8d963c-d650-41cb-b354-bdc18e4cd334" />
</br>

#### 모터 제어를 위한 XDC PIN 할당

<img width="1632" height="262" alt="image" src="https://github.com/user-attachments/assets/77502565-88a6-43a6-8959-592ec0890e96" />

#### Block Design

<img width="1149" height="567" alt="image" src="https://github.com/user-attachments/assets/cd0e7c64-3389-48c3-a2cb-7320bd980b29" />

* Pin MAP
  
<img width="1000" height="1200" alt="image" src="https://github.com/user-attachments/assets/d17d2aac-ded4-4893-99e3-35612078910e" />

<img width="800" height="600" alt="image" src="https://github.com/user-attachments/assets/d298d819-77a2-444d-a0f6-0e1464376a68" />

```
G  -> G
25 -> JA1:J1
26 -> JA2:L2
12 -> JA3:J2
27 -> JA4:G2
17 -> JA7:H1
16 -> JA8:K2
21 -> JA9:H2
22 -> JA10:G3
```
* 자신의 모터에 맞춰서 제어
```
  motorReg[8] = (1 << 31) | period_val; // 우앞
  motorReg[9] = duty_val;
  motorReg[10] = 0;
  motorReg[11] = 0;
  
  motorReg[12] = (1 << 31) | period_val; // 좌앞
  motorReg[13] = duty_val;
  motorReg[14] = 0;
  motorReg[15] = 0;
  
  motorReg[0] = (1 << 31) | period_val;  // 좌뒤
  motorReg[1] = duty_val;
  motorReg[2] = 0;
  motorReg[3] = 0;
  
  motorReg[4] = (1 << 31) | period_val; // 우뒤
  motorReg[5] = duty_val;
  motorReg[6] = 0;
  motorReg[7] = 0;

```
