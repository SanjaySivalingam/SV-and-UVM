class piso_stress_test extends piso_base_test;
    `uvm_component_utils(piso_stress_test)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    task run_phase(uvm_phase phase);
        piso_virtual_sequence vseq = piso_virtual_sequence::type_id::create("vseq");
        phase.raise_objection(this);
        vseq.load_shift_seq.num_txns = 100;
        vseq.start(env.vseqr);
        phase.drop_objection(this);
    endtask
endclass