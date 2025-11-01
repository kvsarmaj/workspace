//******************************************************************************
// File: prefetch_3d.sv
// Description: Implement an address generator for adjacent location prefetcher for a 3d memory model
//              Identify adjacent addresses of every input address
//              Maintain a FIFO to keep all addresses generated every clock cycle
//              Issue address out for each adjacent address
//******************************************************************************

`include "prefetch_addr_gen_includes.svh"

module prefetch_addr_gen_sol2
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

    mem_loc_t    addr_in_loc;

    logic [5:0]  adj_addr_loc_valid;
    mem_loc_t    adj_addr_loc[5:0];
    logic [2:0]  num_valid_adj_addr;

    mem_loc_t    adj_addr_loc_fifo[30:0];
    logic [30:0] adj_addr_loc_fifo_push;
    logic [2:0]  adj_addr_loc_fifo_push_index[30:0];
    logic [4:0]  adj_addr_loc_fifo_curr_wr_ptr;
    logic [4:0]  adj_addr_loc_fifo_curr_rd_ptr;
    logic        adj_addr_loc_fifo_empty;
    mem_loc_t    adj_addr_loc_fifo_pop_val;

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
    // Adjacent Addresses
    //****************************************************************

    // lx-1
    always_comb
    begin
        adj_addr_loc_valid = 1'b0;
        adj_addr_loc[0]    = '{default: '0};
        if(addr_in_valid)
        begin
            if(addr_in_loc.lx - 1'b1 >= 0)
            begin
                adj_addr_loc_valid[0] = 1'b1;
                adj_addr_loc[0].lx    = addr_in_loc.lx - 1'b1;
                adj_addr_loc[0].ly    = addr_in_loc.ly;
                adj_addr_loc[0].lz    = addr_in_loc.lz;
            end // if (addr_in_loc.lx - 1'b1 >= 0)
        end // if (addr_in_valid)
    end // always_comb

    // lx+1
    always_comb
    begin
        adj_addr_loc_valid = 1'b0;
        adj_addr_loc[1]    = '{default: '0};
        if(addr_in_valid)
        begin
            if(addr_in_loc.lx + 1'b1 <= 2)
            begin
                adj_addr_loc_valid[1] = 1'b1;
                adj_addr_loc[1].lx    = addr_in_loc.lx + 1'b1;
                adj_addr_loc[1].ly    = addr_in_loc.ly;
                adj_addr_loc[1].lz    = addr_in_loc.lz;
            end // if (addr_in_loc.lx + 1'b1 <= 2)
        end // if (addr_in_valid)
    end // always_comb

    // ly-1
    always_comb
    begin
        adj_addr_loc_valid = 1'b0;
        adj_addr_loc[2]    = '{default: '0};
        if(addr_in_valid)
        begin
            if(addr_in_loc.ly - 1'b1 >= 0)
            begin
                adj_addr_loc_valid[2] = 1'b1;
                adj_addr_loc[2].lx    = addr_in_loc.lx;
                adj_addr_loc[2].ly    = addr_in_loc.ly - 1'b1;
                adj_addr_loc[2].lz    = addr_in_loc.lz;
            end // if (addr_in_loc.ly - 1'b1 <= 0)
        end // if (addr_in_valid)
    end // always_comb

    // ly+1
    always_comb
    begin
        adj_addr_loc_valid = 1'b0;
        adj_addr_loc[3]    = '{default: '0};
        if(addr_in_valid)
        begin
            if(addr_in_loc.ly + 1'b1 <= 2)
            begin
                adj_addr_loc_valid[3] = 1'b1;
                adj_addr_loc[3].lx    = addr_in_loc.lx;
                adj_addr_loc[3].ly    = addr_in_loc.ly - 1'b1;
                adj_addr_loc[3].lz    = addr_in_loc.lz;
            end // if (addr_in_loc.ly - 1'b1 <= 0)
        end // if (addr_in_valid)
    end // always_comb

    // lz-1
    always_comb
    begin
        adj_addr_loc_valid = 1'b0;
        adj_addr_loc[4]    = '{default: '0};
        if(addr_in_valid)
        begin
            if(addr_in_loc.lz - 1'b1 >= 0)
            begin
                adj_addr_loc_valid[4] = 1'b1;
                adj_addr_loc[4].lx    = addr_in_loc.lx;
                adj_addr_loc[4].ly    = addr_in_loc.ly;
                adj_addr_loc[4].lz    = addr_in_loc.lz - 1'b1;
            end // if (addr_in_loc.ly - 1'b1 <= 0)
        end // if (addr_in_valid)
    end // always_comb

    // lz+1
    always_comb
    begin
        adj_addr_loc_valid = 1'b0;
        adj_addr_loc[5]    = '{default: '0};
        if(addr_in_valid)
        begin
            if(addr_in_loc.ly + 1'b1 <= 2)
            begin
                adj_addr_loc_valid[5] = 1'b1;
                adj_addr_loc[5].lx    = addr_in_loc.lx;
                adj_addr_loc[5].ly    = addr_in_loc.ly;
                adj_addr_loc[5].lz    = addr_in_loc.lz + 1'b1;
            end // if (addr_in_loc.ly - 1'b1 <= 0)
        end // if (addr_in_valid)
    end // always_comb

    assign num_valid_adj_addr = adj_addr_loc_valid[0]
                                +  adj_addr_loc_valid[1]
                                +  adj_addr_loc_valid[2]
                                +  adj_addr_loc_valid[3]
                                +  adj_addr_loc_valid[4]
                                +  adj_addr_loc_valid[5];
    //****************************************************************

    //****************************************************************
    // Adjacent Address Location fifo
    //****************************************************************

    // Write pointer
    always_ff@(posedge i_clk or negedge i_reset_n)
    begin
        if(~i_reset_n)
            adj_addr_loc_fifo_curr_wr_ptr <= 6'd0;
        else
        begin
            if(adj_addr_loc_fifo_curr_wr_ptr + num_valid_adj_addr > 30)
                adj_addr_loc_fifo_curr_wr_ptr <= adj_addr_loc_fifo_curr_wr_ptr + num_valid_adj_addr - 30;
            else
                adj_addr_loc_fifo_curr_wr_ptr <= adj_addr_loc_fifo_wr_ptr + num_valid_adj_addr;
        end // else: !if(~i_reset_n)
    end // always_ff@ (posedge i_clk or negedge i_reset_n)

    // Identify which indices in adj_addr_loc_fifo to push adj_addr_loc into
    always_comb
    begin
        for(int i=0;i<31;i=i+1)
        begin: l_adj_addr_loc_fifo_push_default
            adj_addr_loc_fifo_push[i] = 1'b0;
        end
        if(num_valid_adj_addr != 2'd0)
        begin
            for(int i=0;i<num_valid_adj_addr;i=i+1)
            begin: l_adj_addr_loc_fifo_push
                if(adj_addr_loc_valid[i])
                begin
                    if(adj_addr_loc_fifo_curr_wr_ptr + i > 30)
                        adj_addr_fifo_push[adj_addr_loc_fifo_curr_wr_ptr + i - 30] = 1'b1;
                    else
                        adj_addr_fifo_push[adj_addr_loc_fifo_curr_wr_ptr + i] = 1'b1;
                end // if (adj_addr_loc_valid[i])
            end // block: l_adj_addr_loc_fifo_push
        end // if (num_valid_adj_addr != 2'd0)
    end // always_comb

    // Identify index of adj_addr_loc to push into adj_addr_loc_fifo
    always_comb
    begin
        for(int i=0;i<31;i=i+1)
        begin: l_adj_addr_loc_fifo_push_index_default
            adj_addr_loc_fifo_push_index[i] = 3'd0;
        end

        if(num_valid_adj_addr != 2'd0)
        begin
            for(int i=0;i<num_valid_adj_addr;i=i+1)
            begin: l_adj_addr_loc_fifo_push_index
                if(adj_addr_loc_valid[i])
                begin
                    if(adj_addr_loc_fifo_curr_wr_ptr + i > 30)
                        adj_addr_loc_fifo_push_index[adj_addr_loc_fifo_curr_wr_ptr + i - 30] = i;
                    else
                        adj_addr_loc_fifo_push_index[adj_addr_loc_fifo_curr_wr_ptr + i] = i;
                end // if (adj_addr_loc_valid[i])
            end // block: l_loc_fifo_push_index
        end // if (num_valid_adj_addr != 2'd0)
    end // always_comb

    for(genvar k=0;k<31;k=k+1)
    begin: g_adj_addr_fifo
        always_ff@(posedge i_clk or negedge i_reset_n)
        begin
            if(~i_reset_n)
                adj_addr_loc_fifo[k] <= '{default: '0};
            else if(adj_addr_loc_fifo_push[k])
                adj_addr_loc_fifo[k] <= adj_addr_loc[adj_addr_loc_fifo_push_index[k]];
        end // always_ff@ (posedge i_clk or negedge i_reset_n)
    end // block: g_adj_addr_fifo

    assign adj_addr_loc_fifo_empty = (adj_addr_loc_fifo_curr_wr_ptr == adj_addr_loc_fifo_curr_rd_ptr);

    // Read pointer
    always_ff@(posedge i_clk or negedge i_reset_n)
    begin
        if(~i_reset_n)
            adj_addr_loc_fifo_curr_rd_ptr <= 5'b0;
        else
        begin
            if(~adj_addr_loc_fifo_empty)
            begin
                if(adj_addr_loc_fifo_curr_rd_ptr + 1'b1 > 30)
                    adj_addr_loc_fifo_curr_rd_ptr <= 5'd0;;
                else
                    adj_addr_loc_fifo_curr_rd_ptr <= adj_addr_loc_fifo_curr_rd_ptr + 1'b1;
            end // if (~adj_addr_loc_fifo_empty)
        end // else: !if(~i_reset_n)
    end // always_ff@ (posedge i_clk or negedge i_reset_n)
    //****************************************************************

    //****************************************************************
    // Output
    //****************************************************************
    assign prefetch_addr_out_valid   = ~adj_addr_loc_fifo_empty;

    assign adj_addr_loc_fifo_pop_val = adj_addr_loc_fifo[adj_addr_loc_fifo_curr_rd_ptr];
    assign prefetch_addr_out         = MEM_MODEL[adj_addr_loc_fifo_pop_val.lx][adj_addr_loc_fifo_pop_val.ly][adj_addr_loc_fifo_pop_val.lz];
    //****************************************************************

endmodule // prefetch_addr_gen_sol2
