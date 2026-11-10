//RV32I Controller Module
//Inputs:
//  Clock (CLK) 
//  Reset (rst)
//  PC Write (pc_wrt)
//  opcode [6:0]
//  Immediate (imm) [31:0]
//  RS1 value (rs1_val) [31:0] 
//  Branch Condition (TRUE/FALSE)
//Outputs:
//  Program Counter (pc) [31:0] 
//  Program Counter + 4 (pc_pl4) [31:0]

// Functionality:
// Normal Case:
//  Processes one 4 byte word/instruction and thus moves four bytes forward
//  output: PC <= PC + 4
// JAL Case:
//  Processes one 4 byte word/instruction that calls a function and thus the processors needs to jump forward to the function code. 
//  output: PC <= PC + imm
// JALR Case:
//  Processes one 4 byte word/instruction that calls a function stored in some memory register
//  output: PC <= rs1 + imm
// Branch Case:
//  Processes one 4 byte word that results in some branching condition, PC unit waits for ALU return FALSE/TRUE before deciding output
//  output (FALSE): PC <= PC + 4
//  output (TRUE): PC <= PC + imm
// Reset Case:
//  Reset program counter.
//  output: PC <= 0/other reset value

module controller (
    input  logic        clk, // Binary (high or low)
    input  logic        reset, // Resets PC, Binary (high or low)
    input  logic        pc_wrt, // Enables PC writing, Binary (high or low)
    input  logic [6:0]  opcode, // 7 bits from end of word
    input  logic signed [31:0] imm, // 
    input  logic [31:0] rs1_val, // 
    input  logic        branch_taken, // Returned from ALU, Binary (high or low)
    output logic [31:0] pc, // Program counter value
    output logic [31:0] pc_pl4 // Program counter plus 4 for JAL instructions
);