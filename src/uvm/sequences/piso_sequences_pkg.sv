package piso_sequences_pkg;
    import uvm_pkg::*;
    import piso_pkg::piso_config; // For cfg in seq_item
    `include "uvm_macros.svh"

    `include "piso_seq_item.sv"
    `include "piso_base_sequence.sv"
    `include "piso_reset_sequence.sv"
    `include "piso_load_shift_sequence.sv"
    `include "piso_corner_sequence.sv"
    `include "piso_virtual_sequence.sv"
endpackage