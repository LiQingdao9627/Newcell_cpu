`include "define.v"

module Newcell_top(
    input clk,
    input rst,
    output [31:0] write_data,
    output [31:0] read_data,
    output [31:0] instr_data
);
    //这里是信号部分
   
    //这里是CPU_CORE的信号

    wire [31:0] mem_in_data;
    wire [31:0] mem_in_instr;
    wire [31:0] instr_addr;
    wire [31:0] mem_addr;
    wire [1:0] size;
    wire sign_ext;
    wire wr_en;
    wire rd_en;
    wire [31:0] mem_write_data;
    reg [2:0] control_status;



    //这里是例化部分
    
    //这里是CPU_CORE的例化部分
    Newcell_cpu_core Newcell_cpu_core_temp(
        .clk(clk),
        .rst(rst),
        .mem_in_data(mem_in_data),
        .mem_in_instr(mem_in_instr),
        .instr_addr(instr_addr),
        .mem_addr(mem_addr),
        .sign_ext_reg(sign_ext),
        .wr_en_reg(wr_en),
        .rd_en_reg(rd_en),
        .mem_write_data(mem_write_data),
        .size_reg(size),
        .control_status(control_status)
    );

    //这里是指令存储器的例化部分
    instr_mem instr_mem_temp(
        .instr_addr(instr_addr),
        .instr(mem_in_instr)
    );

    //这里是数据存储器的例化部分
    mem mem_temp(
        .wr_en(wr_en),
        .rd_en(rd_en),
        .clk(clk),
        .size(size),
        .sign_ext(sign_ext),
        .addr(mem_addr),
        .in_data(mem_write_data),
        .out_data(mem_in_data),
        .control_status(control_status)
    );

    //这里是顶层模块的运行逻辑部分

    assign write_data = mem_write_data;
    assign read_data  = mem_in_data;
    assign instr_data = mem_in_instr;



endmodule