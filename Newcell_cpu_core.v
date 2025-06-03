`include "define.v"

module Newcell_cpu_core(
    input clk,
    input rst,
    input [31:0] mem_in_data,
    input [31:0] mem_in_instr,//好不容易读进来的指令

    output [31:0] instr_addr,
    output reg [31:0] mem_addr,
    output reg [1:0] size_reg,
    output reg sign_ext_reg,
    output reg wr_en_reg,
    output reg rd_en_reg,
    output reg [31:0] mem_write_data,
    output reg [2:0] control_status);//这是一个CPU核，要和外界的存储器交互的…(我终于开始写注释了)

    //为模块例化准备信号的部分

    //这里是PC的信号~
    wire jump;
    reg [31:0] jump_pc;
    wire [31:0] pc;//介个是用来读指令的地址~
    wire [31:0] pc_next;
    reg [31:0] sext_offset;

    //这里是指令翻译器的信号~
    wire [31:0] instr;
    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] func3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] func7;
    wire [31:0] immI;
    wire [31:0] immS;
    wire [31:0] immB;
    wire [31:0] immU;
    wire [31:0] immJ;

    //这里是控制单元的信号~(暂定,还要不断完善)
    wire [4:0] alu_ctrl;
    wire alu_src;
    wire [2:0] immwho;
    wire reg_wr_en;
    wire reg_data_from;
    wire reg_rst;
    wire b_pc;
    wire shamt;
    wire [1:0] size;
    wire sign_ext;
    wire wr_en;
    wire rd_en;


    //这里是寄存器堆的信号~
    reg [31:0] wr_data;
    wire [31:0] src_a;
    wire [31:0] src_b;

    //这里是ALU的信号~
    wire zero;
    wire [31:0] result;
    reg [31:0] in_src_a;
    reg [31:0] in_src_b;

    //这是虚实地址转换器的信号~
    wire [31:0] virtual_addr;
    wire [31:0] real_addr;





    //模块例化的部分
    pc pc_temp(
        .clk(clk),
        .rst(rst),
        .jump(jump_reg),
        .jump_pc(jump_pc),
        .sext_offset(sext_offset),
        .zero(zero_reg),
        .pc(pc),
        .pc_next(pc_next),
        .control_status(control_status));

    instr_tra instr_tra_temp(
        .instr(instr_reg),
        .opcode(opcode),
        .rd(rd),
        .func3(func3),
        .rs1(rs1),
        .rs2(rs2),
        .func7(func7),
        .immI(immI),
        .immS(immS),
        .immB(immB),
        .immU(immU),
        .immJ(immJ)
    );

    control control_temp(
        .clk(clk),
        .opcode(opcode_reg),
        .func3(func3_reg),
        .func7(func7_reg),
        .immI(immI_reg),
        .immS(immS_reg),
        .immB(immB_reg),
        .immU(immU_reg),
        .immJ(immJ_reg),
        .alu_ctrl(alu_ctrl),
        .alu_src(alu_src),
        .immwho(immwho),
        .reg_wr_en(reg_wr_en),
        .reg_data_from(reg_data_from),
        .reg_rst(reg_rst),
        .jump(jump),
        .b_pc(b_pc),
        .sign_ext(sign_ext),
        .size(size),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .shamt(shamt),
        .rst(rst),
        .control_status(control_status)
    );

    regfile regfile_temp(
        .clk(clk),
        .in_rs1(rs1_reg),
        .in_rs2(rs2_reg),
        .rd(rd_reg),
        .control_status(control_status),
        .wr_data(wr_data),
        .wr_en(reg_wr_en_reg),
        .out_rs1(src_a),
        .out_rs2(src_b)
    );

    alu alu_temp(
        .alu_ctrl(alu_ctrl),
        .src_a(in_src_a),
        .src_b(in_src_b),
        .zero(zero),
        .result(result)
    );

    addr_tra addr_tra_temp(
        .virtual_addr(virtual_addr),
        .real_addr(real_addr)
    );

    //为了实现多周期CPU，这里加入了信号的寄存器。

    //IF
    reg [31:0] instr_reg;
    reg [31:0] pc_next_reg;
    reg [31:0] pc_reg;

    //ID
    reg [6:0] opcode_reg;
    reg [4:0] rd_reg;
    reg [2:0] func3_reg;
    reg [4:0] rs1_reg;
    reg [4:0] rs2_reg;
    reg [6:0] func7_reg;
    reg [31:0] immI_reg;
    reg [31:0] immS_reg;
    reg [31:0] immB_reg;
    reg [31:0] immU_reg;
    reg [31:0] immJ_reg;

    //EX
    reg b_pc_reg;
    reg reg_wr_en_reg;
    reg reg_data_from_reg;
    reg jump_reg;
    reg reg_rst_reg;
    reg [7:0] result_reg;
    reg zero_reg;
    reg alu_src_reg;
    reg [2:0] immwho_reg;
    reg [7:0] src_b_reg;
    reg [7:0] wr_data_reg;

    //MEM
    reg [7:0] mem_in_data_reg;

    //下面是执行逻辑~

    assign shamt = rs2_reg[5];

    //和外界存储器交互的部分

    assign instr_addr = real_addr;
    assign virtual_addr = pc;
    assign instr      = mem_in_instr;

    //内部控制逻辑

    always@(*)begin

    mem_addr  = result_reg;

    //立即数判断逻辑(还有一些命令逻辑)
    if(alu_src_reg==1'b0)//值得注意的是这个模块是用来判断立即数是否进入ALU的，如果立即数用在了别的地方，要是用别的逻辑。
    begin
        in_src_a = src_a;
        in_src_b = src_b;
    end
    else
    begin
        case(immwho_reg)
        `UimmI:
        begin
            in_src_a = src_a;
            in_src_b = immI_reg;
        end
        `UimmS:
        begin
            in_src_a = src_a;
            in_src_b = immS_reg;
            mem_write_data= src_b_reg;

        end
        `UimmB:
        begin
            in_src_a = src_a;
            in_src_b = immB_reg<<1;
        end
        `UimmU:
        begin
            if(opcode_reg==7'b0110111)
            begin
               in_src_a = immU_reg;
               in_src_b = 32'd12;
            end
            if(opcode_reg==7'b0010111)
            begin
                in_src_a = immU_reg;
                in_src_b = pc_reg;
            end
            if(opcode_reg==7'b1101111)
            begin
                in_src_a = pc_reg;
                in_src_b = immJ_reg;
                jump_pc  = result_reg;
            end
            if(opcode_reg==7'b1100111)
            begin
                if(func3_reg==3'b000)
                begin
                    in_src_a = pc_reg;
                    in_src_b = immI_reg;
                    jump_pc  = result_reg&(~32'b1);
                end
            end
            end
        `UimmJ:
        begin
            in_src_a = src_a;
            in_src_b = immJ_reg<<1;
        end

        endcase
    end

    if(b_pc_reg)
    begin
        sext_offset = immB_reg;
        jump_pc  = pc_next_reg;
    end

    //寄存器写入来源逻辑
    if(reg_data_from_reg==1'b0)
    begin
        if(reg_rst_reg==1'b0)
        begin
            if(opcode_reg == 7'b1101111 ? 1 : opcode_reg == 7'b1100111 ? func3_reg == 3'b000 ? 1 : 0 : 0)
            begin
                wr_data = pc_next_reg;
            end
            else
            begin
                wr_data = result_reg;
            end
        end
        else
        begin
            wr_data = {32{zero_reg}};
        end
    end
    else
    begin
        wr_data = mem_in_data_reg;
    end

    //多周期执行逻辑（数据在寄存器间传递）
    
    case(control_status)
        `IF:
        begin
            instr_reg = instr;
            pc_next_reg = pc_next;
            pc_reg = pc;
        end
        `ID:
        begin
            opcode_reg = opcode;
            rd_reg = rd;
            func3_reg = func3;
            rs1_reg = rs1;
            rs2_reg = rs2;
            func7_reg = func7;
            immI_reg = immI;
            immS_reg = immS;
            immB_reg = immB;
            immU_reg = immU;
            immJ_reg = immJ;
        end

        `EX:
        begin
            b_pc_reg = b_pc;
            reg_wr_en_reg = reg_wr_en;
            reg_data_from_reg = reg_data_from;
            jump_reg = jump;
            reg_rst_reg = reg_rst;
            sign_ext_reg = sign_ext;
            size_reg = size;
            wr_en_reg = wr_en;
            rd_en_reg = rd_en;
            result_reg = result;
            zero_reg = zero;
            alu_src_reg = alu_src;
            immwho_reg = immwho;
            src_b_reg = src_b;
            wr_data_reg = wr_data;
        end

        `MEM:
        begin
            mem_in_data_reg = mem_in_data;
        end


        
    endcase

    end
endmodule