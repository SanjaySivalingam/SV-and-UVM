class piso_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(piso_virtual_sequencer)
  uvm_sequencer #(piso_seq_item) piso_seqr; // handle to piso agent's sequencer

  function new(string name, uvm_component parent);
      super.new(name, parent);
  endfunction
endclass