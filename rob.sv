import types_pkg::*;

module rob (
    input  logic clk,
    input  logic reset,
    
    // from rename stage
    input  logic write_en,
    input  logic [4:0] rob_tag_in,
    input  logic [7:0] pd_new_in,
    input  logic [7:0] pd_old_in,
    input logic [31:0] pc_in,
    
    // from FU stage 
    input logic complete_in,
    input logic [4:0] rob_fu,
    input logic mispredict,
    input logic branch,
    
    // upstream
    output logic rob_tag_out,
    output logic valid_retired,
    output logic complete_out,
    output logic full,
    output logic empty
);
    logic advance;
    rob_data rob_table[0:15];
    rob_data re_rob_table[0:15];   
    
    logic [4:0]  w_ptr, r_ptr;      
    logic [4:0]  ctr;            
    
    assign full  = (ctr == 16);
    assign empty = (ctr == 0);
    
    logic do_write;           
    logic do_read;
    
    assign do_read = advance && (ctr!=0);
    assign do_write = write_en;
    assign complete_out = complete_in;
    assign rob_table[rob_fu].complete = complete_in;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            w_ptr    <= '0;
            r_ptr    <= '0;
            ctr      <= '0;
            advance <= '0;
            for (int i = 0; i < 16; i++) begin
                rob_table[i].pd_new = '0;
                rob_table[i].pd_old = '0;
                rob_table[i].pc = '0;
                rob_table[i].complete = '0;
                rob_table[i].rob_tag = '0;
                rob_table[i].valid = '0;
            end
        end else begin
            // inform reservation station an instruction is retired, 
            // also reset that row in the table, advance r_ptr by 1
            if (rob_table[r_ptr].complete) begin
                advance <= 1'b1;
                rob_tag_out <= r_ptr;
                rob_table[r_ptr].pd_new <= '0;
                rob_table[r_ptr].pd_old <= '0;
                rob_table[r_ptr].pc = '0;
                rob_table[r_ptr].complete <= '0;
                rob_table[r_ptr].rob_tag <= '0;
                rob_table[r_ptr].valid <= '0; 
            end else begin
                // don't advance if not retired yet
                advance <= 1'b0;
            end
            if (mispredict) begin
                rob_table <= re_rob_table;
            end
            if (do_write && (ctr == 16) && !do_read) begin
                r_ptr <= (r_ptr + 1) % 16;
            end
            if (do_read) begin
                r_ptr    <= (r_ptr + 1) % 16;
            end
            if (branch) begin
                re_rob_table <= rob_table;
            end
            if (do_write) begin
                rob_table[rob_tag_in].pd_new <= pd_new_in;
                rob_table[rob_tag_in].pd_old <= pd_old_in;
                rob_table[rob_tag_in].pc <= pc_in;
                rob_table[rob_tag_in].complete <= 1'b0;
                rob_table[rob_tag_in].valid <= 1'b1;
                rob_table[rob_tag_in].rob_index <= rob_tag_in;
                w_ptr      <= (w_ptr + 1) % 16;
            end
            
            unique case ({do_write, do_read})
                2'b10: if (ctr < 16) ctr <= ctr + 1'b1;
                2'b01: ctr <= ctr - 1'b1;    
                default: ctr <= ctr;          
            endcase 
        end
    end
endmodule
