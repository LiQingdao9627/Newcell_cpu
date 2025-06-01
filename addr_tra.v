//这是一个虚实地址转换器，它负责将虚拟地址转换为真实地址。由于我们还没有加入虚拟存储器，因此这里的转换暂时使用直接替换的算法。

module addr_tra(
    input [31:0] virtual_addr,
    output [31:0] real_addr
);
    assign real_addr = virtual_addr;

endmodule