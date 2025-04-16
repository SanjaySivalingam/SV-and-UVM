class piso_driver extends uvm_driver #(piso_seq_item);
    virtual piso_if vif;
    `uvm_component_utils(piso_driver)
  
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  
    function void build_phase(uvm_phase phase); // Retrieves vif
      super.build_phase(phase);
      if (!uvm_config_db#(virtual piso_if)::get(this, "", "vif", vif))
        `uvm_fatal("DRV", "No virtual interface set")
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      if (vif == null) `uvm_fatal("DRV", "Virtual interface not set")
    endfunction

    /*
    What happens if item_done is omitted?
      The sequencer would stall, as it waits for the driver to signal completion, potentially hanging the simulation.
    */
    task run_phase(uvm_phase phase); // Drives DUT signals
      piso_seq_item req;
      vif.cb.load <= 0;
      vif.cb.data_in <= 0;
      vif.cb.rst_n <= 0;
      @(vif.cb);
      vif.cb.rst_n <= 1;
      forever begin
        req = piso_seq_item::type_id::create("req");
        seq_item_port.get_next_item(req); // retrieves the next sequence item from the sequencer, blocking until available.
        @(vif.cb);
        vif.cb.rst_n <= req.rst_n;
        vif.cb.load <= req.load;
        vif.cb.data_in <= req.data_in;
        `uvm_info("DRV", $sformatf("Driving load=%b, data_in=%4b", req.load, req.data_in), UVM_MEDIUM)
        seq_item_port.item_done(); // signals completion, allowing the sequencer to send the next item, maintaining handshake integrity.
      end
    endtask
endclass
