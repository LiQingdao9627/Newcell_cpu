`include "define.v"

module Newcell_cpu_core(
    input clk,
    input rst,
    input [31:0] mem_in_data,
    input [31:0] mem_in_instr,//好不容易读进来的指令

    output [31:0] instr_addr,
    output reg [31:0] out_mem_addr,
    output reg [1:0] out_size,
    output reg out_sign_ext,
    output reg out_wr_en,
    output reg out_rd_en,
    output reg [31:0] out_mem_write_data);//这是一个CPU核，要和外界的存储器交互的…(我终于开始写注释了)

    //为模块例化准备信号的部分

    //存储器交互的流水中间信号
    wire [31:0] mem_addr;
    wire [1:0] size;
    wire sign_ext;
    wire wr_en;
    wire rd_en;
    reg [31:0] mem_write_data;


    //这里是PC的信号~
    wire jump;
    reg [31:0] jump_pc;
    wire [31:0] pc;//介个是用来读指令的地址~
    wire [31:0] pc_next;
    reg [31:0] sext_offset;

    //这里是指令翻译器的信号~
    reg [31:0] instr;
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
    reg reg_wr_en;
    wire reg_data_from;
    wire reg_rst;
    wire b_pc;
    wire shamt;
    //控制部分用到的流水中间信号
    reg [6:0] in_opcode;
    reg [2:0] in_func3;
    reg [4:0] in_rs1;
    reg [4:0] in_rs2;
    reg [6:0] in_func7;
    reg [31:0] in_immI;
    reg [31:0] in_immS;
    reg [31:0] in_immB;
    reg [31:0] in_immU;
    reg [31:0] in_immJ;
    reg [31:0] in_pc_next;
    reg [31:0] in_pc;


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

    //流水缓存信号

    //写后读信号

    reg WAB_pause;
    wire WAB_reg_wr_en;

    //IF

    reg [31:0] IF_instr;
    reg [31:0] IF_pc_next;
    reg IF_E;
    reg [31:0] IF_pc;

    //ID

    reg [6:0] ID_opcode;
    reg [4:0] ID_rd;
    reg [2:0] ID_func3;
    reg [4:0] ID_rs1;
    reg [4:0] ID_rs2;
    reg [6:0] ID_func7;
    reg [31:0] ID_immI;
    reg [31:0] ID_immS;
    reg [31:0] ID_immB;
    reg [31:0] ID_immU;
    reg [31:0] ID_immJ;
    reg ID_E;
    reg [31:0] ID_pc_next;
    reg [31:0] ID_pc;

    //EX

    reg EX_b_pc;
    reg EX_reg_wr_en;
    reg EX_reg_data_from;
    reg EX_jump;
    reg EX_reg_rst;
    reg EX_sign_ext;
    reg EX_wr_en;
    reg [1:0] EX_size;
    reg EX_rd_en;
    reg [31:0] EX_mem_write_data;
    reg [31:0] EX_result;
    reg [31:0] EX_jump_pc;
    reg [31:0] EX_sext_offset;
    reg [31:0] EX_mem_addr;
    reg EX_zero;
    reg [31:0] EX_pc_next;
    reg [4:0] EX_rd;
    reg [6:0] EX_opcode;
    reg [2:0] EX_func3;
    reg EX_E;
    reg in_alu_src;

    //MEM

    reg MEM_E;
    reg [4:0] MEM_rd;
    reg [31:0] MEM_pc_next;
    reg MEM_b_pc;
    reg MEM_reg_wr_en;
    reg MEM_reg_data_from;
    reg MEM_jump;
    reg MEM_reg_rst;
    reg [31:0] MEM_result;
    reg [31:0] MEM_jump_pc;
    reg [31:0] MEM_sext_offset;
    reg MEM_zero;
    reg [31:0] MEM_mem_in_data;
    reg [6:0] MEM_opcode;
    reg [2:0] MEM_func3;

    //WB

    reg WB_E;
    reg [4:0] WB_rd;
    reg [31:0] WB_pc_next;
    reg WB_b_pc;
    reg WB_reg_wr_en;
    reg WB_reg_data_from;
    reg WB_jump;
    reg WB_reg_rst;
    reg [31:0] WB_result;
    reg [31:0] WB_jump_pc;
    reg [31:0] WB_sext_offset;
    reg WB_zero;
    reg [31:0] WB_mem_in_data;
    reg [6:0] WB_opcode;
    reg [2:0] WB_func3;
    





    //模块例化的部分
    pc pc_temp(
        .clk(clk),
        .rst(rst),
        .jump(WB_jump),
        .jump_pc(WB_jump_pc),
        .sext_offset(WB_sext_offset),
        .zero(WB_zero),
        .WAB_pause(WAB_pause),
        .pc(pc),
        .pc_next(pc_next));

    instr_tra instr_tra_temp(
        .instr(IF_instr),
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
        .opcode(ID_opcode),
        .func3(ID_func3),
        .func7(ID_func7),
        .immI(ID_immI),
        .immS(ID_immS),
        .immB(ID_immB),
        .immU(ID_immU),
        .immJ(ID_immJ),
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
        .in_rs1(in_rs1),
        .in_rs2(in_rs2),
        .rd(WB_rd),
        .wr_data(wr_data),
        .wr_en(WB_reg_wr_en),
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

    assign shamt = ID_rs2[5];
    assign WAB_reg_wr_en = (ID_opcode==7'b0110011) || (ID_opcode==7'b0110111) || (ID_opcode==7'b0010111) || (ID_opcode==7'b1101111) || (ID_opcode==7'b1100111) || (ID_opcode==7'b0000011) || (ID_opcode==7'b0010011 && ((ID_func3==3'b001)?(shamt==1'b0):((ID_func3==3'b101)?(shamt==1'b0):1'b1)));

    //和外界存储器交互的部分

    assign instr_addr = real_addr;
    assign virtual_addr = pc;
    assign mem_addr   = result;

    //内部控制逻辑

    always@(*)begin

    //写后读

    //立即数判断逻辑(还有一些命令逻辑)
    if(in_alu_src==1'b0)//值得注意的是这个模块是用来判断立即数是否进入ALU的，如果立即数用在了别的地方，要是用别的逻辑。
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
            in_src_b = in_immI;
        end
        `UimmS:
        begin
            in_src_a = src_a;
            in_src_b = in_immS;
            mem_write_data= src_b;

        end
        `UimmB:
        begin
            in_src_a = src_a;
            in_src_b = in_immB<<1;
        end
        `UimmU:
        begin
            if(in_opcode==7'b0110111)
            begin
               in_src_a = in_immU;
               in_src_b = 32'd12;
            end
            if(in_opcode==7'b0010111)
            begin
                in_src_a = in_immU;
                in_src_b = in_pc;
            end
            if(in_opcode==7'b1101111)
            begin
                in_src_a = in_pc;
                in_src_b = in_immJ;
                jump_pc  = result;
            end
            if(in_opcode==7'b1100111)
            begin
                if(in_func3==3'b000)
                begin
                    in_src_a = in_pc;
                    in_src_b = in_immI;
                    jump_pc  = result&(~32'b1);
                end
            end
            end
        `UimmJ:
        begin
            in_src_a = src_a;
            in_src_b = in_immJ<<1;
        end

        endcase
    end

    if(b_pc)
    begin
        sext_offset = in_immB;
        jump_pc  = in_pc_next;
    end

    //寄存器写入来源逻辑
    if(WB_reg_data_from==1'b0)
    begin
        if(WB_reg_rst==1'b0)
        begin
            if(WB_opcode == 7'b1101111 ? 1 : WB_opcode == 7'b1100111 ? WB_func3 == 3'b000 ? 1 : 0 : 0)
            begin
                wr_data = WB_pc_next;
            end
            else
            begin
                wr_data = WB_result;
            end
        end
        else
        begin
            wr_data = {32{WB_zero}};
        end
    end
    else
    begin
        wr_data = WB_mem_in_data;
    end
    end

     //流水信号处理

    //IF

    always@(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            IF_E <= 1'b0;
            WAB_pause <= 1'b0;
        end
        else
        begin
        IF_instr <= mem_in_instr;
        IF_pc_next <= pc_next;
        IF_E <= 1'b1;
        IF_pc <= pc;
        end
    end

    //ID

    always@(posedge clk)
    begin
        if(WAB_pause==1'b0)
        begin
          instr <= IF_instr;
          ID_opcode <= opcode;
          ID_rd     <= rd;
          ID_func3  <= func3;
          ID_rs1    <= rs1;
          ID_rs2    <= rs2;
          ID_func7  <= func7;
          ID_immI   <= immI;
          ID_immS   <= immS;
          ID_immB   <= immB;
          ID_immU   <= immU;
          ID_immJ   <= immJ;
          ID_pc_next <= IF_pc_next;
          ID_E <= IF_E;
          ID_pc <= IF_pc;
          if(((((rs1==ID_rd)||(rs2==ID_rd))&&WAB_reg_wr_en)||(((ID_rs1==EX_rd)||(ID_rs2==EX_rd))&&EX_reg_wr_en)||(((ID_rs1==MEM_rd)||(ID_rs2==MEM_rd))&&MEM_reg_wr_en)||(((ID_rs1==WB_rd)||(ID_rs2==WB_rd))&&WB_reg_wr_en))&&(|(rs1||ID_rd)&&(|(rs2||ID_rd))&&(|(ID_rs1||EX_rd))&&(|(ID_rs2||EX_rd))&&(|(ID_rs1||MEM_rd))&&(|(ID_rs2||MEM_rd))&&(|(ID_rs1||WB_rd))&&(|(ID_rs2||WB_rd))))
          begin
            WAB_pause<=1'b1;
          end
        end
        if(WAB_pause==1'b1)
        begin
            WAB_pause<=(((rs1==ID_rd)||(rs2==ID_rd))&&WAB_reg_wr_en)?1'b1:((((ID_rs1==EX_rd)||(ID_rs2==EX_rd))&&EX_reg_wr_en)?1'b1:(((ID_rs1==MEM_rd)||(ID_rs2==MEM_rd))&&MEM_reg_wr_en)?1'b1:(((ID_rs1==WB_rd)||(ID_rs2==WB_rd))&&WB_reg_wr_en));
            ID_E <= 1'b0;
        end
    end

    //EX

    always@(posedge clk)
    begin
        EX_E <= ID_E;
        if(ID_E==1'b1)
        begin
        EX_b_pc <= b_pc;
        EX_reg_wr_en <= reg_wr_en;
        EX_reg_data_from <= reg_data_from;
        EX_jump <= jump;
        EX_reg_rst <= reg_rst;
        EX_sign_ext <= sign_ext;
        EX_wr_en <= wr_en;
        EX_size <= size;
        EX_rd_en <= rd_en;
        EX_mem_write_data <= mem_write_data;
        EX_result <= result; 
        EX_jump_pc <= jump_pc;
        EX_sext_offset <= sext_offset;
        EX_mem_addr <= mem_addr;
        EX_rd <= ID_rd;
        EX_pc_next <= ID_pc_next;
        EX_opcode <= ID_opcode;
        EX_func3 <= ID_func3;

        in_opcode <= ID_opcode;
        in_func3 <= ID_func3;
        in_pc <= ID_pc;
        in_pc_next <= ID_pc_next;
        in_rs1 <= ID_rs1;
        in_rs2 <= ID_rs2;
        in_func7 <= ID_func7;
        in_immI <= ID_immI;
        in_immS <= ID_immS;
        in_immB <= ID_immB;
        in_immU <= ID_immU;
        in_immJ <= ID_immJ;
        in_alu_src <= alu_src;
        end

    end

    //MEM

    always@(posedge clk)
    begin
        MEM_E <= EX_E;
        if(EX_E==1'b1)
        begin
        MEM_rd <= EX_rd;
        MEM_pc_next <= EX_pc_next;
        MEM_b_pc <= EX_b_pc;
        MEM_reg_wr_en <= EX_reg_wr_en;
        MEM_reg_data_from <= EX_reg_data_from;
        MEM_jump <= EX_jump;
        MEM_reg_rst <= EX_reg_rst;
        MEM_result <= result;
        MEM_jump_pc <= jump_pc;
        MEM_sext_offset <= EX_sext_offset;
        MEM_zero <= EX_zero;
        MEM_opcode <= EX_opcode;
        MEM_func3 <= EX_func3;

        out_sign_ext <= EX_sign_ext;
        out_wr_en <= (MEM_E==1'b1)?EX_wr_en:1'b0;
        out_size <= EX_size;
        out_rd_en <= EX_rd_en;
        out_mem_write_data <= EX_mem_write_data;

        MEM_mem_in_data <= mem_in_data;
        end
    end

    //WB

    always@(posedge clk)
    begin
        WB_E <= MEM_E;
        WB_rd <= MEM_rd;
        WB_pc_next <= MEM_pc_next;
        WB_b_pc <= MEM_b_pc;
        WB_reg_wr_en <= (MEM_E==1'b1)?MEM_reg_wr_en:1'b0;
        WB_reg_data_from <= MEM_reg_data_from;
        WB_jump <= MEM_jump;
        WB_reg_rst <= MEM_reg_rst;
        WB_result <= MEM_result;
        WB_jump_pc <= MEM_jump_pc;
        WB_sext_offset <= MEM_sext_offset;
        WB_zero <= MEM_zero;
        WB_mem_in_data <= mem_in_data;
        WB_opcode <= MEM_opcode;
        WB_func3 <= MEM_func3;
    end

endmodule