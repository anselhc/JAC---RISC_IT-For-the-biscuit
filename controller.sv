//RV32I Controller Module
//Inputs:
//  Clock (CLK)
//  Opcode
//  Immediate
//  rs1
//  Branch Condition (TRUE/FALSE)
//Outputs:
//  Program Counter (PC)

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
