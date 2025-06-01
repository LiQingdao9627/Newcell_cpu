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

    always@(clk)
    begin
        reg_wr_en = 1'b0;
        wr_en = 1'b0;
        jump      = 1'b0;
        reg_rst   = 1'b0;
        b_pc      = 1'b0;
        wr_en     = 1'b0;
        rd_en     = 1'b0;
        case(opcode)
          7'b0110011://R型指令？
          begin
            case(func3)
            3'b000: 
            begin
                if(func7==7'b0000000)//R add
                begin
                    alu_ctrl      = `ALU_ADD; 
                    reg_wr_en     = 1'b1;
                    alu_src       = 1'b0;
                    reg_data_from = 1'b0;
                end
                if(func7==7'b0100000)// R sub
                begin
                    alu_ctrl      = `ALU_SUB;
                    reg_wr_en     = 1'b1;
                    alu_src       = 1'b0;
                    reg_data_from = 1'b0;
                end
            end
            3'b001:// R sll
            begin
                alu_ctrl      = `ALU_LOGIC_LEFT_MOVE;
                reg_wr_en     = 1'b1;
                alu_src       = 1'b0;
                reg_data_from = 1'b0;
            end
            3'b010:// R slt
            begin
                alu_ctrl      = `ALU_COMPARE_SMA_ZERO;
                reg_wr_en     = 1'b1;
                alu_src       = 1'b0;
                reg_data_from = 1'b0;
                reg_rst       = 1'b1;
            end
            3'b011:// R sltu
            begin
                alu_ctrl      = `ALU_COMPARE_UNS_SMA_ZERO;
                reg_wr_en     = 1'b1;
                alu_src       = 1'b0;
                reg_data_from = 1'b0;
                reg_rst       = 1'b1;
            end
            3'b100:// R xor
            begin
                alu_ctrl      = `ALU_XOR;
                reg_wr_en     = 1'b1;
                alu_src       = 1'b0;
                reg_data_from = 1'b0;
            end
            3'b101:
            begin
                if(func7==7'b0000000)//R srl
                begin
                    alu_ctrl      = `ALU_LOGIC_RIGHT_MOVE;
                    reg_wr_en     = 1'b1;
                    alu_src       = 1'b0;
                    reg_data_from = 1'b0;
                end
                if(func7==7'b0100000)//R sra
                begin
                    alu_ctrl      = `ALU_ARI_RIGHT_MOVE;
                    reg_wr_en     = 1'b1;
                    alu_src       = 1'b0;
                    reg_data_from = 1'b0;
                end
            end
            3'b110://R or
            begin
                alu_ctrl          = `ALU_OR;
                reg_wr_en         = 1'b1;
                alu_src           = 1'b0;
                reg_data_from     = 1'b0;
            end
            3'b111://R and
            begin
                alu_ctrl          = `ALU_AND;
                reg_wr_en         = 1'b1;
                alu_src           = 1'b0;
                reg_data_from     = 1'b0;
            end

            endcase
          end
          
          7'b0110111: //U lui
          begin
            alu_ctrl              = `ALU_LOGIC_LEFT_MOVE;
            reg_wr_en             = 1'b1;
            alu_src               = 1'b1;
            reg_data_from         = 1'b0;
            immwho                = `UimmU;
          end

          7'b0010111: //U auipc
          begin
            alu_ctrl              = `ALU_auipc_LEFT_MOVE_ADD;
            alu_src               = 1'b1;
            immwho                = `UimmU;
            reg_wr_en             = 1'b1;
            reg_data_from         = 1'b0;
          end

          7'b1101111: //J jal
          begin
            alu_ctrl              = `ALU_ADD;
            alu_src               = 1'b1;
            immwho                = `UimmJ;
            reg_wr_en             = 1'b1;
            reg_data_from         = 1'b0;
            jump                  = 1'b1;
          end

          7'b1100111: //I jalr
          begin
            if(func3 == 3'b000)
            begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmI;
                reg_wr_en         = 1'b1;
                reg_data_from     = 1'b0;
                jump              = 1'b1;
            end
          end

          7'b1100011:
          begin
            case(func3)
              
              3'b000://B beq
              begin
                alu_ctrl          = `ALU_COMPARE_E_ZERO;
                alu_src           = 1'b0;
                jump              = 1'b1;
                b_pc              = 1'b1;
              end

              3'b001://B bne
              begin
                alu_ctrl          = `ALU_COMPARE_UNE_ZERO;
                alu_src           = 1'b0;
                jump              = 1'b1;
                b_pc              = 1'b1;
              end

              3'b100://B blt
              begin
                alu_ctrl          = `ALU_COMPARE_SMA_ZERO;
                alu_src           = 1'b0;
                jump              = 1'b1;
                b_pc              = 1'b1;
              end

              3'b101://B bge
              begin
                alu_ctrl          = `ALU_COMPARE_BIGE_ZERO;
                alu_src           = 1'b0;
                jump              = 1'b1;
                b_pc              = 1'b1;
              end

              3'b110://B bltu
              begin
                alu_ctrl          = `ALU_COMPARE_UNS_SMA_ZERO;
                alu_src           = 1'b0;
                jump              = 1'b1;
                b_pc              = 1'b1;
              end

              3'b111://B bgeu
              begin
                alu_ctrl          = `ALU_COMPARE_UNS_BIGE_ZERO;
                alu_src           = 1'b0;
                jump              = 1'b1;
                b_pc              = 1'b1;
              end

            endcase
          end

          7'b0000011:
          begin
            case(func3)

              3'b000://I lb
              begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmI;
                reg_wr_en         = 1'b1;
                reg_data_from     = 1'b1;
                rd_en             = 1'b1;
                sign_ext          = 1'b1;
                size              = `byte;
              end

              3'b001://I lh
              begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmI;
                reg_wr_en         = 1'b1;
                reg_data_from     = 1'b1;
                rd_en             = 1'b1;
                sign_ext          = 1'b1;
                size              = `halfword;
              end

              3'b010://I lw
              begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmI;
                reg_wr_en         = 1'b1;
                reg_data_from     = 1'b1;
                rd_en             = 1'b1;
                sign_ext          = 1'b1;
                size              = `word;
              end

              3'b100://I lbu
              begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmI;
                reg_wr_en         = 1'b1;
                reg_data_from     = 1'b1;
                rd_en             = 1'b1;
                sign_ext          = 1'b0;
                size              = `byte;
              end

              3'b101://I lhu
              begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmI;
                reg_wr_en         = 1'b1;
                reg_data_from     = 1'b1;
                rd_en             = 1'b1;
                sign_ext          = 1'b0;
                size              = `halfword;
              end

            endcase
          end

          7'b0100011:
          begin
            case(func3)
               
              3'b000://S sb
              begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmS;
                wr_en             = 1'b1;
                size              = `byte;
              end 

              3'b001://S sh
              begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmS;
                wr_en             = 1'b1;
                size              = `halfword;
              end

              3'b010://S sw
              begin
                alu_ctrl          = `ALU_ADD;
                alu_src           = 1'b1;
                immwho            = `UimmS;
                wr_en             = 1'b1;
                size              = `word;
              end

            endcase
          end

          7'b0010011:
          begin
            case(func3)

              3'b000://I addi
              begin
                alu_ctrl         = `ALU_ADD;
                alu_src          = 1'b1;
                immwho           = `UimmI;
                reg_wr_en        = 1'b1;
                reg_data_from    = 1'b0;
              end

              3'b010://I slti
              begin
                alu_ctrl         = `ALU_COMPARE_SMA_ZERO;
                alu_src          = 1'b1;
                immwho           = `UimmI;
                reg_wr_en        = 1'b1;
                reg_data_from    = 1'b0;
                reg_rst          = 1'b1;
              end

              3'b011://I sltiu
              begin
                alu_ctrl         = `ALU_COMPARE_UNS_SMA_ZERO;
                alu_src          = 1'b1;
                immwho           = `UimmI;
                reg_wr_en        = 1'b1;
                reg_data_from    = 1'b0;
                reg_rst          = 1'b1;
              end

              3'b100://I xori
              begin
                alu_ctrl         = `ALU_XOR;
                alu_src          = 1'b1;
                immwho           = `UimmI;
                reg_wr_en        = 1'b1;
                reg_data_from    = 1'b0;
              end

              3'b110://I ori
              begin
                alu_ctrl         = `ALU_OR;
                alu_src          = 1'b1;
                immwho           = `UimmI;
                reg_wr_en        = 1'b1;
                reg_data_from    = 1'b0;
              end

              3'b111://I andi
              begin
                alu_ctrl         = `ALU_AND;
                alu_src          = 1'b1;
                immwho           = `UimmI;
                reg_wr_en        = 1'b1;
                reg_data_from    = 1'b0;
              end

              3'b001://I slli
              begin
                if(~shamt)
                begin
                 alu_ctrl         = `ALU_LOGIC_LEFT_MOVE;
                 alu_src          = 1'b1;
                 immwho           = `UimmI;
                 reg_wr_en        = 1'b1;
                 reg_data_from    = 1'b0;
                end
              end

              3'b101:
              begin
                if(func7==7'b0000000)//I srli
                begin
                 if(~shamt)
                 begin
                   alu_ctrl        = `ALU_LOGIC_RIGHT_MOVE;
                   alu_src         = 1'b1;
                   immwho          = `UimmI;
                   reg_wr_en       = 1'b1;
                   reg_data_from   = 1'b0;
                 end
                end
                if(func7==7'b0100000)//I srai
                begin
                  if(~shamt)
                  begin
                    alu_ctrl       = `ALU_ARI_RIGHT_MOVE;
                    alu_src        = 1'b1;
                    immwho         = `UimmI;
                    reg_wr_en      = 1'b1;
                    reg_data_from  = 1'b0;
                  end
                end
              end

            endcase
          end

        endcase
    end


endmodule