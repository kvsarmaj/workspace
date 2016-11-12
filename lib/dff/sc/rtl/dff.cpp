#include <systemc.h>
#include <dff.rtl.files>

SC_MODULE(sc_dff)
{
  //*****************************************************************************
  //ports
  //*****************************************************************************
  sc_in<bool> d;
  sc_in<bool> clk;
  sc_out<bool> q;
 
  void dff()
  {
      q = d;
  }
 
  SC_CTOR(sc_dff)
  {
    SC_METHOD(dff);
    sensitive << clk.pos();
  }
};
