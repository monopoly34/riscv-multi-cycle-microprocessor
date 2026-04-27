// OR module
// used to determine the PC enable signal
module or_gate(
    input or_in1, // PCWrite
    input or_in2, // output of and gate

    output or_out // pc_en
);
    assign or_out = or_in1 | or_in2;
endmodule
