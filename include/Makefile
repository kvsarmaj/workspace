CC = g++
SC_INCLUDE = -I. -I$(SYSTEMC_HOME)/include $(SC_INC)
SC_CFLAGS = 
SC_LDFLAGS = -L. -L$(SYSTEMC_HOME)/lib-linux64 -Wl,-rpath=$(SYSTEMC_HOME)/lib-linux64 
SC_EXTRA_FLAGS = -lsystemc -lm
SC_SRC_FILES = $(SC_SIM_FILES)
SC_EXE = sim
SC_VCD_VIEW = gtkwave
SC_GTK_OPTS = -S $(WS_ROOT)/include/add_all_sig.tcl

.PHONY: clean

all: clean comp_run

comp_run: gen_sim comp run vcd  

gen_sim:
	@echo "-----------------------------------------------------"
	@echo "Generating sim.cpp                                   "
	@echo "-----------------------------------------------------"
	perl $(WS_TOOL_ROOT)/gen_sim_file.pl -mod $(MOD) -dump_hier -log -create_sim_file -inc_list "$(SC_INC)" -sim_file=$(SC_EXE).cpp
	@echo "-----------------------------------------------------"
ifeq ("$(wildcard sim.cpp)","")
	@echo "sim.cpp generation failed"
else
	@echo "sim.cpp generation successful"
endif
	@echo "-----------------------------------------------------"

comp: $(SC_EXE) 

$(SC_EXE): 
	@echo "-----------------------------------------------------" | tee -a build.log
	@echo " Building SystemC simulation for $(MOD)              " | tee -a build.log
	@echo "-----------------------------------------------------" | tee -a build.log
	$(CC) $(SC_INCLUDE) $(SC_CFLAGS) $(SC_LDFLAGS) $(SC_EXTRA_FLAGS) $(SC_SRC_FILES) -o $@ 2>&1 | tee -a build.log

run: $(SC_EXE)
	@echo "-----------------------------------------------------" | tee -a sim.log
	@echo " Running SystemC sumulation for $(MOD)               " | tee -a sim.log
	@echo "-----------------------------------------------------" | tee -a sim.log
	./$(SC_EXE) | tee -a sim.log

vcd: $(SC_EXE)
	$(SC_VCD_VIEW) $(SC_GTK_OPTS) $(SC_EXE).vcd &

clean: 
	rm -f $(SC_EXE).cpp $(SC_EXE) $(SC_EXE).vcd *.log

