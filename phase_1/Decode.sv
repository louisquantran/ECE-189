`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2025 03:35:10 PM
// Design Name: 
// Module Name: Decode
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


module Decode(
    input logic clk,
    input logic reset,
    
    input logic [31:0] instr,
    input logic [31:0] PC_in,
    input logic valid_in,
    input logic ready_out,
    
    output logic ready_in,
    output logic valid_out,
    output logic [31:0] PC_out,
    
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output logic [4:0] rd,
    output logic [31:0] imm,
    output logic [2:0] ALUOp,
    output logic [6:0] Opcode
);
    logic [31:0] PC_out_hold;
    logic [4:0] rs1_hold;
    logic [4:0] rs2_hold;
    logic [4:0] rd_hold;
    logic [31:0] imm_hold;
    logic [2:0] ALUOp_hold;
    logic [6:0] Opcode_hold;
    
    logic [4:0] rs1_now;
    logic [4:0] rs2_now;
    logic [4:0] rd_now;
    logic [31:0] imm_now;
    logic [2:0] ALUOp_now;
    logic [6:0] Opcode_now;
        
    ImmGen immgen_dut (
        .instr(instr),
        .imm(imm_now)
    );
    
    always_comb begin
        Opcode_now = instr[6:0];
        // We only support a few instructions, therefore the decoded signals will not fully cover every instruction
        case (Opcode_now) 
            // imm_now is already calculated
            // I-type
            7'b0010011: begin
                rs1_now = instr[19:15];
                rs2_now = 5'b0;
                rd_now = instr[11:7];
                ALUOp_now = 3'b000;
            end
            // LUI
            7'b0110111: begin
                rs1_now = 5'b0;
                rs2_now = 5'b0;
                rd_now = instr[11:7];
                ALUOp_now = 3'b101;
            end
            // R-type
            7'b0110011: begin
                rs1_now = instr[19:15];
                rs2_now = instr[24:20];
                rd_now = instr[11:7];
                ALUOp_now = 3'b001;
            end 
            // L-type
            7'b0000011: begin
                rs1_now = instr[19:15];
                rs2_now = 5'b0;
                rd_now = instr[11:7];
                ALUOp_now = 3'b010;
            end
            // S-type
            7'b0100011: begin
                rs1_now = instr[19:15];
                rs2_now = instr[24:20];
                rd_now = 5'b0;
                ALUOp_now = 3'b011;
            end
            // B-type
            7'b1100011: begin
                rs1_now = instr[19:15];
                rs2_now = instr[24:20];
                rd_now = 5'b0;
                ALUOp_now = 3'b100;
            end
            // J-type
            7'b1100111: begin
                rs1_now = instr[19:15];
                rs2_now = 5'b0;
                rd_now = instr[11:7];
                ALUOp_now = 3'b110;
            end
            // When the instruction is undefined
            default: begin 
                rs1_now = 5'b0;
                rs2_now = 5'b0;
                rd_now = 5'b0;
                ALUOp_now = 3'b0;
            end
        endcase
    end
    
    // Skid buffer part
    logic full;
    
    // Assign output signals accordingly
    assign valid_out = (full) ? 1'b1 : valid_in;
    assign ready_in = (full) ? 1'b0 : ready_out;
    assign rs1 = (full) ? rs1_hold : rs1_now;
    assign rs2 = (full) ? rs2_hold : rs2_now;
    assign rd = (full) ? rd_hold : rd_now;
    assign imm = (full) ? imm_hold : imm_now;
    assign ALUOp = (full) ? ALUOp_hold : ALUOp_now;
    assign Opcode = (full) ? Opcode_hold : Opcode_now;
    assign PC_out = (full) ? PC_out_hold : PC_in;
    
    always_ff @(posedge clk) begin 
        // reset
        if (reset) begin 
            rs1_hold <= 5'b0;
            rs2_hold <= 5'b0;
            rd_hold <= 5'b0;
            imm_hold <= 32'b0;
            ALUOp_hold <= 3'b0;
            Opcode_hold <= 7'b0;
            full <= 1'b0;
            PC_out_hold <= 32'b0;
        end else begin
            // Hold the values when downstream can't take it this cycle
            if (valid_in && !ready_out && !full) begin
                full <= 1'b1;
                
                rs1_hold <= rs1_now;
                rs2_hold <= rs2_now;
                rd_hold <= rd_now;
                imm_hold <= imm_now;
                ALUOp_hold <= ALUOp_now;
                Opcode_hold <= Opcode_now;
                PC_out_hold <= PC_in;
            // Release the values when downstream is ready
            end else if (ready_out && full) begin
                full <= 1'b0;
            end
        end
    end 
endmodule
