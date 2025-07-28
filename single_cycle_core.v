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

module cpu_toplevel(input m_clk, input btnC, input reset, input[15:0] sw, output[15:0] led);  
    button_debouncer #(.DEBOUNCE_TIMEOUT(5_000_000)) add_debouncer(.clk(m_clk), .btn(btnC), .rst(reset), .btn_debounced(clk));
    single_cycle_core_v single_cycle_core_inst(.clk(clk), .reset(reset), .sw(sw), .led(led));
endmodule


module single_cycle_core_v(input clk, input reset, input[15:0] sw, output [15:0] led);   
    //////////////////////////////////////////////////////
    // Instruction Fetch Stage (IF)
    //////////////////////////////////////////////////////
    
    // PC signals
    wire[3:0] sig_next_pc_IF;
    wire[3:0] sig_next_pc_branch_IF;
    wire[3:0] sig_next_pc_normal_IF;
    wire[3:0] sig_curr_pc_IF;
    
    // Next PC signals
    wire[3:0] sig_one_4b = "0001";
    wire[15:0] sig_zero = 16'b0000_0000_0000_0000;
    wire sig_pc_carry_out_normal_IF;
    wire sig_pc_carry_out_branch_IF;
    
    // PC branch check signals
    wire sig_a_gt_b_IF;
    wire sig_b_gt_a_IF;
    wire sig_a_eq_b_IF;
    wire sig_branch_valid_IF;
     
    // Instruction
    wire[15:0] sig_insn_IF;
    
    adder_4b next_PC_normal(
        .src_a(sig_curr_pc_IF),
        .src_b(sig_one_4b),
        .sum(sig_next_pc_normal_IF), // sig_next_pc_normal
        .carry_out(sig_pc_carry_out_normal_IF) // sig_pc_carry_out_normal
    );
    
    adder_4b next_PC_branch(
        .src_a(sig_curr_pc_IF),
        .src_b(sig_insn_ID[3:0]), // No need for sign extension when we only have 4 bits for memory
        .sum(sig_next_pc_branch_IF), 
        .carry_out(sig_pc_carry_out_branch_IF) // sig_pc_carry_out_branch
    );
    
    // Branching logic
    comparator_16b branch_sel(
        .src_a(sig_read_data_a_ID), 
        .src_b(sig_read_data_b_ID), 
        .a(sig_a_gt_b_IF),
        .b(sig_b_gt_a_IF),
        .eq(sig_a_eq_b_IF)
    );
    
    // TODO: THIS IS A BIG ISSUE WHEN WE PIPELINE!!!!!!!!!!!!!!!!!
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // To fix, move the next pc calculate logic to just after the register file
    assign sig_branch_valid_IF = sig_a_eq_b_IF && sig_branch_ID; 
    
    mux_2to1_4b mux_PC(
        .mux_select(sig_branch_valid_IF), // sig_branch
        .data_a(sig_next_pc_normal_IF), 
        .data_b(sig_next_pc_branch_IF),
        .data_out(sig_next_pc_IF)
    );
    
    program_counter PC(
        .clk(clk),
        .reset(reset),
        .hold(sig_pipeline_stall_ID),
        .addr_in(sig_next_pc_IF),
        .addr_out(sig_curr_pc_IF)
    );
    
    instruction_memory ins_mem(
        .clk(clk),
        .reset(reset),
        .addr_in(sig_curr_pc_IF),
        .insn_out(sig_insn_IF)
    );

    wire [15:0] sig_insn_unstalled_ID;
    
    stage_register #(.N(16)) IF_ID(clk, sig_branch_ID, sig_pipeline_stall_ID,
        {
            sig_insn_IF
        },
        {
            sig_insn_unstalled_ID
        }
    );
    
    //////////////////////////////////////////////////////
    //  Instruction Decode Stage (ID)
    //////////////////////////////////////////////////////
        //  Hazard Detection Unit
        //////////////////////////////////////////////////////

    wire sig_pipeline_stall_ID;

    hazard_detection_unit hdu(
        .mem_to_reg_EX(sig_mem_to_reg_EX),
        .mem_write_reg_EX(sig_write_register_EX),
        //.alu_src(sig_alu_src),
        .reg_a_ID(sig_insn_unstalled_ID[11:8]),
        .reg_b_ID(sig_insn_unstalled_ID[7:4]),
        .pipeline_stall(sig_pipeline_stall_ID)
    );

    wire [15:0] sig_insn_ID;

    mux_2to1_16b mux_stall(
        .mux_select(sig_pipeline_stall_ID),
        .data_a(sig_insn_unstalled_ID),
        .data_b(sig_zero),
        .data_out(sig_insn_ID)   
    );

    //////////////////////////////////////////////////////
        //  Control Unit
        //////////////////////////////////////////////////////
    
    wire sig_branch_ID; // Current instruction is a branch
    
    wire sig_alu_src_ID; // ALU input B from register or from immediate value?
     
    wire sig_mem_write_ID; // Data memory write enable 
    wire sig_mem_to_reg_ID; // Write to register from data memory or ALU?
    wire sig_switch_input_ID; // Write to register from data mem/ALU or switches
    
    wire sig_reg_dst_ID; // Use register B or C as destination reg
    wire sig_reg_write_ID; // Register file write enable  
    wire sig_show_ID; // Register file destination register normal or constant 15

    control_unit ctrl_unit(
        .opcode(sig_insn_ID[15:12]),
        .reg_dst(sig_reg_dst_ID),
        .reg_write(sig_reg_write_ID),
        .alu_src(sig_alu_src_ID),
        .mem_write(sig_mem_write_ID),
        .mem_to_reg(sig_mem_to_reg_ID),
        .branch(sig_branch_ID),
        .show(sig_show_ID),
        .switch_input(sig_switch_input_ID)
    );
    
    //////////////////////////////////////////////////////
        //  Register File
        //////////////////////////////////////////////////////
     
    // Destination Register
    wire[3:0] sig_write_register_ID;
    wire[3:0] sig_write_register_normal_ID;
    wire[3:0] sig_write_register_show = 4'b1111;
    
    
    // Register file signals
    wire[15:0] sig_read_data_a_ID;
    wire[15:0] sig_read_data_b_ID;
    
    wire[15:0] sig_sign_extended_offset_ID;
    
    sign_extend_4to16 sign_extend(
        .data_in(sig_insn_ID[3:0]),
        .data_out(sig_sign_extended_offset_ID)
    );
    
    // When is register B used as the write destination vs register C? 
    mux_2to1_4b mux_reg_dst(
        .mux_select(sig_reg_dst_ID),
        .data_a(sig_insn_ID[7:4]),
        .data_b(sig_insn_ID[3:0]),
        .data_out(sig_write_register_normal_ID)   
    );
    
    mux_2to1_4b mux_show_write_reg(
        .mux_select(sig_show_ID),
        .data_a(sig_write_register_normal_ID),
        .data_b(sig_write_register_show),
        .data_out(sig_write_register_ID)
    );
    
    register_file register_file_inst(
        .reset(reset),
        .clk(clk),
        .read_register_a(sig_insn_ID[11:8]),
        .read_register_b(sig_insn_ID[7:4]),
        .write_enable(sig_reg_write_WB), 
        .write_register(sig_write_register_WB), 
        .write_data(sig_write_data_WB), 
        .read_data_a(sig_read_data_a_ID),          
        .read_data_b(sig_read_data_b_ID),
        .show_reg(led)
    );
    
    wire[15:0] sig_insn_EX; // For the forwarding unit
    wire sig_alu_src_EX;
    wire [15:0] sig_read_data_a_EX;
    wire [15:0] sig_read_data_b_EX;
    wire [15:0] sig_sign_extended_offset_EX;
    wire sig_mem_write_EX;
    wire sig_mem_to_reg_EX;
    wire sig_switch_input_EX;
    wire sig_reg_dst_EX;
    wire sig_reg_write_EX;
    wire sig_show_EX;
    wire [3:0] sig_write_register_EX;
            
    stage_register #(.N(16*4 + 7 + 4)) ID_EX(clk, reset, sig_zero[0],
        {
            sig_insn_ID,
            sig_alu_src_ID, sig_read_data_a_ID, sig_read_data_b_ID, sig_sign_extended_offset_ID,
            sig_mem_write_ID,
            sig_mem_to_reg_ID, sig_switch_input_ID, sig_reg_dst, sig_reg_write_ID, sig_show_ID, sig_write_register_ID
        }, {
            sig_insn_EX,
            sig_alu_src_EX, sig_read_data_a_EX, sig_read_data_b_EX, sig_sign_extended_offset_EX,
            sig_mem_write_EX,
            sig_mem_to_reg_EX, sig_switch_input_EX, sig_reg_dst_EX, sig_reg_write_EX, sig_show_EX, sig_write_register_EX
        }
    );
    
    //////////////////////////////////////////////////////
    //  Execute Stage (EX)
    //////////////////////////////////////////////////////
 
    // ALU Signals
    wire[15:0] sig_alu_src_b_EX;
    wire[15:0] sig_alu_result_EX; 
    wire sig_alu_carry_out_EX;

    //////////////////////////////////////////////////////
        //  Forwarding Unit
        //////////////////////////////////////////////////////
    
    wire [15:0] sig_data_a_EX;
    wire [15:0] sig_data_b_EX;

    forwarding_unit forwarder(
        .clk(clk), .reset(reset),

        .reg_a_EX(sig_insn_EX[11:8]), .data_a_EX(sig_read_data_a_EX),
        .reg_b_EX(sig_insn_EX[7:4]), .data_b_EX(sig_read_data_b_EX),

        .result_MEM(sig_alu_result_MEM),
        .write_register_MEM(sig_write_register_MEM),
        .reg_write_MEM(sig_reg_write_MEM),

        .result_WB(sig_write_data_WB),
        .write_register_WB(sig_write_register_WB),
        .reg_write_WB(sig_reg_write_WB),

        .forwarded_data_a_EX(sig_data_a_EX),
        .forwarded_data_b_EX(sig_data_b_EX)
    );
    

    
    // Immediate value or register B?
    mux_2to1_16b mux_alu_src(
        .mux_select(sig_alu_src_EX),
        .data_a(sig_data_b_EX),
        .data_b(sig_sign_extended_offset_EX),
        .data_out(sig_alu_src_b_EX)
    );
    
    //////////////////////////////////////////////////////
        //  Arithmetic Logic Unit
        //////////////////////////////////////////////////////

    // Perform operations
    adder_16b ALU(
        .src_a(sig_data_a_EX),
        .src_b(sig_alu_src_b_EX),
        .sum(sig_alu_result_EX),
        .carry_out(sig_alu_carry_out_EX)
    );
    
    wire [15:0] sig_read_data_b_MEM;
    wire [15:0] sig_alu_result_MEM;
    wire sig_mem_write_MEM;
    wire sig_mem_to_reg_MEM;
    wire sig_switch_input_MEM;
    wire sig_reg_dst_MEM;
    wire sig_reg_write_MEM;
    wire sig_show_MEM;
    wire [3:0] sig_write_register_MEM;
    
    stage_register #(.N(1 + 2*16 + 5 + 4)) EX_MEM(clk, reset, sig_zero[0],
        {
            sig_mem_write_EX, sig_alu_result_EX, sig_read_data_b_EX,
            sig_mem_to_reg_EX, sig_switch_input_EX, sig_reg_dst_EX, sig_reg_write_EX, sig_show_EX, sig_write_register_EX
        }, {
            sig_mem_write_MEM, sig_alu_result_MEM, sig_read_data_b_MEM,
            sig_mem_to_reg_MEM, sig_switch_input_MEM, sig_reg_dst_MEM, sig_reg_write_MEM, sig_show_MEM, sig_write_register_MEM
        }
    );
    
    
    //////////////////////////////////////////////////////
    //  Memory Access Stage (MEM)
    //////////////////////////////////////////////////////
    
    wire[15:0] sig_data_mem_out_MEM;
    
    // Read or write from memory
    data_memory data_mem(
        .reset(reset),
        .clk(clk),
        .write_enable(sig_mem_write_MEM),
        .write_data(sig_read_data_b_MEM),
        .addr_in(sig_alu_result_MEM[3:0]),
        .data_out(sig_data_mem_out_MEM)
    );
    
    wire [15:0] sig_data_mem_out_WB;
    wire [15:0] sig_alu_result_WB;
    wire sig_mem_to_reg_WB;
    wire sig_switch_input_WB;
    wire sig_reg_dst_WB;
    wire sig_reg_write_WB;
    wire sig_show_WB;
    wire [3:0] sig_write_register_WB;
    
    stage_register #(.N(5 + 2*16 + 4)) MEM_WB(clk, reset, sig_zero[0],
        {
            sig_mem_to_reg_MEM, sig_switch_input_MEM, sig_reg_dst_MEM, sig_reg_write_MEM, sig_show_MEM,
            sig_data_mem_out_MEM, sig_alu_result_MEM, sig_write_register_MEM
        }, {
            sig_mem_to_reg_WB, sig_switch_input_WB, sig_reg_dst_WB, sig_reg_write_WB, sig_show_WB,
            sig_data_mem_out_WB, sig_alu_result_WB, sig_write_register_WB
        }
    );
    
    //////////////////////////////////////////////////////
    //  Writeback Stage (WB)
    //////////////////////////////////////////////////////

    wire[15:0] sig_write_data_WB;
    wire [15:0] sig_write_data_intermediate_WB;
    
    // Are we writing from the ALU or from data memory?
    mux_2to1_16b mux_alu_mem_intermediate(
        .mux_select(sig_mem_to_reg_WB),
        .data_a(sig_alu_result_WB),
        .data_b(sig_data_mem_out_WB),
        .data_out(sig_write_data_intermediate_WB) // TODO: Changed sig_write_data_intermediate -> sig_write_data
    );
    
    // Are we writing from ALU/data mem or from the switches?
    mux_2to1_16b mux_intermediate_switch_reg(
        .mux_select(sig_switch_input_WB),
        .data_a(sig_write_data_intermediate_WB),
        .data_b(sw),
        .data_out(sig_write_data_WB)
    );    
