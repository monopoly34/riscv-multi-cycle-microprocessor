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
