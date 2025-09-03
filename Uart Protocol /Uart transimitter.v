 // the protocol is asynchronous in nature, instead of clocks-
 //- we will use something called Baud rate or Bits_per_second
 // the tranismission is can be done between any two transmitter 
 // or recievers

module uart_transmitter 
// a basic protocol used in old serial communication
#(parameter CLKs_Per_Bit) // baud rate is used to set bits per cycle of 
// of the input clk connected to the transmitter
(
    input i_tx_dv, // verification bit for transmitter to recieve a byte that is to be transmitted
    input i_clk, 
    input [7:0]i_tx_Byte,
    output   wire tx_active,
    output  reg tx_serial,
    output  reg tx_done,
);  
// Design the fsm
parameter Idle=3'b000,
          Start=3'b001,
          Send=3'b010,
          Stop=3'b011;
        //
// define all regs and wires

reg [2:0] r_sm_main=0; // the current state
reg  [$clog2(CLKs_Per_Bit):0] r_clk_count=0; // tracks the no of bits recieved
reg [2:0] Bit_index=0;
reg [7:0] r_tx_data=0; // datapath to track input to transmitter
// reg r_tx_done=0; // to display successfull transmisson of bits used in cleanup state cases
reg r_tx_active=0; // to show that the transmission has begin


always@(posedge i_clock)// next_state_logic
begin [2:0] 
    case(r_sm_main)
    Idle:
    begin
    tx_serial<=1'b1; // open the transmission line
    tx_done<=0;
    Bit_index<=0;
    r_clk_count<=0;
    if(i_tx_dv==1'b1) // when we recieve the verification bit
    begin 
    r_tx_data<=i_tx_Byte; // take the input byte
    r_sm_main<=Start; // change the state
    r_tx_active<=1'b1; // tell the reciever to be ready
    end 
    end 
    // send the zero bit and get ready for the rest
    Start:
    begin
        tx_serial<=0;
        if(r_clk_count< CLKs_Per_Bit-1)
        begin
          r_sm_main<=Start;
          r_clk_count<=r_clk_count+1;
        end 
        else
        begin 
        r_clk_count<=0;
        r_sm_main<=Send;
        end
      
    end 
    // send the least significant bit first.
    Send:
    begin 
         tx_serial<=r_tx_data[7-Bit_index];
        // we keep the bit same until it is properly recieved.
        if(r_clk_count< CLKs_Per_Bit-1)
            begin
                r_clk_count<=r_clk_count+1;
        r_sm_main<=Send; 
            end 
        else
        begin 
            if(Bit_index<7)
            begin
            Bit_index<=Bit_index+1;
            r_sm_main<=Send;
            end
            else
            begin
            r_sm_main<=Stop;
            Bit_index<=0;
            end 
        end
    end
    Stop:
    begin
        tx_serial<=1'b1;
    if(r_clk_count<=CLKs_Per_Bit-1)
    begin
        r_clk_count<=r_clk_count+1;
        r_sm_main<=Stop;
    end
    else
    begin
    tx_done<=1'b1;
    r_clk_count<=0;
    r_sm_main<= Idle;
    end 
    end
    // cleanup:
    // begin
    // r_tx_done<=1'b1;
    // r_sm_main<=1'b1;
    // end 
    default: r_sm_main<=Idle;
    // the clean up state is not necessary as generally used
    // we can instead use stop state. The cleanup code will be commented for the viewer
    endcase
end
assign tx_active <=r_tx_active;
// assign tx_done<=r_tx_done;

endmodule