# Design Decisions

This document covers what and why design decisions in the this project were made. The exact structure of how to document the decisions is still being decided so when in doubt, write it out and it will be cleaned up later.

Modularity would be beneficial for productive teaming
Potential module structure:

- Top module
  - Instances other modules
  - Process instruction type
  - ALU destination selection
- Memory module
  - inputs: clk, func3, dmem_wren, dmem_data, dmem_address, imem_address
  - outputs: dmem_data, imem_data, reset
- Controller module
  - inputs: clk
  - outputs: PC
  - Updates program counter
  - Handles JAL instructions
- ALU module
  - inputs: clk
  - output: ALU output
  - Determines ALU inputs
    - Immediate processing
  - Determines ALU function
