// It is a encoder file
//note: It is only work for the data input of 8 bits(The input data writing into memory should be 8 bit)

// the input is coming from controller (which is of 8 bits)
// the output is with parity bits (encoded_data)
// the encoded data is stored in the MEMORY
//




module en_code(input       [7:0] data, 
               output reg [11:0] encoded_data
              );
   always@(data) begin
      encoded_data[0]=data[0]^data[1]^data[3]^data[4]^data[6];
      encoded_data[1]=data[0]^data[2]^data[3]^data[5]^data[6];
      encoded_data[3]=data[1]^data[2]^data[3]^data[7];
      encoded_data[7]=data[4]^data[5]^data[6]^data[7];
      encoded_data[2]=data[0];
      encoded_data[6:4]=data[3:1];
      encoded_data[11:8]=data[7:4];
      //$display("%b",encoded_data);
   end
endmodule

