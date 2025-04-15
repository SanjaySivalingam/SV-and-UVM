class piso_test extends piso_base_test;
    piso_virtual_sequence vseq;
  
    `uvm_component_utils(piso_test)
  
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    /*
    What’s uvm_test_top?
      uvm_test_top is the top-level test instance, like piso_test (named automatically by UVM). 
      A path like uvm_test_top.env.agt.seqr targets the sequencer for config or stimulus, ensuring precise control in UVM’s hierarchy.
    */

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      vseq = piso_virtual_sequence::type_id::create("vseq");

      uvm_config_db#(int)::set(this, "uvm_test_top.env.agt.seqr.*", "num_txns", 20); // stores num_txns=20 in the config_db, targeting the sequence instance. 

      // Type override example
      // uvm_factory::set_type_override_by_type(piso_seq_item::get_type(),extended_seq_item::get_type()); // deprecated
      //piso_seq_item::type_id::set_type_override(extended_seq_item::get_type());

      // Instance override example
      //uvm_factory::set_inst_override_by_type(piso_seq_item::get_type(),extended_seq_item::get_type(),"env.agt.seqr.*"); // deprecated
      piso_seq_item::type_id::set_inst_override(extended_seq_item::get_type(), "env.agt.seqr.*");
    endfunction
  
    task run_phase(uvm_phase phase);
      phase.raise_objection(this); // keeps the run_phase active
      vseq.start(env.vseqr);
      phase.phase_done.set_drain_time(this, 1000); // 1000ns -> to ensure simulation ends if objections linger. Prevents infinite runs due to testbench errors.
      phase.drop_objection(this); // ends the run_phase after sequence completes.
    endtask
endclass