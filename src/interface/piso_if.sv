interface piso_if (input logic clk);
    logic rst_n, load;
    logic [3:0] data_in;
    logic data_out;

    /* 
    How do clocking blocks prevent race conditions?
      They synchronize testbench operations to the clock, ensuring inputs to the DUT are driven before the DUT samples them and 
      outputs are sampled after the DUT updates, eliminating timing conflicts. 
    Why use #1step for inputs?
      #1step samples inputs at the clock edge and makes them visible immediately in the Reactive region, 
      ideal for synchronous DUTs like PISO, ensuring the monitor sees data_out without delay.
    */    
    clocking cb @(posedge clk);
      output rst_n, load, data_in; //drive at clock edge ( if delay mentioned, drive after delay)
      input  #1step data_out; // sample at the clock edge, visible at t=0ns (reactive region)
    endclocking

    /* 
    How do assertions complement UVM? 
      Assertions provide low-level, cycle-accurate checks in the interface, while UVM handles high-level transaction verification, 
      creating a layered verification strategy.
    */
    property no_simultaneous_rst_load;
        @(cb) !rst_n |-> !load; // Reset and load cannot occur simultaneously
    endproperty
    property data_out_reset;
      @(cb) !rst_n |-> data_out == 0;
    endproperty
    property stable_during_load;
      @(cb) load |-> ##1 $stable(data_out);
    endproperty

    assert property(no_simultaneous_rst_load) else $error("Reset and load active simultaneously");
    assert property(data_out_reset) else $error("data_out non-zero during reset");
    assert property(stable_during_load) else $error("data_out not stable during load");

    /* 
    Why use modports instead of raw signals?
      Modports provide a contract between modules, ensuring correct signal directions and reducing errors in complex testbenches with multiple components.
    */
    modport dut (input clk, rst_n, load, data_in, output data_out);
endinterface