// it is a classbased testbench file 

// pacakge

package pack;
   typedef enum bit[1:0] {NO_OPER = 0, READ = 1, WRITE = 3} operation;
   typedef enum bit {PORT_A,PORT_B} port_sel;
   parameter T1=4,T2=6,D_W=8,A_W=5,R_W=12,WL_A=3,RL_A=3,WL_B=3,RL_B=3;
endpackage

// importing package

import pack::*;

// Transaction class

class transaction ;
   rand   reg       [D_W-1:0]   Data,Dout='b0;     // Data: input data  Dout: output data
   rand   reg       [A_W-1:0]   Addr;              // Address
   randc  operation             opr;               // operation
   rand   port_sel              port;              // port

   // constraints:
  
   //  constraint c1{Addr inside{[0:15]};}   // constraint for address A and B 
   //  constraint c2{opr == 'b01;}
   //  constraint c3{port == PORT_A;}
   //  constraint c4{Data==Addr;}

   // copy method   
   function transaction copy();
      copy        =   new();   
      copy.Data   =   this.Data;
      copy.Dout   =   this.Dout;
      copy.Addr   =   this.Addr;
      copy.opr    =   this.opr;
      copy.port   =   this.port;
   endfunction
   // input display   
   function void display(string name);
      $display($time,"\t\t\t\t%s Data=%d,Addr=%d operation=%s port_name=%s",name,Data,Addr,opr,port);
   endfunction

   // output display
   function void display2(string name); 
      $display($time,"\t\t\t\t%s Dout=%d port=%s",name,Dout,port);
   endfunction  

   // Address display where the read starts
   function void display3(string name);
      $display($time,"\t\t\t\t%s Address=%d port=%s",name,Addr,port);
   endfunction 
endclass


//Generator class

class generator;
  rand transaction tr;       // transaction  
  mailbox gdmbx;             // mailbox
  event ev1;                 // event
  virtual intf vif;          // virtual interface

  int gen_data;

  function new(mailbox gdmbx);
     tr         =  new();
     this.gdmbx =  gdmbx;
  endfunction

  // genereting the random packets
  task run();
  fork
    forever
    begin
     gdmbx.get(gen_data);
     //integer i=1;
     //repeat(50)
     if(gen_data)
     begin
        //$display("\t\t %d th time Randomization in generator",i);
        tr.randomize();// with {enA==1;weA==0;enB==0;weB==1;};         
        gdmbx.put(tr.copy);
        tr.display("GENERATOR");
        //$display("port=%d",tr.port);
        //i=i+1;
        //@ev1;
     end
     end
  join_none
  endtask

endclass

//Driver class

class driver ;
  transaction tr;           // transaction handle
  mailbox gdmbx;            // GENERATOR to DRIVER mailbox
  event ev1,ev2;
  virtual intf vif;         // VIRTUAL INTERFACE
  
  function new(mailbox gdmbx);
    this.gdmbx = gdmbx;
  endfunction

  task run();
    integer i=0,j=0;
    forever     
    begin
      gdmbx.put(1);
      gdmbx.get(tr);      
    fork     
    
     // THREAD 1 
      begin
         @(negedge vif.clkA);  
 
         if(tr.port == PORT_A && tr.opr == WRITE)
         begin                  
            vif.DinA   <=   tr.Data;
            vif.AddA   <=   tr.Addr;
            vif.weA    <=   'b1;
            vif.enA    <=   'b1;
            tr.display("DRV A WR at"); 
         end
         if(tr.port == PORT_A && tr.opr == READ)
         begin
            vif.enA    <=   'b1;
            vif.weA    <=   'b0; 
            vif.AddA   <=   tr.Addr;
            tr.display3("DRIVER A read operation at"); 
         end

         if(tr.port == PORT_A && tr.opr == NO_OPER)
         begin
            vif.enA    <=   'b0;
            tr.display("DRIVER A");
         end

      end
      
    // THREAD 2 
      begin
        @(negedge vif.clkB);
        if(tr.port == PORT_B && tr.opr == WRITE )
        begin     
           vif.DinB    <=   tr.Data;
           vif.AddB    <=   tr.Addr;
           vif.weB     <=   'b1;
           vif.enB     <=   'b1;
           tr.display("DRV A WR at"); 
        end

        if(tr.port == PORT_B && tr.opr == READ)
        begin
           vif.enB <= 'b1;
           vif.weB  <= 'b0; 
           vif.AddB <= tr.Addr;
           tr.display3(" DRIVER B read operation at");
        end

        if(tr.port == PORT_B && tr.opr == NO_OPER)
        begin
           vif.enB <= 'b0;
           tr.display("DRIVER B");
        end
      end
    join
    
    ->ev1;
    end
  endtask
