# TCOUNTER
- Using zyboz720 board
- ZYNQ7 
---
## Add TCOUNTER Module 

<img width="800" height="400" alt="image" src="https://github.com/user-attachments/assets/c0663004-ef8f-4464-b61b-b79b36f16e33" />

<img width="800" height="400" alt="image" src="https://github.com/user-attachments/assets/d3e85cd4-f9d2-4eeb-9edb-7a3c055c6eba" />

<img width="436" height="163" alt="image" src="https://github.com/user-attachments/assets/045d6359-96fe-4ac9-80e6-460bba18f6bd" />

<img width="917" height="619" alt="image" src="https://github.com/user-attachments/assets/a5e240cd-7238-4d61-a08f-fcefdc62b5c2" />

<img width="917" height="624" alt="image" src="https://github.com/user-attachments/assets/ea653526-6664-402d-907e-9833d9d4b716" />

<img width="772" height="524" alt="image" src="https://github.com/user-attachments/assets/c57fdef4-a375-4bb7-8dcd-fef10d937b8f" />

- Slave mode : cpu에서 시작되는 명령에 따라 동작함 (DMA - LW SW:짐꾼)
- motor 500Hz / sub 50Hz (pwm)
- counter, top, compare register 사용 설계 - 12 register

<img width="914" height="620" alt="image" src="https://github.com/user-attachments/assets/4d98d11f-075d-49d4-b050-a2ecec9280db" />

<img width="384" height="266" alt="image" src="https://github.com/user-attachments/assets/1c2c4509-68bf-4110-a34f-e6d80a3272e6" />

- 12개 register

<img width="919" height="615" alt="image" src="https://github.com/user-attachments/assets/48faf705-9cb0-43dd-9465-8efb63d765ba" />

- ip repo => hdl 생성

### IP SCR 수정

<img width="904" height="508" alt="image" src="https://github.com/user-attachments/assets/6028e089-aee1-4b54-a908-57c7f1c539cd" />

<img width="492" height="385" alt="image" src="https://github.com/user-attachments/assets/485a99c7-3b65-48c6-9ac7-6c588750d9b4" />


### 구조

<img width="568" height="184" alt="image" src="https://github.com/user-attachments/assets/e14c219d-30c7-4d33-8628-cc78a28b8342" />

<img width="1250" height="507" alt="image" src="https://github.com/user-attachments/assets/40c6aa17-7e54-4408-a20e-8143237f8479" />


### lED GPIO 추가

<img width="683" height="430" alt="image" src="https://github.com/user-attachments/assets/87e5a6db-01dd-4c7f-a585-6ded3846af19" />




