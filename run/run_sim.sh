#!/bin/bash

# Example for QuestaSim; adjust for VCS, Xcelium, etc.

vlib work
vlog -sv \
    src/dut/piso.sv \
    src/interface/piso_if.sv \
    src/uvm/config/piso_config.sv \
    src/uvm/sequences/*.sv \
    src/uvm/agent/*.sv \
    src/uvm/env/*.sv \
    src/uvm/tests/*.sv \
    tb/tb.sv
vsim -c -do "run -all; quit" work.tb +UVM_TESTNAME=piso_test