`include "define.v"

module mem(//这是同步写异步读
    input wr_en,
    input rd_en,
    input clk,
    input [1:0] size,
    input sign_ext,//1是符号位扩展
    input [31:0] addr,
    input [31:0] in_data,
    output reg [31:0] out_data
);
    
    reg [7:0] mem [0:1023];

    always@(clk)
    begin
        if(wr_en)
        begin
            case(size)

             `byte     : mem[addr[9:0]] <= in_data[7:0];
             `halfword : begin mem[addr[9:0]+1] <= in_data[7:0]; mem[addr[9:0]] <= in_data[15:8]; end
             `word     : begin mem[addr[9:0]+3] <= in_data[7:0]; mem[addr[9:0]+2] <= in_data[15:8]; mem[addr[9:0]+1] <= in_data[23:16]; mem[addr[9:0]] <= in_data[31:24]; end
             default  : ;

            endcase
        end
    end

    always@(*)
    begin
        out_data = 32'b0;
        if(rd_en)
        begin
            if(sign_ext)
            begin
                case(size)

                 `byte     : out_data = {{24{mem[addr[9:0]][7]}},mem[addr[9:0]]};
                 `halfword : out_data = {{16{mem[addr[9:0]+1][7]}},mem[addr[9:0]+1],mem[addr[9:0]]};
                 `word     : out_data = {mem[addr[9:0]+3],mem[addr[9:0]+2],mem[addr[9:0]+1],mem[addr[9:0]]};
                 default  : out_data = 32'b0;

                endcase
            end
            else
            begin
                case(size)

                 `byte     : out_data = {24'b0,mem[addr[9:0]]};
                 `halfword : out_data = {16'b0,mem[addr[9:0]+1],mem[addr[9:0]]};
                 `word     : out_data = {mem[addr[9:0]+3],mem[addr[9:0]+2],mem[addr[9:0]+1],mem[addr[9:0]]};
                 default  : out_data = 32'b0;

                endcase
            end
        end
        else
        begin
            out_data = 32'b0;
        end
    end


endmodule