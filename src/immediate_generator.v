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
