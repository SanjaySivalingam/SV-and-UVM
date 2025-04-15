class piso_env extends uvm_env; 
    piso_agent agt;
    piso_scoreboard scb;
    piso_coverage cov;
    piso_virtual_sequencer vseqr;

    `uvm_component_utils(piso_env)

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agt = piso_agent::type_id::create("agt", this);
      scb = piso_scoreboard::type_id::create("scb", this);
      cov = piso_coverage::type_id::create("cov", this);
      vseqr = piso_virtual_sequencer::type_id::create("vseqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      agt.mon.ap.connect(scb.ap);
      agt.mon.ap.connect(cov.analysis_export); // monitor to subscriber
      //agt.mon.ap.connect(cov.fifo.analysis_export); // monitor to subscriber with fifo
      vseqr.piso_seqr = agt.seqr; // connect virtual sequencer to agent sequencer
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      `uvm_info("ENV", "Topology finalized", UVM_MEDIUM)
    endfunction
endclass