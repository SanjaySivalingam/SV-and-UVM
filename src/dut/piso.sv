module piso #
  (parameter WIDTH = 4)(
    input  logic        clk,      // Clock
    input  logic        rst_n,    // Active-low reset
    input  logic        load,     // Load parallel data
    input  logic [WIDTH-1:0]  data_in,  // 4-bit parallel input
    output logic        data_out  // Serial output
  );
    logic [WIDTH-1:0] shift_reg;
  
  /*
  How do you verify an async reset?
    I apply reset at random intervals, including mid-cycle, and check that registers clear instantly 
    and recover correctly, using assertions and coverage to confirm behavior.
  */

    always_ff @(posedge clk or negedge rst_n) begin //async reset -> Ensures the reset works regardless of clock state, critical for robust designs.
      if (!rst_n) begin
        shift_reg <= 4'b0;
        data_out  <= 1'b0;
      end
      else if (load) begin
        shift_reg <= data_in;     // Load parallel data
        data_out  <= data_in[WIDTH-1];  // MSB out first
      end
      else begin
        shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};  // Shift left
        data_out  <= shift_reg[WIDTH-1];            // Output MSB
      end
    end
    assert property (@(posedge clk) load |=> data_out == $past(data_in[3])) else
      $error("Load output mismatch");
    /*
    //Option 2: Immediate check with #1step
      assert property (@(posedge clk) load |-> ##0 data_out == data_in[3] #1step)
      else $error("Load output mismatch");

      //##0 ensures immediate evaluation, but #1step shifts sampling to post-NBA.
      //Less common, as it requires precise timing control.
    */
endmodule