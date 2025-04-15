//transaction class
class piso_seq_item extends uvm_sequence_item; 
    rand bit [3:0] data_in;
    rand bit       load;
    bit            data_out; //captured output
    bit            rst_n;
    piso_config    cfg; // Nested object (unnecessary in this example but useful in larger testbenches)
    rand bit [31:0] timestamp; // For debug, not compared

    constraint data_in_c { data_in dist {0:/10, 15:/10, [1:14]:/80}; }// Favor corner cases
    constraint reset_load_c { !rst_n -> load == 0; } // enforce assertion

  /*
  How do you ensure randomization covers all scenarios?
    I use constraints to bias inputs toward corner cases and collect functional coverage to verify all required patterns are hit.
  Performance Trade-off: Macros add overhead (e.g., memory for metadata). 
    For simple classes, manual methods might be faster, but macros ensure consistency in large testbenches. 
  How does the factory improve testbench flexibility?
    It allows overriding classes at runtime, so I can swap a generic sequence item with a specialized one for a specific test without changing the testbench structure.
  */

    `uvm_object_utils_begin(piso_seq_item) // registers the class with UVM factory
      `uvm_field_int(data_in, UVM_ALL_ON) // register class fields for built-in UVM operations (e.g., uvm_field_int creates a do_print method that formats data_in as a string)
      `uvm_field_int(load, UVM_ALL_ON) // int, object, string, array_int, sarray_int, real, queue_int
      `uvm_field_int(data_out, UVM_ALL_ON | UVM_NOCOMPARE) // UVM_ALL_ON, UVM_NO{PRINT|COPY|COMPARE}, (UVM_ALL_ON | UVM_NOPRINT)
      `uvm_field_int(timestamp, UVM_ALL_ON | UVM_NOCOMPARE) 
      `uvm_field_int(rst_n, UVM_ALL_ON | UVM_NOCOMPARE)
      `uvm_field_object(cfg, UVM_ALL_ON | UVM_DEEP) // Ensures nested objects are handled correctly (e.g., deep copied)
    `uvm_object_utils_end
  
    function new(string name = "piso_seq_item");
      super.new(name);
      cfg = piso_config::type_id::create("cfg"); // using the factory
      //cfg = new("cfg"); // using the new method
    endfunction

    //manual methods if avoiding macros
    // Modify to Handle nested objects.
    function void do_copy(uvm_object rhs); // Virtual method overridden from uvm_object. rhs: Generic source object to copy from.
        piso_seq_item tmp; // Declares a handle of type piso_seq_item for type-safe access.
        super.do_copy(rhs); // Calls parent’s do_copy (e.g., uvm_sequence_item) to copy base fields (e.g., m_name).
        $cast(tmp, rhs); // Converts rhs (type uvm_object) to tmp (type piso_seq_item). Ensures tmp.data_in is accessible.
        data_in = tmp.data_in; // Copies scalar field data_in.
        load = tmp.load; // Copies scalar field load.
        timestamp = tmp.timestamp;
        data_out = tmp.data_out;
        rst_n = tmp.rst_n;
        cfg = (tmp.cfg != null) ? piso_config::type_id::create("cfg") : null;
        if (cfg != null) cfg.copy(tmp.cfg); // Recursively copies tmp.sub_txn into sub_txn, ensuring deep copy.
    endfunction

    // Modify to change format (e.g., UVM_BIN for PISO). Example: Binary output for data_in.
    function void do_print(uvm_printer printer); // custom print method (Overrides default format (e.g., binary instead of hex))
        super.do_print(printer);
        printer.print_field("data_in", data_in, $bits(data_in), UVM_BIN);
        printer.print_field("load", load, 1, UVM_BIN);
        printer.print_field("data_out", data_out, 1, UVM_BIN);
    endfunction

    // Modify to skip fields (e.g., debug flags). Example: Compare only data_in.
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        piso_seq_item tmp;
        $cast(tmp, rhs);
        return (data_in == tmp.data_in && load == tmp.load);
    endfunction

    // Modify to change field order or format. Example: Pack data_in first.
    function void do_pack(uvm_packer packer); // uvm_packer ->(bitstream manager). Serializes for cross-language interfaces.
        super.do_pack(packer);
        packer.pack_field_int(data_in, $bits(data_in));
        packer.pack_field_int(load, 1);
    endfunction

    // Modify to match do_pack order. Example: Unpack load last.
    function void do_unpack(uvm_packer packer);
        super.do_unpack(packer);
        data_in = packer.unpack_field_int($bits(data_in)); // $bits() function returns the bit width of a variable or type.
        load = packer.unpack_field_int(1);
    endfunction

    // Modify to select fields for recording. Example: Record data_in only.
    function void do_record(uvm_recorder recorder);
        super.do_record(recorder);
        recorder.record_field("data_in", data_in, $bits(data_in), UVM_BIN);
        recorder.record_field("load", load, 1, UVM_BIN);
    endfunction
endclass

//extended transaction class to demonstrate overriding
class extended_seq_item extends piso_seq_item; 
    rand bit debug_flag;
    `uvm_object_utils(extended_seq_item)
    function new(string name = "extended_seq_item");
      super.new(name);
    endfunction
endclass