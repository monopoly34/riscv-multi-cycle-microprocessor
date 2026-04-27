// REGISTERS module
// contains 32 general-purpose 32-bit registers
module registers #(parameter DATA_LENGTH = 32)(
    input clk,
    input reset,
    input RegWrite,

    // register addresses (decoded from the instruction)
    input [4:0] read_register_1, // [19:15] -> rs1
    input [4:0] read_register_2, // [24:20] -> rs2
    input [4:0] write_register, // [11:7] -> rd

    // data to be written into the destination register (rd)
    input [DATA_LENGTH-1:0] write_data,

    // data read from the source registers (rs1 and rs2)
    output [DATA_LENGTH-1:0] read_data_1,
    output [DATA_LENGTH-1:0] read_data_2
);
    // 32 registers, each 32 bits wide
    reg [DATA_LENGTH-1:0] memory [0:DATA_LENGTH-1];

    // read operation is asynchronous (also hardwires register 0(x0) to always be 0)
    assign read_data_1 = (read_register_1 != 5'b0) ? memory[read_register_1] : 32'b0;
    assign read_data_2 = (read_register_2 != 5'b0) ? memory[read_register_2] : 32'b0;

    // loop counter for the reset block
    integer i;

    // write operation is synchronous
    always@(posedge clk) begin
        if(reset == 1'b1) begin
            for(i=0;i<32;i=i+1) begin
                memory[i] <= 0;
            end
        end else begin
            // write only if RegWrite is active and we are not trying to overwrite register 0(x0)
            if(RegWrite == 1'b1 && write_register != 5'b0) begin
                memory[write_register] <= write_data;
            end
        end
    end
endmodule
