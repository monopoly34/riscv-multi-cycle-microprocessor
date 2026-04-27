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
