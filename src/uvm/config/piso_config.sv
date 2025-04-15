class piso_config extends uvm_object;
    int load_delay;          // Delay after load
    bit is_active = UVM_ACTIVE; // Agent activity
    int num_shifts = 4;      // Number of shifts per load
  
    `uvm_object_utils_begin(piso_config)
        `uvm_field_int(load_delay, UVM_ALL_ON)
        `uvm_field_int(is_active, UVM_ALL_ON)
        `uvm_field_int(num_shifts, UVM_ALL_ON)
    `uvm_object_utils_end
  
    function new(string name = "piso_config");
        super.new(name);
    endfunction
  
    function void do_copy(uvm_object rhs);
        piso_config tmp;
        super.do_copy(rhs);
        $cast(tmp, rhs);
        load_delay = tmp.load_delay;
        is_active = tmp.is_active;
        num_shifts = tmp.num_shifts;
    endfunction
endclass