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
