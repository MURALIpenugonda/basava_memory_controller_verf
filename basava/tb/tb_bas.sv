// it is a testbench file
// in this module we instatntiated subsystem module file which is collection of controller and memory bank file.
// in this generating the all transactions and sending it to subsystem
// here i used 4 taks for four different operations 
                                  // writeA  :  write of port A
                                  // writeB  :  write of PORT B
                                  // readA   :  Read from PORT A
                                  // readB   :  read from PORT B

//PARAMETERS :  D_W : DATA_WIDTH ( THE SIZE OF DATA IN EACH LOCATION in bits)
      //        A_W : ADDRESS_WIDTH (Each memory location size in bits )
      //        R_W : RAM_WIDTH (DATA+ PARITY BITS)// 
      //        T1  : time period of clock A
      //        T2  : time period of clock B
// parameters for latency:
      //  WL_A :  Write latency of port A
      //  RL_A :  Read latency of port A
      //  WL_B :  Write latency of port B
      //  RL_B :  Read latency of port B



module tb_b;
   parameter         D_W=8, A_W=6,R_W=12;
   parameter         WL_A=3,RL_A=3,WL_B=3,RL_B=3;
   parameter         T1=4,T2=4; 
   reg               clkA = 'b0, clkB = 'b0;
   reg               enA  = 'b0, enB  = 'b0;
   reg               weA  = 'b0, weB  = 'b0;
   reg   [D_W-1:0]   DinA = 'b0, DinB = 'b0;
   reg   [A_W-1:0]   AddA = 'b0, AddB = 'b0;
   wire  [D_W-1:0]   DoutA,DoutB;

 //  Memory_Subsystem #(D_W,A_W,WL_A,RL_A,WL_B,RL_B) dut(.input_DinA(DinA),.input_DinB(DinB),.input_AddA(AddA),.input_AddB(AddB),
 //                   .input_clkA(clkA),.input_clkB(clkB),.input_enA(enA),.input_enB(enB),
 //                 .input_weA(weA),.input_weB(weB),.final_Dout_A(DoutA),.final_Dout_B(DoutB));
 //HARISH MEMORY SUB SYSTEM
 //Memory_Subsystem #(D_W,A_W,R_LTY,W_LTY) harish ({clkB,clkA},{DinB,DinA},{AddB,AddA},{enB,enA},{weB,weA},{DoutB,DoutA},{});


 // VINAY MEMORY SUBSYSTEM

 //memory_subsystem #(W_LTY,R_LTY,A_W) vinay (DinA,DinB,AddA,AddB,clkA,clkB,weA,weB,enA,enB,DoutA,DoutB,,,,); 


 // BASAVA sub_system

   sub_system #(D_W,A_W,R_W,WL_A,RL_A,WL_B,RL_B) dut(.input_DinA(DinA),
                                                      .input_DinB(DinB),
                                                      .input_AddA(AddA),
                                                      .input_AddB(AddB),
                                                      .input_clkA(clkA),
                                                      .input_clkB(clkB),
                                                      .input_enA(enA),
                                                      .input_enB(enB),
                                                      .input_weA(weA),
                                                      .input_weB(weB),
                                                      .final_Dout_A(DoutA),
                                                      .final_Dout_B(DoutB));


   always
         #(T1/2) clkA <=~clkA;
   always
         #(T2/2) clkB <=~clkB;
  

   initial begin
      enA='b0;
       #12;
       repeat(1)
       begin   
            //max_input();
      full_write();
      full_read();
      specific(1,35,120);  
      specific_W_and_R(25,125);  
      random_wr_rd_A();
      random_wr_rd_B();
      random_wr_rd_C();
      random_wr_rd_D();
                   
       end
   end

   
                                   
   task specific(bit w,bit [A_W-1:0] A,bit [D_W-1:0] D=0); // writing specific data in specific address or reading data from specific address
   weA=w;
   AddA=A;
   if(weA)    DinA=D;
   endtask

   task specific_W_and_R(bit [A_W-1:0] A,bit [D_W-1:0] D); // writing specific data in specific address or reading data from that specific address
   weA='b1;
   AddA=A;
   if(weA)    DinA=D;
   #(WL_A*T1);
   weA=0;
   #T1;
   endtask




   task full_write();              // writing the data in all locations of memory
      for(int i=0;i<64;i++)
      begin
         enA='b1;
         weA='b1;
         AddA=i;
         DinA=i;
         #T2;
      end
   endtask
   
   task full_read();              // reading the data in all locations of memory
      for(int j=0;j<64;j++)
      begin
         enA='b1;
         weA='b0;
         AddA=j;
         #T2; 
      end  
   endtask


   task random_wr_rd_A();         // writing the random data in random locations and reading thedata from random locations of memory with PORT A signal
      for(int i=0;i<200;i++)
      begin
         enA=$random();
         weA=$random();
         if(enA==1)               AddB=$urandom_range(0,(2**A_W)-1);
         if(enA==1 && weA==1)     DinA=$urandom();       
         #T1;
      end
   endtask
   
   task random_wr_rd_B();         // writing the random data in random locations and reading thedata from random locations of memory with PORT B signals
      for(int i=0;i<200;i++)
      begin
         enB=$random();
         weB=$random();
         if(enB==1)               AddB=$urandom_range(0,(2**A_W)-1);
         if(enB==1 && weB==1)     DinB=$urandom();
         #T2;
      end
   endtask


   task random_wr_rd_C();         // writing the random data in random locations and reading from same locations of memory with PORT B signals
      for(int i=0;i<200;i++)
      begin
         enB='b1;
         weB='b1;
         if(enB==1)               AddB=$urandom_range(0,(2**A_W)-1);
         if(enB==1 && weB==1)     DinB=$urandom();  
         #(WL_B*T2);
         weB=0;               
         #(T2);
         enB=0;
         #T2;
      end
   endtask


   task random_wr_rd_D();         // writing the random data in random locations and reading from same locations of memory with PORT A signals
      for(int i=0;i<200;i++)
      begin
         enA='b1;
         weA='b1;
         if(enA==1)               AddA=$urandom_range(0,(2**A_W)-1);
         if(enA==1 && weA==1)     DinA=$urandom();
         #(WL_A*T1);
         weA='b0;
         #(T1);
         enA=0;
         #T1;
     end
   endtask
 
   task max_input();              // it is the case in which the input is of all 1's (for covearge if any Dout bits are not covered)
      enA='b1;
      weA='b1;
      AddA=2**6;
      DinA=32'b11111111;  
      #T1;
      weA=0;
      #T1;
   endtask
   
     
  
     

  
   initial
   begin
      $monitor($time," datainA=%0d,datainB=%0d,AddressA=%0d,AddressB=%0d,enA=%0d,enB=%0d,weA=%0d,WeB=%0d,DataoutA=%0d,DataoutB=%0d",
                      DinA,DinB,AddA,AddB,enA,enB,weA,weB,DoutA,DoutB);
    
     // #3000 $finish;

   end
   
   initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
   end
endmodule