endclass

// MONITOR CLASS

class monitor;

   reg           T_weA     [WL_A-1:0];             // temporary registers to store the write and read enables
   reg           T_reA     [RL_A-1:0];             // i used these values for the sending the data into scoreboard after latency 
   reg           T_weB     [WL_B-1:0];   
   reg           T_reB     [RL_B-1:0];

   transaction tr2,tr3,tr4;
   mailbox mrmbx,msmbxA,msmbxB;                    // mailboxes mr: MON to REF         ms: MON to SCO
   event mse1,mse2;                                // events   mse1,mse2: events used in monitor and scoreboard
   virtual intf vif;                               // virtual interface

   function new(mailbox mrmbx,msmbxA,msmbxB);
      tr2           =  new();
      tr3           =  new();
      tr4           =  new();
      this.mrmbx    =  mrmbx;
      this.msmbxA   =  msmbxA;
      this.msmbxB   =  msmbxB;
   endfunction



   task run1();

      fork 
         begin
            @(posedge vif.clkA);
            if(vif.enA)
            begin
               T_weA[0] = vif.weA;
               T_reA[0] = !vif.weA;
               //$display("%d %p",vif.weA,T_weA);
            end
            for(int i=1;i<=WL_A;i++)             T_weA[i]  <=  T_weA[i-1];                 // shifting write enable signal 
            for(int j=1;j<=RL_A;j++)             T_reA[j]  <=  T_reA[j-1];
         end
         
         begin
            @(posedge vif.clkB);
               if(vif.enB)
               begin
               T_weB[0] = vif.weB;
               T_reB[0] = !vif.weB;
               end 
            for(int k=1;k<=WL_B;k++)             T_weB[k]  <=  T_weB[k-1];                 // shifting write enable signal             
            for(int l=1;l<=RL_B;l++)             T_reB[l]  <=  T_reB[l-1];
         end 

      join
   endtask
  

   // task for sending the data intpo reference model and score board

   task  run2();
      // sending the data into reference model  

      if(T_weA[0])                         // when write starts it will exucute
         begin
            tr2.Data = vif.DinA;
            tr2.Addr = vif.AddA;
            tr2.port = PORT_A;
            tr2.opr  = WRITE; 
            mrmbx.put(tr2.copy);            
            if($test$plusargs("DEBUG"))    tr2.display("MON_A: WRITE..........");
         end  

       // port A read

      if(!T_weA[0])                        // when read starts it will exucute
         begin
            tr2.Addr = vif.AddA;
            tr2.Dout = vif.DoutA;
            tr2.port = PORT_A;
            tr2.opr  = READ;
            mrmbx.put(tr2.copy);
            if($test$plusargs("DEBUG"))    tr2.display3("MON_A to ref READ....");
            //$display("!weA=%p",!T_weA);
            end
      
      
      //port B write
    
     
      if(T_weB[0])                         // when write starts it will exucute
         begin
            tr2.Data = vif.DinB;
            tr2.Addr = vif.AddB;
            tr2.port = PORT_B;
            tr2.opr  = WRITE;
            mrmbx.put(tr2.copy);   
            if($test$plusargs("DEBUG"))    tr2.display("MON_B: WRITE..........");
         end

      // port B read

      if(!T_weB[0])                        // when read starts then it will exucute 
         begin
            tr2.Addr  = vif.AddB;
            tr2.Dout = vif.DoutB;
            tr2.port =PORT_B;
            tr2.opr =READ;
            mrmbx.put(tr2.copy);
            if($test$plusargs("DEBUG"))    tr2.display3("MON_B: READ and put in reference.......");
         end

      //scoreboard

       if(!T_weA[RL_A-1])                  // after latency of port A read it will exucute
         begin
            //@(posedge vif.clkA);
            tr3.Addr  = vif.AddA;
            tr3.Dout = vif.DoutA;
            tr3.port=PORT_A;
            tr3.opr =READ;
            msmbxA.put(tr3.copy);
            -> mse1;
            if($test$plusargs("DEBUG"))
                begin
                   $display($time,"\t\t\t\ttrigered at mon AAA");
                   tr3.display2("MON_A to sco and putting in monitor");            
                end
            end

      if(!T_weB[RL_B-1])                   // after latency of port B read it will exucute
         begin
            tr4.Addr = vif.AddB;
            tr4.Dout = vif.DoutB;
            tr4.port = PORT_B;
            tr4.opr  = READ;
            msmbxB.put(tr4.copy);
            -> mse2;
            if($test$plusargs("DEBUG"))
                begin
                   $display($time,"\t\t\t\ttrigered at mon BBB");
                   tr4.display2("MON_B to sco and putting in monitor");            
                end
         end
    
   endtask


   task run();
         forever
         begin
             fork
                 run1();
                 run2();
             join
         end
   endtask  
