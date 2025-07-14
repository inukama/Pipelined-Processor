//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.09.2019 15:31:52
// Design Name: 
// Module Name: single_cycle_core
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
// 
//////////////////////////////////////////////////////////////////////////////////

//---------------------------------------------------------------------------
//-- single_cycle_core.vhd - A Single-Cycle Processor Implementation 
//-- adapted from the VHDL model developed by Lih Wen Koh with the infromation as copied below.
//--
//-- Notes : 
//--
//-- See single_cycle_core.pdf for the block diagram of this 
//-- single cycle processor core.
//--
//-- Instruction Set Architecture (ISA) for the single-cycle-core:
//--   Each instruction is 16-bit wide, with four 4-bit fields.
//--
//--     noop      
//--        # no operation or to signal end of program
//--        # format:  | opcode = 0 |  0   |  0   |   0    | 
//--
//--     load  rt, rs, offset     
//--        # load data at memory location (rs + offset) into rt
//--        # format:  | opcode = 1 |  rs  |  rt  | offset |
//--
//--     store rt, rs, offset
//--        # store data rt into memory location (rs + offset)
//--        # format:  | opcode = 3 |  rs  |  rt  | offset |
//--
//--     add   rd, rs, rt
//--        # rd <- rs + rt
//--        # format:  | opcode = 8 |  rs  |  rt  |   rd   |
//--
//--
//-- Copyright (C) 2006 by Lih Wen Koh (lwkoh@cse.unsw.edu.au)
//-- All Rights Reserved. 
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



// Custom instructions
 
//--     show
//--        # $15 <- offset($rs) 
//--        # format:  | opcode = D |  rs  |   X  |  offset  |

//--     load_switch rs
//--        # rt <- switches
//--        # format:  | opcode = 8 |  X  |  rt  |  X  |

module cpu_toplevel(input m_clk, input btnC, input reset, input[15:0] switches, output[15:0] led);  
    button_debouncer #(.DEBOUNCE_TIMEOUT(5_000_000)) add_debouncer(m_clk, btnC, rst, clk);
    single_cycle_core_v single_cycle_core_inst(.clk(clk), .reset(reset), .switches(switches), .led(led));
endmodule


