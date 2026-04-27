`timescale 1ns / 1ps

// PROGRAM COUNTER module   
// holds the address of the current instruction and updates in on the clock edge
module program_counter #(parameter DATA_LENGTH = 32)(
    input clk,
    input reset,
    input pc_en,

    // the address of the next instruction to be executed
    input [DATA_LENGTH-1:0] pc_next,

    // the current instruction address sent to the instruction memory
    output reg [DATA_LENGTH-1:0] pc_out
);

    always@(posedge clk) begin
        if(reset == 1'b1) begin
            pc_out <= 32'b0;
        end else if(pc_en == 1'b1) begin
            pc_out <= pc_next;
        end
    end
endmodule

// MUX 2:1
module mux2to1 #(parameter DATA_LENGTH = 32)(
    input [DATA_LENGTH-1:0] mux_in1, // mux_sel == 1
    input [DATA_LENGTH-1:0] mux_in2, // mux_sel == 0
    input mux_sel, // IorD, MemtoReg or ALUSrcA

    output [DATA_LENGTH-1:0] mux_out
);
    assign mux_out = (mux_sel == 1'b1) ? mux_in1 : mux_in2;
endmodule

// MUX 3:1
module mux3to1 #(parameter DATA_LENGTH = 32)(
    input [DATA_LENGTH-1:0] mux_in_B, // mux_sel == 00
    input [DATA_LENGTH-1:0] mux_in_IMM, // mux_sel == 10
    input [1:0] ALUSrcB,

    output reg [DATA_LENGTH-1:0] mux_out
);
    always@(*) begin
        case(ALUSrcB)
            2'b00: mux_out = mux_in_B;
            2'b01: mux_out = { {29{1'b0}},3'b100 };
            2'b10: mux_out = mux_in_IMM;
            default: mux_out = { {29{1'b0}},3'b100 };
        endcase
    end
endmodule

// MEMORY module
// instruction and data memory combined in one (Von Neumann architecture)
module memory #(parameter DATA_LENGTH = 32, MEM_SIZE = 256)(
    input clk,
    input [DATA_LENGTH-1:0] memory_addr,
    input [DATA_LENGTH-1:0] memory_in,
    input MemWrite,
    input MemRead,

    output [DATA_LENGTH-1:0] memory_out
);

    // memory array, each location holds 1 byte
    reg [DATA_LENGTH/4-1:0] memory [0:MEM_SIZE*4-1];

    // read from memory operation behavior
    // memory provides 32 bits = 4 bytes = 4 locations/addresses
    assign memory_out = (MemRead == 1'b1) ?
    { memory[memory_addr+3], memory[memory_addr+2], memory[memory_addr+1], memory[memory_addr] }
    : 32'b0;

    // write in memory operation behavior
    always@(posedge clk) begin
        if(MemWrite == 1'b1) begin
            // memory receives 32 bits = 4 bytes = 4 locations/addresses
            { memory[memory_addr+3], memory[memory_addr+2], memory[memory_addr+1], memory[memory_addr] } <= memory_in;
        end
    end

    // memory content initialization from file
    initial begin
        $readmemh("memory.mem", memory);
    end
endmodule

// INSTRUCTION REGISTER module
// holds the current instruction fetched from memory
module instruction_register #(parameter DATA_LENGTH = 32)(
    input clk,
    input reset,
    input IRWrite,
    input [DATA_LENGTH-1:0] instruction_register_in,

    output reg [DATA_LENGTH-1:0] instruction_register_out
);

    always@(posedge clk) begin
        if(reset == 1'b1) begin
            instruction_register_out <= 32'b0;
        end else if(IRWrite == 1'b1) begin
            instruction_register_out <= instruction_register_in;
        end
    end
endmodule

// A, B, MEMORY DATA REGISTER and ALUOut module
// holds intermediate data between clock cycles
module memory_register #(parameter DATA_LENGTH = 32)(
    input clk,
    input reset,
    input [DATA_LENGTH-1:0] mem_reg_in,

    output reg [DATA_LENGTH-1:0] mem_reg_out
);
    always@(posedge clk) begin
        if(reset == 1'b1) begin
            mem_reg_out <= 32'b0;
        end else begin
            mem_reg_out <= mem_reg_in;
        end
    end
endmodule

// IMMEDIATE GENERATOR module
// extracts and sign-extends the imm values embedded within the instructions
module immediate_generator #(parameter DATA_LENGTH = 32)(
    input [DATA_LENGTH-1:0] imm_gen_in, // instruction [31:0]
    output reg [DATA_LENGTH-1:0] imm_gen_out
);
    wire [6:0] opcode = imm_gen_in[6:0];

    always@(imm_gen_in) begin
        case(opcode)
            // I-type: load, arithmetic and immediate
            7'b0000_011,
            7'b0001_111,
            7'b0011_011,
            7'b1100_111,
            7'b1110_011,
            7'b0010_011: imm_gen_out = { {20{imm_gen_in[31]}}, imm_gen_in[31:20] };

            // S-type: store
            7'b0100_011: imm_gen_out = { {20{imm_gen_in[31]}}, imm_gen_in[31:25], imm_gen_in[11:7] };

            // SB-type: conditional branch
            7'b1100_011: imm_gen_out = { {20{imm_gen_in[31]}}, imm_gen_in[7], imm_gen_in[30:25], imm_gen_in[11:8], 1'b0 };

            // UJ-type: unconditional jump
            7'b1101_111: imm_gen_out = { {12{imm_gen_in[31]}}, imm_gen_in[19:12], imm_gen_in[20], imm_gen_in[30:25], imm_gen_in[11:8], 1'b0 };

            // U-type: upper immediate
            7'b0010_111,
            7'b0110_111: imm_gen_out = { imm_gen_in[31:12], {12{1'b0}} };

            default:
            imm_gen_out = 32'h0000_0000;
        endcase
    end
endmodule

// REGISTERS module
// contains 32 general-purpose 32-bit registers
module registers #(parameter DATA_LENGTH = 32)(
    input clk,
    input reset,
    input RegWrite,

    // register addresses (decoded from the instruction)
    input [4:0] read_register_1, // [19:15] -> rs1
    input [4:0] read_register_2, // [24:20] -> rs2
    input [4:0] write_register, // [11:7] -> rd

    // data to be written into the destination register (rd)
    input [DATA_LENGTH-1:0] write_data,

    // data read from the source registers (rs1 and rs2)
    output [DATA_LENGTH-1:0] read_data_1,
    output [DATA_LENGTH-1:0] read_data_2
);
    // 32 registers, each 32 bits wide
    reg [DATA_LENGTH-1:0] memory [0:DATA_LENGTH-1];

    // read operation is asynchronous (also hardwires register 0(x0) to always be 0)
    assign read_data_1 = (read_register_1 != 5'b0) ? memory[read_register_1] : 32'b0;
    assign read_data_2 = (read_register_2 != 5'b0) ? memory[read_register_2] : 32'b0;

    // loop counter for the reset block
    integer i;

    // write operation is synchronous
    always@(posedge clk) begin
        if(reset == 1'b1) begin
            for(i=0;i<32;i=i+1) begin
                memory[i] <= 0;
            end
        end else begin
            // write only if RegWrite is active and we are not trying to overwrite register 0(x0)
            if(RegWrite == 1'b1 && write_register != 5'b0) begin
                memory[write_register] <= write_data;
            end
        end
    end
endmodule

// ALU CONTROL module
module alu_control(
    input [1:0] ALUOp,
    input [6:0] funct7,
    input [2:0] funct3,

    output reg [3:0] alu_control
);
    always@(*) begin
        casex({ALUOp, funct7, funct3})
            12'b00_xxxxxxx_xxx: alu_control = 4'b0010; // lw or sw
            12'b01_xxxxxxx_xxx: alu_control = 4'b0110; // beq

            12'b10_0000000_000: alu_control = 4'b0010; // add
            12'b10_0100000_000: alu_control = 4'b0110; // subtract
            12'b10_0000000_111: alu_control = 4'b0000; // and
            12'b10_0000000_110: alu_control = 4'b0001; // or
            12'b10_0000000_100: alu_control = 4'b0011; // xor

            12'b11_xxxxxxx_000: alu_control = 4'b0010; // addi
            12'b11_xxxxxxx_111: alu_control = 4'b0000; // andi
            12'b11_xxxxxxx_110: alu_control = 4'b0001; // ori
            12'b11_xxxxxxx_100: alu_control = 4'b0011; // xori

            default:
            alu_control = 4'b0000;
        endcase
    end
endmodule

// ALU module
module alu #(parameter DATA_LENGTH = 32)(
    input [3:0] alu_control,
    input [DATA_LENGTH-1:0] op_a,
    input [DATA_LENGTH-1:0] op_b,

    output reg [DATA_LENGTH-1:0] result_alu,
    output Zero
);
    always@(*) begin
        case(alu_control)
            4'b0010: result_alu = op_a + op_b;
            4'b0110: result_alu = op_a - op_b;
            4'b0000: result_alu = op_a & op_b;
            4'b0001: result_alu = op_a | op_b;
            4'b0011: result_alu = op_a ^ op_b;
            default: result_alu = 32'h0000_0000;
        endcase
    end

    // assert Zero flag if the ALU result is 0
    assign Zero = (result_alu == 0) ? 1 : 0;
endmodule

// AND module
// used to determine if a branch condition is met
module and_gate(
    input and_in1, // PCWriteCond
    input and_in2, // Zero

    output and_out
);
    assign and_out = and_in1 & and_in2;
endmodule

// OR module
// used to determine the PC enable signal
module or_gate(
    input or_in1, // PCWrite
    input or_in2, // output of and gate

    output or_out // pc_en
);
    assign or_out = or_in1 | or_in2;
endmodule

// CONTROL module
// finite state machine (FSM) controlling the multi-cycle datapath
module control(
    input clk,
    input reset,
    input [6:0] opcode,

    output PCWriteCond,
    output PCWrite,
    output IorD,
    output MemRead,
    output MemWrite,
    output MemtoReg,
    output IRWrite,
    output PCSource,
    output ALUSrcA,
    output RegWrite,

    output [1:0] ALUOp,
    output [1:0] ALUSrcB
);
    reg [3:0] ns;
    reg [3:0] cs;

    reg [13:0] control;

    assign {PCWriteCond, PCWrite, IorD, MemRead, MemWrite, MemtoReg, IRWrite, RegWrite, ALUSrcA, ALUSrcB, ALUOp, PCSource} = control;

    // compute next state
    always@(cs or opcode) begin
        casex({cs,opcode})
            // state 0 : instruction fetch
            11'b0000_xxxxxxx: ns = 4'b0001;

            // state 1 : instruction decode / register fetch
            11'b0001_0000011, // lw  
            11'b0001_0100011: ns = 4'b0010; // sw
            11'b0001_0110011: ns = 4'b0110; // R
            11'b0001_1100011: ns = 4'b1000; // beq
            11'b0001_0010011: ns = 4'b1001; // I

            // state 2 : memory address computation
            11'b0010_0000011: ns = 4'b0011; // lw
            11'b0010_0100011: ns = 4'b0101; // sw

            // state 3 : memory access (read)
            11'b0011_xxxxxxx: ns = 4'b0100; // lw

            // state 4 : memory read completion step
            11'b0100_xxxxxxx: ns = 4'b0000; // lw

            // state 5 : memory access (write)
            11'b0101_xxxxxxx: ns = 4'b0000; // sw

            // state 6 : execution
            11'b0110_xxxxxxx: ns = 4'b0111; // R

            // state 7 : R-type completion
            11'b0111_xxxxxxx: ns = 4'b0000; // R

            // state 8 : branch completion
            11'b1000_xxxxxxx: ns = 4'b0000; // beq

            // state 9: I-type execution
            11'b1001_xxxxxxx: ns = 4'b1010;

            // state 10: I-type completion
            11'b1010_xxxxxxx: ns = 4'b0000;
            default: ns = 4'b0000;
        endcase
    end

    // update current state
    always@(posedge clk) begin
        if(reset == 1'b1) begin
            cs <= 0;
        end else begin
            cs <= ns;
        end
    end

    // compute and generate outputs for each state
    always@(cs) begin
        case(cs)
            // PCWriteCond, PCWrite, IorD, MemRead, MemWrite, MemtoReg, IRWrite, RegWrite, ALUSrcA, ALUSrcB, ALUOp, PCSource
            4'b0000: control = 14'b0_1_0_1_0_0_1_0_0_01_00_0;
            4'b0001: control = 14'b0_0_0_0_0_0_0_0_0_10_00_x;
            4'b0010: control = 14'b0_0_0_0_0_0_0_0_1_10_00_x;
            4'b0011: control = 14'b0_0_1_1_0_0_0_0_x_xx_xx_x; // we don't care what ALU is doing
            4'b0100: control = 14'b0_0_0_0_0_1_0_1_x_xx_xx_x;
            4'b0101: control = 14'b0_0_1_0_1_0_0_0_x_xx_xx_x;
            4'b0110: control = 14'b0_0_0_0_0_0_0_0_1_00_10_x;
            4'b0111: control = 14'b0_0_0_0_0_0_0_1_x_xx_xx_x;
            4'b1000: control = 14'b1_0_0_0_0_0_0_0_1_00_01_1;
            4'b1001: control = 14'b0_0_0_0_0_0_0_0_1_10_11_x;
            4'b1010: control = 14'b0_0_0_0_0_0_0_1_x_xx_xx_x;
            default: control = 14'b0;
        endcase
    end

endmodule

// MICROPROCESSOR module
module microprocessor #(parameter DATA_LENGTH = 32)(
    input clk,
    input reset
);
    wire [DATA_LENGTH-1:0] instruction; // output of IR

    // MUX 2:1
    wire [DATA_LENGTH-1:0] mux1_to_memory;
    wire [DATA_LENGTH-1:0] mux2_to_registers;
    wire [DATA_LENGTH-1:0] mux3_to_alu;
    wire [DATA_LENGTH-1:0] mux4_to_pc;

    // MUX 3:1
    wire [DATA_LENGTH-1:0] mux_to_alu;

    // OR
    wire out_of_and_gate;
    wire pc_enable;

    // PC
    wire [DATA_LENGTH-1:0] pc_to_mux1_and_mux3;

    // MEMORY
    wire [DATA_LENGTH-1:0] memory_to_mdr_or_ir;

    // MEMORY DATA REGISTER
    wire [DATA_LENGTH-1:0] mdr_to_mux2;

    // REGISTERS
    wire [DATA_LENGTH-1:0] reg_to_A;
    wire [DATA_LENGTH-1:0] reg_to_B;

    // IMMDEDIATE GENERATOR
    wire [DATA_LENGTH-1:0] ig_to_mux;

    // A & B REGISTERS
    wire [DATA_LENGTH-1:0] B_reg_to_memory_or_mux;
    wire [DATA_LENGTH-1:0] A_reg_to_mux3;

    // ALU & ALU CONTROL
    wire [DATA_LENGTH-1:0] ALU_result;
    wire [3:0] alu_cntrl;
    wire Zero;


    // ALUOut
    wire [DATA_LENGTH-1:0] aluout_to_mux1_mux2_and_mux3;

    // outputs of CONTROL
    wire PCWriteCond;
    wire PCWrite;
    wire IorD;
    wire MemRead;
    wire MemWrite;
    wire MemtoReg;
    wire IRWrite;
    wire PCSource;
    wire ALUSrcA;
    wire RegWrite;
    wire [1:0] ALUSrcB;
    wire [1:0] ALUOp;

    control CNTRL(
        .clk        (clk),
        .reset      (reset),
        .opcode     (instruction[6:0]),
        .PCWriteCond(PCWriteCond),
        .PCWrite    (PCWrite),
        .IorD       (IorD),
        .MemRead    (MemRead),
        .MemWrite   (MemWrite),
        .MemtoReg   (MemtoReg),
        .IRWrite    (IRWrite),
        .PCSource   (PCSource),
        .ALUSrcA    (ALUSrcA),
        .RegWrite   (RegWrite),
        .ALUSrcB    (ALUSrcB),
        .ALUOp      (ALUOp)
    );

    or_gate OR(
        .or_in1 (PCWrite),
        .or_in2 (out_of_and_gate),
        .or_out (pc_enable)
    );

    and_gate AND(
        .and_in1    (PCWriteCond),
        .and_in2    (Zero),
        .and_out    (out_of_and_gate)
    );

    program_counter PC(
        .clk     (clk),
        .reset   (reset),
        .pc_en   (pc_enable),
        .pc_next (mux4_to_pc),
        .pc_out  (pc_to_mux1_and_mux3)
    );

    mux2to1 MUX1(
        .mux_in1    (aluout_to_mux1_mux2_and_mux3),
        .mux_in2    (pc_to_mux1_and_mux3),
        .mux_sel    (IorD),
        .mux_out    (mux1_to_memory)
    );

    mux2to1 MUX2(
        .mux_in1    (mdr_to_mux2),
        .mux_in2    (aluout_to_mux1_mux2_and_mux3),
        .mux_sel    (MemtoReg),
        .mux_out    (mux2_to_registers)
    );

    mux2to1 MUX3(
        .mux_in1    (A_reg_to_mux3),
        .mux_in2    (pc_to_mux1_and_mux3),
        .mux_sel    (ALUSrcA),
        .mux_out    (mux3_to_alu)
    );

    mux2to1 MUX4(
        .mux_in1    (aluout_to_mux1_mux2_and_mux3),
        .mux_in2    (ALU_result),
        .mux_sel    (PCSource),
        .mux_out    (mux4_to_pc)
    );

    mux3to1 MUX(
        .mux_in_B   (B_reg_to_memory_or_mux),
        .mux_in_IMM (ig_to_mux),
        .ALUSrcB    (ALUSrcB),
        .mux_out    (mux_to_alu)
    );

    memory MEM(
        .clk            (clk),
        .memory_addr    (mux1_to_memory),
        .memory_in      (B_reg_to_memory_or_mux),
        .MemWrite       (MemWrite),
        .MemRead        (MemRead),
        .memory_out     (memory_to_mdr_or_ir)
    );

    memory_register MDR(
        .clk         (clk),
        .reset       (reset),
        .mem_reg_in  (memory_to_mdr_or_ir),
        .mem_reg_out (mdr_to_mux2)
    );

    instruction_register IR(
        .clk                      (clk),
        .reset                    (reset),
        .IRWrite                  (IRWrite),
        .instruction_register_in  (memory_to_mdr_or_ir),
        .instruction_register_out (instruction)
    );

    registers REG(
        .clk             (clk),
        .reset           (reset),
        .RegWrite        (RegWrite),
        .read_register_1 (instruction[19:15]),
        .read_register_2 (instruction[24:20]),
        .write_register  (instruction[11:7]),
        .write_data      (mux2_to_registers),
        .read_data_1     (reg_to_A),
        .read_data_2     (reg_to_B)
    );

    immediate_generator IG(
        .imm_gen_in     (instruction),
        .imm_gen_out    (ig_to_mux)
    );

    memory_register A(
        .clk         (clk),
        .reset       (reset),
        .mem_reg_in  (reg_to_A),
        .mem_reg_out (A_reg_to_mux3)
    );

    memory_register B(
        .clk         (clk),
        .reset       (reset),
        .mem_reg_in  (reg_to_B),
        .mem_reg_out (B_reg_to_memory_or_mux)
    );

    alu_control ALUCNTRL(
        .ALUOp       (ALUOp),
        .funct7      (instruction[31:25]),
        .funct3      (instruction[14:12]),
        .alu_control (alu_cntrl)
    );

    alu ALU(
        .alu_control (alu_cntrl),
        .op_a        (mux3_to_alu),
        .op_b        (mux_to_alu),
        .result_alu  (ALU_result),
        .Zero        (Zero)
    );

    memory_register ALUOut(
        .clk         (clk),
        .reset       (reset),
        .mem_reg_in  (ALU_result),
        .mem_reg_out (aluout_to_mux1_mux2_and_mux3)
    );

endmodule 
