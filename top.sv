// Top module. Connects components together to have functional RISC-V architecture
import instruction_type_pkg::*;

module top (
    input  logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);

    //
    instr_type_t current_instr_type;

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

    // Control & mux select signals
    logic        reset;
    logic        pc_wrt;
    logic        dmem_wren;
    logic        sel_op1;    // 0: rs1_val, 1: PC
    logic        sel_op2;    // 0: rs2_val, 1: imm
    logic [1:0]  rd_sel;     // 0: alu_out, 1: dmem_out, 2: pc_pl4, 3: imm

    // Basically wires
    logic [6:0] op_code;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic signed [31:0] imm;
    logic [31:0] pc_pl4;
    logic [31:0] alu_op1;
    logic [31:0] alu_op2;
    logic [31:0] alu_out;
    logic branch_taken;
    logic [31:0] dmem_addr;
    logic [31:0] dmem_in;
    logic [31:0] dmem_out;

    assign op_code = instr[6:0];
    assign funct3 = instr[14:12];
    assign funct7 = instr[31:25];

    // Data wires
    assign dmem_addr = alu_out;
    assign dmem_in = rs2_val;
    assign branch_taken = alu_out[0];

    //
    logic fetch, decode, exec, mem, write;

    always_ff @(posedge clk) begin
    // FSM cycles through stages
        if (reset) begin
            fetch  <= 1'b1;
            decode <= 1'b0;
            exec   <= 1'b0;
            mem    <= 1'b0;
            write     <= 1'b0;
        end else begin
            fetch  <= write;
            decode <= fetch;
            exec   <= decode;
            mem    <= exec;
            write     <= mem;
        end
    end

    always_comb begin
        /* let "register file" == "RF". "instruction register" == "IR"
        High level connections

        IR output -> Immed gen // Immediate and funct7 are passed into the same logic for ALU, which handles selecting the proper values based on the instruction type
        IR output[] -> rs1 (register file)
        IR output[] -> rs2 (register file)
        IR output[] -> rd (register file)
        PC -> 1 (mux 1)
        pc_pl4 -> 2 (mux rd)

        Immed gen -> 1 (mux 2)
        Immed gen -> 3 (mux rd)
        rs2v (rf) -> 0 (mux 2)
        rs2v (rf) -> in (Dmem)

        rs1v (rf) -> 0 (mux 1)
        IR -> funct3 || funct7 (ALU 2)
        out (Dmem) -> 1 (mux rd)

        out (mux 1) -> op1 (ALU 2)
        out (mux 2) -> op2 (ALU 2)
        
        ALU2_out -> 0 (mux rd)
        ALU2_out -> address (Dmem)

        out (mux rd) -> rdv

        */
        // functs from op_code
        if (decode) begin
            ir_write = 1'b1;
        end

        if (mem) begin
            if (current_instr_type == S_STORE) begin
                dmem_wren = 1'b1;
            end
        end

        if (write) begin
            pc_wrt = 1'b1;
            case (current_instr_type)
                R_ALU, I_ALU, I_LOAD, I_JALR, U_LUI, U_AUIPC, J_JAL: begin
                    rf_wren = 1'b1;
                end
            endcase
        end
    end

    always_comb begin
    // mux 1
        if (sel_op1)
            alu_op1 = PC;
        else
            alu_op1 = rs1_val;
    end

    always_comb begin
    // mux 2
        if (sel_op2)
            alu_op2 = imm;
        else
            alu_op2 = rs2_val;
    end

    always_comb begin
    // mux rd
        case (rd_sel)
            2'd0:    rd_val = alu_out;
            2'd1:    rd_val = dmem_out;
            2'd2:    rd_val = pc_pl4;
            2'd3:    rd_val = imm;
            default: rd_val = 32'd0;
        endcase
    end

    always_comb begin
    // decode instructions to flags
        sel_op1 = 1'b0;
        sel_op2 = 1'b0;
        rd_sel  = 2'd0;

        case (current_instr_type)
            R_ALU: begin
                sel_op1 = 1'b0; // rs1_val
                sel_op2 = 1'b0; // rs2_val
                rd_sel  = 2'd0; // alu_out
            end
            I_ALU: begin
                sel_op1 = 1'b0; // rs1_val
                sel_op2 = 1'b1; // imm
                rd_sel  = 2'd0; // alu_out
            end
            I_LOAD: begin
                sel_op1 = 1'b0; // rs1_val
                sel_op2 = 1'b1; // imm
                rd_sel  = 2'd1; // dmem_out
            end
            S_STORE: begin
                sel_op1 = 1'b0; // rs1_val
                sel_op2 = 1'b1; // imm
            end
            B_BRANCH: begin
                sel_op1 = 1'b0; // rs1_val
                sel_op2 = 1'b0; // rs2_val
            end
            U_LUI: begin
                rd_sel  = 2'd3; // imm
            end
            U_AUIPC: begin
                sel_op1 = 1'b1; // PC
                sel_op2 = 1'b1; // imm
                rd_sel  = 2'd0; // alu_out (PC + imm)
            end
            J_JAL, I_JALR: begin
                rd_sel  = 2'd2; // pc_pl4
            end
        endcase
    end

    // always_comb begin
    // // always_comb logic [3:0] instruction_type(input logic [6:0] op_code)
    //     unique case (op_code)
    //         7'b0110011: sel_op1 = 0, sel_op2 = 0 // R-type (Register-Register ALU)
    //         7'b0010011: // I-type (Immediate ALU)
    //         7'b0000011: // I-type (Loads)
    //         7'b1100111: // I-type (Jump & Link Register - JALR)
    //         7'b1110011: // I-type (Environment / System)
    //         7'b0001111: // I-type (Misc Memory - Fences)
    //         7'b0100011: sel_op2 = 1, sel_op2 = 0, wren = 1, // S-type (Store)
    //         7'b1100011: // B-type (Branch)
    //         7'b0110111: wren = 1, rd_sel = 3 // U-type (Upper Immediate - LUI) -> set MUX 2 to pos 3 to read in imm_u value, have write enabled
    //         7'b0010111: wren = 1, rd_sel = 0, sel_op2 = 1, sel_op1 = 1// U-type (Add Upper Imm to PC - AUIPC)
    //         7'b1101111: // J-type (Jump & Link - JAL)
    //     endcase
    // end

    // De-code op-code to instr
    always_comb begin
        case (op_code)
            7'b0110011: current_instr_type = R_ALU;    // Register-Register ALU
            7'b0010011: current_instr_type = I_ALU;    // Immediate ALU
            7'b0000011: current_instr_type = I_LOAD;   // Loads
            7'b1100111: current_instr_type = I_JALR;   // Jump & Link Register
            7'b1110011: current_instr_type = I_SYSTEM; // Environment / System
            7'b0001111: current_instr_type = I_FENCE;  // Misc Memory (Fences)
            7'b0100011: current_instr_type = S_STORE;  // Store
            7'b1100011: current_instr_type = B_BRANCH; // Branch
            7'b0110111: current_instr_type = U_LUI;    // Upper Immediate (LUI)
            7'b0010111: current_instr_type = U_AUIPC;  // Add Upper Imm to PC (AUIPC)
            7'b1101111: current_instr_type = J_JAL;    // Jump & Link (JAL)
            default:    current_instr_type = UNKNOWN;
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

