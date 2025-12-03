module traffic_light_mod(
    input clk,
    input rst,
    input mod,
    output reg [2:0] traffic_light,
    output reg mod_light
    );
    localparam RED = 2'b00;
    localparam YELLOW = 2'b01;
    localparam GREEN = 2'b10;
    localparam BLINK_MODE = 1'b1;
    localparam RED_MODE = 1'b0;

    //100MHz 클럭 기준
    localparam SEC_10  = 1000000000; // 10초
    localparam SEC_8   = 800000000;  // 8초
    localparam SEC_2   = 200000000;  // 2초
    localparam SEC_0_5 = 50000000;   // 0.5초

    reg [31:0] count;
    reg [1:0] curr_state;
    reg [1:0] next_state;
    reg curr_mod;


    reg blink_state;

    always @(posedge clk, posedge rst) begin
        if(rst == 1'b1) begin
            //count <= 0;
            curr_state <= RED;
            curr_mod <= RED_MODE;
            //mod_light <=1'b0;
            //traffic_light <= 3'b100;
            
        end
        else begin
            curr_mod <= mod;
            curr_state <= next_state;
         
        end
    end

    always @(posedge clk, posedge rst) begin
        if(rst == 1'b1) begin
            count <= 0;     
            blink_state <= 1'b0;       
        end
        else begin
            case(curr_mod)
                RED_MODE: begin
                    if(curr_state != next_state)begin
                        count <= 0;
                    end
                    else begin
                        count <= count + 1;
                    end
                end
                BLINK_MODE: begin
                    if (count >= SEC_0_5)begin
                        count <= 0;
                        blink_state <= ~blink_state;
                    end

                    else begin
                        count <= count + 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin

        case(curr_mod)
            RED_MODE: begin
                case(curr_state)
                    RED: begin
                        if(count >= SEC_10) begin
                            next_state = GREEN;
                        end
                        else begin // LATCH 생성 방지
                            next_state = RED;
                        end

                    end
                    GREEN: begin
                        if(count >= SEC_8) begin
                            next_state = YELLOW;
                        end
                        else begin
                            next_state = GREEN; 
                        end

                    end
                    YELLOW: begin
                        if(count >= SEC_2) begin
                            next_state = RED;
                        end
                        else begin
                            next_state = YELLOW;
                        end

                    end
                    default: begin
                        next_state = RED;
                    end
                endcase
            end
            BLINK_MODE: begin  // 아무것도 안해줘도 선언해서 넣어줘야됨
                next_state = curr_state;
            end
            default: next_state = RED;
        endcase

    end

    always @(*) begin
        mod_light = (curr_mod == RED_MODE) ? 1'b1 : 1'b0;
        case(curr_mod)
            RED_MODE: begin

                case(curr_state)
                    RED: traffic_light = 3'b100;
                    GREEN: traffic_light = 3'b001;
                    YELLOW: traffic_light = 3'b010;
                    default: traffic_light = 3'b000;

                endcase
            end
            BLINK_MODE: begin

                case(blink_state)
                    1'b0: traffic_light = 3'b100;
                    1'b1: traffic_light = 3'b010;
                    default: traffic_light = 3'b000;
                endcase
            end
            default: traffic_light = 3'b100;
        endcase
    end
endmodule
