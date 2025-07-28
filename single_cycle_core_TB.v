`timescale 1ns / 1ps
module single_cycle_core_Test_Bench();
    reg clk, reset;
    reg [15:0] switches;
    
    wire [15:0] led;

    initial begin
        $dumpfile("cpu_testbench.vcd");
        $dumpvars(0);
        switches=5;
        clk=0;
        reset=0;
        #10
        reset=1;
        #8
        reset=0;
        #2000;
        $finish;
    end

    always #2 clk=~clk;


    single_cycle_core_v single_cycle_core_inst(.clk(clk), .reset(reset), .sw(switches), .led(led));
endmodule