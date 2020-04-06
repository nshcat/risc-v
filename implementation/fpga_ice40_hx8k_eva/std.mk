TARGET_STEM = riscv

PINS_FILE = pins.pcf

YOSYS_LOG  = synth.log
YOSYS_ARGS = -v3 -l $(YOSYS_LOG)

VERILOG_SRCS = $(wildcard ./../src/*.v) $(wildcard ./src/*.v)

BIN_FILE  = $(TARGET_STEM).bin
ASC_FILE  = $(TARGET_STEM).asc
JSON_FILE = $(TARGET_STEM).json

all:	$(BIN_FILE)

$(BIN_FILE):	$(ASC_FILE)
	icepack	$< $@

$(ASC_FILE):	$(JSON_FILE) $(PINS_FILE)
	nextpnr-ice40 $(NEXTPNR_FLAGS) --freq 16.5 --json $(JSON_FILE) --asc $(ASC_FILE) --pcf $(PINS_FILE)

$(JSON_FILE):	$(VERILOG_SRCS)
	yosys $(YOSYS_ARGS) -p "synth_ice40 -abc9 -json $(JSON_FILE)" $(VERILOG_SRCS)

prog:	$(BIN_FILE)
	$(PROG_BIN) $<

timings:$(ASC_FILE)
	icetime -tmd $(ICETIME_DEVICE) $<

clean:
	rm -f $(BIN_FILE) $(ASC_FILE) $(JSON_FILE) $(YOSYS_LOG)

.PHONY:	all clean prog timings


