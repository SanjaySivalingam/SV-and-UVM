class piso_corner_sequence extends piso_base_sequence;
  `uvm_object_utils(piso_corner_sequence)
  task body;
    piso_seq_item req = piso_seq_item::type_id::create("req");

    // Load 0
    start_item(req);
    req.rst_n = 1;
    req.load = 1;
    req.data_in = 4’b0000;
    finish_item(req);

    // Shift 4 times
    repeat (req.cfg.num_shifts) begin
      start_item(req);
      req.rst_n = 1;
      req.load = 0;
      finish_item(req);
    end

    // Load all 1s
    start_item(req);
    req.rst_n = 1;
    req.load = 1;
    req.data_in = 4’b1111;
    finish_item(req);
  endtask
endclass