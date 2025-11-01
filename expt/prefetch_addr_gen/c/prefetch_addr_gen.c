// Problem statement:
// In a 3D memory model, while prefetching data,
// prefetch data from adjacency along with the fetch address.
// Definition of adjacency:
// Any location that is one step away from the missing location in each direction.

// Solution:
// Arrange the 3D model as a 3D array
// Based on address in, find the location of the address
// Step in each direction +1 and -1 to find the adjacent locations
// Any location that is greater than 2 or less than 0 are discarded
// Number of locations to lookup may be different

#include <stdio.h>
#include <stdint.h>

int main() {

  int prefetch_addr_gen(uint32_t);
  uint32_t addr_in;

  printf("\n");
  printf("Enter an address to lookup: ");
  scanf("%d", &addr_in);
  printf("%d", addr_in);

  return(prefetch_addr_gen(addr_in));

}

// Arrange memory as a 3x3x3 3D-matrix with each location holding the address
// Find the location of address in. Use the location to step +1 and -1 on each axis

int prefetch_addr_gen(uint32_t addr_in) {

  uint32_t mem[3][3][3];
  int x, y, z;
  int lookup_x, lookup_y, lookup_z;


  // Arrange 3D memory model
  int data = 0;
  for(z=0;z<3;z++) {
    for(y=0;y<3;y++) {
      for(x=0;x<3;x++) {
        mem[x][y][z] = data++;
      }
    }
  }

  for(z=0;z<3;z++) {
    for(y=0;y<3;y++) {
      for(x=0;x<3;x++) {
        printf("\t(%d,%d,%d) = %d", x, y, z, mem[x][y][z]);
      }
      printf("\n");
    }
    printf("\n");
  }

  // Lookup address
  for(z=0;z<3;z++) {
    for(y=0;y<3;y++) {
      for(x=0;x<3;x++) {
        if(mem[x][y][z] == addr_in) {
          lookup_x = x;
          lookup_y = y;
          lookup_z = z;
        }
      }
    }
  }

  printf("\n");
  printf("lookup x = %d, y= %d, z = %d, address at (x,y,z) = %d\n", lookup_z, lookup_y, lookup_z, mem[lookup_x][lookup_y][lookup_z]);

  // Figure out adjacencies
  printf("\n");
  printf("Adjacancies are:\n");
  printf("x axis:\n");
  if(lookup_x - 1 >= 0) {
    printf("Adjancency at (%d, %d, %d) = %d\n", lookup_x-1, lookup_y, lookup_z, mem[lookup_x-1][lookup_y][lookup_z]);
  }
  if(lookup_x + 1 <= 2) {
    printf("Adjancency at (%d, %d, %d) = %d\n", lookup_x+1, lookup_y, lookup_z, mem[lookup_x+1][lookup_y][lookup_z]);
  }
  printf("y axis:\n");
  if(lookup_y - 1 >= 0) {
    printf("Adjancency at (%d, %d, %d) = %d\n", lookup_x, lookup_y-1, lookup_z, mem[lookup_x][lookup_y-1][lookup_z]);
  }
  if(lookup_y + 1 <= 2) {
    printf("Adjancency at (%d, %d, %d) = %d\n", lookup_x, lookup_y+1, lookup_z, mem[lookup_x][lookup_y+1][lookup_z]);
  }
  printf("z axis:\n");
  if(lookup_z - 1 >= 0) {
    printf("Adjancency at (%d, %d, %d) = %d\n", lookup_x, lookup_y, lookup_z-1, mem[lookup_x][lookup_y][lookup_z-1]);
  }
  if(lookup_z + 1 <= 2) {
    printf("Adjancency at (%d, %d, %d) = %d\n", lookup_x, lookup_y, lookup_z+1, mem[lookup_x][lookup_y][lookup_z+1]);
  }
  printf("\n");

  return 0;
}
