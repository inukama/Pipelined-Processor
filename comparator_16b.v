

module comparator_16b(
    input[15:0] src_a, 
    input[15:0] src_b, 
    output a,
    output b,
    output eq
);
    assign a = src_a > src_b;
    assign b = src_b > src_a;
    assign eq = ~(a | b);
endmodule