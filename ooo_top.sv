`timescale 1ns/1ps
import types_pkg::*;

module ooo_top (
  input  logic clk,
  input  logic reset,
  input  logic exec_ready   // downstream of Decode / Execute
);

  // PC generator
  logic [31:0] pc_reg;

  // Fetch 
  fetch_data fetch_out;
  logic      v_fetch;
  logic      r_to_fetch;  

  fetch u_fetch (
    .pc_in     (pc_reg),
    .ready_out (r_to_fetch),
    .valid_out (v_fetch),
    .data_out  (fetch_out)
  ); 

  // Skid buffer from Fetch to Decode
  fetch_data sb_f_out;
  logic      v_sb;
  logic      r_from_decode; 

  skid_buffer #(.T(fetch_data)) u_fb (
    .clk       (clk),
    .reset     (reset),
    .valid_in  (v_fetch & ~reset),
    .data_in   (fetch_out),
    .ready_in  (r_to_fetch),
    .ready_out (r_from_decode),
    .valid_out (v_sb),
    .data_out  (sb_f_out)
  );

  // Decode 
  decode_data decode_out;
  logic       v_decode;

  // Post-Decode skid buffer 
  decode_data sb_d_out;
  logic       r_sb_to_decode;  
  logic       v_dsb;

  decode u_decode (
    // Upstream
    .instr     (sb_f_out.instr),
    .pc_in     (sb_f_out.pc),
    .valid_in  (v_sb),
    .ready_in  (r_from_decode),

    // Downstream to post-Decode skid
    .ready_out (r_sb_to_decode),
    .valid_out (v_decode),
    .data_out  (decode_out)
  );

  // Skid buffer from Decode to Testbench 
  skid_buffer #(.T(decode_data)) u_db (
    .clk       (clk),
    .reset     (reset),
    // Upstream 
    .valid_in  (v_decode),
    .data_in   (decode_out),
    .ready_in  (r_sb_to_decode),
    // Downstream 
    .ready_out (exec_ready),
    .valid_out (v_dsb),
    .data_out  (sb_d_out)
  );

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      pc_reg <= 32'h0000_0000;
    end else if (v_sb && r_from_decode) begin
      // For now, PC + 4, we will add PC + offset in the future
      pc_reg <= sb_f_out.pc + 32'd4;
    end
  end

endmodule
