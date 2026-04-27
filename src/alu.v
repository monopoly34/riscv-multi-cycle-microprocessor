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
