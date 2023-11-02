`include "rotation.sv"
`include "vectoring.sv"
`include "input_scaling.sv"
`include "output_scaling.sv"

module cordic_division(
  input clk,reset,
  input operands_val,
  input signed [15:0] A,
  output signed [15:0] sqrt_x,
  output ready, sqrt_valid);
  
  reg[1:0] state, state_next;
  
  parameter width=16;
  
  //----------- Scaling x ------- / /
  wire signed [15:0] X_scaled;
  wire [2:0] k;
  wire scale_valid, shift_sig; // shift signal from scale module
  
  scale_num scale_num(
    .clk(clk),.reset(reset),.ack(sqrt_valid),
    .num(A),
    .inp_valid(operands_val),
    .X_scaled(X_scaled),
    .k(k),
    .out_valid(scale_valid), .ready(ready), .shift_sig(shift_sig)
  );
  //----------------------------//
  
  
  //-----------  2x-1 ---------//
  localparam signed val_1 = 16'hf800; //-1
  wire signed [15:0] x_2_1 = (X_scaled<<1) + val_1; //2x-1
  
  //---------------------------//
  
  
  // For vectoring mode
  wire beta_valid;
  wire signed [15:0] beta;
  wire vect_ready;
  wire count_eq_15;
  
  CORDIC_vectoring CORDIC_vectoring(
  	.clk(clk),.reset(reset),
    .operands_val(shift_sig),.out_valid(beta_valid),
    .A(x_2_1), .B(16'h04dc), 
    .theta(beta), .ready(vect_ready),.count_eq_15(count_eq_15)
  );
  
  // For rotation mode
  wire rot_ready;
  wire signed [15:0] rot_x_start=16'h04dc;
  wire signed [15:0] rot_y_start=16'h0;
  wire signed [15:0] rot_sin;
  wire rot_valid;
  wire count_2_eq_15;
  wire signed [15:0] rot_out;
  
  CORDIC_rotation CORDIC_rotation(
    .clk(clk),.reset(reset),
    .operands_val(count_eq_15),.out_valid(rot_valid),
    .cos(rot_out),.sin(rot_sin),
    .x_start(rot_x_start),.y_start(rot_y_start),
    // beta_2 should be put instead of beta
    .angle(beta>>>1),.ready(rot_ready), .count_eq_15(count_2_eq_15)
  );
  
  //------------------ Output scaling ---------------//
  
  output_scaling output_scaling(
    .clk(clk),.reset(reset),
    .inp_valid(count_2_eq_15),
    .k(k),
    .rot_inp(rot_out),
    .out(sqrt_x),
    .out_valid(sqrt_valid)
);
  
  //-------------------------------------------------//
  
  localparam IDLE = 2'd0;
  localparam BUSY = 2'd1;
  localparam DONE = 2'd2;
  
  assign ready = (state==IDLE);
  assign sqrt_valid = (state==DONE);
  
  always @(*)  
  begin
  // Default is to stay in the same state
                                                  
  case (state)
    IDLE :
      if (operands_val)
        state_next = BUSY;
      else
        state_next = IDLE;
                                                     
    BUSY :
      if (count_2_eq_15)
        state_next = DONE;
      else
        state_next = BUSY;
                                                    
    DONE :
        state_next = IDLE; 
    
  endcase
 end 
  
   always @(posedge clk)
    if(reset)
      state <= IDLE;
    else
      state <= state_next;
  
endmodule
