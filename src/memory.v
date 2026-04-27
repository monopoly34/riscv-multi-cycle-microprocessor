// MEMORY module
// instruction and data memory combined in one (Von Neumann architecture)
module memory #(parameter DATA_LENGTH = 32, MEM_SIZE = 256)(
    input clk,
    input [DATA_LENGTH-1:0] memory_addr,
    input [DATA_LENGTH-1:0] memory_in,
    input MemWrite,
    input MemRead,

    output [DATA_LENGTH-1:0] memory_out
);

    // memory array, each location holds 1 byte
    reg [DATA_LENGTH/4-1:0] memory [0:MEM_SIZE*4-1];

    // read from memory operation behavior
    // memory provides 32 bits = 4 bytes = 4 locations/addresses
    assign memory_out = (MemRead == 1'b1) ?
    { memory[memory_addr+3], memory[memory_addr+2], memory[memory_addr+1], memory[memory_addr] }
    : 32'b0;

    // write in memory operation behavior
    always@(posedge clk) begin
        if(MemWrite == 1'b1) begin
            // memory receives 32 bits = 4 bytes = 4 locations/addresses
            { memory[memory_addr+3], memory[memory_addr+2], memory[memory_addr+1], memory[memory_addr] } <= memory_in;
        end
    end

    // memory content initialization from file
    initial begin
        $readmemh("memory.mem", memory);
    end
endmodule
