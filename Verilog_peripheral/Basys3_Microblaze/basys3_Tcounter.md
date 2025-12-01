# basys3 module

## Block Desgin

<img width="1132" height="356" alt="image" src="https://github.com/user-attachments/assets/212f62f4-ba2b-4c38-b074-7b64daafe7cd" />


* xdc 생성

<img width="1592" height="403" alt="image" src="https://github.com/user-attachments/assets/1f19ee56-0224-480f-ba70-6e7080c0226d" />

<img width="537" height="177" alt="image" src="https://github.com/user-attachments/assets/ac3170eb-fd36-4c3d-8aab-98c339ca05ef" />


### LED 제어
#### GPIO Address 

<img width="793" height="389" alt="image" src="https://github.com/user-attachments/assets/21caba69-6f33-4b24-9cf7-110a532c3ffb" />

<img width="491" height="119" alt="image" src="https://github.com/user-attachments/assets/54bf686e-2590-4261-9183-f69c739cfb22" />

<img width="408" height="36" alt="image" src="https://github.com/user-attachments/assets/9d6988f5-cc61-4761-8b66-439a59b10a90" />
</br>

- petalinux gpio 제어 랑 비슷함
```
Address 0x40000000

*(unsigned int *) XPAR_GPIO_0_BASEADDR= 0x3;  // 0011 <- 끝에 두개 led 만 켜짐
```

#### 결과

<img width="517" height="391" alt="image" src="https://github.com/user-attachments/assets/a8ad765e-c776-47fb-915a-9885a855779e" />

- button(U18) 누르면 TERA TERAM 출력
<img width="597" height="116" alt="image" src="https://github.com/user-attachments/assets/28937060-cd5a-4ff6-9b61-895125dfa17c" />

---

### lED Wdith 변경 (2 -> 4)

<img width="1158" height="453" alt="image" src="https://github.com/user-attachments/assets/75762225-b498-4b2e-a5e8-370e639c646e" />

<img width="1781" height="436" alt="image" src="https://github.com/user-attachments/assets/5497e8de-3969-450d-896c-f23666049596" />

<img width="528" height="265" alt="image" src="https://github.com/user-attachments/assets/91ed46ef-337c-48ad-9d5c-2af1cf80d30c" />

#### bitstream update

<img width="600" height="400" alt="image" src="https://github.com/user-attachments/assets/8d69b3ae-0ceb-406e-bfb4-4f86e143fb63" />

<img width="546" height="412" alt="image" src="https://github.com/user-attachments/assets/d639c822-df05-4187-a7c7-347e7526711c" />

<img width="739" height="305" alt="image" src="https://github.com/user-attachments/assets/1d435321-b57c-4f84-b942-22775454eb39" />

<img width="519" height="149" alt="image" src="https://github.com/user-attachments/assets/9ac21cde-8770-48c9-ae95-cb74bfd21c27" />
<img width="252" height="26" alt="image" src="https://github.com/user-attachments/assets/604570d8-5c60-485e-a3fe-8c88348746ed" />
</br>

```c
*(unsigned int *) XPAR_GPIO_0_BASEADDR= 0xf; // 1111 lED 할당한 4개 ON
```

<img width="595" height="449" alt="image" src="https://github.com/user-attachments/assets/f0b07ed4-a5d1-4087-8310-64b5741266dc" />

---

### LED IP Module 제어

<img width="922" height="616" alt="image" src="https://github.com/user-attachments/assets/e32fa309-e294-4cf3-acd1-d81753e79a86" />

<img width="918" height="613" alt="image" src="https://github.com/user-attachments/assets/02439566-d0ab-400e-90bf-f3dfbc528584" />

#### LED IP Code 수정

<img width="438" height="36" alt="image" src="https://github.com/user-attachments/assets/49965590-4185-4abc-a298-f389d9ac75a6" />
</br>
<img width="470" height="88" alt="image" src="https://github.com/user-attachments/assets/fb8b77b2-876b-4eed-8df2-67afdf98cf21" />
<img width="284" height="69" alt="image" src="https://github.com/user-attachments/assets/e4fc473a-cbc4-4131-b043-27efd2a74059" />

<img width="298" height="31" alt="image" src="https://github.com/user-attachments/assets/2e312ffa-68d8-4274-99fd-76a8a2c7b6d5" />
</br>
<img width="448" height="83" alt="image" src="https://github.com/user-attachments/assets/83b8a402-02be-4f2b-989b-4e302e277f5a" />
<img width="335" height="49" alt="image" src="https://github.com/user-attachments/assets/e13aaa13-f9bd-4aec-acac-893f1f2e6386" />