endclass

// fucntional coverage class
class func_coverage;
  
  transaction cov_pkt;
  
  covergroup coverage;
    ADDR  : coverpoint cov_pkt.Addr{  option.auto_bin_max = 20;}
    DATA  : coverpoint cov_pkt.Data{  option.auto_bin_max = 20;}
    DOUT  : coverpoint cov_pkt.Dout{  option.auto_bin_max = 20;}
    PORT  : coverpoint cov_pkt.port;
    WRITE : coverpoint cov_pkt.opr{   bins WR = WRITE;}
    READ  : coverpoint cov_pkt.opr{   bins RD = READ;}
    WRITE_ADDR_X_DATA_X_PORT : cross WRITE,ADDR,DATA,PORT;
    READ_ADDR_X_DATA_X_PORT  : cross READ,ADDR,DATA,PORT;
  endgroup

  function new();
    cov_pkt   = new();
    coverage  = new();
  endfunction

endclass : func_coverage

// reference model

class ref_model ;
   reg [D_W-1:0] mem[(2**(A_W)-1):0];           // MEMORY IN REFERENCE MODEL
   transaction tr2,trA,trB;                     // TRANSACTION CLASS HANDLES
   virtual intf vif;                            // virtual interface
   mailbox mrmbx,rsmbxA,rsmbxB;                 // mailboxes used

   //function coverage class decalaration.
   func_coverage covh;

   //event decalaration for 100% functional coverage triggering.
   event cov_done;

   function new(mailbox mrmbx,rsmbxA,rsmbxB);
      trA          =  new();
      trB          =  new();
      this.mrmbx   =  mrmbx;
      this.rsmbxA  =  rsmbxA;
      this.rsmbxB  =  rsmbxB;
      covh         =  new();
   endfunction
  

   task run();
      //for(integer i=0;i<64;i++) mem[i] = 0;     // initialising the memory
      forever
      begin
         mrmbx.get(tr2);
         trA.port = PORT_A;
         trB.port = PORT_B;
 
         if($test$plusargs("DEBUG"))
         begin
            if(tr2.opr == WRITE)         tr2.display("referrence_WRITE_Started");
            if(tr2.opr == READ)          tr2.display3("reference_READ_Started at address..................");
         end

         fork
      // Thread 1
            begin
               if(tr2.port == PORT_A && tr2.opr == WRITE)  begin
                                                               // $display("1111111");
                                                               mem[tr2.Addr]  <= #(T1*(WL_A-1)) tr2.Data; 
                                                           end
                                                        
            end
      // Thread 2
            begin 	  
               if(tr2.port == PORT_A && tr2.opr == READ)   begin
                                                               trA.Dout     <= #(T1*(RL_A-1)) mem[tr2.Addr];
                                                               trA.port     <= #(T1*(RL_A-1)) PORT_A;
                                                               trA.opr      <= #(T1*(RL_A-1)) READ;
                                                               trA.Addr     <= #(T1*(RL_A-1)) tr2.Addr;
                                                               rsmbxA.put(trA);
                                                               //trA.display2("in ref_read_A output");
                                                           end
            end
      // Thread 3
            begin
               if(tr2.port == PORT_B && tr2.opr == WRITE)  begin
                                                               // $display("2222222");
                                                               mem[tr2.Addr]  <= #(T2*(WL_B-1)) tr2.Data; 
                                                               //$display("data writing to meomory---------mem[%h] = %h",tr2.Addr,mem[tr2.Addr]);
                                                           end
  	  
            end
      // Thread 4
            begin
               if(tr2.port == PORT_B && tr2.opr == READ)   begin
                                                               trB.Dout     <= #(T2*(RL_B-1)) mem[tr2.Addr];
                                                               trB.port     <= #(T2*(RL_B-1)) PORT_B;
                                                               trB.opr      <= #(T2*(RL_B-1)) READ;
                                                               trB.Addr     <= #(T2*(RL_B-1)) tr2.Addr;
                                                               rsmbxB.put(trB);
                                                               //trB.display2("in ref_read_B output");
                                                           end
            end

          join

          if(tr2.opr  == WRITE)
          begin
            covh.cov_pkt  = tr2;
            //$display("Time: %0t",$time);
            //foreach(mem[i]) $write("--mem[%h] = %h--",i,mem[i]);
            //$display("");
          end
          else if(tr2.opr == READ)
          begin
            if(tr2.port == PORT_A)   covh.cov_pkt  = trA;
            if(tr2.port == PORT_B)   covh.cov_pkt  = trB;
          end
          covh.coverage.sample();
          if(covh.coverage.get_coverage == 100) ->cov_done;
          $display("*********************************************************************************coverage = %0f",covh.coverage.get_coverage());
            
          /*
          if($test$plusargs("DEBUG"))
              begin
                 if(tr2.Dout == trA.Dout) $display("in reference model the out from reference and scoreboard is same AAA");
                 if(tr2.Dout == trB.Dout) $display("in reference model the out from reference and scoreboard is same BBB");
              end
          */             
            
      end
   endtask



