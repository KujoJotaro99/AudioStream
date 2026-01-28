TOP := top
RTL_DIR := ../../rtl/top
FILELIST := $(RTL_DIR)/filelist.json
PCF := icebreaker.pcf
BUILD := build

YOSYS := yosys
NEXTPNR := nextpnr-ice40
ICEPACK := icepack

DEVICE := up5k
PACKAGE := sg48

VERILOG_SOURCES := $(shell python3 -c "import json, os; \
    j=json.load(open('$(FILELIST)')); \
    print(' '.join(f if os.path.isabs(f) else os.path.join('$(RTL_DIR)', f) for f in j['files']))")

JSON := $(BUILD)/$(TOP).json
ASC := $(BUILD)/$(TOP).asc
BIN := $(BUILD)/$(TOP).bin

.PHONY: all netlist synth place bitstream abstract clean

all: bitstream

$(BUILD):
	mkdir -p $(BUILD)

netlist: $(JSON)

INCLUDE_DIRS := -I../../submodules/basejump_stl/bsg_misc

$(JSON): $(VERILOG_SOURCES) | $(BUILD)
	$(YOSYS) -p "verilog_defaults -sv; read_verilog -sv $(INCLUDE_DIRS) $(VERILOG_SOURCES); synth_ice40 -top $(TOP) -json $(JSON)"

synth: $(JSON)

place: $(ASC)

$(ASC): $(JSON) $(PCF) | $(BUILD)
	$(NEXTPNR) --$(DEVICE) --package $(PACKAGE) --json $(JSON) --pcf $(PCF) --asc $(ASC)

bitstream: $(BIN)

$(BIN): $(ASC) | $(BUILD)
	$(ICEPACK) $(ASC) $(BIN)

abstract:
	netlistsvg $(JSON) -o $(BUILD)/$(TOP).svg
	@if command -v rsvg-convert >/dev/null 2>&1; then \
		rsvg-convert -f pdf -o $(BUILD)/$(TOP).pdf $(BUILD)/$(TOP).svg; \
	elif command -v inkscape >/dev/null 2>&1; then \
		inkscape $(BUILD)/$(TOP).svg --export-type=pdf --export-filename=$(BUILD)/$(TOP).pdf; \
	else \
		echo 'warning: rsvg-convert or inkscape not found, skipping pdf export'; \
	fi

clean:
	rm -rf $(BUILD)
