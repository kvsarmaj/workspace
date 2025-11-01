//******************************************************************************
// File: prefetch_addr_gen_pipe_stage.sv
// Description: Pipeline stage for prefetch address generator
//              Holds addr_in, any previously generated addresses and currently generated address
//******************************************************************************

`include "prefetch_addr_gen_includes.svh"

module prefetch_addr_gen_pipe_stage
    #(
      parameter  NUM_GEN_ADDR_IN = 1,
      localparam NUM_GEN_ADDR_OUT = NUM_GEN_ADDR_IN + 1;
      )
    (
     input logic      i_clk,
     input logic      i_reset_n,

     input logic      prev_addr_in_valid,
     input mem_loc_t  prev_addr_in_loc,
     input logic      prev_pipe_valid[NUM_GEN_ADDR_IN-1:0],
     input mem_loc_t  prev_pipe_loc[NUM_GEN_ADDR_IN-1:0],

     input logic      curr_pipe_valid,
     input mem_loc_t  curr_pipe_loc,

     output logic     next_addr_in_valid,
     output mem_loc_t next_addr_in_loc,
     output logic     next_pipe_valid[NUM_GEN_ADDR_OUT-1:0],
     output mem_loc_t next_pipe_loc[NUM_GEN_ADDR_OUT-1:0]
     );

    for(genvar k=0;k<NUM_GEN_ADDR_OUT-1;k=k+1)
    begin: g_next_pipe_loc
        always_ff@(posedge i_clk or negedge i_reset_n)
        begin
            if(~i_reset_n)
                next_pipe_valid[k] <= 1'b0;
            else
                next_pipe_valid[k] <= prev_pipe_valid[k];
        end // always_ff@ (posedge i_clk or negedge i_reset_n)
        
        always_ff@(posedge i_clk or negedge i_reset_n)
        begin
            if(~i_reset_n)
                next_pipe_loc[k] <= '{default: '0};
            else
                next_pipe_loc[k] <= next_pipe_loc[k];
        end // always_ff@ (posedge i_clk or negedge i_reset_n)
    end // block: g_next_pipe_loc

    always_ff@(posedge i_clk or negedge i_reset_n)
    begin
        if(~i_reset_n)
            next_pipe_valid[NUM_GEN_ADDR-1] <= 1'b0;
        else
            next_pipe_valid[NUM_GEN_ADDR-1] <= curr_pipe_valid;
    end // always_ff@ (posedge i_clk or negedge i_reset_n)

    always_ff@(posedge i_clk or negedge i_reset_n)
    begin
        if(~i_reset_n)
            next_pipe_loc[NUM_GEN_ADDR-1] <= '{default: '0};
        else
            next_pipe_loc[NUM_GEN_ADDR-1] <= curr_pipe_loc;
    end // always_ff@ (posedge i_clk or negedge i_reset_n)

    always_ff@(posedge i_clk or negdged i_reset_n)
    begin
        if(~i_reset_n)
            next_addr_in_valid <= prev_addr_in_valid;
        else
            next_addr_in_valid <= prev_addr_in_valid;
    end // always@ (posedge i_clk or negdged i_reset_n)

    always_ff@(posedge i_clk or negedge i_reset_n)
    begin
        if(~i_reset_n)
            next_addr_in_loc <= '{default: '0};
        else
            next_addr_in_loc <= prev_addr_in_loc;
    end // always_ff@ (posedge i_clk or negedge i_reset_n)

endmodule // prefetch_addr_gen_pipe_stage

