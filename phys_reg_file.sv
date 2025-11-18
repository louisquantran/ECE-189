`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2025 05:54:38 PM
// Design Name: 
// Module Name: phys_reg_file
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


module phys_reg_file(
    input logic clk,
    input logic reset,
    
    // from ROB
    input logic write_en,
    input logic [31:0] data_in,
    input logic [6:0] pd_in,
    
    // from RS
    input logic read_en_alu,
    input logic read_en_b,
    input logic read_en_mem,
    
    input logic [6:0] ps1_in_alu,
    input logic [6:0] ps2_in_alu,
    input logic [6:0] ps1_in_b,
    input logic [6:0] ps2_in_b,
    input logic [6:0] ps1_in_mem, 
    input logic [6:0] ps2_in_mem,
    
    // Output data
    output logic [31:0] ps1_out_alu,
    output logic [31:0] ps2_out_alu,
    output logic [31:0] ps1_out_b,
    output logic [31:0] ps2_out_b,
    output logic [31:0] ps1_out_mem,
    output logic [31:0] ps2_out_mem
);
    logic [31:0] prf [0:127];
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (logic [6:0] i = 0; i < 128; i++) begin
                prf[i] <= '0;
            end
        end else begin
            if (read_en_alu) begin
                ps1_out_alu <= prf[ps1_in_alu];
                ps2_out_alu <= prf[ps2_in_alu];
            end
            if (read_en_b) begin
                ps1_out_b <= prf[ps1_in_b];
                ps2_out_b <= prf[ps2_in_b];
            end
            if (read_en_mem) begin
                ps1_out_mem <= prf[ps1_in_mem];
                ps2_out_mem <= prf[ps2_in_mem];
            end
            if (write_en) begin
                prf[pd_in] <= data_in;
            end
        end
    end
endmodule
