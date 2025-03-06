#verilator export
VERILATOR = $(VERILATOR_ROOT)/bin/verilator


#vivado tcl define
VIVADO = vivado
TCL_SCRIPT = $(DESIGN).tcl
PROJECT_NAME = rtl_simulation
VIVADO_PROJECT_NAME = vivado_sim

#yosys-sta define
LIB_PATH = $(PROJ_PATH)/yosys

DESIGN ?= top
SDC_FILE ?= $(PROJ_PATH)/sdc/$(DESIGN).sdc
RTL_FILES ?= $(shell find $(PROJ_PATH)/vsrc -name "*.v")
export CLK_FREQ_MHZ ?= 500

RESULT_DIR = $(LIB_PATH)/result/$(DESIGN)-$(CLK_FREQ_MHZ)MHz
SCRIPT_DIR = $(LIB_PATH)/scripts
NETLIST_SYN_V   = $(RESULT_DIR)/$(DESIGN).netlist.syn.v
NETLIST_FIXED_V = $(RESULT_DIR)/$(DESIGN).netlist.fixed.v
TIMING_RPT = $(RESULT_DIR)/$(DESIGN).rpt


#verilator define
TOPNAME = $(DESIGN)
INC_PATH = $(OBJ_DIR)

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

PROJ_PATH = $(shell pwd)


# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc --trace -j -O3 --x-assign fast --x-initial fast --noassert


# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v" -not -path "$(abspath ./vsrc/tb)/*")
CSRCS = $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)

	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

default: $(BIN)
$(shell mkdir -p $(BUILD_DIR))


# wave simulation
wave: $(BIN)
	@$(BIN)
# gtkwave dump.vcd

# vivado simulation
vivado:
	$(VIVADO) -mode batch -source $(TCL_SCRIPT)


#yosys simulation
syn: $(NETLIST_SYN_V)
$(NETLIST_SYN_V): $(RTL_FILES) $(SCRIPT_DIR)/yosys.tcl
	mkdir -p $(@D)
	echo tcl $(SCRIPT_DIR)/yosys.tcl $(DESIGN) \"$(RTL_FILES)\" $@ | yosys -l $(@D)/yosys.log -s -

fix-fanout: $(NETLIST_FIXED_V)
$(NETLIST_FIXED_V): $(SCRIPT_DIR)/fix-fanout.tcl $(SDC_FILE) $(NETLIST_SYN_V)
	$(LIB_PATH)/bin/iEDA -script $^ $(DESIGN) $@ 2>&1 | tee $(RESULT_DIR)/fix-fanout.log

sta: $(TIMING_RPT)
$(TIMING_RPT): $(SCRIPT_DIR)/sta.tcl $(SDC_FILE) $(NETLIST_FIXED_V)
	$(LIB_PATH)/bin/iEDA -script $^ $(DESIGN) 2>&1 | tee $(RESULT_DIR)/sta.log


clean:
	rm -rf $(BUILD_DIR) *.log *.dmp *.vpd core
	-rm -rf $(VIVADO_PROJECT_NAME) $(PROJECT_NAME).runs $(PROJECT_NAME).sim $(PROJECT_NAME).cache $(PROJECT_NAME).hw $(PROJECT_NAME).ip_user_files $(PROJECT_NAME).xpr *.jou *.log *.str
	-rm -rf $(LIB_PATH)/result/
	-rm -rf vivado*.log vivado*.jou
	-rm -rf .Xil/ .cache/ .sim/
	-rm -rf ./reports
	-rm *.vcd *.view

.PHONY: init syn fix-fanout sta clean

