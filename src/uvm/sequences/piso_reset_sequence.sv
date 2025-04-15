class piso_reset_sequence extends piso_base_sequence;
  `uvm_object_utils(piso_reset_sequence)
  function new(string name = "piso_reset_sequence");
    super.new(name);
  endfunction
  task body;
    piso_seq_item req = piso_seq_item::type_id::create("req");
    start_item(req);
    req.rst_n = 0;
    req.load = 0;
    req.data_in = 0;
    finish_item(req);
    #($urandom_range(2, 8));

    // Deassert reset
    start_item(req);
    req.rst_n = 1;
    req.load = 0;
    req.data_in = 0;
    finish_item(req);
  endtask
endclass