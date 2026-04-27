// MUX 2:1
module mux2to1 #(parameter DATA_LENGTH = 32)(
    input [DATA_LENGTH-1:0] mux_in1, // mux_sel == 1
    input [DATA_LENGTH-1:0] mux_in2, // mux_sel == 0
    input mux_sel, // IorD, MemtoReg or ALUSrcA

    output [DATA_LENGTH-1:0] mux_out
);
    assign mux_out = (mux_sel == 1'b1) ? mux_in1 : mux_in2;
endmodule
