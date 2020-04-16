# Configuration options
FEATURE_DBG_PORT?=OFF
FEATURE_RV32E?=OFF

# Build defines
DEFINES = 

ifeq ($(FEATURE_DBG_PORT),ON)
    DEFINES += -D FEATURE_DBG_PORT
endif

ifeq ($(FEATURE_RV32E),ON)
    DEFINES += -D FEATURE_RV32E
endif


TARGET_STEM = riscv
PINS_FILE = pins.pcf

YOSYS_LOG  = synth.log
YOSYS_ARGS = -v3 -l $(YOSYS_LOG) -D YOSYS_HX8K $(DEFINES)

VERILOG_SRCS = $(wildcard ./../src/*.v) $(wildcard ./src/*.v)

BIN_FILE  = $(TARGET_STEM).bin
ASC_FILE  = $(TARGET_STEM).asc
FLASHED_FILE = $(TARGET_STEM)_flashed.asc
JSON_FILE = $(TARGET_STEM).json
FIRMWARE_IMG = ./../memory/flash.txt
MARKER = ./../memory/marker.txt

all:	$(BIN_FILE)

$(BIN_FILE):	$(FLASHED_FILE)
	icepack	$< $@

$(ASC_FILE):	$(JSON_FILE) $(PINS_FILE)
	nextpnr-ice40 $(NEXTPNR_FLAGS) --freq 16.5 --json $(JSON_FILE) --asc $(ASC_FILE) --pcf $(PINS_FILE)

$(JSON_FILE):	$(VERILOG_SRCS)
	yosys $(YOSYS_ARGS) -p "synth_ice40 -abc9 -json $(JSON_FILE)" $(VERILOG_SRCS)

$(FLASHED_FILE): $(ASC_FILE) $(FIRMWARE_IMG)
	icebram $(MARKER) $(FIRMWARE_IMG) < $(ASC_FILE) > $(FLASHED_FILE)

prog:	$(BIN_FILE)
	$(PROG_BIN) $<

timings:$(ASC_FILE)
	icetime -tmd $(ICETIME_DEVICE) $<

clean:
	rm -f $(BIN_FILE) $(ASC_FILE) $(FLASHED_FILE) $(JSON_FILE) $(YOSYS_LOG)

.PHONY:	all clean prog timings


