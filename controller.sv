//RV32I Controller Module
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
    input  logic [6:0]  op_code, // 7 bits from end of word
    input  logic signed [31:0] imm, // 
    input  logic [31:0] rs1_val, // 
    input  logic        branch_taken, // Returned from ALU, Binary (high or low)
    output logic [31:0] pc, // Program counter value
    output logic [31:0] pc_pl4 // Program counter plus 4 for JAL instructions
);


// Define Opcodes
localparam logic [6:0] OP_JAL    = 7'b1101111; // JAL
localparam logic [6:0] OP_JALR   = 7'b1100111; // JALR
localparam logic [6:0] OP_BRANCH = 7'b1100011; // Branching

// Logic flow:
// 1. Determine instruction type
// 2. Have a bunch of cases for the instruction types
// 3. Process the specific case
// 4. Write PC

logic [31:0] next_pc;

assign pc_plus4 = pc + 32'd4;

// Decide where to go next
always_comb begin
  case (opcode)
    OP_JAL:    next_pc = pc + imm; // Jump imm / 4 instructions
    OP_JALR:   next_pc = (rs1_val + imm) & ~32'h1; // Ensure the final bit is always 0 so there are no odd memory addresses
    OP_BRANCH: next_pc = branch_taken ? pc + imm : pc_plus4; // If true, pc + imm, if false pc + 4 like normal
    default:   next_pc = pc_plus4;
  endcase
end

// Remember the value determined in always_comb
always_ff @(posedge clk) begin
  if (reset)         pc <= 32'h0; // Reset the program counter to 0
  else if (pc_write) pc <= next_pc; // Write the PC value determined in always_comb to the output register
end