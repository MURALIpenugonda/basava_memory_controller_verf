                                               // DUALPORT : (DPRAM)
 // it is dual_port RAM file :
     
  //        IT ALLOWS MULTIPLE READS AND WRITES AT THE SAME TIME,UNLIKE SINGLEPORT RAM WHICH ALLOWS ONLY ONE ACCESS AT A TIME. 
  //        Here i used registers to store the data until the latency completed
  //        my design will work for any latency(0,1,2....)
  //        The data stored in memory is encoded data(data_bits + parity_bits)
  //        The data is going out from memory is decoded data(data_bits)

//all the Temp signals are used to store the respective information at a the specific time and stores upto latency period
// note: memory initialistion: value= index 

// in this module we have 4 operaations 
                   //   write operation PORT  A
                   //   write operation of PORT B
                   //   READ operation of PORT A
                   //   READ operation of PORT B

//PARAMETERS :  D_W : DATA_WIDTH ( THE SIZE OF DATA IN EACH LOCATION in bits)
      //        A_W : ADDRESS_WIDTH (Each memory location size in bits )
      //        R_W : RAM_WIDTH (DATA+ PARITY BITS)

// parameters for latency:
      //  WL_A :  Write latency of port A
      //  RL_A :  Read latency of port A
      //  WL_B :  Write latency of port B
      //  RL_B :  Read latency of port B


//        WLA :  Write latency of port A
      //  RLA :  Read latency of port A
      //  WLB :  Write latency of port B
      //  RLB :  Read latency of port B

//note:
// local parameters used (previosly i Designed my design latency as number of clock cycles but then I come  known that it is actually no of sampling edges)
//                            so i did not change my entire code and I made use of localparam for same opearation
                              // i.e : As previosly 2 latency means the opearation after 2 clock cycles which is at 3rd posedge(so actual latency=3) 
                              //  I made use of local parameter and made -1 to the main latency parameters and assign to local parameters
//                                (so if the latency 2 then output at 2nd edge or after 1 cycle)


