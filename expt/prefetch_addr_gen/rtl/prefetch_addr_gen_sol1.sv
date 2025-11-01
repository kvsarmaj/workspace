//******************************************************************************
// File: prefetch_addr_gen_sol1.sv
// Description: Implement an address generator for adjacent location prefetcher for a 3d memory model
//              Identify adjacent addresses of every input address
//              6 pipeline stages to calculate address 
//              Issue address out for each adjacent address
//******************************************************************************

`include "prefetch_addr_gen_includes.svh"

module prefetch_addr_gen_sol1
    (
     input logic        i_clk,
     input logic        i_reset_n,

     input logic        addr_in_valid,
     input logic [4:0]  addr_in,

     output logic       prefetch_addr_out_valid,
     output logic [4:0] prefetch_addr_out
     );

    parameter bit [4:0] MEM_MODEL[2:0][2:0][2:0] = {{{5'd0,  5'd1,  5'd2 },
                                                     {5'd3,  5'd4,  5'd5 },
                                                     {5'd6,  5'd7,  5'd8 }},
                                                    {{5'd9,  5'd10, 5'd11},
                                                     {5'd12, 5'd13, 5'd14},
                                                     {5'd15, 5'd16, 5'd17}},
                                                    {{5'd18, 5'd19, 5'd20},
                                                     {5'd21, 5'd22, 5'd23},
                                                     {5'd24, 5'd25, 5'd26}}};

    mem_loc_t   addr_in_loc;

    logic       addr_in_adj_lx_minus_1_valid;
    mem_loc_t   addr_in_adj_lx_minus_1;

    logic       pipe_0_addr_in_valid;
    mem_loc_t   pipe_0_addr_in_loc;
    logic       pipe_0_valid;
    mem_loc_t   pipe_0_loc;

    logic       pipe_1_adj_lx_plus_1_valid;
    mem_loc_t   pipe_1_adj_lx_plus_1;

    logic       pipe_1_addr_in_valid;
    mem_loc_t   pipe_1_addr_in_loc;
    logic       pipe_1_valid[1:0];
    mem_loc_t   pipe_1_loc[1:0];

    logic       pipe_2_adj_ly_minus_1_valid;
    mem_loc_t   pipe_2_adj_ly_minus_1;

    logic       pipe_2_addr_in_valid;
    mem_loc_t   pipe_2_addr_in_loc;
    logic       pipe_2_valid[2:0];
    mem_loc_t   pipe_2_loc[2:0];

    logic       pipe_3_adj_ly_plus_1_valid;
    mem_loc_t   pipe_3_adj_ly_plus_1;

    logic       pipe_3_addr_in_valid;
    mem_loc_t   pipe_3_addr_in_loc;
    logic       pipe_3_valid[3:0];
    mem_loc_t   pipe_3_loc[3:0];

    logic       pipe_4_adj_lz_minux_1_valid;
    mem_loc_t   pipe_4_adj_lz_minus_1;

    logic       pipe_4_addr_in_valid;
    mem_loc_t   pipe_4_addr_in_loc;
    logic       pipe_4_valid[4:0];
    mem_loc_t   pipe_4_loc[4:0];

    logic       pipe_5_adj_lz_plus_1_valid;
    mem_loc_t   pipe_5_adj_lz_plus_1;

    logic       pipe_5_valid[5:0];
    mem_loc_t   pipe_5_loc[5:0];
    logic [5:0] pipe_5_valid_l;

    logic       output_fifo_empty;
    logic       output_fifo_push_l;
    logic [5:0] output_fifo_valid_l;
    logic       output_fifo_valid[5:0];
    mem_loc_t   output_fifo_loc[5:0];
    logic [2:0] output_fifo_curr_ptr;
    mem_loc_t   output_fifo_loc_at_curr_ptr;

    //****************************************************************
    // Look locations of address in
    //****************************************************************
    always_comb
    begin
        mem_loc_t = '{default:'0};
        if(addr_in_valid)
        begin
            for(int z=0;z<3;z=z+1)
            begin: l_z_axis_lookup
                for(int y=0;y<3;y=y+1)
                begin: l_y_axis_lookup
                    for(int x=0;x<3;x=x+1)
                    begin: l_x_axis_lookup
                        if(MEM_MODEL[x][y][z] == addr_in)
                        begin
                            addr_in_loc.lx = x;
                            addr_in_loc.lx = y;
                            addr_in_loc.lx = z;
                        end // if (MEM_MODEL[x][y][z] == addr_in)
                    end // block: l_x_axis_lookup
                end // block: l_y_axis_lookup
            end // block: l_z_axis_lookup
        end // if (addr_in_valid)
    end // always_comb
    //****************************************************************

    //****************************************************************
    // lx-1 address generation and pipe 0 stage
    //****************************************************************
    always_comb
    begin
        addr_in_adj_lx_minus_1_valid = 1'b0;
        addr_in_adj_lx_minus_1 = '{default:'0};
        if(addr_in_valid)
        begin
            if(addr_in_loc.lx - 1'b1 >= 0)
            begin
                addr_in_adj_lx_minus_1_valid = 1'b1;
                addr_in_adj_lx_minus_1.lx    = addr_in_loc_lx - 1'b1;
                addr_in_adj_lx_minus_1.ly    = addr_in_lox_ly;
                addr_in_adj_lx_minus_1.lz    = addr_in_lox_lz;
            end // if (addr_in_loc.lx - 1'b1 >= 0)
        end // if (addr_in_valid)
    end // always_comb
    //******************************************************

    //******************************************************
    // Pipeline stage 0
    //******************************************************
    prefetch_addr_gen_pipe_stage
        #(
          // This parameter is set to 1 to avoid compile issues.
          // Address locs going in to stage 0 is 0.
          // We tie off prev_pipe_valid and prev_pipe_loc signals to 0
          .NUM_GEN_ADDR_IN (1)
          )
    u_prefetch_addr_gen_pipe_stage_0
        (
         .i_clk              (i_clk                        ),
         .i_reset_n          (i_reset_n                    ),
         .prev_addr_in_valid (addr_in_valid                ),
         .prev_addr_in_loc   (addr_in                      ),
         .prev_pipe_valid    (1'b0                         ),
         .prev_pipe_loc      ('{default:'0}                ),
         .curr_pipe_valid    (addr_in_adj_lx_minus_1_valid ),
         .curr_pipe_loc      (addr_in_adj_lx_minus_1       ),
         .next_addr_in_valid (pipe_0_addr_in_valid         ),
         .next_addr_in_loc   (pipe_0_addr_inloc            ),
         .next_pipe_valid    (pipe_1_valid                 ),
         .next_pipe_loc      (pipe_1_loc                   )
         );
    //******************************************************

    //****************************************************************

    //****************************************************************
    // lx+1 address generation and pipe 1 stage
    //****************************************************************
    always_comb
    begin
        pipe_1_adj_lx_plus_1_valid = 1'b0;
        pipe_1_adj_lx_plus_1        = '{default:'0};
        if(pipe_0_addr_in_valid)
        begin
            if(pipe_0_addr_in_loc.lx + 1'b1 <= 2)
            begin
                pipe_1_adj_lx_plus_1_valid = 1'b1;
                pipe_1_adj_lx_plus_1.lx    = pipe_0_loc_lx + 1'b1;
                pipe_1_adj_lx_plus_1.ly    = pipe_0_lox_ly;
                pipe_1_adj_lx_plus_1.lz    = pipe_0_lox_lz;
            end // if (pipe_0_addr_in_loc.lx + 1 <= 2)
        end // if (pipe_0_addr_in_valid)
    end // always_comb
    //******************************************************

    //******************************************************
    // Pipeline stage 1
    //******************************************************
    prefetch_addr_gen_pipe_stage
        #(
          .NUM_GEN_ADDR_IN (1)
          )
    u_prefetch_addr_gen_pipe_stage_1
        (
         .i_clk              (i_clk                      ),
         .i_reset_n          (i_reset_n                  ),
         .prev_addr_in_valid (pipe_0_addr_in_valid       ),
         .prev_addr_in_loc   (pipe_0_addr_in             ),
         .prev_pipe_valid    (pipe_0_valid               ),
         .prev_pipe_loc      (pipe_0_loc                 ),
         .curr_pipe_valid    (pipe_1_adj_lx_plus_1_valid ),
         .curr_pipe_loc      (pipe_1_adj_lx_plus_1       ),
         .next_addr_in_valid (pipe_1_addr_in_valid       ),
         .next_addr_in_loc   (pipe_1_addr_in_loc         ),
         .next_pipe_valid    (pipe_1_valid               ),
         .next_pipe_loc      (pipe_1_loc                 )
         );
    //******************************************************

    //****************************************************************

    //****************************************************************
    // ly-1 address generation and pipe 2 stage
    //****************************************************************
    always_comb
    begin
        pipe_2_adj_ly_minus_1_valid = 1'b0;
        pipe_2_adj_ly_minus_1        = '{default:'0};
        if(pipe_1_addr_in_valid)
        begin
            if(pipe_1_addr_in_loc.ly - 1'b1 >= 0)
            begin
                pipe_2_adj_ly_minus_1_valid = 1'b1;
                pipe_2_adj_ly_minus_1.lx    = pipe_1_loc_lx;
                pipe_2_adj_ly_minus_1.ly    = pipe_1_lox_ly - 1'b1;
                pipe_2_adj_ly_minus_1.lz    = pipe_1_lox_lz;
            end // if (pipe_1_addr_in_loc.ly - 1'b1 >= 0)
        end // if (pipe_1_addr_in_valid)
    end // always_comb
    //******************************************************

    //******************************************************
    // Pipeline stage 2
    //******************************************************
    prefetch_addr_gen_pipe_stage
        #(
          .NUM_GEN_ADDR_IN (2)
          )
    u_prefetch_addr_gen_pipe_stage_1
        (
         .i_clk              (i_clk                       ),
         .i_reset_n          (i_reset_n                   ),
         .prev_addr_in_valid (pipe_1_addr_in_valid        ),
         .prev_addr_in_loc   (pipe_1_addr_in              ),
         .prev_pipe_valid    (pipe_1_valid                ),
         .prev_pipe_loc      (pipe_1_loc                  ),
         .curr_pipe_valid    (pipe_2_adj_ly_minus_1_valid ),
         .curr_pipe_loc      (pipe_2_adj_ly_minus_1       ),
         .next_addr_in_valid (pipe_2_addr_in_valid        ),
         .next_addr_in_loc   (pipe_2_addr_in_loc          ),
         .next_pipe_valid    (pipe_2_valid                ),
         .next_pipe_loc      (pipe_2_loc                  )
         );
    //******************************************************

    //****************************************************************

    //****************************************************************
    // ly+1 address generation and pipe 3 stage
    //****************************************************************
    always_comb
    begin
        pipe_3_adj_ly_plus_1_valid = 1'b0;
        pipe_3_adj_ly_plus_1        = '{default:'0};
        if(pipe_2_addr_in_valid)
        begin
            if(pipe_2_addr_in_loc.ly + 1'b1 <= 2)
            begin
                pipe_3_adj_ly_plus_1_valid = 1'b1;
                pipe_3_adj_ly_plus_1.lx    = pipe_2_loc_lx;
                pipe_3_adj_ly_plus_1.ly    = pipe_2_lox_ly + 1'b1;
                pipe_3_adj_ly_plus_1.lz    = pipe_2_lox_lz;
            end // if (pipe_2_addr_in_loc.ly + 1'b1 <= 2)
        end // if (pipe_2_addr_in_valid)
    end // always_comb
    //******************************************************

    //******************************************************
    // Pipeline stage 3
    //******************************************************
    prefetch_addr_gen_pipe_stage
        #(
          .NUM_GEN_ADDR_IN (3)
          )
    u_prefetch_addr_gen_pipe_stage_1
        (
         .i_clk              (i_clk                      ),
         .i_reset_n          (i_reset_n                  ),
         .prev_addr_in_valid (pipe_2_addr_in_valid       ),
         .prev_addr_in_loc   (pipe_2_addr_in             ),
         .prev_pipe_valid    (pipe_2_valid               ),
         .prev_pipe_loc      (pipe_2_loc                 ),
         .curr_pipe_valid    (pipe_3_adj_ly_plus_1_valid ),
         .curr_pipe_loc      (pipe_3_adj_ly_plus_1       ),
         .next_addr_in_valid (pipe_3_addr_in_valid       ),
         .next_addr_in_loc   (pipe_3_addr_in_loc         ),
         .next_pipe_valid    (pipe_3_valid               ),
         .next_pipe_loc      (pipe_3_loc                 )
         );
    //******************************************************

    //****************************************************************

    //****************************************************************
    // lz-1 address generation and pipe 4 stage
    //****************************************************************
    always_comb
    begin
        pipe_4_adj_lz_minus_1_valid = 1'b0;
        pipe_4_adj_lz_minus_1        = '{default:'0};
        if(pipe_3_addr_in_valid)
        begin
            if(pipe_3_addr_in_loc.lz - 1'b1 >= 0)
            begin
                pipe_4_adj_lz_minus_1_valid = 1'b1;
                pipe_4_adj_lz_minus_1.lx    = pipe_3_loc_lx;
                pipe_4_adj_lz_minus_1.ly    = pipe_3_lox_ly;
                pipe_4_adj_lz_minus_1.lz    = pipe_3_lox_lz - 1'b1;
            end // if (pipe_3_addr_in_loc.lz - 1 >= 0)
        end // if (pipe_3_addr_in_valid)
    end // always_comb
    //******************************************************

    //******************************************************
    // Pipeline stage 4
    //******************************************************
    prefetch_addr_gen_pipe_stage
        #(
          .NUM_GEN_ADDR_IN (4)
          )
    u_prefetch_addr_gen_pipe_stage_1
        (
         .i_clk              (i_clk                       ),
         .i_reset_n          (i_reset_n                   ),
         .prev_addr_in_valid (pipe_3_addr_in_valid        ),
         .prev_addr_in_loc   (pipe_3_addr_in              ),
         .prev_pipe_valid    (pipe_3_valid                ),
         .prev_pipe_loc      (pipe_3_loc                  ),
         .curr_pipe_valid    (pipe_4_adj_lz_minus_1_valid ),
         .curr_pipe_loc      (pipe_4_adj_lz_minus_1       ),
         .next_addr_in_valid (pipe_4_addr_in_valid        ),
         .next_addr_in_loc   (pipe_4_addr_in_loc          ),
         .next_pipe_valid    (pipe_4_valid                ),
         .next_pipe_loc      (pipe_4_loc                  )
         );
    //******************************************************

    //****************************************************************

    //****************************************************************
    // lz+1 address generation and pipe 5 stage
    //****************************************************************
    always_comb
    begin
        pipe_5_adj_lz_plus_1_valid = 1'b0;
        pipe_5_adj_lz_plus_1        = '{default:'0};
        if(pipe_4_addr_in_valid)
        begin
            if(pipe_4_addr_in_loc.lz + 1'b1 <= 2)
            begin
                pipe_5_adj_lz_plus_1_valid = 1'b1;
                pipe_5_adj_lz_plus_1.lx    = pipe_4_loc_lx;
                pipe_5_adj_lz_plus_1.ly    = pipe_4_lox_ly;
                pipe_5_adj_lz_plus_1.lz    = pipe_4_lox_lz - 1'b1;
            end // if (pipe_4_addr_in_loc.lz - 1 >= 0)
        end // if (pipe_4_addr_in_valid)
    end // always_comb
    //******************************************************

    //******************************************************
    // Pipeline stage 5
    //******************************************************
    prefetch_addr_gen_pipe_stage
        #(
          .NUM_GEN_ADDR_IN (5)
          )
    u_prefetch_addr_gen_pipe_stage_1
        (
         .i_clk              (i_clk                      ),
         .i_reset_n          (i_reset_n                  ),
         .prev_addr_in_valid (1'b0                       ),
         .prev_addr_in_loc   ('{default:'0}              ),
         .prev_pipe_valid    (pipe_4_valid               ),
         .prev_pipe_loc      (pipe_4_loc                 ),
         .curr_pipe_valid    (pipe_5_adj_lz_plus_1_valid ),
         .curr_pipe_loc      (pipe_5_adj_lz_plus_1       ),
         .next_addr_in_valid (                           ),
         .next_addr_in_loc   (                           ),
         .next_pipe_valid    (pipe_5_valid               ),
         .next_pipe_loc      (pipe_5_loc                 )
         );
    //******************************************************

    //****************************************************************

    //****************************************************************
    // Output
    //****************************************************************
    for(genvar k=0;k<6;k=k+1)
    begin: g_pipe_5_valid_l
        assign pipe_5_valid_l[k]  = pipe_5_valid[k];
    end
    assign output_fifo_push_l = |pipe_5_valid_l;

    always_ff@(posedge i_clk or negedge i_reset_n)
    begin
        if(~i_reset_n)
            output_fifo_curr_ptr <= 2'd0;
        else
        begin
            if(output_fifo_curr_ptr == 2'd5)
                output_fifo_curr_ptr <= 2'd0;
            else if(~output_fifo_empty)
                output_fifo_curr_ptr <= output_fifo_curr_ptr + 1'b1;
        end // else: !if(~i_reset_n)
    end // always_ff@ (posedge i_clk or negedge i_reset_n)

    for(genvar k=0;k<6;k=k+1)
    begin: g_output_fifo_valid_l
        assign output_fifo_valid_l = output_fifo_valid[k];
    end

    assign output_fifo_empty = |output_fifo_valid_l;

    //******************************************************
    // Output FIFO
    //******************************************************
    // Log all available outputs from pipe_5 into the FIFO in a single cycle
    // Convert location into address
    // Output each stage based on valid
    //******************************************************
    for(genvar k=0;k<=6;k=k+1)
    begin: g_output_fifo_valid
        always_ff@(posedge i_clk or negedge i_reset_n)
        begin
            if(~i_reset_n)
                output_fifo_valid[k] <= 1'b0;
            else
            begin
                if(output_fifo_empty & output_fifo_push_l)
                    output_fifo_valid[k] <= pipe_5_valid[k];
                else if(~output_fifo_empty & (k == output_fifo_curr_ptr))
                    output_fifo_valid[k] <= 1'b0;
            end // else: !if(~i_reset_n)
        end // always_ff@ (posedge i_clk or negedge i_reset_n)

        always_ff@(posedge i_clk or negedge i_reset_n)
        begin
            if(~i_reset_n)
                output_fifo_loc[k] <= '{default: '0};
            else if(output_fifo_empty & output_fifo_push_l)
                output_fifo_loc[k] <= pipe_5_loc[k];
        end // always_ff@ (posedge i_clk or negedge i_reset_n)
    end // block: g_output_fifo_valid
    //******************************************************

    assign prefetch_addr_out_valid     = output_fifo_valid[output_fifo_curr_ptr];

    assign output_fifo_loc_at_curr_ptr = output_fifo_loc[output_fifo_curr_ptr];
    assign prefetch_addr_out           = MEM_MODEL[output_fifo_loc_at_curr_ptr.lx][output_fifo_loc_at_curr_ptr.ly][output_fifo_loc_at_curr_ptr.lz];

    //****************************************************************

endmodule // prefetch_addr_gen_sol1
