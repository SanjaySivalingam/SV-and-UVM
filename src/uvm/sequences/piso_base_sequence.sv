//create generic sequences independent of tb to reuse them across tests and objects.
class piso_base_sequence extends uvm_sequence #(piso_seq_item);
  `uvm_object_utils(piso_base_sequence)
  function new(string name = "piso_base_sequence");
    super.new(name);
  endfunction
  virtual task body;
    `uvm_fatal("SEQ", "Base sequence body not overridden")
  endtask
endclass