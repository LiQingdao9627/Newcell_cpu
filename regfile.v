module regfile(
    input clk,//这里设计的是异步读，同步写
    input [4:0] in_rs1,
    input [4:0] in_rs2,
    input [4:0] rd,
    input [31:0] wr_data,
    input wr_en,
    output [31:0] out_rs1,
    output [31:0] out_rs2
);
    reg [31:0] rf[0:31];

    `ifdef SIMULATION
    initial begin
        $readmemh("regfile.hex",rf);
    end
    `endif

    assign out_rs1 = rf[in_rs1];
    assign out_rs2 = rf[in_rs2];

    always@(clk)
    begin
        rf[0] <= 0;
        if(wr_en && rd!=0)
        begin
            rf[rd] <= wr_data;
        end
    end

endmodule