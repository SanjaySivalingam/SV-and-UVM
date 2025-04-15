class piso_monitor extends uvm_monitor;
    virtual piso_if vif;
    uvm_analysis_port #(piso_seq_item) ap;
      
    `uvm_component_utils(piso_monitor)

    /*
    How does a monitor support reactive testing? 
      It captures DUT activity and sends transactions to components like scoreboards, which react by checking or updating coverage, enabling dynamic verification.
    */

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction
  
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual piso_if)::get(this, "", "vif", vif))
        `uvm_fatal("MON", "No virtual interface set")
    endfunction
  
    /* 
    Why create txn in run_phase?
      It’s created dynamically to capture or generate transactions during simulation, like sampling PISO signals in the monitor.
    */

    task run_phase(uvm_phase phase);
      piso_seq_item txn;
      // Wait for initial reset
      @(vif.cb iff vif.cb.rst_n);
      forever begin
        @(vif.cb);
        txn = piso_seq_item::type_id::create("txn");
        txn.rst_n = vif.cb.rst_n;
        txn.load = vif.cb.load;
        txn.data_in = vif.cb.data_in;
        txn.data_out = vif.cb.data_out;
        ap.write(txn);
        `uvm_info("MON", $sformatf("Sampled load=%b, data_in=%4b, data_out=%b", txn.load, txn.data_in, txn.data_out), UVM_MEDIUM)
      end
    endtask
endclass