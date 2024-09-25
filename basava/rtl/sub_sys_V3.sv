// it is subsyestem  file 
// in this file we have 2 modules instatnitiated within it
//                     1. memory controller
//                     2. memory bank
// here the inputs are coming from testbench and then those are going to controller and the controller outputs are connected to the memory bank inputs 

//PARAMETERS :  D_W : DATA_WIDTH ( THE SIZE OF DATA IN EACH LOCATION in bits)  =8 (fixed)
      //        A_W : ADDRESS_WIDTH (Each memory location size in bits ) (varaible)
      //        R_W : RAM_WIDTH (DATA+ PARITY BITS)    =>8+4=12

 
// DATA_WIDTH (D_W)  :
// Data width is 8 bit (possible values are 0 t0 2**7)  maximum value of data is 127   :D_W =8(fixed)
// I fixed this data beacuse i have done encoding and decoding the data for 8 bits input data only.

// ADDRESS WIDTH(A_W):
// you can take any value of address bits as you want : A_W is variable 
// based on this value the memory depth will be created automatically 
// here I used n address bits in which 2 of MSB bits are used as a selection lines for selecting memory.
// (n-2) address bits are passed into memory    (2**n locations)


// ***note: avoid of using same address for write at same time for different ports

// some notations used in this code to decrese the varaible length in design
                   // c_m  : controller to memory
                   // m_c : memory  to controller 

// parameters for latency:
      //  WL_A :  Write latency of port A
      //  RL_A :  Read latency of port A
      //  WL_B :  Write latency of port B
      //  RL_B :  Read latency of port B

/* 
   Example USecase:
            _______________________________________________
            |   ____________           ____________   top |
            |  |            |         |            |      |
            |  | controller |<=======>|Memory_BANK |      |
            |  |            |         |            |      |
            |  |            |         |            |      |
            |  |            |         |            |      |
            |  |            |         |            |      |
            |  |____________|         |____________|      |
            |                                             |
            |_____________________________________________|

*/

//Note: *** when passing parameters you should confine D_W(DATA_WIDTH) to 8 and R_W(RAM_WIDTH) to 12 which are fixed in my design and used for
//          encoding and decoding the data
// You can pass any values to remaining parameters there is no restrictions.


module sub_system #(parameter D_W=8,A_W=6,R_W=12,
            parameter WL_A=3,RL_A=3,WL_B=3,RL_B=3)
 
//                                   PORT A              PORT B
           (input                    input_clkA,        input_clkB,       // input clock signals for PORT A and B       
            input                    input_enA,         input_enB,        // main enable signals for Port A and B
            input                    input_weA,         input_weB,        // Write enable signals for PORT A and B
            input      [D_W-1:0]     input_DinA,        input_DinB,       // input data signals for PORT A and B
            input      [A_W-1:0]     input_AddA,        input_AddB,       // input address signals for PORT A and B
            output reg [D_W-1:0]     final_Dout_A,      final_Dout_B      // output read data signals from PORT A and B 
           );

   wire [R_W-1:0]      c_m_DinA,c_m_DinB;                                 // input data from controller to memory bank 
   wire [A_W-1:0]      c_m_AddA,c_m_AddB;                                 // input address from controller to memory bank   
   wire                c_m_weA,c_m_weB;                                   // write enable signals from controller to memory bank 
   wire                c_m_enA,c_m_enB;                                   // enable signal from controller to memory bank
   wire                c_m_clkA,c_m_clkB;                                 // clock signals from controller to memory bank
   wire [R_W-1:0]      m_c_decoded_A,m_c_decoded_B;                       // It is the output data coming from memory(encoded data) so we have to decode this output
                                                                          //  act as input signal to decode(which is decoded to actual data in decoder)
                                                                          //  act as output signal from memory_bank. 
   
controller #(D_W,A_W,R_W,WL_A,RL_A,WL_B,RL_B) dut(.I_DinA(input_DinA),        
                                                  .I_DinB(input_DinB),
                                                  .I_AddA(input_AddA),    
                                                  .I_AddB(input_AddB),
                                                  .I_clkA(input_clkA),      
                                                  .I_clkB(input_clkB),
                                                  .I_enA(input_enA),        
                                                  .I_enB(input_enB),
                                                  .I_weA(input_weA),        
                                                  .I_weB(input_weB),
                                                  .OUT_Dout_A(final_Dout_A),
                                                  .OUT_Dout_B(final_Dout_B),
                                                  .O_DinA(c_m_DinA),       
                                                  .O_DinB(c_m_DinB),
                                                  .O_enA(c_m_enA),         
                                                  .O_enB(c_m_enB),
                                                  .O_weA(c_m_weA),
                                                  .O_weB(c_m_weB),
                                                  .O_clkA(c_m_clkA),
                                                  .O_clkB(c_m_clkB),
                                                  .O_AddA(c_m_AddA),
                                                  .O_AddB(c_m_AddB),
                                                  .decoded_input_A(m_c_decoded_A),
                                                  .decoded_input_B(m_c_decoded_B));


memory_bank  #(D_W,A_W,R_W,WL_A,RL_A,WL_B,RL_B) dut_bank(.i_DinA(c_m_DinA),
                                                         .i_DinB(c_m_DinB),
                                                         .i_AddA(c_m_AddA),
                                                         .i_AddB(c_m_AddB),
                                                         .i_clkA(c_m_clkA),
                                                         .i_clkB(c_m_clkB),
                                                         .i_enA(c_m_enA),
                                                         .i_enB(c_m_enB),
                                                         .i_weA(c_m_weA),
                                                         .i_weB(c_m_weB),
                                                         .O_Dout_A(m_c_decoded_A),
                                                         .O_Dout_B(m_c_decoded_B));
                                               


endmodule 
