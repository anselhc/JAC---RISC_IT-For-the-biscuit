# Design Decisions

This document covers what and why design decisions in the this project were made. The exact structure of how to document the decisions is still being decided so when in doubt, write it out and it will be cleaned up later.

Modularity would be beneficial for productive teaming
Potential module structure:

- Top module (Connor)
  - Instances other modules
  - Process instruction type
  - ALU destination selection
- Memory module
  - inputs: clk, func3, dmem_wren, dmem_data, dmem_address, imem_address
  - outputs: dmem_data, imem_data, reset
//Inputs:
//  Clock (CLK) 
//  Reset (rst)
//  PC Write (pc_wrt)
//  Opcode (op_code) [6:0]
//  Immediate (imm) [31:0]
//  RS1 value (rs1_val) [31:0] 
//  Branch Condition (TRUE/FALSE)
//Outputs:
//  Program Counter (pc) [31:0] 
//  Program Counter + 4 (pc_pl4) [31:0]
- ALU module (Ansel)
  - inputs: clk
  - output: ALU output
  - Determines ALU inputs
    - Immediate processing
  - Determines ALU function
