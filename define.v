`ifndef RTL_DEF
`define RTL_DEF

//ALU define

`define ALU_AND                   5'b00000
`define ALU_OR                    5'b00001
`define ALU_XOR                   5'b00010
`define ALU_ADD                   5'b00011
`define ALU_COMPARE_BIG_RESULT    5'b00100
`define ALU_COMPARE_SMA_RESULT    5'b00101
`define ALU_COMPARE_BIGE_ZERO     5'b00110
`define ALU_COMPARE_SMA_ZERO      5'b00111
`define ALU_COMPARE_E_ZERO        5'b01000
`define ALU_COMPARE_UNE_ZERO      5'b01001
`define ALU_COMPARE_SMAE_ZERO     5'b01010
`define ALU_COMPARE_BIG_ZERO      5'b01011
`define ALU_LOGIC_LEFT_MOVE       5'b01100
`define ALU_LOGIC_RIGHT_MOVE      5'b01101
`define ALU_ARI_LEFT_MOVE         5'b01110 
`define ALU_ARI_RIGHT_MOVE        5'b01111
`define ALU_COMPARE_UNS_SMA_ZERO  5'b10000
`define ALU_SUB                   5'b10001
`define ALU_auipc_LEFT_MOVE_ADD   5'b10010
`define ALU_COMPARE_UNS_BIGE_ZERO 5'b10011

//mem define

`define byte                    2'b00
`define halfword                2'b01
`define word                    2'b10

//control define
`define UimmI                    3'b000
`define UimmS                    3'b001
`define UimmB                    3'b010
`define UimmU                    3'b011
`define UimmJ                    3'b100 

`define IF                       3'b000
`define ID                       3'b001
`define EX                       3'b010
`define MEM                      3'b011
`define WB                       3'b100

`endif