controller u_controller (
        .clk          (clk),
        .reset        (reset),
        .pc_wrt       (pc_wrt),
        .op_code      (op_code),
        .imm          (imm),
        .rs1_val      (rs1_val),
        .branch_taken (branch_taken),
        .pc           (PC),
        .pc_pl4       (pc_pl4)
    );

    ALU_handler u_alu (
        .funct3          (funct3),
        .op_code         (op_code),
        .immediate       (imm[11:0]), //// this is wrong!!!!!... I think
        .source_reg1     (rs1_val),
        .source_reg2     (rs2_val),
        .destination_reg (alu_out)
    );

    memory #(
        .IMEM_INIT_FILE_PREFIX (IMEM_INIT_FILE_PREFIX),
        .DMEM_INIT_FILE_PREFIX (DMEM_INIT_FILE_PREFIX),
        .CLK_FREQ              (CLK_FREQ)
    ) u_memory (
        .clk           (clk),
        .funct3        (funct3),
        .dmem_wren     (dmem_wren),
        .dmem_address  (dmem_addr),
        .dmem_data_in  (dmem_in),
        .imem_address  (PC),
        .imem_data_out (imem_data),
        .dmem_data_out (dmem_out),
        .reset         (reset),
        .led           (),          // Connect to a top-level port if needed
        .red           (RGB_R),
        .green         (RGB_G),
        .blue          (RGB_B)
    );

endmodule



// ALU will output register. Means sign extention or zeroing will occur somewhere relative to DMem
// Do I need different wren? -> regardless make sure it is - if not set to 1 in op_code


// I need to make all of the Immed gen block -> it needs to be able to send complete imm_x value to controller module or send through ALU (based on instruction type)