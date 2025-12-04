`timescale 1ns / 1ps

module UltrasonicDistanceFSM(
    input clk, rst,
    output trig,
    input echo,
    output [9:0] distance_cm_out,
    output [2:0] curr_state_out,
    output led_1hz
    );

    localparam [2:0]
    IDLE = 0,
    TRIG = 1,
    WAIT = 2,
    MEASURE = 3,
    TENMS = 4;

    reg [2:0] curr_state, next_state;

    always @ (posedge clk) begin
        if(rst == 1) begin
            curr_state <= IDLE;
        end
        else begin
            curr_state <= next_state;
        end
    end

    assign curr_state_out = curr_state;

    //Timer 1 : 1Hz Timer 1초 주기 (trig enable 신호를 1초 마다 줘서 초음파가 1초마다 측정)
    reg [26:0] cnt1s;
    always @(posedge clk) begin
        if (rst ==1) begin
            cnt1s <= 0;
        end
        else begin
            cnt1s <= cnt1s +1;
            if( cnt1s == (100_000_000 - 1)) begin
                cnt1s <= 0;
            end
        end
    end

    wire trigEn;
   // assign led_1hz = (cnt1s == (100_000_000 - 1))? 1: 0; 
   // assign led_1hz = (cnt1s < ((100_000_000 - 1) /2 ))? 1: 0; 
    assign trigEn = (cnt1s == (100_000_000 - 1))? 1: 0;

    //Timer 2 : 10us Timer 10us 주기 (trig 신호가 10us 동안 유지됨)
    reg [9:0] cnt10us;
    always @(posedge clk) begin
        if (rst ==1) begin
            cnt10us <= 0;
        end
        else if(curr_state == TRIG)begin
            cnt10us <= cnt10us +1;
            if( cnt10us == (1000 - 1)) begin
                cnt10us <= 0;
            end
        end
        else begin
            cnt10us <= 0;
        end
    end
    wire tTrig = (cnt10us == (1000 - 1))? 1: 0;

    //Timer 3 : 460us 지나버리면 응답없음 IDLE 돌아감 (trigger 신호가 460us 유지됨)
    reg [15:0] cnt460us;
    always @(posedge clk) begin
        if (rst ==1) begin
            cnt460us <= 0;
        end
        else if(curr_state == WAIT)begin
            cnt460us <= cnt460us +1;
            if( cnt460us == (46000)) begin // 46000 -1 => 46000 크다고해서 변경
                cnt460us <= 0;
            end
        end
        else begin
            cnt460us <= 0;
        end
    end
    wire tWait;
    assign tWait = (cnt460us == (46000))? 1: 0;

    //Timer 4 : Measurement time 18ms
    //echo 신호가 1에서 0으로 바뀌는 그 구간을 거리 측정할떄 사용한다.
    reg [21:0] cnt18ms;
    reg [21:0] distance_duration;
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
            if( cnt18ms == (1800_000 - 1)) begin
                cnt18ms <= 0;
            end
        end
        else begin
            cnt18ms <= 0;
        end
    end
    wire tMeasure_done;
    assign tMeasure_done = (cnt18ms == (1800_000 - 1))? 1: 0;

    //Timer 5 : Tenms Timer 10ms 주기 (echo 신호가 10ms 동안 유지됨)
    reg [19:0] cnt10ms;
    always @(posedge clk) begin
        if (rst ==1) begin
            cnt10ms <= 0;
        end
        else if(curr_state == TENMS) begin
            cnt10ms <= cnt10ms +1;
            if( cnt10ms == (1000_000 - 1)) begin
                cnt10ms <= 0;
            end
        end
        else begin
            cnt10ms <= 0;
        end
    end
    wire t10ms;
    assign t10ms = (cnt10ms == (1000_000 - 1))? 1: 0;

    // Distance Calculation
    // v = 340m/s, d = 170m * t (round trip)
    // 100us -> 1.7cm

    wire [9:0] distance_cm = distance_duration * 17 / 100_000;
    assign distance_cm_out = distance_cm;

    // FSM
    always @(*) begin
        next_state = curr_state;

        case(curr_state)
            IDLE:begin
                if(trigEn == 1)begin
                    next_state = TRIG;
                end
            end
            TRIG: begin
                if(tTrig == 1)begin
                    next_state = WAIT;
                end
            end
            WAIT: begin
                if(echo == 1) begin
                    next_state = MEASURE;
                end
                else if(tWait == 1) begin
                    next_state = IDLE;
                end
            end
            MEASURE: begin
                if(echo == 0) begin
                    next_state = TENMS;
                end
                else if(tMeasure_done == 1) begin
                    next_state = IDLE;
                end
            end
            TENMS: begin
                if(t10ms == 1) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    assign trig = (curr_state == TRIG) ? 1 : 0;
endmodule

