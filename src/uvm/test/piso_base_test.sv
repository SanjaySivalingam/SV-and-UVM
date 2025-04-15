import uvm_pkg::*;
import piso_pkg::*;

class piso_base_test extends uvm_test;
    piso_env env;
    piso_config cfg;

    `uvm_component_utils(piso_base_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = piso_env::type_id::create("env", this);
        cfg = piso_config::type_id::create("cfg");

        cfg.load_delay = 5;
        cfg.is_active = UVM_ACTIVE;
        cfg.num_shifts = 4;

        uvm_config_db#(piso_config)::set(this, "env.agt", "cfg", cfg);
    endfunction
    
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
endclass