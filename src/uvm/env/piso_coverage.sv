class piso_coverage extends uvm_subscriber #(piso_seq_item);

  //uvm_tlm_analysis_fifo #(piso_seq_item) fifo; //when using tlm fifo
  piso_seq_item txn;

  /*
  BTS
  uvm_analysis_export #(T) analysis_export;
  local uvm_analysis_imp #(T, this_type) analysis_imp;
  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    analysis_imp = new("analysis_imp", this);
  endfunction
  virtual function void write(T t); endfunction
  */

  covergroup cg; // can also be in the monitor
    load: coverpoint txn.load { 
      bins load_on = {1}; 
      bins load_off = {0}; 
    }
    data_in: coverpoint txn.data_in {
      bins zeros = {0};
      bins ones = {15};
      bins others = {[1:14]};
    }
    data_out: coverpoint txn.data_out { 
      bins zero = {0}; 
      bins one = {1}; 
    }
    transition_data: coverpoint txn.data_in {
      bins trans_0_to_15 = (0 => 15);
    }
    rst_n: coverpoint txn.rst_n { 
      bins active = {0}; 
      bins inactive = {1}; 
    }
    data_out_trans: coverpoint txn.data_out { 
      bins zero_to_one = (0 => 1); 
    }
    load_data: cross load, data_in; // cross ensures verification of interdependent signals
    reset_load: cross rst_n, load;
  endcovergroup

  `uvm_component_utils(piso_coverage)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    //fifo = new("fifo", this, 10); // when using tlm fifo, 10 to set depth, default -> unlimited
    cg = new; // covergroups are instantiated with new() (no arguments) or new without parentheses.
  endfunction

  function void write(piso_seq_item txn); // mon.ap.write(txn) triggers cov.write. Non-blocking, allowing parallel processing.
    this.txn = txn; // to make txn available to cg's coverpoints, since cg references class members, not the write argument.
    cg.sample();
    `uvm_info("COV", $sformatf("Sampled load=%b, data_in=%4b, data_out=%b", txn.load, txn.data_in, txn.data_out), UVM_MEDIUM)
  endfunction

  /* // when using fifo
  //Monitor’s ap.write(txn) fills fifo.
  //cov retrieves via fifo.get

  task run_phase(uvm_phase phase);
    piso_seq_item txn;
    forever begin
      if(fifo.can_get())
        fifo.get(txn); // blocking get
        cg.sample();
      end else begin
        bit success;
        success = fifo.try_get(txn); // non-blocking get
        if (success) cg.sample();
        else @(vif.cb); // wait if fifo is empty
      end
    end
  endtask 
  */
endclass