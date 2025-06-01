`include "define.v"

module Newcell_cpu_core(
    input clk,
    input rst,
    input [31:0] mem_in_data,
    input [31:0] mem_in_instr,//好不容易读进来的指令

    output [31:0] instr_addr,
    output [31:0] mem_addr,
    output [1:0] size,
    output sign_ext,
    output wr_en,
    output rd_en,
    output reg [31:0] mem_write_data);//这是一个CPU核，要和外界的存储器交互的…(我终于开始写注释了)

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
        .jump(jump),
        .jump_pc(jump_pc),
        .sext_offset(sext_offset),
        .zero(zero),
        .pc(pc),
        .pc_next(pc_next));

    instr_tra instr_tra_temp(
        .instr(instr),
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
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .immI(immI),
        .immS(immS),
        .immB(immB),
        .immU(immU),
        .immJ(immJ),
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
        .shamt(shamt)
    );

    regfile regfile_temp(
        .clk(clk),
        .in_rs1(rs1),
        .in_rs2(rs2),
        .rd(rd),
        .wr_data(wr_data),
        .wr_en(reg_wr_en),
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

    //下面是执行逻辑~

    assign shamt = rs2[5];

    //和外界存储器交互的部分

    assign instr_addr = real_addr;
    assign virtual_addr = pc;
    assign instr      = mem_in_instr;
    assign mem_addr   = result;

    //内部控制逻辑

    always@(*)begin
        in_src_a = 0;
        in_src_b = 0;
        mem_write_data = 0;
        jump_pc  = 0;
        sext_offset = 0;
        wr_data  = 0;

    //立即数判断逻辑(还有一些命令逻辑)
    if(alu_src==1'b0)//值得注意的是这个模块是用来判断立即数是否进入ALU的，如果立即数用在了别的地方，要是用别的逻辑。
    begin
        in_src_a = src_a;
        in_src_b = src_b;
    end
    else
    begin
        case(immwho)
        `UimmI:
        begin
            in_src_a = src_a;
            in_src_b = immI;
        end
        `UimmS:
        begin
            in_src_a = src_a;
            in_src_b = immS;
            mem_write_data= src_b;

        end
        `UimmB:
        begin
            in_src_a = src_a;
            in_src_b = immB<<1;
        end
        `UimmU:
        begin
            if(opcode==7'b0110111)
            begin
               in_src_a = immU;
               in_src_b = 32'd12;
            end
            if(opcode==7'b0010111)
            begin
                in_src_a = immU;
                in_src_b = pc;
            end
            if(opcode==7'b1101111)
            begin
                in_src_a = pc;
                in_src_b = immJ;
                jump_pc  = result;
            end
            if(opcode==7'b1100111)
            begin
                if(func3==3'b000)
                begin
                    in_src_a = pc;
                    in_src_b = immI;
                    jump_pc  = result&(~32'b1);
                end
            end
            end
        `UimmJ:
        begin
            in_src_a = src_a;
            in_src_b = immJ<<1;
        end

        endcase
    end

    if(b_pc)
    begin
        sext_offset = immB;
        jump_pc  = pc_next;
    end

    //寄存器写入来源逻辑
    if(reg_data_from==1'b0)
    begin
        if(reg_rst==1'b0)
        begin
            if(opcode == 7'b1101111 ? 1 : opcode == 7'b1100111 ? func3 == 3'b000 ? 1 : 0 : 0)
            begin
                wr_data = pc_next;
            end
            else
            begin
                wr_data = result;
            end
        end
        else
        begin
            wr_data = {32{zero}};
        end
    end
    else
    begin
        wr_data = mem_in_data;
    end

    end
endmodule