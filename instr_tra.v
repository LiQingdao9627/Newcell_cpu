module instr_tra(
    input [31:0] instr,
    output [6:0] opcode,
    output [4:0] rd,
    output [2:0] func3,
    output [4:0] rs1,
    output [4:0] rs2,
    output [6:0] func7,
    output [31:0] immI,
    output [31:0] immS,
    output [31:0] immB,
    output [31:0] immU,
    output [31:0] immJ);

    assign opcode = instr[6:0];
    assign rd = instr[11:7];
    assign func3 = instr[14:12];
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign func7 = instr[31:25];
    assign immI = {{20{instr[31]}},instr[31:20]};
    assign immS = {{25{instr[31]}},instr[31:25]};
    assign immB = {{19{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8],1'b0};
    assign immU = {instr[31:12],12'b0};
    assign immJ = {{11{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21],1'b0};

endmodule