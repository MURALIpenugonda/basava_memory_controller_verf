// it is a memory control file... 
// in this we have hamming encoder and hamming decoder modules
// for this (controller) the inputs are coming from top module and output are driven into memory bank

//PARAMETERS :  D_W : DATA_WIDTH ( THE SIZE OF DATA IN EACH LOCATION in bits) =8 (fixed)
      //        A_W : ADDRESS_WIDTH (Each memory location size in bits )
      //        R_W : RAM_WIDTH (DATA+ PARITY BITS)=> 8+4=12
// ***note: avoid of using same address for write at same time for different ports

// parameters for latency:
      //  WL_A :  Write latency of port A
      //  RL_A :  Read latency of port A
      //  WL_B :  Write latency of port B
      //  RL_B :  Read latency of port B
 


module controller #(parameter D_W,A_W,R_W,
                    parameter WL_A,RL_A,WL_B,RL_B)

                   (input                    I_clkA,I_clkB,                   //the clock signals of A and B
                    input                    I_enA,I_enB,                     //are ENABLE signals
                    input                    I_weA,I_weB,                     //WRITE ENABLE, READ enable signals to initiate the respetive operation
                    input      [D_W-1:0]     I_DinA,I_DinB,                   // INPUT_DATA for respective ports
                    input      [A_W-1:0]     I_AddA,I_AddB,                   // ADDRESS for respective ports
                    input      [R_W-1:0]     decoded_input_A,decoded_input_B, // output data from memory  
                    output reg [D_W-1:0]     OUT_Dout_A,OUT_Dout_B ,          // final output of controller
                    output                   O_clkA,O_clkB,                   //  output of clock A,B from controller
                    output                   O_enA,O_enB,                     //  output of enable A,B from controller
                    output                   O_weA,O_weB,                     //  output of write_enable A,B from controller
                    output     [R_W-1:0]     O_DinA,O_DinB,                   //  output of data input A,B from controller
                    output     [A_W-1:0]     O_AddA,O_AddB                    //  output of address input A,B from controller 
                   );

// here we are passing the same values by using wires from one module to another
// these signals are not changed before and after passing throgh this design  (this module i.e controller)
   assign O_clkA  =  I_clkA;
   assign O_clkB  =  I_clkB;
   assign O_enA   =  I_enA; 
   assign O_enB   =  I_enB;
   assign O_weA   =  I_weA; 
   assign O_weB   =  I_weB;
   assign O_AddA  =  I_AddA; 
   assign O_AddB  =  I_AddB;

// instantiation of hamming encoder and hamming decoders

   en_code dutin_enA(.data(I_DinA),.encoded_data(O_DinA));
   en_code dutin_enB(.data(I_DinB),.encoded_data(O_DinB));
   de_code dutdeA(.Dout(decoded_input_A),.decoded_data(OUT_Dout_A));
   de_code dutdeB(.Dout(decoded_input_B),.decoded_data(OUT_Dout_B));

endmodule

