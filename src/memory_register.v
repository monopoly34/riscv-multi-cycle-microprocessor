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
