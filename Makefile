FEMTORV_DIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
PROJECTNAME=soc
VERILOGS=rtl/$(PROJECTNAME).v

YOSYS_ICESUGAR_OPT=-q -p "synth_ice40 -relut -top $(PROJECTNAME) -json $(PROJECTNAME).json"
NEXTPNR_ICESUGAR_OPT=--force --json $(PROJECTNAME).json --pcf rtl/icesugar.pcf --asc $(PROJECTNAME).asc --freq 12 --up5k --package sg48
ICELINK_DIR=/mnt/iCELink

#######################################################################################################################

ICESUGAR: ICESUGAR.firmware_config ICESUGAR.synth ICESUGAR.prog

ICESUGAR.synth: #FIRMWARE/firmware.hex
	yosys $(YOSYS_ICESUGAR_OPT) $(VERILOGS)
	nextpnr-ice40 $(NEXTPNR_ICESUGAR_OPT)
	icetime -p rtl/icesugar.pcf -P sg48 -r $(PROJECTNAME).timings -d up5k -t $(PROJECTNAME).asc
	icepack -s $(PROJECTNAME).asc $(PROJECTNAME).bin

ICESUGAR.show: FIRMWARE/firmware.hex 
	yosys $(YOSYS_ICESUGAR_OPT) $(VERILOGS)
	nextpnr-ice40 $(NEXTPNR_ICESUGAR_OPT) --gui

ICESUGAR.prog:
	# icesprog $(PROJECTNAME).bin
	cp $(PROJECTNAME).bin $(ICELINK_DIR)

ICESUGAR.firmware_config:
	#(cd FIRMWARE; make libs)