module dual_port #( parameter D_W,A_W,R_W=12,
                    parameter WL_A,RL_A,WL_B,RL_B)
                   (input                           in_clkA,in_clkB,      //the clock signals of A and B
                    input                           in_enA,in_enB,        //are ENABLE signals
                    input                           in_weA,in_weB,        //WRITE ENABLE, READ enable signals to initiate the respetive operation
                    input      [R_W-1:0]            in_Din_A,in_Din_B,    // INPUT_DATA for respective ports
                    input      [A_W-3:0]            in_Addr_A,in_Addr_B,  // ADDRESS for respective ports
                    output reg [R_W-1:0]            o_Dout_a,o_Dout_b     //output of memory after decode
                   );

   localparam    WLA=WL_A-1, RLA=RL_A-1, WLB=WL_B-1, RLB=RL_B-1;          // local parameters
   reg [R_W-1:0] mem[(2**(A_W-2)-1):0];   // memory 

   // TEMPORORY REGISTERS TO STORE THE DATA AND ADDRESSE UPTO LATENCY
   reg [R_W-1:0] T_w_data_A [WLA-1:0];                                    // temp register for storing the INPUT data_A upto latency             
   reg [R_W-1:0] T_r_data_A [RLA-1:0];                                    // temp register for storing the OUTPUT data_A upto latency  
   reg [R_W-1:0] T_w_data_B [WLB-1:0];                                    // temp register for storing the INPUT data_B upto latency 
   reg [R_W-1:0] T_r_data_B [RLB-1:0];                                    // temp register for storing the OUTPUT DATA_A data upto latency 
   reg [R_W-1:0] T_addr_A   [WLA-1:0];                                    // temp ADDRESS_A register to store the address upto latency cycles
   reg [R_W-1:0] T_addr_B   [WLB-1:0];                                    // temp ADDRESS_B register to store the address upto latency cycles
   bit           T_weA      [WLA-1:0];                                    // temp registers to store write enable upto latency of port A
   bit           T_reA      [RLA-1:0];                                    // temp registers to store read enable upto latency of port A
   bit           T_weB      [WLB-1:0];                                    // temp registers to store write enable upto latency of port B 
   bit           T_reB      [RLB-1:0];                                    // temp registers to store read enable upto latency of port B     
   

   initial 
   begin 
      for(int i=0;i<WLA;i++)
      begin
         T_w_data_A[i] <= 'b0;
         T_w_data_B[i] <= 'b0;
         T_r_data_A[i] <= 'b0;
         T_r_data_B[i] <= 'b0;
         T_addr_A[i]   <= 'b0;
         T_addr_B[i]   <= 'b0;
       //  #1 T_r_data_A[RLA-1]=11;

      end
   end


  //MEMORY INITIALSATION
   initial begin
     // for(int i=0;i<2**(A_W-2);i++)   
       //  mem[i]=i;
   end
  // initial        //initilization memory
      // $readmemh("memory.sv",mem); 

   //PORT_A WRITE OPERTAION WITH LATENCY OF WLA

   always@(posedge in_clkA)
   begin 
      if(in_enA)
      begin
         T_weA[0]                 <=  in_weA;                     // storing the write enable signal          
         if(WLA==0 && in_weA)   
            mem[in_Addr_A]        <=  in_Din_A;                   // if latency is 1 and write operation then it will excute
         else if(in_weA)                                   
         begin
            T_w_data_A[0]         <=  in_Din_A;                   // storing the address and data in temporary[0] 
            T_addr_A[0]           <=  in_Addr_A; 
         end
      end  
      if(!in_enA)   T_weA[0]      <=  'b0;                        // if enable is low then made T_weA=0, whatever value of main weA it will ignore it  

      // IF LATENCY>=2  
      for(int i=1;i<WLA;i++)
      begin
          T_w_data_A[i]           <=  T_w_data_A[i-1];            // shifting data and address upto latency from one register to another for every one clock cycle
          T_addr_A[i]             <=  T_addr_A[i-1]; 
          T_weA[i]                <=  T_weA[i-1];                 // shifting write enable signal 
      end 
      if(T_weA[WLA-1])    
          mem[T_addr_A[WLA-1]]    <=  T_w_data_A[WLA-1];          // writing data into memory after latency
   end

 // PORT A READ OPERATION WITH LATENCY OF RLA
   always@(posedge in_clkA)
   begin
      if(in_enA)      
      begin
         T_reA[0]                 <=  !in_weA  ;  
         if(RLA==0 && !in_weA)
            o_Dout_a              <=  mem[in_Addr_A];             //if latency is 1 then it will excute
         else       T_r_data_A[0] <=  mem[in_Addr_A];             // storing the output data in temporary [0]     
      end
      // IF LATENCY>=2
      for(int i=1;i<RLA;i++)       
      begin
          T_r_data_A[i]           <=   T_r_data_A[i-1];           // shifting read data upto latency from one register to another for every one clock cycle
          T_reA[i]                <=   T_reA[i-1];                // shifting READ ENABLE  signal
      end
      if(T_reA[RLA-1])   
          o_Dout_a                <=   T_r_data_A[RLA-1];         //shifting data and address upto latency from one register to another for every one clock cycle
   end    
  
     
   //PORT_B WRITE OPERTAION WITH LATENCY OF WLB

   always@(posedge in_clkB)
   begin   
      if(in_enB)
      begin
         T_weB[0]                 <=   in_weB;                    // storing the write enable signal 
         if(WLB==0 && in_weB)    
            mem[in_Addr_B]        <=   in_Din_B;                  // if latency is 1 and write operation then it will excute
         else
         begin
            T_w_data_B[0]         <=   in_Din_B;                  // storing the address and data in temporary[0] 
            T_addr_B[0]           <=   in_Addr_B;
         end                          
      end  
      if(!in_enB)   T_weB[0]      <=   'b0;                       // if enable is zero then made T_weB[0]=0 so no opeartion is started.

      // IF LATENCY>=2  
      for(int i=1;i<WLB;i++)
      begin
         T_w_data_B[i]            <=   T_w_data_B[i-1];           // shifting data and address upto latency from one register to another for every one clock cycle
         T_addr_B[i]              <=   T_addr_B[i-1];
         T_weB[i]                 <=   T_weB[i-1];                // shifting write enable signal
      end   
      if(T_weB[WLB-1])                                            // writing data into memory after latency
         mem[T_addr_B[WLB-1]]     <=   T_w_data_B[WLB-1];  
   end

   //PORT_B READ OPERTAION WITH LATENCY OF RLB

   always@(posedge in_clkB)
   begin
      if(in_enB)      
      begin
         T_reB[0]                 <=   !in_weB  ;                 // storing the read enable signal
         if(RLB==0) o_Dout_b      <=   mem[in_Addr_B];            //if latency is 1 then it will excute
         else       T_r_data_B[0] <=   mem[in_Addr_B];            // storing the output data in temporary varable[0]  
      end

      // IF LATENCY>=2 
      for(int i=1;i<RLB;i++)       
      begin
          T_r_data_B[i]           <=   T_r_data_B[i-1];           // shifting output read data upto latency for every clock cycle
          T_reB[i]                <=   T_reB[i-1];                // shifting  READ ENABLE signal
      end
      if(T_reB[RLB-1])   
          o_Dout_b                <=   T_r_data_B[RLB-1];         // shifting data and address upto latency from one register to another for every one clock cycle
   end   
  
endmodule     

