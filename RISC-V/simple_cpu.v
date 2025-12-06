`timescale 1ns / 1ps

module jun_CPU(

    );
endmodule

module SingleCycleProcessor(
    //    input clk,
    //    input rst
    );

    wire [31:0] PC, PCNext;
    wire [31:0] PCPlus4;
    wire [31:0] PCTarget;
    wire [31:0] Instr;

    wire [31:0] WriteData;
    wire [31:0] ImmExt;
    wire [31:0] SrcA, SrcB;
    wire [31:0] ALUResult;
    //reg [2:0] ALUControl = 3'b000;
    wire [31:0] ReadData;
    
    wire [31:0] Result;
    // reg RegWrite = 0;
    // reg MemWrite = 0;
    // reg [1:0] ImmSrc = 0;
    // reg ALUSrc = 0;
    // reg [1:0] ResultSrc = 0;
    // wire [31:0] Result;
    // reg PCSrc = 0;

    // wire [6:0] op;
    // wire [2:0] func3;
    // wire funct7;
    // wire Zero;

    // assign op = Instr[6:0];
    // assign func3 = Instr[14:12];
    // assign funct7 = Instr[30];
    
    // ControlUnit cu (op, func3, funct7, Zero, PCSrc, ResultSrc, MemWrite, ALUControl, ALUSrc, ImmSrc, RegWrite);

    // --- 제어 신호용 wire 선언 ---
    // ControlUnit 입력 신호
    wire [6:0] op;
    wire [2:0] func3;
    wire        funct7; 
    wire        Zero;

    // ControlUnit 출력 신호
    wire        PCSrc;
    wire [1:0]  ResultSrc;
    wire        MemWrite;
    wire [2:0]  ALUControl;
    wire        ALUSrc;
    wire [1:0]  ImmSrc;
    wire        RegWrite;

    // --- 명령어 필드 분리 ---
    assign op = Instr[6:0];
    assign func3 = Instr[14:12];
    assign funct7 = Instr[30];

    // --- 제어 유닛(ControlUnit) 연결 ---
    ControlUnit u_ControlUnit (
        .op(op),
        .func3(func3),
        .funct7(funct7),
        .Zero(Zero),
        .PCSrc(PCSrc),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl),
        .ALUSrc(ALUSrc),
        .ImmSrc(ImmSrc),
        .RegWrite(RegWrite)
    );

    assign PCPlus4 = PC + 4;
    assign PCTarget = PC + ImmExt;
    assign PCNext = (PCSrc == 1) ? PCTarget : PCPlus4;



    reg clk=0, rst = 0;
    always #20 clk = ~clk;
    
    // --- 시뮬레이션용 리셋 신호 추가 ---
    initial begin
        rst = 1;
        #30; // 리셋 유지
        rst = 0;
    end
    
    // initial begin // 시뮬레이션
    //     #10 rst=1; // 
    //     #100 rst=0;
    //     #100 RegWrite = 1;
    //     #100 clk=1;

    //     ImmSrc = 1;
    //     MemWrite = 1;

    //     #10 ALUSrc = 1;
    //     #10 ALUControl = 3'b011;
    //     MemWrite = 0;
    //     ResultSrc = 1;

    // end


    assign ImmExt = (ImmSrc == 2'b00 ) ? {{20{Instr[31]}},Instr[31:20]}:
    (ImmSrc == 2'b01 ) ? {{20{Instr[31]}},Instr[31:25],Instr[11:7]}:
    (ImmSrc == 2'b10)?{{20{Instr[31]}},Instr[7],Instr[31:25],Instr[11:8],1'b0}:
    (ImmSrc == 2'b11) ?{{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:21],1'b0}: {32{1'bx}};
    // Program Counter
    ProgramCounter pc(
    .clk(clk),
    .rst(rst),
    .PCNext(PCNext),
    .PC(PC)
    );

    // Instruction Memory
    InstructionMemory im(
    .A(PC),
    .RD(Instr)
    );

    // Register File
    RegisterFile rf(
    .clk(clk),
    .WE3(RegWrite),
    .A1(Instr[19:15]), // rs1
    .A2(Instr[24:20]), // rs2
    .A3(Instr[11:7]),  // rd
    .WD3(Result),
    .RD1(SrcA),
    .RD2(WriteData)
    );

    // Data Memory
    DataMemory dm(
    .clk(clk),
    .WE(MemWrite),
    .A(ALUResult),
    .WD(WriteData),
    .RD(ReadData)
    );


    assign SrcB = (ALUSrc == 0)? WriteData : ImmExt;

    ALU alu(
    .SrcA(SrcA),
    .SrcB(SrcB),
    .ALUControl(ALUControl),
    .ALUResult(ALUResult),
    .Zero(Zero)
    );

    assign Result = (ResultSrc == 2'b00)?ALUResult:
    (ResultSrc == 2'b01)?ReadData:
    (ResultSrc == 2'b10)?PCPlus4: {32{1'bx}};
endmodule


module ProgramCounter(
    input clk,
    input rst,
    input [31:0] PCNext,
    output reg [31:0] PC
    );
    always @(posedge clk, posedge rst) begin
        if(rst == 1'b1) begin
            PC <= 32'h1000;
        end
        else begin
            PC <= PCNext;
        end
    end
endmodule

module InstructionMemory(
    input [31:0] A,
    output [31:0] RD
    //output reg[31:0] RD
    );

    reg [31:0] mem [0:3];
    // assign RD = mem[A];
    // always @(*) begin
    //     case(A)
    //         32'h1000: RD <= 32'hFFC4A303;
    //         32'h1004: RD <= 32'h0064A423;
    //         32'h1008: RD <= 32'h0062E233;
    //         32'h100C: RD <= 32'hFE420AE3;
    //         default: RD <= 32'h00000000;
    //     endcase
    // end
    initial begin
        mem[0] = 32'hFFC4A303;
        mem[1] = 32'h0064A423;
        mem[2] = 32'h0062E233;
        mem[3] = 32'hFE420AE3;
    end

    assign RD = mem[(A - 32'h1000) >> 2];

endmodule

module RegisterFile(
    input clk,
    input WE3, // 쓰기 활성화
    input [4:0] A1, //읽기 포트 1의 레지스터 주소 (rs1)
    input [4:0] A2, //읽기 포트 2의 레지스터 주소 (rs2)
    input [4:0] A3, //쓰기 포트의 레지스터 주소 (rd)
    input [31:0] WD3,
    output  [31:0] RD1,
    output  [31:0] RD2
    );

    reg [31:0] x [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            x[i] = 0;
        end
        x[5] = 32'd6;
        x[9] = 32'h2004;
    end

    assign RD1 = x[A1];
    assign RD2 = x[A2];

    always @(posedge clk) begin

        if(WE3  && A3 != 5'b00000) begin
            x[A3] <= WD3;
        end
    end

endmodule

module DataMemory(
    input clk,
    input WE,
    input [31:0] A,
    input [31:0] WD, // 쓰는 데이터 (write data)
    output [31:0] RD // 읽는 데이터 (read data)
    );

    // 1. 주소 0x2000 (인덱스 2048)을 포함할 수 있도록 크기를 넉넉하게 확장
    reg [31:0] mem [0:4095];

    assign RD = mem[A[31:2]];

    initial begin
        // 2. 주소 0x2000에 해당하는 인덱스(2048)에 10을 저장
        mem[2048] = 32'd10;
    end

    always @(posedge clk) begin
        if(WE) begin
            mem[A[31:2]] <= WD;
        end
    end

    // parameter BASE_ADDRESS = 32'h2000;

    // reg [31:0] mem [0:1023];

    // initial begin
    //     mem[0] = 32'd10; // 0x2000 address
    // end
    // assign RD = mem[(A - BASE_ADDRESS) >> 2];
    // always @(posedge clk) begin

    //     if(WE) begin
    //         mem[(A - BASE_ADDRESS) >> 2] <= WD;
    //     end
    // end

endmodule

module ALU(
    input [31:0] SrcA,
    input [31:0] SrcB,
    input [2:0] ALUControl,
    output reg[31:0] ALUResult,
    output Zero
    );

    always @(*) begin
        case(ALUControl)
            3'b000: ALUResult = SrcA + SrcB;
            3'b001: ALUResult = SrcA - SrcB;
            3'b010: ALUResult = SrcA & SrcB;
            3'b011: ALUResult = SrcA | SrcB;
            3'b100: ALUResult = SrcA ^ SrcB;
            3'b101: ALUResult = SrcA << SrcB;
            3'b110: ALUResult = SrcA >> SrcB;
            default: ALUResult =32'hx;
        endcase
    end
    //assign Zero = (SrcA == SrcB);
    assign Zero = (ALUResult == 32'b0);
endmodule

module ControlUnit(
    input [6:0]op,
    input [2:0] func3,
    input funct7,
    input Zero,
    output PCSrc,
    output [1:0] ResultSrc,
    output MemWrite,
    output[2:0]ALUControl,
    output ALUSrc,
    output [1:0]ImmSrc,
    output RegWrite
    );
    wire Jump;
    wire Branch;
    wire [1:0]ALUOp ;
    MainDecoder m_D(op,Branch,Jump,ResultSrc,MemWrite,ALUSrc,ImmSrc,RegWrite,ALUOp);
    ALUDecoder alu_D(ALUOp,op[5],funct3,funct7,ALUControl);
    assign PCSrc=(Zero&Branch) | Jump;

endmodule


module MainDecoder(
    input [6:0] op,
    output Branch,
    output Jump,
    output [1:0] ResultSrc,
    output MemWrite,
    output ALUSrc,
    output [1:0] ImmSrc,
    output RegWrite,
    output [1:0] ALUOp
    );
    `define LW 7'b000_0011
    `define SW 7'b010_0011
    `define RType 7'b011_0011
    `define BEQ 7'b110_0011
    `define ADDi 7'b001_0011
    `define JAL 7'b110_1111

    assign RegWrite = (op == `LW) || (op == `RType) || (op == `ADDi) || (op == `JAL);

    // assign ImmSrc = (op==`LW || op == `ADDi)?2'b00:
    // (op==`SW)?2'b01:
    // (op==`BEQ)? 2'b10 : 2'bxx;
    assign ImmSrc = (op == `LW || op == `ADDi) ? 2'b00 :
                    (op == `SW) ? 2'b01 :
                    (op == `BEQ) ? 2'b10 :
                    (op == `JAL) ? 2'b11 : 2'bxx;


    assign ALUSrc = (op==`LW )|| (op == `SW) || (op == `ADDi);

    assign MemWrite = (op == `SW);

    // assign ResultSrc = (op == `LW)? 2'b01:
    // (op == `RType || op == `ADDi) ? 2'b00: 2'bxx;
    assign ResultSrc = (op == `RType || op == `ADDi) ? 2'b00 :
                       (op == `LW) ? 2'b01 :
                       (op == `JAL) ? 2'b10 : 2'bxx; // JAL adds PC+4 result

    assign Branch = (op == `BEQ);

    // assign ALUOp = ((op == `LW) || (op == `SW)) ? 2'b00:
    // (op == `RType || op == `ADDi)? 2'b10:
    // (op == `BEQ)? 2'b01: 2'bxx;
    assign ALUOp = ((op == `LW) || (op == `SW)) ? 2'b00 :
                   (op == `RType || op == `ADDi) ? 2'b10 :
                   (op == `BEQ) ? 2'b01 :
                   (op == `JAL) ? 2'b00 : 2'bxx; // JAL uses ALU for additions


    assign Jump = (op == `JAL);
endmodule

module ALUDecoder(
    input [1:0] ALUOp,
    input op5,
    input [2:0] funct3,
    input funct7,
    output [2:0] ALUControl
    );

    assign ALUControl = (ALUOp == 2'b00)? 3'b000:
    (ALUOp == 2'b01)? 3'b001:
    ((ALUOp == 2'b10) && (funct3 == 3'b000) && ({op5,funct7} !=2'b11))? 3'b000:
    ((ALUOp == 2'b10) && (funct3 == 3'b000) && ({op5,funct7} ==2'b11))? 3'b001:
    ((ALUOp == 2'b10) && (funct3 == 3'b010))? 3'b101:
    ((ALUOp == 2'b10) && (funct3 == 3'b110))? 3'b011:
    ((ALUOp == 2'b10) && (funct3 == 3'b111))? 3'b010: 3'bxxx;
endmodule
