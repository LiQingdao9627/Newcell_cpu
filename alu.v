`include "define.v"

module alu(
    input [4:0]  alu_ctrl,
    input [31:0] src_a,
    input [31:0] src_b,
    output reg zero,
    output reg [31:0] result
); 

    always@(*)
    begin
        result = 32'b0;
        zero   = 1'b0;
        case(alu_ctrl)

          `ALU_AND:                   result = src_a & src_b;
          `ALU_OR:                    result = src_a | src_b;
          `ALU_XOR:                   result = src_a ^ src_b;
          `ALU_ADD:                   result = src_a + src_b;
          `ALU_SUB:                   result = src_a - src_b;
          `ALU_COMPARE_BIG_RESULT:    result = (src_a>src_b)?src_a:src_b;
          `ALU_COMPARE_SMA_RESULT:    result = (src_a<src_b)?src_a:src_b;
          `ALU_COMPARE_BIGE_ZERO:     zero   = (src_a>=src_b)?1:0;
          `ALU_COMPARE_SMA_ZERO:      zero   = (src_a<src_b)?1:0;
          `ALU_COMPARE_E_ZERO:        zero   = (src_a==src_b)?1:0;
          `ALU_COMPARE_UNE_ZERO:      zero   = (src_a!=src_b)?1:0;
          `ALU_COMPARE_SMAE_ZERO:     zero   = (src_a<=src_b)?1:0;
          `ALU_COMPARE_BIG_ZERO:      zero   = (src_a>src_b)?1:0;
          `ALU_LOGIC_LEFT_MOVE:       result = src_a<<src_b[4:0];
          `ALU_LOGIC_RIGHT_MOVE:       result = src_a>>src_b[4:0];
          `ALU_ARI_LEFT_MOVE:         result = src_a<<<src_b[4:0];
          `ALU_ARI_RIGHT_MOVE:        result = src_a>>>src_b[4:0];
          `ALU_COMPARE_UNS_SMA_ZERO:  zero   = src_a[31]<src_b[31]?1:src_a[31]>src_b?0:src_a[30:0]<src_b[30:0]?1:0;
          `ALU_COMPARE_UNS_BIGE_ZERO: zero   = src_a[31]>src_b[31]?1:src_a[31]<src_b?0:src_a[30:0]>=src_b[30:0]?1:0;
          `ALU_auipc_LEFT_MOVE_ADD:    result = (src_a<<32'd12) + src_b;
          default:            begin  result = 32'b0;zero<=1'b0;end

        endcase
    end
    

endmodule