endclass


// score board 

class scoreboard;
   mailbox rsmbxA,rsmbxB,msmbxA,msmbxB;    // mailboxes used
   transaction trA,trB,tr5,tr6;            // transaction class handles
   event mse1,mse2;                        // events used

   function new(mailbox rsmbxA,rsmbxB,msmbxA,msmbxB);
      trA           =   new();
      trB           =   new();
      tr5           =   new();
      tr6           =   new();
      this.rsmbxA   =   rsmbxA;            //reference to scoreboard mailbox
      this.rsmbxB   =   rsmbxB;
      this.msmbxA   =   msmbxA;            // monitor to scoreboard mailbox
      this.msmbxB   =   msmbxB;
   endfunction


   // task for comparing the data from port A

   task  compareA();
     @mse1;
     // wait(mse1.triggered);
      rsmbxA.get(trA);
      msmbxA.get(tr5);
      if($test$plusargs("DEBUG"))
         begin
            trA.display2("REF_to_SCO getting the info in scoreboard from PORT A");
            tr5.display2("MON_to_SCO getting the info in scoreboard from PORT A");
            //$display($time,"mon to sco AAA");
         end 
            
      if(trA.port === tr5.port)
         begin
            if(trA.Dout === tr5.Dout)  $display("[SCO]...................................................................................................NO ERROR");
         
            if(trA.Dout !== tr5.Dout)  $display("[SCO] .........................................................error because the expexted and actual is not same");
            
            trA.display2("reference  output from port A");
            tr5.display2("scoreboard output from port A");
            $display("\t\t\t\t*************** comparison ended ****************");

         end

      //else
         //$display("[SCO]error due to mismatch in the either ports or in operation");
       
   endtask

   // task for comparing the data from port B

   task  compareB();
      @ mse2;
      //wait(mse2.triggered);
      rsmbxB.get(trB);
      msmbxB.get(tr6);
      if($test$plusargs("DEBUG"))
         begin
            trB.display2("REF_to_SCO getting the info in scoreboard from port B");
            tr6.display2("MON_to_SCO getting the info in scoreboard from port B");
            //$display($time,"mon to sco BBB");
         end
            
      if(trB.port === tr6.port)
         begin
            if(trB.Dout === tr6.Dout)  $display("[SCO]...................................................................................................NO ERROR");
       
            if(trB.Dout !== tr6.Dout)  $display("[SCO] .........................................................error because the expexted and actual is not same");
          
            trB.display2("reference  output from port B");
            tr6.display2("scoreboard output from port B");
            $display("\t\t\t\t ************** comparison ended ****************");

      end

      //else
           //$display("[SCO]error due to mismatch in the either ports or in operation");
            
         
   endtask

    
   task run;
      fork
         forever compareA();
         forever compareB();
      join
   endtask

