
// this part of the module will receive the data sent from the transmitter
// the clks per system can vary per baud rate and input system
module Uart_receiver #(parameter CLKs_Per_Bit=87)
(
    input i_clk, // input clk of the connected system
    input i_rx_serial,
    output o_rx_DV,
    output [7:0] o_rx_byte
);
parameter Idle= 3'b000;
parameter  Start=3'b001;
parameter Active=3'b010;
parameter Stop=3'b011;
// parameter Cleanup=3'b100;

reg r_rx_data_r; 
reg r_rx_data;

reg [$clog2(CLKs_Per_Bit):0]     r_Clock_Count = 0;

 
 
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [7:0]     r_Rx_Byte     = 0;
  reg           r_Rx_DV       = 0;
  reg [2:0]     r_SM_Main     = 3'b000;
  
always@(posedge i_clk) // this prevents the effects of metastability.
begin
r_rx_data_r <= i_rx_serial;
r_rx_data<=r_rx_data_r;
end

// write the state transition logic
always@(posedge i_clk)
begin
case(r_SM_Main)
Idle:
begin
r_Rx_DV <=1'b0;
r_Clock_Count =0;
r_Bit_Index <=0;

if(r_rx_data==1'b0)
r_SM_Main <= Start;
else
 r_SM_Main <=Idle;
end

Start:
begin
  // error handling for the start bit
    if(r_Clock_Count==(CLKs_Per_Bit-1)/2) 
    begin
    if(r_rx_data==1'b0 ) 
    begin
    r_Clock_Count <=0; 
        r_SM_Main <=Active;
 end
    else
    begin
           r_SM_Main <=Idle;
        end
    end 
    else
    begin
    r_Clock_Count<=r_Clock_Count +1'b1;
    end
end
    // note: we are sampling in the middle of bits here.
    // this is reduce sampling metastable states
Active:
    begin 
        // now each we sample after a full Clk_per_bit
        if(r_Clock_Count<=CLKs_Per_Bit-1)
        begin
            r_Clock_Count<=r_Clock_Count+1;
            r_SM_Main<= Active;
        end 
        else
        begin
        r_Rx_Byte[r_Bit_Index] <=r_rx_data; // give synchronised output 
        
        if(r_Bit_Index <7)
        begin 
         r_Bit_Index<=r_Bit_Index +1'b1;
         r_SM_Main<=Active;
        end 
        else
        begin
        r_Bit_Index <=0;
        r_SM_Main <= Stop;
        end 
        end
    end 
    
Stop: 
    begin
        if(r_Clock_Count<=CLKs_Per_Bit-1)
        begin
            r_Clock_Count<=r_Clock_Count+1;
            r_SM_Main<= Stop;
        end 
    else 
    begin
          r_Rx_DV   <=1'b1;
        r_Clock_Count <=0;
        r_SM_Main <= Idle;
    end 
    end

 default : r_SM_Main <= Idle;
          
endcase
end

        
  assign o_rx_DV   = r_Rx_DV;
  assign o_rx_Byte = r_Rx_Byte;
   
endmodule 
