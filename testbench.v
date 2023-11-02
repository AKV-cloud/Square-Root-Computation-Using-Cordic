module SQRT_tb;
  
  reg signed [15:0] A;
  reg operands_val;
  reg reset;
  reg clk;
  wire sqrt_valid, ready;
  
  wire signed [15:0] sqrt_x;

  localparam SF = 2.0**-11.0;  // scaling factor is 2^-14
  
  // Instantiate the Unit Under Test (UUT)
  cordic_division div_mod  (.operands_val(operands_val),
                            .A(A),
                            .clk(clk),
                            .reset(reset),
                            .sqrt_valid(sqrt_valid),
                            .sqrt_x(sqrt_x),
                            .ready(ready)
                           );

 
  // Clock generation
  
  always #5 clk = ~clk;
 
  
  // Driving Stimulus 
  
    initial 
    begin 
      drive_reset();     
          
      drive_input(16'h04dc); // a is 0.6
      check_output(); // outp should be 0.7745 (2*0.6-1, cosin(..),theta/2, cos(theta/2))
      
      drive_input(16'h0600); // a is 0.75
      check_output(); // outp should be 0.8366
      
      drive_input(16'h10cd); // a is 2.1
      check_output(); // outp should be 1.45
      
      drive_input(16'h199a); // a is 3.2
      check_output(); // outp should be 1.78
      
      drive_input(16'h4348); // a is 8.41
      check_output(); // outp should be 2.9
      
      drive_input(16'h4800); // a is 9
      check_output(); // outp should be 3
      
      drive_input(16'h5800); // a is 11
      check_output(); // outp should be 3.31
      
      drive_input(16'h6200); // a is 12.25
      check_output(); // outp should be 3.5
  
      repeat(5)@(negedge clk)     
     $finish;
    end
    
  task drive_reset();
    $display ("Driving the reset");
    clk = 1'b0;
    @ (negedge clk)
    reset = 0;
    @ (negedge clk)
    reset = 1;
    @ (negedge clk)
    reset = 0;
  endtask 
  
  task drive_input(input signed [15:0] a);
   
    wait (ready == 1)
       $display ("Received the ready signal and driving the Input");    
       @ (negedge clk)  
        operands_val = 1;
        A = a;
        @ (negedge clk)
        operands_val = 0;
   endtask 
  
  
  task check_output();
    @ (posedge sqrt_valid)
    $display ("Recieved Output Valid");
    $display("(%f) = %f ", $itor(A * SF), $itor(sqrt_x * SF));      
      
  endtask   
      
   initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0);
   end
  
  	
  
endmodule