<img width="485" height="221" alt="image" src="https://github.com/user-attachments/assets/f13a636d-cd6f-4e13-bdce-a6513d2e2ad4" />

<img width="1007" height="356" alt="image" src="https://github.com/user-attachments/assets/078af8a4-a44e-427c-8898-762330b40bb9" />

* LED IP Module xdc 수정
<img width="1584" height="164" alt="image" src="https://github.com/user-attachments/assets/54fe8d50-3d57-408f-badb-419137dbad4d" />
<img width="415" height="89" alt="image" src="https://github.com/user-attachments/assets/d12b1c6e-6963-4590-a636-a47bb04d3afb" />

* design_1_wrapper update

<img width="736" height="307" alt="image" src="https://github.com/user-attachments/assets/b10432e9-2988-4d82-895c-f4c357ae2217" />

<img width="515" height="149" alt="image" src="https://github.com/user-attachments/assets/df4e1351-bc4c-4aab-b94b-685928312c9e" />

- error
<img width="713" height="59" alt="image" src="https://github.com/user-attachments/assets/076015de-e0a6-4f6d-8e62-d2ff77b57e11" />

- 기존에 있는 make file을 우리가 만든 IP Module make file 넣어준다 ( ip module을 만들면 make file 오류가생김)

<img width="471" height="545" alt="image" src="https://github.com/user-attachments/assets/6d39b14f-2a9c-4ba2-82ee-1f4e38540253" />


* adderess check
<img width="526" height="81" alt="image" src="https://github.com/user-attachments/assets/dbf527bd-8ce8-4673-8924-d36064ecf3a9" />

* code 
```c
*(unsigned int *) XPAR_MYIP_LED4_0_S00_AXI_BASEADDR = 0xf;
```

<img width="595" height="445" alt="image" src="https://github.com/user-attachments/assets/029a41c0-6780-419f-8cf4-b659675157a7" />

---

### IP Module tcounter 
* 이미 만들어진 외부 IP Module 사용하기
  - Project Settings → IP → Repository에서 생성된 IP가 있는 디렉터리를 추가

<img width="1030" height="843" alt="image" src="https://github.com/user-attachments/assets/f2303cc3-9a42-4b1d-8d6f-24e270e243d9" />

<img width="593" height="232" alt="image" src="https://github.com/user-attachments/assets/4c4313a1-7a2f-4621-b381-635132cc7d8a" />

<img width="775" height="518" alt="image" src="https://github.com/user-attachments/assets/6b1c04f4-0278-4064-bdc1-a7899d18edf9" />

* IP Module code

- myip_tcounter2_v1_0_S00_AXI.v
<img width="426" height="89" alt="image" src="https://github.com/user-attachments/assets/333b302b-9fcc-45f7-946d-23d642540daa" />

<img width="574" height="168" alt="image" src="https://github.com/user-attachments/assets/078191bd-4ec2-414f-b39a-c0add47841c1" />

- myip_tcounter2_v1_0.v
<img width="429" height="83" alt="image" src="https://github.com/user-attachments/assets/596bf187-8667-40a7-bf07-4fe8d95b5bd2" />
<img width="402" height="63" alt="image" src="https://github.com/user-attachments/assets/fa52e52e-392c-4e48-947b-dc898f089f0e" />

- TCounter.v
```Verilog
`timescale 1ns / 1ps

module TCounter(
    input CLK,
    input RSTn,
    input [31:0] top_in, // en, 4bit reserved, 27bit top
    input [31:0] cmp_in, // 5bit reserved, 27bit cmp
    output PWM
    );
    reg [26:0] cnt; // 27비트
    wire [26:0] top = top_in[26:0];
    wire [26:0] cmp = cmp_in[26:0];
    wire cnt_en = top_in[31];
    always @(posedge CLK) begin
        begin : CNT_MOD
            if(RSTn==0) cnt<=0;
            else if(cnt_en) begin
                if(cnt >= top) begin
                    cnt <= 0;
                end
                else begin
                    cnt<=cnt+1;
                end                
            end
            else cnt<=0;
        end
    end
    assign PWM = (cnt < cmp)?1:0;
endmodule


```
- C언어 포인트 배열
- 참고 : https://github.com/hjjk2688/Verilog/edit/main/Verilog_basic/c.md

### vitis code


