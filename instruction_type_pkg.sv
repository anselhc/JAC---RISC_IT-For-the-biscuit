package instruction_type_handler:
    typedef enum logic [2:0] {
        R_TYPE,
        I_TYPE,
        S_TYPE,
        B_TYPE,
        U_TYPE,
        J_TYPE,
        UNKNOWN
    } instr_type_t;
endpackage