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
