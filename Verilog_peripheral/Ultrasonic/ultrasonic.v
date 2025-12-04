module UltrasonicDistanceCM(
    input clk, rst,
    output trig,
    input echo,
    output [9:0] distance_cm_out,
    output [2:0] curr_state_out,
    output led_1hz
    );
    localparam [2:0]
    IDLE = 3'b000,
    TriggerStart = 3'b001,
    TriggerEnd = 3'b010,
    EchoWait = 3'b011,
    EchoStarted = 3'b100,
    EchoEnded = 3'b101;

    reg [2:0] curr_state, next_state;
    always @ (posedge clk) begin : state_register
        if(rst==1) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
        end
    end
    assign curr_state_out = curr_state;

    reg [26:0] count1hz;
    always @ (posedge clk) begin : timer1hz
        if(rst==1) begin
            count1hz <= 0;
        end else begin
            count1hz <= count1hz + 1;
            if(count1hz == (100_000_000 - 1)) begin
                count1hz <= 0;
            end
        end
    end
    assign led_1hz = (count1hz < (100_000_000 / 2)) ? 1 : 0;
    wire en1hz = (count1hz == (100_000_000 - 1)) ? 1 : 0;

    reg [9:0] count10us; // 10ns*1000
    always @ (posedge clk) begin : timer10us
        if(rst==1) begin
            count10us <= 0;
        end else if(curr_state == TriggerStart) begin
            count10us <= count10us + 1;
            if(count10us == 1000 - 1) begin
                count10us <= 0;
            end
        end else begin
            count10us <= 0;
        end
    end
    wire done_10us = (count10us == 1000 - 1) ? 1 : 0;

    reg [19:0] count10ms; // 10ns*1000*1000
    always @ (posedge clk) begin : timer10ms
        if(rst==1) begin
            count10ms <= 0;
        end else if(curr_state == EchoEnded) begin
            count10ms <= count10ms + 1;
            if(count10ms == 1000_000 - 1) begin
                count10ms <= 0;
            end
        end else begin
            count10ms <= 0;
        end
    end
    wire done_10ms = (count10ms == 1000_000 - 1) ? 1 : 0;

    // 100us(10ns*10000)~18ms(10ns*1000000*1.8),
    // 36ms(10ns*1000000*3.6=22bit 필요)
    reg [21:0] count_distance, duration_10ns;
    always @ (posedge clk) begin : timer_distance
        if(rst==1) begin
            count_distance <= 0;
            duration_10ns <= 0;
        end else if(curr_state == EchoStarted) begin
            count_distance <= count_distance + 1;
            if(echo==0) begin
                duration_10ns <= count_distance;
            end
        end else begin
            count_distance <= 0;
        end
    end

    // 거리 계산
    // v = 340m/sec 340m:1sec=(distance*2):tsec, 2*d=340m*tsec, d=170m*tsec
    // 100us==100/1000_000, d_100us=170*100cm*(100/1000_000)=1.7cm
    // 18ms==18/1000s, d_18ms=170*100cm*(18/1000)=306cm, 36ms=612
    wire [9:0] distance_cm = duration_10ns * 17 / 100_000;
    assign distance_cm_out = distance_cm;

    // 다음 상태 결정
    always @ * begin : comb_next_state
        next_state = curr_state;
        case(curr_state)
            IDLE: begin // 0
                if(en1hz==1) begin
                    next_state = TriggerStart;
                end
            end
            TriggerStart: begin // 1
                if(done_10us==1) begin
                    next_state = TriggerEnd;
                end
            end
            TriggerEnd: begin // 2
                next_state = EchoWait;
            end
            EchoWait: begin // 3
                if(echo==1) begin
                    next_state = EchoStarted;
                end else if(en1hz==1) begin
                    next_state = IDLE; // echo 신호가 안올라 갈 때
                end
            end
            EchoStarted: begin // 4
                if(echo==0) begin
                    next_state = EchoEnded;
                end
                // else if(en1hz==1) next_state=IDLE;// echo 신호가 안내려 갈 때
            end
            EchoEnded: begin // 5
                if(done_10ms==1) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    assign trig = (curr_state == TriggerStart) ? 1 : 0;
endmodule


module UltrasonicDistanceDisplay(
    input clk, // W5
    input rst, // U18, BTNC
    output trig, // J3
    input echo, // L3
    output led_1hz, // U16, LD0 
    output [3:0] AN, // W4,V4,U4,U2
    output [6:0] dec_out, // W7,W6,U8,V8,U5,V5,U7
    output reg[0:5] curr_state_led // L1,P1,N3,P3,U3,W3
    );

    wire [9:0] distance_cm_out;
    wire [2:0] curr_state_out;

    UltrasonicDistanceCM udCM_0 (
        .clk(clk),
        .rst(rst),
        .trig(trig),
        .echo(echo),
        .distance_cm_out(distance_cm_out),
        .curr_state_out(curr_state_out),
        .led_1hz(led_1hz)
    );

    wire [13:0] Digit = {4'b0000, distance_cm_out};

    _4_DIGIT_DISPLAY _4_dd_0 (
        .CLK100MHz(clk),
        .RST(rst),
        .Digit(Digit),
        .AN(AN),
        .dec_out(dec_out)
    );

    always @ * begin
        curr_state_led = 6'b000000;
        case(curr_state_out)
            3'b000: curr_state_led = 6'b100000;
            3'b001: curr_state_led = 6'b010000;
            3'b010: curr_state_led = 6'b001000;
            3'b011: curr_state_led = 6'b000100;
            3'b100: curr_state_led = 6'b000010;
            3'b101: curr_state_led = 6'b000001;
            default: curr_state_led = 6'b000000;
        endcase
    end
endmodule