endmodule




module forwarding_unit (
    input clk, input reset,

    input [3:0] reg_a_EX,
    input [15:0] data_a_EX,
    input [3:0] reg_b_EX,
    input [15:0] data_b_EX,

    input [15:0] result_MEM,
    input [3:0] write_register_MEM,
    input reg_write_MEM,

    input [15:0] result_WB,
    input [3:0] write_register_WB,
    input reg_write_WB,

    output reg [15:0] forwarded_data_a_EX,
    output reg [15:0] forwarded_data_b_EX
);
    always@* begin
        forwarded_data_a_EX = data_a_EX;
        forwarded_data_b_EX = data_b_EX;

        if (reg_a_EX != 0) begin
            if (reg_write_MEM && write_register_MEM == reg_a_EX) begin
                forwarded_data_a_EX = result_MEM;
            end else if (reg_write_WB && write_register_WB == reg_a_EX) begin
                forwarded_data_a_EX = result_WB;
            end
        end

        if (reg_b_EX != 0) begin
            if (reg_write_MEM && write_register_MEM == reg_b_EX) begin
                forwarded_data_b_EX = result_MEM;
            end else if (reg_write_WB && write_register_WB == reg_b_EX) begin
                forwarded_data_b_EX = result_WB;
            end
        end
    end

    /*
        Forwarding unit:
            - Forwards data from MEM and WB to EX 
        
        Assumptions:
            - If reg_write is set, it will always write to that memory location

        Pseudocode:
            If MEM writes to reg X
                forward to reg a if a == X
            else if WB writes to reg X
                forward to reg a if a == X

            If MEM writes to reg X
                forward to reg b if b == X
            else if WB writes to reg X
                forward to reg b if b == X
    */
endmodule


module hazard_detection_unit(
    input mem_to_reg_EX,
    //input alu_src,
    input [3:0] mem_write_reg_EX, // 
    input [3:0] reg_a_ID,
    input [3:0] reg_b_ID,
    output pipeline_stall
); 
    assign pipeline_stall = mem_to_reg_EX & (mem_write_reg_EX == reg_a_ID | mem_write_reg_EX == reg_b_ID);
endmodule




module stage_register
    #(parameter N=16) (
        input clk,
        input reset,
        input hold,
        input [N-1:0] data_next,
        output reg [N-1:0] data
    );
    
    always@(posedge clk) begin
        if (reset) begin
            data <= 0;
        end else begin
            data <= hold ? data : data_next;
        end
    end
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
