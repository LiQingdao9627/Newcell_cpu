`include "define.v"

module pc(
    input clk,
    input rst,
    input jump,
    input [31:0] sext_offset,
    input zero,
    input [2:0] control_status,
    input [31:0] jump_pc,//这里的虚实地址映射采用相等的算法，等到后期拓展了TLB之后会修正虚实地址的映射。
    output reg [31:0] pc,
    output [31:0] pc_next
);
    wire [31:0] branch_pc;

    assign pc_next = pc + 32'h4;
    assign branch_pc = pc+sext_offset;

    always@(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            pc <= 32'h0;
        end
        else
        begin
            if(control_status==`IF)
            begin
             if(jump)
              begin
                  if(zero)
                  begin
                       pc <= branch_pc;
                   end
                  else
                  begin
                      pc<=jump_pc;
                   end
               end
               else
               begin
                  pc<=pc_next;
              end
             end
        end
    end
endmodule
