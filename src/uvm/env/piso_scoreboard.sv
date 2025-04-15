class piso_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(piso_seq_item, piso_scoreboard) ap;

    bit [3:0] shift_reg = 4'b0;  // Expected shift register state intialized to 0
    bit rst_active = 0;
  
    `uvm_component_utils(piso_scoreboard)
  
    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
      super.start_of_simulation_phase(phase);
      shift_reg = 4’b0; // Reset model
    endfunction
  
    /* 
    What’s the role of write in a scoreboard?
      It receives transactions from monitors, compares actual vs. expected results, and logs errors, like verifying PISO’s data_out. 
    */

    function bit predictive_data_out(bit load, bit [3:0] data_in);
      if(load) return data_in[3];
      else return shift_reg[3];
    endfunction

    function void write(piso_seq_item txn); // processes transactions from analysis ports
      `uvm_info("SCB", $sformatf("Received: rst_n=%b, load=%b, data_in=%4b, data_out=%b", txn.rst_n, txn.load, txn.data_in, txn.data_out), UVM_MEDIUM)

      bit expected_data_out = predictive_data_out(txn.load, txn.data_in);

      if (!txn.rst_n) shift_reg = 4'b0;

      if (txn.data_out !== expected_data_out) `uvm_error("SCB", $sformatf("Load mismatch: Expected %b, Got %b", expected_data_out, txn.data_out))

      if (txn.load) shift_reg = txn.data_in;
      else shift_reg = {shift_reg[2:0], 1'b0};  // Shift left (can use queues to do all this logic too)
    endfunction

    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (shift_reg != 0)
        `uvm_warning("SCB", "Shift register not cleared")
    endfunction
endclass