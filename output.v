module output_scaling
  (
	input clk,reset,
    input inp_valid,
    input [2:0] k,
    input signed [15:0] rot_inp,
    output reg signed [15:0] out,
    output reg out_valid
);
  wire signed [15:0] rot_shifted;
  assign rot_shifted=rot_inp<<k; // left shifting by k
  
  // passing values to the register
  always@(posedge clk)
    if(reset)
      begin
        out_valid<=0;
        out<=0;
      end
    else
      begin
        out_valid<=inp_valid;
        if (inp_valid)
          out<=rot_shifted;
        else
          out<=0;
      end
  
endmodule
