# FSM

## 구현 단계
1. define state
2. current state logic
3. next state logic
4. output logic
5. timer logic
6. test bench


#### Simualtion

- 1~3 단계 까지 구성후 simulation 결과
- testbench code
```Verilog
    initial begin
        rst = 1;
        #100 rst = 0;
        #100 display_on = 1;
        #100 t_done = 1;
        #10 t_done = 0;
        #100 t_done = 1;
        #10 t_done = 0;
        #100 t_done = 1;
        #10 t_done = 0;
        #100 t_done = 1;
        #10 t_done = 0;
        #1000 display_on = 0;
    end
    
    always #5 clk = ~clk;

```

<img width="1275" height="638" alt="image" src="https://github.com/user-attachments/assets/e32581b4-5173-453f-bb75-57e2ddaa787d" />

---
- 1~5 단계 simulation 결과
- counter 결과를 10진수로 확인

<img width="667" height="454" alt="image" src="https://github.com/user-attachments/assets/12be651f-2797-4718-a368-2a5af29299c2" />

- simulation 시간 10 ms 

<img width="155" height="39" alt="image" src="https://github.com/user-attachments/assets/f476256b-9c7f-40fb-b238-c8563a82abed" />

<img width="947" height="563" alt="image" src="https://github.com/user-attachments/assets/df479940-5940-41b4-aa75-59572191c404" />

```Verilog
`timescale 1ns / 1ps
`default_nettype none

module digit_display(

);
    // 1. define states
    localparam [2:0]
    IDLE = 0,
    D1000 = 1,
    D100 = 2,
    D10 = 3,
    D1 = 4;

    reg clk = 0, rst;
    reg [2:0] curr_state, next_state;
    
    // 2.current state logic
    always @ (posedge clk) begin : state_register
        if(rst==1) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end

    wire t_done; 
    reg  display_on = 0;
    // 3. next state logic
    always @ (*) begin 
        next_state = curr_state;
        case(curr_state)
            IDLE: begin
                if(display_on == 1) begin
                    next_state = D1000;
                end else begin
                    next_state = IDLE;
                end
            end
            D1000: begin
                if(t_done == 1) begin
                    next_state = D100;
                end 
                else if(display_on == 0) begin
                    next_state = IDLE;
                end

            end
            D100: begin
                if(t_done == 1) begin
                    next_state = D10;
                end 
                else if(display_on == 0) begin
                    next_state = IDLE;
                end
            end
            D10: begin
                if(t_done == 1) begin
                    next_state = D1;
                end 
                else if(display_on == 0) begin
                    next_state = IDLE;
                end
            end
            D1: begin
                if(t_done == 1) begin
                    next_state = D1000;
                end 
                else if(display_on == 0) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
        
    end
    reg [3:0] an;
    reg [6:0] ag; // a ,b, c ... g
    reg [6:0] digit1000 = 1, digit100 = 2, digit10 = 3, digit1 = 4; 
    // 4. output logic
    always @ (*) begin
        an = 4'b0000;
        ag = 7'b000_0000; 
        case(curr_state)
            D1000: begin
                an = 4'b1000;
                ag = digit1000;                
            end
            D100:begin
                an = 4'b0100;
                ag = digit100;   
            end
            D10:begin
                an = 4'b0010;
                ag = digit10;   
            end            
            D1:begin
                an = 4'b0001;
                ag = digit1;   
            end       
        endcase
    end
    
    
    // 5. timer logic
    // 100MHz = 초당 100_000_000 번 카운팅  26:0 
    // 100M / 1000 = 100_000 번 카운팅  천분의 1초  16:0
    wire cnt1ms_en;
    assign cnt1ms_en = (curr_state == D1000)? 1: 
                     (curr_state == D100)? 1:
                     (curr_state == D10)? 1:
                     (curr_state == D1)?1:0;                 
       
                     
    reg [16:0] cnt1ms;
    always @(posedge clk) begin
        if(rst == 1) begin
            cnt1ms <= 0;
        end
        
        else if(cnt1ms_en == 1) begin
            cnt1ms <= cnt1ms +1;
            if(cnt1ms == 100_000 -1) begin
               cnt1ms <= 0;
            end
        end
        
        else begin
            cnt1ms <= 0;
        end
        
    end
    assign t_done = (cnt1ms == 100_000 -1)? 1: 0;
                   
    
    
    // 6. test bench
 
    initial begin
        rst = 1;
        #100 rst = 0;
        #100 display_on = 1;
    end
    
    always #5 clk = ~clk;
endmodule


```