module single_cycle_core_v(input clk, input reset, input[15:0] switches, output [15:0] led);   
    //////////////////////////////////////////////////////
    // Instruction Fetch Stage (IF)
    //////////////////////////////////////////////////////
    
    // PC signals
    wire[3:0] sig_next_pc;
    wire[3:0] sig_next_pc_branch;
    wire[3:0] sig_next_pc_normal;
    wire[3:0] sig_curr_pc;
    
    // Next PC signals
    wire[3:0] sig_one_4b = "0001";
    wire sig_pc_carry_out_normal;
    wire sig_pc_carry_out_branch;
    
    // PC branch check signals
    wire sig_a_gt_b;
    wire sig_b_gt_a;
    wire sig_a_eq_b;
    wire sig_branch_valid;
    
    
    // Instruction
    wire[15:0] sig_insn;
    
    
    adder_4b next_PC_normal(
        .src_a(sig_curr_pc),
        .src_b(sig_one_4b),
        .sum(sig_next_pc_normal), // sig_next_pc_normal
        .carry_out(sig_pc_carry_out_normal) // sig_pc_carry_out_normal
    );
    
    adder_4b next_PC_branch(
        .src_a(sig_curr_pc),
        .src_b(sig_sign_extended_offset),
        .sum(sig_next_pc_branch), 
        .carry_out(sig_pc_carry_out_branch) // sig_pc_carry_out_branch
    );
    
    // Branching logic
    comparator_16b branch_sel(
        .src_a(sig_read_data_a), 
        .src_b(sig_read_data_b), 
        .a(sig_a_gt_b),
        .b(sig_b_gt_a),
        .eq(sig_a_eq_b)
    );
    
    assign sig_branch_valid = sig_a_eq_b && sig_branch;
    
    mux_2to1_4b mux_PC(
        .mux_select(sig_branch_valid), // sig_branch
        .data_a(sig_next_pc_normal), 
        .data_b(sig_next_pc_branch),
        .data_out(sig_next_pc)
    );
    
    program_counter PC(
        .clk(clk),
        .reset(reset),
        .addr_in(sig_next_pc),
        .addr_out(sig_curr_pc)
    );
    
    instruction_memory ins_mem(
        .clk(clk),
        .reset(reset),
        .addr_in(sig_curr_pc),
        .insn_out(sig_insn)
    );
    
    //////////////////////////////////////////////////////
    //  Instruction Decode Stage (ID)
    //////////////////////////////////////////////////////
    
    // Destination Register
    wire sig_reg_dst;
    wire[3:0] sig_write_register;
    wire[3:0] sig_write_register_normal;
    wire[3:0] sig_write_register_show = 4'b1111;
    wire sig_reg_write; 
    wire sig_show;
    
    // Register file signals
    wire sig_mem_write;
    wire sig_mem_to_reg;
    wire[15:0] sig_write_data;
    wire[15:0] sig_read_data_a;
    wire[15:0] sig_read_data_b;
    
    wire[15:0] sig_sign_extended_offset;
    
    sign_extend_4to16 sign_extend(
        .data_in(sig_insn[3:0]),
        .data_out(sig_sign_extended_offset)
    );
    
    // When is register B used as the write destination vs register C?
    mux_2to1_4b mux_reg_dst(
        .mux_select(sig_reg_dst),
        .data_a(sig_insn[7:4]),
        .data_b(sig_insn[3:0]),
        .data_out(sig_write_register_normal)   
    );
    
    mux_2to1_4b mux_show_write_reg(
        .mux_select(sig_show),
        .data_a(sig_write_register_normal),
        .data_b(sig_write_register_show),
        .data_out(sig_write_register)
    );
    
    register_file register_file_inst(
        .reset(reset),
        .clk(clk),
        .read_register_a(sig_insn[11:8]),
        .read_register_b(sig_insn[7:4]),
        .write_enable(sig_reg_write),
        .write_register(sig_write_register), 
        .write_data(sig_write_data),
        .read_data_a(sig_read_data_a),
        .read_data_b(sig_read_data_b),
        .show_reg(led)
    );
    
    //////////////////////////////////////////////////////
    //  Execute Stage (EX)
    //////////////////////////////////////////////////////
    
    // ALU Signals
    wire sig_alu_src;
    wire[15:0] sig_alu_src_b;
    wire[15:0] sig_alu_result; 
    wire sig_alu_carry_out;
    
    // Immediate value or register B?
    mux_2to1_16b mux_alu_src(
        .mux_select(sig_alu_src),
        .data_a(sig_read_data_b),
        .data_b(sig_sign_extended_offset),
        .data_out(sig_alu_src_b)
    );
    
    // Perform operations
    adder_16b ALU(
        .src_a(sig_read_data_a),
        .src_b(sig_alu_src_b),
        .sum(sig_alu_result),
        .carry_out(sig_alu_carry_out)
    );
    
    //////////////////////////////////////////////////////
    //  Memory Access Stage (MEM)
    //////////////////////////////////////////////////////
    
    wire[15:0] sig_data_mem_out;
    
    // Read or write from memory
    data_memory data_mem(
        .reset(reset),
        .clk(clk),
        .write_enable(sig_mem_write),
        .write_data(sig_read_data_b),
        .addr_in(sig_alu_result[3:0]),
        .data_out(sig_data_mem_out)
    );
    
    //////////////////////////////////////////////////////
    //  Writeback Stage (WB)
    //////////////////////////////////////////////////////
    
    wire sig_switch_input;
    wire [15:0] sig_write_data_intermediate;
    
    // Are we writing from the ALU or from data memory?
    mux_2to1_16b mux_alu_mem_intermediate(
        .mux_select(sig_mem_to_reg),
        .data_a(sig_alu_result),
        .data_b(sig_data_mem_out),
        .data_out(sig_write_data_intermediate)
    );
    
    // Are we writing from ALU/data mem or from the switches?
    mux_2to1_16b mux_intermediate_switch_reg(
        .mux_select(sig_switch_input),
        .data_a(sig_write_data_intermediate),
        .data_b(switches),
        .data_out(sig_write_data)
    );
    
    
    
    
    //////////////////////////////////////////////////////
    //  Control Unit
    //////////////////////////////////////////////////////
    
    control_unit ctrl_unit(
        .opcode(sig_insn[15:12]),
        .reg_dst(sig_reg_dst),
        .reg_write(sig_reg_write),
        .alu_src(sig_alu_src),
        .mem_write(sig_mem_write),
        .mem_to_reg(sig_mem_to_reg),
        .branch(sig_branch),
        .show(sig_show),
        .switch_input(sig_switch_input)
    );
    
endmodule



module button_debouncer
#(
    parameter DEBOUNCE_TIMEOUT = 5_000_000
)(
    input clk,
    input btn,
    input rst,
    output reg btn_debounced
);
    reg [31:0] debounce_timer;
    reg [31:0] debounce_timer_next;
    
    reg btn_debounced_next;
    
    // Clock logic
    always@ (posedge clk) begin
        if (rst) begin
            debounce_timer <= 0;
            btn_debounced <= 0;
        end else begin
            debounce_timer <= debounce_timer_next;
            btn_debounced <= btn_debounced_next;
        end
    end
    
    // Next State Logic
    always@* begin
        if (rst || btn == 0) begin
            debounce_timer_next = 0;
            btn_debounced_next = 0;
        end else if (debounce_timer == DEBOUNCE_TIMEOUT) begin
            debounce_timer_next = debounce_timer;
            btn_debounced_next = 1;
        end else begin
            debounce_timer_next = debounce_timer + 1;
            btn_debounced_next = 0; 
        end
    end
endmodule
// Tested
