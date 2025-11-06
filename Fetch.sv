`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2025 03:30:11 PM
// Design Name: 
// Module Name: Fetch
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

import types_pkg::*;

module Fetch(
    input logic clk,
    input logic reset,
    
    // Upstrea  
    input logic [31:0] pc_in,
    
    // Downstream
    input logic ready_out,
    output logic valid_out,
    output fetch_data data_out
);
    logic [31:0] pc_icache;
    logic [31:0] instr_icache;
        
    // Call ICache
    ICache ICache_dut (
        .clk(clk),
        .reset(reset),
        .address(pc_icache),
        .instruction(instr_icache)
    );
    
//     Sequential assignments
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out.instr <= 32'b0;
            data_out.pc <= 32'b0;
        end else begin
            pc_icache <= pc_in;
            data_out.pc <= pc_icache;
            data_out.instr <= instr_icache;
            valid_out <= 1'b1;
        end
    end
endmodule