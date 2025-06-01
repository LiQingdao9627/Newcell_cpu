module instr_mem(
    input  [31:0] instr_addr,
    output [31:0] instr
);
    reg [7:0] mem [1023:0];

    `ifdef SIMULATION
    initial begin
        $readmemb("instr.hex",mem);
    end
    `endif

    assign instr = {mem[instr_addr[9:0]+3],mem[instr_addr[9:0]+2],mem[instr_addr[9:0]+1],mem[instr_addr[9:0]]};


endmodule