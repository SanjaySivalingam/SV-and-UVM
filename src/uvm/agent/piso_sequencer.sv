class piso_sequencer extends uvm_sequencer #(piso_seq_item);
    `uvm_component_utils(piso_sequencer)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass