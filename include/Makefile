CC = g++
SC_INCLUDE = -I. -I$(SYSTEMC_HOME)/include $(SC_INC)
SC_CFLAGS = 
SC_LDFLAGS = -L. -L$(SYSTEMC_HOME)/lib-linux64 -Wl,-rpath=$(SYSTEMC_HOME)/lib-linux64 
SC_EXTRA_FLAGS = -lsystemc -lm
SC_SRC_FILES = $(SC_RTL_FILES) $(SC_TB_FILES) $(SC_SIM_FILES)
SC_EXE = sim
SC_VCD_VIEW = gtkwave
SC_GTK_OPTS = -S $(WS_ROOT)/include/add_all_sig.tcl

.PHONY: clean

all: clean comp_run

comp_run: gen_sim comp run vcd  

gen_sim: 
	perl $(WS_TOOL_ROOT)/gen_sim_file.pl -mod $(MOD) -dump_hier -create_sim_file -inc_list "$(SC_INC)"

comp: $(SC_EXE) 

$(SC_EXE): $(SC_SRC_FILES)
	@echo "///////--------------------------/////////"
	@echo "            SystemC Compile               "
	@echo "///////--------------------------/////////"
	$(CC) $(SC_INCLUDE) $(SC_CFLAGS) $(SC_LDFLAGS) $(SC_EXTRA_FLAGS) $(SC_SRC_FILES) -o $@

run: $(SC_EXE)
	./$(SC_EXE)

vcd: $(SC_EXE)
	$(SC_VCD_VIEW) $(SC_GTK_OPTS) $(SC_EXE).vcd &

clean: 
	rm -f $(SC_EXE) $(SC_EXE).vcd

