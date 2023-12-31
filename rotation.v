module CORDIC_rotation(clk, reset, operands_val, out_valid, cos, sin, x_start, y_start, angle, ready, count_eq_15);

   // Inputs
   input clk;
   input reset;
   input operands_val;
   input signed [15:0] x_start, y_start;
   input signed [15:0] angle;

   // Outputs
   output signed [15:0] sin, cos;
   output out_valid;
   output reg count_eq_15;
   output ready; 
  
  localparam IDLE = 2'd0;
  localparam BUSY = 2'd1;
  localparam DONE = 2'd2;

   // Generate table of atan values
  reg signed [15:0] atan_out;
  reg signed [15:0] x_reg;
  reg signed [15:0] y_reg;
  reg signed [15:0] theta_reg;
        
  wire [15:0] x_mux_out, y_mux_out, theta_mux_out;
  reg [15:0] x_add_out, y_add_out, theta_add_out;
  
  reg [15:0] x_shift, y_shift;
  
  reg [3:0] count;
  wire [3:0] address; 
  reg [1:0] state, state_next; 
  wire count_en;
  
  assign address = count;
    
  // Look up table in 5.11 format 
  
  always @(*)
     begin
       case(address)
        4'd0:  atan_out = 'b0000011001001000 ;
        4'd1:  atan_out = 'b0000001110110110;  
        4'd2:  atan_out = 'b0000000111110110; 
        4'd3:  atan_out = 'b0000000011111111;
        4'd4:  atan_out = 'b0000000010000000 ;
        4'd5:  atan_out = 'b0000000001000000;
        4'd6:  atan_out = 'b0000000000100000;
        4'd7:  atan_out = 'b0000000000010000;
        4'd8:  atan_out = 'b0000000000001000;
        4'd9:  atan_out = 'b0000000000000100;
        4'd10: atan_out = 'b0000000000000010;
        4'd11: atan_out = 'b0000000000000001;
        4'd12: atan_out = 'b0000000000000000;
        4'd13: atan_out = 'b0000000000000000 ;
        4'd14: atan_out = 'b0000000000000000 ;
        4'd15: atan_out = 'b0000000000000000 ;  
       endcase    
   end              
          
     
  // 2:1 Multiplexers
         
 assign x_mux_out = (state == IDLE) ? x_start : x_add_out; 
 assign y_mux_out = (state == IDLE) ? y_start : y_add_out;
 assign theta_mux_out = (state == IDLE) ? angle : theta_add_out;   
 assign count_eq_15 = (count == 4'd15);
 assign out_valid = (state == DONE);
 assign count_en = (state == BUSY);
 assign ready = (state == IDLE);  
 assign cos = x_reg;
 assign sin = y_reg;  

  
 
//  Barrel Shifter
  always@(*)
    begin
      case(count)
        0: begin
          x_shift={x_reg[15:0]};
          y_shift={y_reg[15:0]};
           end
        1: begin
          x_shift={x_reg[15:1]};
          y_shift={y_reg[15:1]};
           end
        2: begin
          x_shift={x_reg[15:2]};
          y_shift={y_reg[15:2]};
           end
        3: begin
          x_shift={x_reg[15:3]};
          y_shift={y_reg[15:3]};
           end
        4: begin
          x_shift={x_reg[15:4]};
          y_shift={y_reg[15:4]};
           end
        5: begin
          x_shift={x_reg[15:5]};
          y_shift={y_reg[15:5]};
           end
        6: begin
          x_shift={x_reg[15:6]};
          y_shift={y_reg[15:6]};
           end
        7: begin
          x_shift={x_reg[15:7]};
          y_shift={y_reg[15:7]};
           end
        8: begin
          x_shift={x_reg[15:8]};
          y_shift={y_reg[15:8]};
           end
        9: begin
          x_shift={x_reg[15:9]};
          y_shift={y_reg[15:9]};
           end
        10: begin
          x_shift={x_reg[15:10]};
          y_shift={y_reg[15:10]};
           end
        11: begin
          x_shift={x_reg[15:11]};
          y_shift={y_reg[15:11]};
           end
        12: begin
          x_shift={x_reg[15:12]};
          y_shift={y_reg[15:12]};
           end
        13: begin
          x_shift={x_reg[15:13]};
          y_shift={y_reg[15:13]};
           end
        14: begin
          x_shift={x_reg[15:14]};
          y_shift={y_reg[15:14]};
           end
        15: begin
          x_shift={x_reg[15]};
          y_shift={y_reg[15]};
           end
      endcase
    end
    
 // add_out muxes   
 always @ (*)
   if (theta_reg[15] == 1)
      begin
        x_add_out = x_reg + y_shift;
        y_add_out = y_reg - x_shift;
        theta_add_out = theta_reg + atan_out;
       end   
      else
       begin
        x_add_out = x_reg - y_shift;
        y_add_out = y_reg + x_shift;
        theta_add_out = theta_reg - atan_out;
       end    
  
   // x and y reg 
   always @(posedge clk)
    if(reset)
      begin
      x_reg <= 0;
      y_reg <= 0;
      theta_reg <= 0;
      end
    else
      begin
       x_reg <= x_mux_out;
       y_reg <= y_mux_out;
       theta_reg <= theta_mux_out;
      end 
  
  
 always @(*)  
  begin
    
  case (state)
    IDLE :
      if (operands_val)
        state_next = BUSY;
      else
        state_next = IDLE;
                                                     
    BUSY :
      if (count_eq_15)
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
     
   always @(posedge clk)
     if(count_en)
      count <= count + 1;
    else
      count <= 0;
         
endmodule