endclass

// environment class

class environment ;
   integer i=0;
   generator gen;
   driver  drv;
   monitor mon;
   ref_model  rfr;
   scoreboard sco;
   event event1,event2,event3;
   mailbox gdmbx,mrmbx,msmbxA,msmbxB,rsmbxA,rsmbxB;     //mailboxes used
   
   virtual intf vif;
   function new(virtual intf vif);
     gdmbx = new();
     msmbxA = new();
     msmbxB =new();
     rsmbxA = new();
     rsmbxB = new();
     mrmbx = new();
     gen = new(gdmbx);
     drv = new(gdmbx);  
     mon = new(mrmbx,msmbxA,msmbxB); 
     rfr = new(mrmbx,rsmbxA,rsmbxB);
     sco = new(rsmbxA,rsmbxB,msmbxA,msmbxB);
     this.vif=vif;
     gen.vif = vif;
     drv.vif = vif;
     mon.vif = vif;
     rfr.vif = vif;
     //gen.ev1 = event1;
     //drv.ev1 = event1;
     //drv.ev2 = event2;
     mon.mse1 = event2;
     sco.mse1 = event2;
     mon.mse2 = event3;
     sco.mse2 = event3;
     //$display("RLA=%d",RL_A);
   endfunction

     task turn();
        //for(i=0;i<32;i++) 
        //  begin
        //       vif.DinA <= i;
        //       vif.AddA <= i;
        //       vif.weA  <= 'b1;
        //       vif.enA  <= 'b1; 
        //       //$display("gjj"); 
        //       #T1;
        //  end
        //for(i=0;i<32;i++) 
        //  begin
        //       vif.DinA <= i;
        //       vif.AddA <= i;
        //       vif.weA  <= 'b0;
        //       vif.enA  <= 'b1; 
        //       //$display("gjj"); 
        //       #T1;
        //  end
          vif.enA =0;
          #10;
          fork
          run();
          /*  Added task for functional coverage*/
          stop();
          join_any
     endtask
     
     task run();
     fork
        gen.run();
        drv.run();
        mon.run();
        rfr.run();
        sco.run();
        join
     endtask

     task stop;
      $display("STOP_TASK started");
      wait(rfr.cov_done.triggered);
      $display("STOP_TASK ended");
      //$finish;
      //$display("Functional Covergae = %0f",rfr.covh.coverage.get_coverage());
     endtask : stop

endclass


// top module

