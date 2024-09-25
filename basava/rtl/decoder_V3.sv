// It is a DECODER file
// it is only work for the encoded data of 12 bits (the data width after reading from memory should be = 12)

// here the input is from the output of read values from respective ports of 12 bits from memory(Dout=Dout_AFTER_LATENCY)
// the output of the this is 8 bit of DATA which is the ACTUAL OUTPUT from the memory to controller
// temp_decoded is used for correcting the code if any error from the memory(any 1 bit change due tosome circumstances)
// place is used for checking the error
//      if    place==0  no error
//      else  toggle the respective bit (place-1) to get the corrected output




module de_code(input      [11:0] Dout,
               output reg [7:0]  decoded_data
              );
   bit[11:0] temp_decode;
   bit[3:0]  place;

   // to get the place value for to check the getted value is correct or not 

   always@(Dout)
   begin
      place[0]=Dout[0]^Dout[2]^Dout[4]^Dout[6]^Dout[8]^Dout[10];
      place[1]=Dout[1]^Dout[2]^Dout[5]^Dout[6]^Dout[9]^Dout[10];
      place[2]=Dout[3]^Dout[4]^Dout[5]^Dout[6]^Dout[11];
      place[3]=Dout[7]^Dout[8]^Dout[9]^Dout[10]^Dout[11];
   end

   always@(*)
   begin
      if(place==0)
      begin
         decoded_data[0]=Dout[2];
         decoded_data[3:1]=Dout[6:4]; 
         decoded_data[7:4]=Dout[11:8];
        // $display("decoded directly %b",decoded_data);
        // $display("decoded=%b D=%b",place,place-1);
      end
    
      // here we doing error_correcting...
      if ($test$plusargs("INJECT_ERROR"))
      begin
      $display("ERROR IDENTIFIED");
      if(place!=0)
         begin
            temp_decode=Dout;
            temp_decode[place-1]=~temp_decode[place-1];
            decoded_data[0]=temp_decode[2];
            decoded_data[3:1]=temp_decode[6:4];  
            decoded_data[7:4]=temp_decode[11:8];
         //$display("decoded=%b D=%b",decoded_data,Dout);
         end  
      end 
   end
   
    
endmodule

