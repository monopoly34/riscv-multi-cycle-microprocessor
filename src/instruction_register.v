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
