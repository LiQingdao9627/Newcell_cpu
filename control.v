`include "define.v"
module control(
    input         clk,
    input  [6:0]  opcode,
    input  [2:0]  func3,
    input  [6:0]  func7,
    input  [31:0] immI,
    input  [31:0] immS,
    input  [31:0] immB,
    input  [31:0] immU,
    input  [31:0] immJ,
    input         shamt,
    input         rst,

    output reg [4:0]  alu_ctrl,//ALU控制信号
    output reg alu_src,//ALU的src2是取立即数还是取rs2中的数(1是取立即数，因为1很像i)
    output reg [2:0] immwho,//ALU的立即数取哪一个

    output reg b_pc,//是否是B指令，用来调控数据对于PC的传输
    output reg reg_wr_en,
    output reg reg_data_from,//写回reg的数据是来自ALU还是来自存储器。1是来自存储器
    output reg        jump,
    output reg reg_rst,//是否是置位命令

    output reg sign_ext,//存储器取出的数据是否进行符号位扩展
    output reg [1:0] size,//存取的大小
    output reg wr_en,//存储器的写使能信号
    output reg rd_en//存储器的读使能信号


);

    reg [2:0] control_status;

    always@(posedge rst)
    begin
      control_status = 3'b000;
    end

                            //R add                                                         J jal                   I jalr                                   I lb                                     I lh                                     I lw                                     I lbu                                    I lhu                                    S sb                                     S sh                                     S sw                                     I addi
    assign alu_ctrl = ((opcode==7'b0110011 && func3==3'b000 && func7==7'b0000000) || (opcode==7'b1101111) || (opcode==7'b1100111 && func3==3'b000) || (opcode==7'b0000011 && func3==3'b000) || (opcode==7'b0000011 && func3==3'b001) || (opcode==7'b0000011 && func3==3'b010) || (opcode==7'b0000011 && func3==3'b100) || (opcode==7'b0000011 && func3==3'b101) || (opcode==7'b0100011 && func3==3'b000) || (opcode==7'b0100011 && func3==3'b001) || (opcode==7'b0100011 && func3==3'b010) || (opcode==7'b0010011 && func3==3'b000))? `ALU_ADD:
                      (opcode==7'b0110011 && func3==3'b000 && func7==7'b0100000)? `ALU_SUB://R sub
                      ((opcode==7'b0110011 && func3==3'b001) || (opcode==7'b0110111) || (opcode==7'b0010011 && func3==3'b001))? `ALU_LOGIC_LEFT_MOVE://R sll U lui I slli
                      ((opcode==7'b0110011 && func3==3'b010) || (opcode==7'b1100011 && func3==3'b100) || (opcode==7'b0010011 && func3==3'b010))? `ALU_COMPARE_SMA_ZERO://R slt B blt I slti
                      ((opcode==7'b0110011 && func3==3'b011) || (opcode==7'b1100011 && func3==3'b110) || (opcode==7'b0010011 && func3==3'b011))? `ALU_COMPARE_UNS_SMA_ZERO://R sltu B bltu I sltiu
                      ((opcode==7'b0110011 && func3==3'b100) || (opcode==7'b0010011 && func3==3'b100))? `ALU_XOR://R xor I xori
                      ((opcode==7'b0110011 && func3==3'b101 && func7 == 7'b0000000) || (opcode==7'b0010011 && func3==3'b101 && func7==7'b0000000))? `ALU_LOGIC_RIGHT_MOVE://R srl I srli
                      ((opcode==7'b0110011 && func3==3'b101 && func7 == 7'b0100000) || (opcode==7'b0010011 && func3==3'b101 && func7==7'b0100000))? `ALU_ARI_RIGHT_MOVE://R sra I srai
                      ((opcode==7'b0110011 && func3==3'b110) || (opcode==7'b0010011 && func3==3'b110))? `ALU_OR://R or I ori
                      ((opcode==7'b0110011 && func3==3'b111) || (opcode==7'b0010011 && func3==3'b111))? `ALU_AND://R and I andi
                      (opcode==7'b0010111)? `ALU_auipc_LEFT_MOVE_ADD://U auipc
                      (opcode==7'b1100011 && func3==3'b000)? `ALU_COMPARE_E_ZERO://B beq
                      (opcode==7'b1100011 && func3==3'b001)? `ALU_COMPARE_UNE_ZERO://B bne
                      (opcode==7'b1100011 && func3==3'b101)? `ALU_COMPARE_BIGE_ZERO://B bge
                      (opcode==7'b1100011 && func3==3'b111)? `ALU_COMPARE_UNS_BIGE_ZERO://B bgeu
                      0;

    assign alu_src = ((opcode==7'b0110011) || (opcode==7'b1100011))?1'b0://所有R型指令,所有B型指令
                     ((opcode==7'b0110111) || (opcode==7'b0010111) || (opcode==7'b1101111) || (opcode==7'b1100111) || (opcode==7'b0000011) || (opcode==7'b0100011) || (opcode==7'b0010011));//U lui U auipc J jal I jalr 所有的载入指令（I l）所有的存储指令(S s) 所有的I型运算指令

    assign immwho  = ((opcode==7'b0110111) || (opcode==7'b0010111))? `UimmU://U lui
                     (opcode==7'b1101111)? `UimmJ://J jal
                     ((opcode==7'b1100111) || (opcode==7'b0000011) || (opcode==7'b0010011))? `UimmI://I jalr 所有的I型加载指令(I l)
                     (opcode==7'b0100011)? `UimmS://所有的S型指令
                     0;

    assign b_pc    = (opcode==7'b1100011);//所有B型指令

    assign reg_wr_en = (opcode==7'b0110011) || (opcode==7'b0110111) || (opcode==7'b0010111) || (opcode==7'b1101111) || (opcode==7'b1100111) || (opcode==7'b0000011) || (opcode==7'b0010011);//所有R型指令 U lui U auipc J jal I jalr 所有的I型load指令 所有的I型运算指令

    assign reg_data_from = (opcode==7'b0000011);//所有的I型load指令

    assign jump = (opcode==7'b1101111) || (opcode==7'b1100111) || (opcode==7'b1100011);//J jal I jalr 所有B型指令

    assign reg_rst = (opcode==7'b0110011 && func3==3'b010) || (opcode==7'b0110011 && func3==3'b011) || (opcode==7'b0010011 && func3==3'b010) || (opcode==7'b0010011 && func3==3'b011); //R slt R sltu I slti I sltiu

    assign sign_ext = (opcode==7'b0000011 && func3==3'b000) || (opcode==7'b0000011 && func3==3'b001) || (opcode==7'b0000011 && func3==3'b010);//I lb I lh I lw（剩下的lbu等不必写）

    assign size = ((opcode==7'b0000011 && func3==3'b000) || (opcode==7'b0000011 && func3==3'b100) || (opcode==7'b0100011 && func3==3'b000))? `byte://I lb I lbu S sb
                  ((opcode==7'b0000011 && func3==3'b001) || (opcode==7'b0000011 && func3==3'b101) || (opcode==7'b0100011 && func3==3'b001))? `halfword://I lh I lhu S sh
                  ((opcode==7'b0000011 && func3==3'b010) || (opcode==7'b0100011 && func3==3'b010))? `word://I lw S sw
                  0;

    assign wr_en = (opcode==7'b0100011);//所有S型指令

    assign rd_en = (opcode==7'b0000011);//所有的I型load指令
    




endmodule