// AND module
// used to determine if a branch condition is met
module and_gate(
    input and_in1, // PCWriteCond
    input and_in2, // Zero

    output and_out
);
    assign and_out = and_in1 & and_in2;
endmodule
