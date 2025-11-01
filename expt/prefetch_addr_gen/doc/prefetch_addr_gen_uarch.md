# Prefetch Address Generation for a 3D Memory Model

Generate addresses for a prefetch unit based on a specified input address.<br>
The address has to adjacent to the specified input address.<br>
Adjacency is defined by a location immediately adjacent to the input address on each axis.<br>

# Design

There are two extremes of possible solutions.
- Solution 1: Latency of 7 cycles, relaxed timing
- Solution 2: Latency of 1 cycle, tight timing

## Solution 1 : prefetch_3d_addr_gen_sol1.sv

Lookup the input address to find the location.<br>
Ignore the request if it is not present in the memory.<br>

Since incoming addresses come with valid and there is no backpressure, the pipeline has to be as deep as the worst case.<br>
With a 3D memory model, the worst case adjacency is 6 when the input address is in the middle of the 3x3x3 memory.<br>

Find the location of the input address by simple lookup.<br>
Assume the input address is at location (lx,ly,lz).<br>
An address is adjacent to input address on any axis if the corresponding location is not less than or not greater than 2.<br>

### Pipeline Stage 0
If lx-1 is greater than or equal to 0, adjacency observed at (lx-1, ly, lz).<br>
Else, do generate an output address.<br>
Store result for lx-1 into a pipeline stage.<br>

### Pipeline Stage 1
If lx+1 is less than or equal to 2, adjacency observed at (lx+1, ly, lz).<br>
Else, do generate an output address.<br>
Store result for lx-1, lx+1 into a pipeline stage.<br>

### Pipeline Stage 2
If ly-1 is greater than or equal to 0, adjacency observed at (lx, ly-1, lz).<br>
Else, do generate an output address.<br>
Store result for lx-1, lx+1, ly-1 into a pipeline stage.<br>

### Pipeline Stage 3
If ly+1 is less than or equal to 2, adjacency observed at (lx, ly+1, lz).<br>
Else, do generate an output address.<br>
Store result for lx-1, lx+1, ly-1, ly+1 into a pipeline stage.<br>

### Pipeline Stage 4
If lz-1 is greater than or equal to 0, adjacency observed at (lx, ly, lz-1).<br>
Else, do generate an output address.<br>
Store result for lx-1, lx+1, ly-1, ly+1, lz-1 into a pipeline stage.<br>

### Pipeline Stage 5
If lz+1 is less than or equal to 2, adjacency observed at (lx, ly, lz+1).<br>
Else, do generate an output address.<br>
Store result for lx-1, lx+1, ly-1, ly+1, lz-1, lz+1 into a pipeline stage.<br>

### Output
Log all valid results out of the 6 into a hold register and issue addresses out every clock cycle.<br>
By the time 6 addresses are output, addresses for the next input address will be available in pipeline output.<br>
When not all generated addresses are valid, there will be less than 6 address outputs.<br>

## Solution 2 : prefetch_3d_addr_gen_sol2.sv

Lookup the input address to find the location.<br>
Ignore the request if it is not present in the memory.<br>

Since incoming addresses come with valid and there is no backpressure, the pipeline has to be as deep as the worst case.<br>
With a 3D memory model, the worst case adjacency is 6 when the input address is in the middle of the 3x3x3 memory.<br>

Find the location of the input address by simple lookup.<br>
Assume the input address is at location (lx,ly,lz).<br>
An address is adjacent to input address on any axis if the corresponding location is not less than or not greater than 2.<br>

Calculate all the possible addresses:
- If lx-1 is greater than or equal to 0, adjacency observed (lx-1, ly,   lz  ).<br>
- If lx+1 is less than or equal to 2,    adjacency observed (lx+1, ly,   lz  ).<br>
- If ly-1 is greater than or equal to 0, adjacency observed (lx,   ly-1, lz  ).<br>
- If ly+1 is less than or equal to 2,    adjacency observed (lx,   ly+1, lz  ).<br>
- If lz-1 is greater than or equal to 0, adjacency observed (lx,   ly,   lz-1).<br>
- If lz+1 is less than or equal to 2,    adjacency observed (lx,   ly,   lz+1).<br>

### FIFO

The FIFO to hold location information for each adjacent address should hold at least 31 locations.<br>
In case every address input generates 6 adjacent addresses, while FIFO is output 6 addresses each clock cycle, 30 new addresses will be generated.<br>

While logging the generated address locations, the FIFO should be able upto log 6 addresses in one cycle.<br>
When number of addresses generated is less than 6, FIFO should log only the generated number of addresses in consecutive locations.<br>

### Output

Read the FIFO in a circular fashion and lookup each location in the FIFO for the address.<br>
Output each address from the FIFO one after the other until FIFO is empty.<br>
