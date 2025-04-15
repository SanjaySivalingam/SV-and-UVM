class piso_virtual_sequence extends uvm_sequence;
  `uvm_object_utils(piso_virtual_sequence)
  `uvm_declare_p_sequencer(piso_virtual_sequencer)

  piso_reset_sequence reset_seq;
  piso_load_shift_sequence load_shift_seq;
  piso_corner_sequence corner_seq;

  function new(string name = "piso_virtual_sequence");
      super.new(name);
  endfunction

  task body;
      `uvm_info("VSEQ", "Starting virtual sequence", UVM_LOW)
      // Reset
      reset_seq = piso_reset_sequence::type_id::create("reset_seq");
      reset_seq.start(p_sequencer.piso_seqr);

      // Load-shift
      load_shift_seq = piso_load_shift_sequence::type_id::create("load_shift_seq");
      load_shift_seq.num_txns = 10;
      load_shift_seq.start(p_sequencer.piso_seqr); //sub_sequence.start(target sequencer)

      // Corner cases
      corner_seq = piso_corner_sequence::type_id::create("corner_seq");
      corner_seq.start(p_sequencer.piso_seqr);

      // Concurrent reset during load-shift
      fork
          begin
              #($urandom_range(20, 50));
              reset_seq = piso_reset_sequence::type_id::create("reset_seq");
              reset_seq.start(p_sequencer.piso_seqr);
          end
          begin
              load_shift_seq = piso_load_shift_sequence::type_id::create("load_shift_seq");
              load_shift_seq.num_txns = 3;
              load_shift_seq.start(p_sequencer.piso_seqr);
          end
      join
  endtask
endclass