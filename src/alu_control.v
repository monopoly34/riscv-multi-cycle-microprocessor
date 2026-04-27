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
