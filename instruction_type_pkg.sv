package instruction_type_pkg:
    typedef enum logic [3:0] {
        R_ALU,      // 0110011: Register-Register ALU
        I_ALU,      // 0010011: Immediate ALU
        I_LOAD,     // 0000011:
        I_JALR,     // 1100111:
        I_SYSTEM,   // 1110011: Environment / System
        I_FENCE,    // 0001111: Misc Memory (Fences)
        S_STORE,    // 0100011:
        B_BRANCH,   // 1100011:
        U_LUI,      // 0110111: Upper Immediate
        U_AUIPC,    // 0010111: Add Upper Imm to PC
        J_JAL,      // 1101111:
        UNKNOWN
    } instr_type_t;
endpackage