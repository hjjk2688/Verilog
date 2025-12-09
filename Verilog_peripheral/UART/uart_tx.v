`timescale 1ns / 1ps;
module uart_tx(
    input clk,
    input rst,
    input tx_start_en,
    input [7:0] input_tx_data,
    //output tx_busy,
    output reg tx
    );

    // reg clk = 0;
    // reg rst = 1;
    // reg tx_start_en = 0;
    // reg [7:0] input_tx_data = 8'b0;

    localparam [1:0] TX_IDLE = 2'b00,
    TX_START = 2'b01,
    TX_DATA = 2'b10,
    TX_STOP = 2'b11;


    parameter CLOCK_SPEED = 100_000_000;
    parameter BAUD_RATE = 9600;
    parameter CLOCKS_PER_BIT = CLOCK_SPEED / BAUD_RATE;

    reg [1:0] curr_state, next_state;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            curr_state <= TX_IDLE;
        end
        else begin
            curr_state <= next_state;
        end
    end

    reg [13:0] bit_cnt;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            bit_cnt <= 0;
        end
        else if(curr_state == TX_IDLE) begin
            bit_cnt <= 0;
        end
        else begin
            bit_cnt <= bit_cnt + 1;
            if(bit_cnt == CLOCKS_PER_BIT -1 ) begin
                bit_cnt <= 0;
            end
        end
    end

    wire baud_rate = (bit_cnt == CLOCKS_PER_BIT -1)? 1:0;

    reg [7:0] tx_data;
    reg [2:0] tx_data_cnt;

    always @(posedge clk or posedge rst) begin
        if(rst == 1) begin
            tx_data <= 8'b0;
            tx_data_cnt <= 3'b000;
        end
        else begin
            case(curr_state)
                TX_IDLE: begin
                    if(tx_start_en) begin
                        tx_data_cnt <= 3'b000;
                        tx_data <= input_tx_data;
                    end

                end
                TX_DATA: begin
                    if(baud_rate)begin
                        tx_data <= tx_data >> 1;
                        tx_data_cnt <= tx_data_cnt + 1;
                    end
                end
                default: begin
                    tx_data <= tx_data;
                    tx_data_cnt <= tx_data_cnt;
                end

            endcase
        end
    end

    always @(*)begin
        next_state = curr_state;
        case(curr_state)
            TX_IDLE: begin
                if(tx_start_en) begin
                    next_state = TX_START;
                end

            end
            TX_START: begin
                if(baud_rate == 1)begin
                    next_state = TX_DATA;
                end

            end
            TX_DATA: begin
                if(baud_rate)begin
                    if(tx_data_cnt == 7)begin
                        next_state = TX_STOP;
                    end
                end
            end
            TX_STOP: begin
                if(baud_rate)begin
                    next_state = TX_IDLE;
                end
            end
            default: begin
                next_state = TX_IDLE;
            end

        endcase
    end


    always @(posedge clk or posedge rst) begin
        if(rst) begin
            tx <= 1'b1;  // IDLE 상태
        end
        else begin
            case(curr_state)
                TX_IDLE: begin
                    tx <= 1'b1;
                end                
                TX_START: begin
                    tx <= 1'b0;
                end                
                TX_DATA: begin
                    tx <= tx_data[0];
                end                
                TX_STOP: begin
                    tx <= 1'b1;
                end                
                default: begin
                    tx <= 1'b1;
                end
            endcase
        end
    end
    

    
    // initial begin
    //     # 5 rst = 1'b0;
    //     #10 tx_start_en = 1'b1;
    //     #10 input_tx_data = 8'b1000_1111;       
        
    // end
    
    // always #5 clk = ~clk;
    
endmodule
