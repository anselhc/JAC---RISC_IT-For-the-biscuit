`timescale 10ns/10ns
`include "top.sv"
// Include the file with the test instructions

// Notes:
// Make a file of all of the input instructions we will need
// Make a file for what the output should be
// Once the test bench finishes, write a python script that compares the two files line by line

// Functionality:
// Instances the top module of the processor
// Top will read from the file and parse the instructions
// The test bench will record what the processor does
// A file will be outputted with the results
// We will manually review the output file to make sure instructions were followed correctly

module proj1_tb;

    logic clk = 0;
    logic RGB_R, RGB_G, RGB_B;


    top u0 (
        .clk            (clk), 
        .RGB_R          (RGB_R), 
        .RGB_G          (RGB_G), 
        .RGB_B          (RGB_B)
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


