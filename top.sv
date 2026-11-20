// Top module. Connects components together to have functional RISC-V architecture
import instruction_type_pkg::*;

module top (
    input  logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);
    //
    logic [31:0] PC; // Program counter

    // IMM
    logic [31:0] instr; // instruction
    logic ir_write;

    //Register File
    logic [31:0] rf [31:0]; /////
    logic [4:0]  rs1; 
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [31:0] rs1_val;
    logic [31:0] rs2_val;
    logic [31:0] rd_val;
    logic rf_wren;

    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];

    assign rs1_val = (rs1 == 5'd0) ? 32'd0 : rf[rs1];
    assign rs2_val = (rs2 == 5'd0) ? 32'd0 : rf[rs2];

    //
    logic [31:0] imem_data;

    always_comb begin
        /* let "register file" == "RF". "instruction register" == "IR"
        High level connections

        IR output -> Immed gen // Immediate and funct7 are passed into the same logic for ALU, which handles selecting the proper values based on the instruction type
        IR output[] -> rs1 (register file)
        IR output[] -> rs2 (register file)
        IR output[] -> rd (register file)
        PC -> 1 (mux 1)

        Immed gen -> 1 (mux 2)
        Immed gen -> 3 (mux rd)
        rs2v (rf) -> 0 (mux 2)
        rs2v (rf) -> DIN (Dmem)

        rs1v (rf) -> 0 (mux 1)
        IR -> funct3 || funct7 (ALU 2)
        Dmem DOUT -> 1 (mux rd)

        out (mux 1) -> op1 (ALU 2)
        out (mux 2) -> op2 (ALU 2)
        
        ALU2_out -> 0 (mux rd)
        ALU2_out -> address (Dmem)

        out (mux rd) -> rdv

        */
        // PC <= PC + 4; // Skip ALU and just add 4 -> might actually need ALU here. Else, this is ALU 1
    end

    // 
    always_comb begin

    end

    // De-code op-code
    always_comb begin
    // always_comb logic [3:0] instruction_type(input logic [6:0] op_code)
        unique case (op_code)
            7'b0110011: sel_op1 = 0, sel_op2 = 0 // R-type (Register-Register ALU)
            7'b0010011: // I-type (Immediate ALU)
            7'b0000011: // I-type (Loads)
            7'b1100111: // I-type (Jump & Link Register - JALR)
            7'b1110011: // I-type (Environment / System)
            7'b0001111: // I-type (Misc Memory - Fences)
            7'b0100011: sel_op2 = 1, sel_op2 = 0, wren = 1, // S-type (Store)
            7'b1100011: // B-type (Branch)
            7'b0110111: wren = 1, rd_sel = 3 // U-type (Upper Immediate - LUI) -> set MUX 2 to pos 3 to read in imm_u value, have write enabled
            7'b0010111: wren = 1, rd_sel = 0, sel_op2 = 1, sel_op1 = 1// U-type (Add Upper Imm to PC - AUIPC)
            7'b1101111: // J-type (Jump & Link - JAL)
        endcase
    end

    // RegF
    integer i;
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'd0;
            end
        end else if (rf_wren && (rd != 5'd0)) begin
            rf[rd] <= rd_val;
        end
    end

    // IMM
    always_comb begin
        case (current_instr_type)
            I_ALU, I_LOAD, I_JALR: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end
            B_BRANCH: begin
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            J_JAL: begin
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            U_LUI, U_AUIPC: begin
                imm = {instr[31:12], 12'b0};
            end
            S_STORE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
        endcase
    end

    // IR
    always_ff @(posedge clk) begin
        if (reset) begin
            instr <= 32'h00000013;
        end else if (ir_write) begin
            instr <= imem_data;
        end
    end

endmodule



// ALU will output register. Means sign extention or zeroing will occur somewhere relative to DMem
// Do I need different wren? -> regardless make sure it is - if not set to 1 in op_code


// I need to make all of the Immed gen block -> it needs to be able to send complete imm_x value to controller module or send through ALU (based on instruction type)