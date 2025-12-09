module uart_rx(  
    input clk,
    input rst,
    input rx,
    output reg [7:0] rx_data
    //output reg rx_data_valid
);

    localparam [1:0] RX_IDLE = 2'b00,
                     RX_START = 2'b01,
                     RX_DATA = 2'b10,
                     RX_STOP = 2'b11;
    
    parameter CLOCK_SPEED = 100_000_000;
    parameter BAUD_RATE = 9600;
    parameter CLOCKS_PER_BIT = CLOCK_SPEED / BAUD_RATE;
   
    reg [1:0] curr_state, next_state;
    
    // 상태 레지스터
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            curr_state <= RX_IDLE;
        end
        else begin
            curr_state <= next_state;
        end
    end

    // 비트 카운터
    reg [13:0] bit_cnt;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            bit_cnt <= 0;
        end
        else if(curr_state == RX_IDLE) begin
            bit_cnt <= 0;
        end
        else begin
            bit_cnt <= bit_cnt + 1;
            if(bit_cnt >= CLOCKS_PER_BIT - 1) begin
                bit_cnt <= 0;
            end
        end
    end
    
    wire baud_rate = (bit_cnt == CLOCKS_PER_BIT - 1) ? 1'b1 : 1'b0;
    wire mid_bit = (bit_cnt == (CLOCKS_PER_BIT / 2) - 1) ? 1'b1 : 1'b0;

    // 데이터 수신 로직 (순차 논리) - 비트 단위로 즉시 저장
    reg [2:0] rx_data_index;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            rx_data <= 8'b0;
            rx_data_index <= 3'b0;
           
        end
        else begin          
            
            case(curr_state)
                RX_IDLE: begin
                    rx_data_index <= 3'b0;
                end
                
                RX_DATA: begin
                    if(mid_bit) begin
                        rx_data[rx_data_index] <= rx;  // 받는 즉시 해당 비트 위치에 저장
                        rx_data_index <= rx_data_index + 1;
                    end
                end
                
            endcase
        end
    end

    // 다음 상태 결정 로직 (조합 논리)
    always @(*) begin
        next_state = curr_state;
        
        case(curr_state)
            RX_IDLE: begin
                if(rx == 1'b0) begin
                    next_state = RX_START;
                end            
            end
            
            RX_START: begin
                if(mid_bit) begin
                    if(rx == 1'b0) begin
                        next_state = RX_DATA;
                    end
                    else begin
                        next_state = RX_IDLE;
                    end
                end
            end
            
            RX_DATA: begin
                if(mid_bit && rx_data_index == 3'd7) begin
                    next_state = RX_STOP;
                end
            end
            
            RX_STOP: begin
                if(baud_rate) begin                    
                    next_state = RX_IDLE;
                end
            end
            
            default: begin
                next_state = RX_IDLE;
            end   
        endcase
    end
    
endmodule
