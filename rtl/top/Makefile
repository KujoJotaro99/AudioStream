TOPLEVEL_LANG ?= verilog

FILELIST_JSON := filelist.json

RTL_SOURCES := $(shell python3 -c "import json; \
    j=json.load(open('$(FILELIST_JSON)')); \
    print(' '.join(j['files']))")

TOPLEVEL := $(shell python3 -c "import json; \
    print(json.load(open('$(FILELIST_JSON)'))['top'])")

BUILD := build
SYNTH_JSON := $(BUILD)/$(TOPLEVEL).json
ICE40_JSON := $(BUILD)/$(TOPLEVEL).ice40.json
ABSTRACT_JSON ?= $(ICE40_JSON)

.PHONY: clean
clean::
	rm -rf $(BUILD)

lint:
	verilator --lint-only $(RTL_SOURCES) --top-module $(TOPLEVEL)

$(BUILD):
	mkdir -p $(BUILD)

.PHONY: synth
synth: $(SYNTH_JSON)

$(SYNTH_JSON): $(RTL_SOURCES) | $(BUILD)
	yosys -p "read_verilog -sv $(RTL_SOURCES); synth -top $(TOPLEVEL); write_json $(SYNTH_JSON)"

.PHONY: synth_ice40
synth_ice40: $(ICE40_JSON)

$(ICE40_JSON): $(RTL_SOURCES) | $(BUILD)
	yosys -p "read_verilog -sv $(RTL_SOURCES); synth_ice40 -top $(TOPLEVEL) -json $(ICE40_JSON)"

.PHONY: abstract
abstract:
	netlistsvg $(ABSTRACT_JSON) -o $(BUILD)/$(TOPLEVEL).svg
	@if command -v rsvg-convert >/dev/null 2>&1; then \
		rsvg-convert -f pdf -o $(BUILD)/$(TOPLEVEL).pdf $(BUILD)/$(TOPLEVEL).svg; \
	elif command -v inkscape >/dev/null 2>&1; then \
		inkscape $(BUILD)/$(TOPLEVEL).svg --export-type=pdf --export-filename=$(BUILD)/$(TOPLEVEL).pdf; \
	else \
		echo 'warning: rsvg-convert or inkscape not found, skipping pdf export'; \
	fi
