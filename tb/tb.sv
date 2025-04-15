module tb;
    import uvm_pkg::*;
    import piso_pkg::*;
    `include "uvm_macros.svh"

    logic clk = 0;
    piso_if intf (.clk(clk));

    piso dut (
      .clk(clk),
      .rst_n(intf.rst_n),
      .load(intf.load),
      .data_in(intf.data_in),
      .data_out(intf.data_out)
    );

    always #5 clk = ~clk;  // 10ns period

    initial begin
      uvm_config_db#(virtual piso_if)::set(null, "*", "vif", intf);
      run_test("piso_test");
      $display("DUT instantiated: %m");
    end

    initial begin
      $dumpfile("piso.vcd");
      $dumpvars(0, tb);
    end
endmodule