module scale_num(
  input clk,reset,ack,
  input signed [15:0] num,
  input inp_valid,
  output reg signed [15:0] X_scaled,
  output reg [2:0] k,
  output out_valid, ready, shift_sig
);
  
  localparam IDLE = 2'b00;
  localparam BUSY = 2'b01;
  localparam DONE = 2'b10;
  
  reg [1:0] state,next_state;
  
  assign out_valid = (state==DONE);
  assign ready = (state == IDLE);
  
  assign shift_sig = (X_scaled<=16'h066e) & (state==BUSY); // 066e is 0.80362
  										// i.e, 2x-1 <= 0.6072
  reg [1:0] mux_sig;
  
  wire signed [15:0] X_shift_2 = X_scaled>>>2; // right shift by 2
  
  reg signed [15:0] mux_out;
  reg [2:0] k_mux_out;//counter k
  
  always@(*)
    begin
      if(inp_valid)
        k_mux_out=0;
      else if(state==BUSY)
        begin
          if(!shift_sig)
            k_mux_out=k+1;
          else
            k_mux_out=k;
        end
    end
  
  // next_state
  always@(*)
    begin
      case(state)
        IDLE: 
          begin
            if(inp_valid) next_state=BUSY;
            else next_state=IDLE;
          end
        BUSY: 
          begin
            if(shift_sig)
              next_state=DONE;
          end
        DONE: 
          begin
            if (ack) next_state=IDLE;
            else next_state=DONE;
          end
      endcase
    end
  
  // x_scaled and k mux signals
  always@(*)
    begin
      case(state)
        IDLE: 
          mux_sig=0;
        BUSY:
          begin
            if(!shift_sig)
              mux_sig=1;
            else
              mux_sig=2;
          end
        DONE: 
          mux_sig=2;
      endcase
    end
    
  	// mux output
    always@(*)
      begin
        case(mux_sig)
          0: mux_out=num;
          1: mux_out= X_shift_2;
          2: mux_out=X_scaled; 
        endcase
      end
   
  // state assignment
   always@(posedge clk)
     begin
       if(reset)
         begin
           state<=IDLE;
           X_scaled<=0;
           k<=0;
         end
       else
         begin
           state<=next_state;
           X_scaled<=mux_out;
           k<=k_mux_out;
         end
     end
  
endmodule
  