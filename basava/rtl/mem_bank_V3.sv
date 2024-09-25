// it is a memeory_bank file
// in this I instatintiated four modules (having 4 memories) inside it.

// DATA_WIDTH (D_W)  :
// Data width is 8 bit (possible values are 0 t0 2**7)  maximum value is 127   :D_W =8(fixed)
// I fixed this data beacuse i have done encoding and decoding the data for 8 bits input data only.

// ADDRESS WIDTH(A_W):
// you can take any value of address bits as you want : A_W is variable 
// based on this value the memory depth will be created automatically 
// here I used n address bits in which 2 of MSB bits are used as a selection lines for selecting memory.
// (n-2) address bits are passed into memory    (2**n locations)
//   let n=12 then 2 of the msb are used for memory selection and remaining 10 are used as address bits
//  ( 2**10 ==1024...  locations) and each location has 12 bit data
// 1.5 byte of data * 1024 locations== 1.5kB memory

// here I used enA1,enA2,enA3,enA4,enB1,enB2,enB3,enB4 to enable respetive memory based on MSB of Address bits from testbench
// here i used last 2 MSB bits to select the particular memory for respective operation
/* i.e  00: memory1 
        01: memory2
        10: memory3
        11: memory4 
 */

/* 
   Example USecase:   DPRAM: DUALPORT RAM
            _______________________________________________
            |                         memory_bank         |
            |   ____________           ____________       |    
            |  |            |         |            |      |
            |  |  DPRAM1    |         |  DPRAM2    |      |
            |  |____________|         |____________|      |
            |                                             |                                     |
            |   ____________           ____________       |    
            |  |            |         |            |      |
            |  |  DPRAM3    |         |  DPRAM4    |      |
            |  |____________|         |____________|      |
            |_____________________________________________|


*/






module memory_bank #(parameter D_W,A_W,R_W,WL_A,RL_A,WL_B,RL_B)
                   (input                    i_clkA,i_clkB,              //the clock signals of A and B
                    input                    i_enA,i_enB,                //are ENABLE signals
                    input                    i_weA,i_weB,                //WRITE ENABLE, READ enable signals to initiate the respetive operation
                    input      [R_W-1:0]     i_DinA,i_DinB,              // INPUT_DATA for respective ports
                    input      [A_W-1:0]     i_AddA,i_AddB,              // ADDRESS for respective ports
                    output reg [R_W-1:0]     O_Dout_A,O_Dout_B           // final output of controller 
                   );

                  
   reg   [3:0]            enA=1'b0;                                     //enabling specific memory based on enable of portA 
   reg   [3:0]            enB=1'b0;                                     //enabling specific memory based on enable of portB 
   reg   [R_W-1:0]        DoutA1[4];                                    //  OUTPUT FROM specific memory of PORT_A 
   reg   [R_W-1:0]        DoutB1[4];                                    //  OUTPUT FROM specific memory of PORT_B
   reg   [1:0]            T_i_AddA[RL_A:0];                             //temp register to store the MSBs of ADDR_A
   reg   [1:0]            T_i_AddB[RL_B:0];                             //temp register to store the MSBs of ADDR_B


// initialising the outputs to zero
 /*  initial begin
   for(int i=0;i<4;i++)
   begin
      DoutA1[i]<=0;
      DoutB1[i]<=0; task specific(bit w,bit [A_W-1:0] A,bit [D_W-1:0] D=0);
   end
   end
*/


   // enabling the respective memory based on MSB of i_AddA value

   always@(*)
   begin
      case(i_AddA[A_W-1:A_W-2])
         2'b00:
               begin
                  enA[0]                 = i_enA;
                  {enA[1],enA[2],enA[3]} = 'b0; 
               end  
         2'b01:
               begin
                  enA[1]                 = i_enA;
                  {enA[0],enA[2],enA[3]} = 'b0;  
               end
         2'b10:
               begin
                  enA[2]                 = i_enA;
                  {enA[1],enA[0],enA[3]} = 'b0;  
               end
         2'b11:
               begin
                  enA[3]                 = i_enA;
                  {enA[1],enA[0],enA[2]} = 'b0;  
               end
       endcase
   end


 // enabling the respective memory based on MSB of i_AddB value

   always@(*)
   begin
      case(i_AddB[A_W-1:A_W-2])
         2'b00:                                          
               begin
                  enB[0]                 = i_enB;
                  {enB[1],enB[2],enB[3]} = 'b0; 
               end  
         2'b01:
               begin
                  enB[1]                 = i_enB;
                  {enB[0],enB[2],enB[3]} = 'b0;  
               end
         2'b10:
               begin
                  enB[2]                 = i_enB;
                  {enB[1],enB[0],enB[3]} = 'b0;  
               end
         2'b11:
               begin
                  enB[3]                 = i_enB;
                  {enB[1],enB[0],enB[2]} = 'b0;  
               end
      endcase
   end



// instantiation of 4 modules (4 RAM's) 
   generate
   genvar i;
      for(i=0;i<4;i++)
      begin
        dual_port #(D_W,A_W,R_W,WL_A,RL_A,WL_B,RL_B) dut_mem1(.in_Din_A(i_DinA),
                                                              .in_Din_B(i_DinB),
                                                              .in_Addr_A(i_AddA[A_W-3:0]),
                                                              .in_Addr_B(i_AddB[A_W-3:0]),
                                                              .in_clkA(i_clkA),
                                                              .in_clkB(i_clkB),
                                                              .in_enA(enA[i]),
                                                              .in_enB(enB[i]),
                                                              .in_weA(i_weA),
                                                              .in_weB(i_weB),
                                                              .o_Dout_a(DoutA1[i]),
                                                              .o_Dout_b(DoutB1[i]));
     
      end
   endgenerate


// OUTPUT DECODER OF PORT A 
 // Storing the address values for getting the output after latency (respective read operation address) 
   always@(posedge i_clkA)
   begin
      if(i_enA && !i_weA)              T_i_AddA[0] <= i_AddA[A_W-1:A_W-2];
 
      for(int i=1;i<=RL_A-1;i++)       T_i_AddA[i] <= T_i_AddA[i-1];
   end

   always@(*)                            
   begin
      case( T_i_AddA[RL_A-1])              // taking the output value based selecting the respective MSB's of addreses 
           2'b00:
                 O_Dout_A = DoutA1[0];
           2'b01:
                 O_Dout_A = DoutA1[1];
           2'b10:
                 O_Dout_A = DoutA1[2];
           2'b11:
                 O_Dout_A = DoutA1[3];
      endcase    
   end

 // OUTPUT DECODER OF PORT A 
 // Storing the address values for getting the output after latency  (respective read operation address) 
   always@(posedge i_clkB)
   begin
      if(i_enB && !i_weB)              T_i_AddB[0] <= i_AddB[A_W-1:A_W-2];
       
      for(int i=1;i<=RL_B-1;i++)       T_i_AddB[i] <= T_i_AddB[i-1];
   end         

   always@(*)
   begin
      case(T_i_AddB[RL_B-1])           // taking the output value based selecting the respective MSB's of addreses 
         2'b00:
                O_Dout_B = DoutB1[0];
         2'b01:
                O_Dout_B = DoutB1[1];
         2'b10:
                O_Dout_B = DoutB1[2];
         2'b11:
                O_Dout_B = DoutB1[3];
      endcase    
   end

endmodule

