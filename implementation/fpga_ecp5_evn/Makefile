PROJ=riscv
TRELLIS?=/usr/share/trellis
VERILOG_SRCS = $(wildcard ./../src/*.v) $(wildcard ./src/*.v)

all: ${PROJ}.bit

%.json: $(VERILOG_SRCS)
	yosys -p "synth_ecp5 -json $@" $(VERILOG_SRCS)

%_out.config: %.json
	nextpnr-ecp5 --json $< --textcfg $@ --um5g-85k --package CABGA381 --lpf ecp5evn.lpf

%.bit: %_out.config
	ecppack --svf ${PROJ}.svf $< $@

${PROJ}.svf : ${PROJ}.bit

prog: ${PROJ}.svf
	openocd -f ${TRELLIS}/misc/openocd/ecp5-evn.cfg -c "transport select jtag; init; svf $<; exit"

clean:
	rm -f *.svf *.bit *.config *.json

.PHONY: prog clean