module top;
   //parameter T1=4,T2=6,D_W=8,A_W=5,R_W=12,WL_A=3,RL_A=3,WL_B=3,RL_B=3;
   intf inf();
   environment env;
   always #(T1/2) inf.clkA = ~inf.clkA;
   always #(T2/2) inf.clkB = ~inf.clkB;
   initial begin
      inf.clkA = 'b0;
      inf.clkB = 'b0;
      env=new(inf);
      read_data_retrieve();
      env.turn();
      $stop;
   end
   initial begin
      //#1000 $finish;
   end
   sub_system #(D_W,A_W,R_W,WL_A,RL_A,WL_B,RL_B) dut(
                                                      .input_clkA(inf.clkA),
                                                      .input_clkB(inf.clkB),
                                                      .input_enA(inf.enA),
                                                      .input_enB(inf.enB),
                                                      .input_weA(inf.weA),
                                                      .input_weB(inf.weB),
                                                      .input_DinA(inf.DinA),
                                                      .input_DinB(inf.DinB),
                                                      .input_AddA(inf.AddA),
                                                      .input_AddB(inf.AddB),
                                                      .final_Dout_A(inf.DoutA),
                                                      .final_Dout_B(inf.DoutB));

  logic [D_W-1:0] ref_dout[2];
  //logic [D_W-1:0] ref_mem[2**A_W];

  assign inf.errorA = '0;
  assign inf.errorB = '0;

  task read_data_retrieve;
  begin
    fork
      forever
      begin
        @(posedge inf.clkA);
        if(inf.enA && (!inf.weA)) begin
          ref_dout[PORT_A]  = env.rfr.mem[inf.AddA];
          //ref_mem[inf.AddA] = ref_dout[PORT_A];
        end
        //else                      ref_dout[PORT_A] = '0;
      end
      forever
      begin
        @(posedge inf.clkB);
        if(inf.enB && (!inf.weB)) begin
          ref_dout[PORT_B]  = env.rfr.mem[inf.AddB];
          //ref_mem[inf.AddB] = ref_dout[PORT_B];
        end
        //else                      ref_dout[PORT_B] = '0;
      end
    join_none
  end
  endtask : read_data_retrieve

	//This concurrent assertion is used to verify whether the dut is performing the read as like an reference model or not. The assertion will be start
	//whever a read data is monitored at the ports. Since there are two ports, each of the port having the seperate assertion.
  property porta_rd_check;
    logic [D_W-1:0] r_douta;
    @(posedge inf.clkA)  ((inf.enA && !inf.weA) ##(RL_A) (~inf.errorA)) |-> (inf.DoutA === $past(ref_dout[PORT_A],RL_A-1));
  endproperty
                                                                                                              
	property portb_rd_check;
    logic [D_W-1:0] r_doutb;
    @(posedge inf.clkB)  ((inf.enB && !inf.weB) ##(RL_B) (~inf.errorB)) |-> (inf.DoutB === $past(ref_dout[PORT_B],RL_B-1));
	endproperty

	//Asserting the properties porta_rd_check,portb_rd_check to monitor the functionality of the multibank memory controller.
	PORTA_RD_CHECK: assert property(porta_rd_check)
										//$info("RD_CHECK ASSERION FOR PORT A is Success at %0t ns",$time);
									else $error("RD_CHECK ASSERION FOR PORT A is Failed at %0t ns",$time);
	
	PORTB_RD_CHECK: assert property(portb_rd_check)
										//$info("RD_CHECK ASSERION FOR PORT B is Success at %0t ns",$time);
									else $error("RD_CHECK ASSERION FOR PORT B is Failed at %0t ns",$time);
	
	PORTA_RD_COV  : cover property(porta_rd_check);
	PORTB_RD_COV  : cover property(portb_rd_check);

endmodule

interface intf;
   reg clkA,clkB;
   reg weA,weB;
   reg enA,enB;
   reg [D_W-1:0]  DinA,DinB;
   reg [A_W-1:0] AddA,AddB;
   reg [D_W-1:0]  DoutA,DoutB;
   reg errorA,errorB;
endinterface



