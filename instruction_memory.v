//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sajid Hussain
// 
// Create Date: 13.09.2019 17:05:51
// Design Name: 
// Module Name: instruction_memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//    //---------------------------------------------------------------------------
//-- instruction_memory.vhd - Implementation of A Single-Port, 16 x 16-bit
//--                          Instruction Memory.
//-- 
//-- Notes: refer to headers in single_cycle_core.vhd for the supported ISA.
//--
//-- Copyright (C) 2006 
//-- All Rights Reserved. 
//-- Written by Lih Wen Koh (lwkoh@cse.unsw.edu.au) in VHDL
//-- Translated into Verilog by Sajid Hussain (sajid.hussain@unsw.edu.au)
//--
//-- The single-cycle processor core is provided AS IS, with no warranty of 
//-- any kind, express or implied. The user of the program accepts full 
//-- responsibility for the application of the program and the use of any 
//-- results. This work may be downloaded, compiled, executed, copied, and 
//-- modified solely for nonprofit, educational, noncommercial research, and 
//-- noncommercial scholarship purposes provided that this notice in its 
//-- entirety accompanies all copies. Copies of the modified software can be 
//-- delivered to persons who use it solely for nonprofit, educational, 
//-- noncommercial research, and noncommercial scholarship purposes provided 
//-- that this notice in its entirety accompanies all copies.
//--
//---------------------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////

module instruction_memory(
    input reset, 
    input clk, 
    input[3:0] addr_in, 
    output[15:0] insn_out
    );
    
    reg[15:0] insn_array[0:15];
    reg[15:0] insn_out_reg;
    
    assign insn_out = insn_out_reg;
    /*
        n + (n-1) + ... + 2 + 1 = n*(n+1)/2
    */
    always @(posedge clk) begin
        if (reset) begin
        
        /*
            insn_array[0] <= 16'hD010; // show  0($0)
            insn_array[1] <= 16'h0000; // load_switch $6
            insn_array[2] <= 16'h0000; // add   $F, $0, $0 // Start of loop
            insn_array[3] <= 16'h0000; // load  $1, 0($0)
            insn_array[4] <= 16'h0000;// load  $2, 1($0)
            insn_array[5] <= 16'h0000; // add   $F, $F, $1
            insn_array[6] <= 16'h0000; // add   $1, $1, $2
            insn_array[7] <= 16'h0000; // beq   $1, $0, 5
            insn_array[8] <= 16'h8111; // nop
            insn_array[9] <= 16'hF00E; // beq   $0, $0, -5 // Jump to start of loop
            insn_array[10] <= 16'h0000;// nop
            insn_array[11] <= 16'h0000;// nop
            insn_array[12] <= 16'h0000;// nop
            insn_array[13] <= 16'h3012;// store $1, 2($0)
            insn_array[14] <= 16'hF00E;// beq   $0, $0, 15
            insn_array[15] <= 16'h0000;// nop
        */

        /*
            ADD $rs $rt $rd
            $rd <= $rs + $rt
        */
        
            insn_array[0] <= 16'hD010; // $1 <= switches
            insn_array[1] <= 16'h1121; // $1 <= 
            insn_array[2] <= 16'h8121; // 
            insn_array[3] <= 16'h81FF; // .
            insn_array[4] <= 16'hF014; // .
            insn_array[5] <= 16'h0000; // .
            insn_array[6] <= 16'hF00B; // .
            insn_array[7] <= 16'h0000; // 
            insn_array[8] <= 16'h0000; // 
            insn_array[9] <= 16'h0000; // 
            insn_array[10] <= 16'h0000;// .
            insn_array[11] <= 16'h0000;//
            insn_array[12] <= 16'h3012;// .
            insn_array[13] <= 16'hF00E;// 
            insn_array[14] <= 16'h0000;// beq   $0, $0, 15
            insn_array[15] <= 16'h0000;// .

            insn_out_reg <= 0;
        end else begin
            insn_out_reg <= insn_array[addr_in];
        end
    end
endmodule
















