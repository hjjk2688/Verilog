module security_1_ver(
    input front_door,rear_door,window,    
    input[3:0] keypad,
    input clk,rst,
    output reg alarm_siren
    );
    
    localparam armed = 2'b00;
    localparam disarmed = 2'b01;
    localparam wait_delay = 2'b10;
    localparam alarm = 2'b11;

    reg [1:0] curr_state, next_state;
    reg start_count;
    wire count_done;
    wire [2:0] sensors;
    reg [31:0] delay_counter;

    assign sensors = {front_door,rear_door,window};
    always @(posedge clk , posedge rst) begin: sync
        if (rst == 1'b1)begin
            //curr_state <= disarmed;
            curr_state <= armed;
        end
        else begin
            curr_state <= next_state;
        end
    end

    always @(curr_state , keypad, count_done) begin: comb
        start_count=1'b0;
        case(curr_state)

            disarmed: begin
                if(keypad==4'b1100) begin
                    next_state = armed;
                    alarm_siren = 1'b0;
                end
                else begin
                    next_state = disarmed;                    
                end
            end
            
            armed: begin
                if(sensors !=3'b000) begin
                    next_state = wait_delay;
                end
                else if (sensors == 3'b000 && keypad == 4'b1100) begin
                    next_state = disarmed;
                end
                else begin
                    next_state = armed;
                    alarm_siren = 1'b0;
                end
            end
            
            wait_delay: begin // 비밀번호가 1100이 아니면 다틀림
                start_count = 1'b1;
                //if(count_done == 1'b0 && keypad == 4'b1100)begin // 30초에 딱맞게 비밀번호 입력해도 바로 컷
                if(keypad == 4'b1100)begin  //30초 딱 맞춰서 비밀번호를 입력한 경우 클럭이 아직들어오지 않았으면 봐준다.
                    next_state = disarmed;
                end
                else if(count_done == 1'b1)begin
                    next_state = alarm;
                end
                else begin
                    next_state = wait_delay;
                    alarm_siren = 1'b0;
                end
            end
            
            alarm: begin
                if (keypad == 4'b1100) begin
                    next_state = disarmed;
                end 
                else begin
                    next_state = alarm;
                    alarm_siren = 1'b1;
                end
            end

            default: begin
                next_state = disarmed;
                alarm_siren = 1'b0;
            end
        endcase
    end

    always @(posedge clk, posedge rst) begin
        if (rst == 1'b1) begin
            delay_counter <= 0;
        end
        else if (curr_state == wait_delay && start_count == 1'b1) begin
            delay_counter <= delay_counter + 1;
        end
        else begin
            delay_counter <= 0;
        end
    end
    
    assign count_done = (delay_counter == 100*1000*1000*30) ? 1'b1 : 1'b0;  // 100MHz 에서 1초는 1억 => 30억 = 30초
endmodule
