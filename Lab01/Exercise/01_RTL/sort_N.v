
`include "sort2.v"


module sort_N
#(parameter W = 8, // Data width
            N = 8) // Number of entries: power of two
(
   input  [63:0] in ,  // Input signals
   output [63:0] out    // Output signals from max to min
                              // Thus o[0] is max
);

wire [7:0] w [0:71];
wire [7:0] i [0:7];  // Input signals
wire [7:0] o [0:7];  // Output signals from max to min
                              // Thus o[0] is max

assign i[0]=in[7:0]  ;
assign i[1]=in[15:8] ;
assign i[2]=in[23:16];
assign i[3]=in[31:24];
assign i[4]=in[39:32];
assign i[5]=in[47:40];
assign i[6]=in[55:48];
assign i[7]=in[63:56];



genvar c,r,a;

generate
   for (c=0; c<8; c=c+1)
   begin :block1
      if (c[0]==1'b0)
      begin :even
         for (r=0; r<8; r=r+2)
            sort2 sort2_i (.a(w[c*8+r]),.b(w[c*8+r+1]),.big(w[c*8+r+N]),.sme(w[c*8+r+8+1]));
      end
      else
      begin :odd
         assign w[c*8+8]=w[c*8];
         for (r=1; r<8-2; r=r+2)
           sort2 sort2_i (.a(w[c*8+r]),.b(w[c*8+r+1]),.big(w[c*8+r+8]),.sme(w[c*8+r+8+1]));
         assign w[c*8+8+8-1]=w[c*8+8-1];
      end
   end

   for (r=0; r<8; r=r+1)
   begin :block2
      assign w[r]=i[r];
      assign o[r]=w[8*8+r];
   end

endgenerate



assign out[7:0]  =o[7];
assign out[15:8] =o[6];
assign out[23:16]=o[5];
assign out[31:24]=o[4];
assign out[39:32]=o[3];
assign out[47:40]=o[2];
assign out[55:48]=o[1];
assign out[63:56]=o[0];


endmodule

