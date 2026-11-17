`timescale 10ns/10ns
`include "top.sv"

// Functionality:
// Instances the top module of the processor
// Top will read from the file and parse the instructions
// The test bench will record what the processor does
// A file will be outputted with the results
// We will manually review the output file to make sure instructions were followed correctly

module proj1_tb;

    logic clk = 0;

    top u0 (
        .clk            (clk), 
    );

    initial begin
        $dumpfile("proj1.vcd");
        $dumpvars(0, proj1_tb);
        #100000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule

