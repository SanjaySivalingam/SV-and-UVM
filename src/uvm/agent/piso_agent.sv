class piso_agent extends uvm_agent;
    piso_driver drv;
    piso_monitor mon;

    uvm_sequencer#(piso_seq_item) seqr;
    piso_config cfg;

    `uvm_component_utils(piso_agent)

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(piso_config)::get(this, "", "cfg", cfg))
        `uvm_fatal("AGT", "No config set")
      is_active = cfg.is_active;
      mon = piso_monitor::type_id::create("mon", this);
      if (is_active == UVM_ACTIVE) begin
        drv = piso_driver::type_id::create("drv", this);
        seqr = uvm_sequencer#(piso_seq_item)::type_id::create("seqr", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      if (is_active == UVM_ACTIVE)
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass