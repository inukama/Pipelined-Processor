`timescale 1ns / 1ps
module single_cycle_core_Test_Bench();
    reg clk, reset;
    reg [15:0] switches;
    
    wire [15:0] led;

    initial begin
        switches=16'b1000_1100_1110_1111;
        clk=0;
        reset=0;
        #10
        reset=1;
        #8
        reset=0;
    end

    always #2 clk=~clk;


    single_cycle_core_v single_cycle_core_inst(.clk(clk), .reset(reset), .switches(switches), .led(led));
endmodule