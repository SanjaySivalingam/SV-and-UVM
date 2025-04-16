class piso_load_shift_sequence extends piso_base_sequence; 
    `uvm_object_utils(piso_load_shift_sequence)
  
    int num_txns = 10; // parameterized repeat count

    function new(string name = "piso_load_shift_sequence");
      super.new(name);
      if (!uvm_config_db#(int)::get(null, "uvm_test_top.env.agt.seqr", "num_txns", num_txns)) // retrieves num_txns from the config_db
        `uvm_info("SEQ", $sformatf("Using default num_txns=%0d", num_txns), UVM_MEDIUM)
        //`uvm_warning("SEQ", "num_txns not set, defaulting to 10") 
    endfunction
  
    task pre_body; // Override pre_body to send a reset transaction before the main sequence. (also done in piso_reset_sequence)
      piso_seq_item req = piso_seq_item::type_id::create("req");
      start_item(req);
      req.load = 0; req.data_in = 0;
      finish_item(req);
    endtask
  
  /*
  always create a fresh instance for every transaction (instead of creating in new()) to avoid race conditions, 
  state contamination, concurrency issues and improve flexibility
  */  
    task body;
      piso_seq_item req;
      repeat (num_txns) begin
        // Load cycle
        req = piso_seq_item::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { load == 1; rst_n == 1; }) 
          `uvm_error("SEQ", "Randomization failed")
        req.timestamp = $time;
        finish_item(req);
        #req.cfg.load_delay;

        // Shift cycles
        repeat (req.cfg.num_shifts) begin
          req = piso_seq_item::type_id::create("req");
          start_item(req);
          if (!req.randomize() with { load == 0; rst_n == 1; })
            `uvm_error("SEQ", "Randomization failed")
          req.timestamp = $time;
          finish_item(req);
        end
      end
    endtask
endclass