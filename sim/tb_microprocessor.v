`timescale 1ns / 1ps

module tb_microprocessor;
    reg clk;
    reg reset;
    
    microprocessor tb_microprocessor(.clk(clk), .reset(reset));
        
    initial begin
        clk = 1'b0; reset = 1'b0;
        #10 reset = 1'b1;
        #10 reset = 1'b0;
        #400 $finish;   
    end
    
    always #5 clk = ~clk;
endmodule
