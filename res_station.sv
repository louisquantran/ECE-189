`timescale 1ns / 1ps
import types_pkg::*;

module res_station(
    input clk,
    input reset,
    
    // from rename
    input rename_data r_data,
    input logic [1:0] fu,
    input logic [6:0] Opcode,
    
    // from fu
    input logic mispredict,
    input logic [4:0] mispredict_tag,
    input logic [7:0] ps_in,
    input logic ps_ready,
    
    // from ROB
    input logic [4:0] rob_index,
    
    // from Dispatch
    input logic [1:0] fu_in,
    input logic fu_ready,
    input logic di_en,
    
    input logic preg_rtable[0:127],
    input logic fu_rtable[0:2],
    
    // Output
    output logic fu_dispatched,
    output logic full,
    output rs_data data_out
);
    rs_data rs_table [0:7];
    
    logic [7:0] valid_bits;
    logic [7:0] ready_bits; 
    assign valid_bits = {rs_table[7].valid, rs_table[6].valid, rs_table[5].valid, 
                    rs_table[4].valid, rs_table[3].valid, rs_table[2].valid, 
                    rs_table[1].valid, rs_table[0].valid};
    assign ready_bits = {rs_table[7].ready, rs_table[6].ready, rs_table[5].ready, 
                    rs_table[4].ready, rs_table[3].ready, rs_table[2].ready, 
                    rs_table[1].ready, rs_table[0].ready};
    logic [4:0] in_idx;
    logic [4:0] out_idx;
    assign data_out = rs_table[out_idx];
    logic in_valid;
    logic out_ready;
    always_comb begin
        in_valid = 1'b0;
        out_ready = 1'b0;
        for (int i = 7; i >= 0; i--) begin
            if (!in_valid && valid_bits[i] == 0) begin
                in_idx = i;
                in_valid = 1'b1;
            end
            if (!out_ready && ready_bits[7-i] == 1) begin
                out_idx = i;
                out_ready = 1'b1;
            end
            if (in_valid && out_ready) begin
                break;
            end
        end
    end
        
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (logic [2:0] i = 0; i <= 7; i++) begin
                rs_table[i] <= '0;
            end
            in_idx <= '0;
            out_idx <= '0; 
            valid_bits <= '0;
        end else begin
            if (ps_ready) begin
                for (logic [3:0] i = 0; i < 8; i++) begin
                    if (rs_table[i].valid) begin
                        if (!rs_table[i].ps1_ready && rs_table[i].ps1 == ps_in) begin
                            rs_table[i].ps1_ready <= 1'b1;
                        end 
                        if (!rs_table[i].ps2_ready && rs_table[i].ps2 == ps_in) begin
                            rs_table[i].ps2_ready <= 1'b1;
                        end
                    end
                end
            end
            if (fu_ready) begin
                for (logic [3:0] i = 0; i < 8; i++) begin
                    if (rs_table[i].valid) begin
                        if (!rs_table[i].fu_ready && rs_table[i].fu == fu) begin
                            rs_table[i].fu_ready <= 1'b1; 
                        end 
                    end
                end
            end
            for (logic [3:0] i = 0; i < 8; i++) begin
                if (rs_table[i].valid) begin
                    if (rs_table[i].ps1_ready && rs_table[i].ps2_ready && rs_table[i].fu_ready) begin
                        rs_table[i].ready <= 1'b1;
                    end
                end
            end
            if (out_ready) begin
                rs_table[out_idx] <= '0;
                for (logic [3:0] i = 0; i < 8; i++) begin
                    if (rs_table[i].valid) begin
                        if (rs_table[i].ps1_ready && rs_table[i].ps1 == rs_table[out_idx].pd) begin
                            rs_table[i].ps1_ready <= 1'b0;
                            rs_table[i].ready <= 1'b0;
                        end 
                        if (rs_table[i].ps2_ready && rs_table[i].ps2 == rs_table[out_idx].pd) begin
                            rs_table[i].ps2_ready <= 1'b0;
                        end
                    end
                end
            end
            // Dispatch to RS
            if (in_valid && di_en) begin
                rs_table[in_idx].valid <= 1'b1;
                rs_table[in_idx].Opcode <= Opcode;
                rs_table[in_idx].pd <= r_data.pd_new;
                rs_table[in_idx].ps1 <= r_data.ps1;
                rs_table[in_idx].ps2 <= r_data.ps2;
                rs_table[in_idx].imm <= r_data.imm;
                rs_table[in_idx].rob_index <= rob_index;
                if (preg_rtable[r_data.ps1] && preg_rtable[r_data.ps2] && fu_rtable[fu]) begin
                    rs_table[in_idx].ready <= 1'b1;
                    rs_table[in_idx].ps1_ready <= 1'b1;
                    rs_table[in_idx].ps2_ready <= 1'b1;
                    rs_table[in_idx].fu_ready <= 1'b1;
                end else begin
                    if (preg_rtable[r_data.ps1]) begin
                        rs_table[in_idx].ps1_ready <= 1'b1;
                    end
                    if (preg_rtable[r_data.ps2]) begin
                        rs_table[in_idx].ps2_ready <= 1'b1;
                    end
                    if (fu_rtable[fu]) begin
                        rs_table[in_idx].fu_ready <= 1'b1;
                    end
                end
            end
        end
    end
endmodule
