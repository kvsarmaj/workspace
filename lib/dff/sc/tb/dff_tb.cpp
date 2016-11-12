#include <systemc.h>
#include <dff.tb.files>
#include <dff.cpp>

SC_MODULE(sc_dff_tb)
{

  //----------------------------------
  //DUT ports to be driven by TB
  //----------------------------------
  sc_signal<bool> d;
  sc_signal<bool> clk;
  sc_signal<bool> q;

  sc_dff U_dff;

  void clock() 
  {
    while(true)
      {
	clk.write(0);
	wait(5, SC_PS);
	clk.write(1);
	wait(5, SC_PS);
      }
  }

  void stim()
  {
    wait(0, SC_PS);
    d.write(1);
    wait(21, SC_PS);
    d.write(0);
    wait(31, SC_PS);
    d.write(1);
    wait(41, SC_PS);
    d.write(0);
    wait(51, SC_PS);
    sc_stop();
  }

  SC_CTOR(sc_dff_tb): U_dff("U_dff")
  {
    SC_THREAD(clock);
    SC_THREAD(stim);

    //----------------------------------
    //Connect tb signals to DUT
    //----------------------------------
    U_dff.clk(clk);
    U_dff.d(d);
    U_dff.q(q);
  }

};

