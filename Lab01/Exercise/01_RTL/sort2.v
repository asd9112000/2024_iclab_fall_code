

module sort2 
#(parameter W = 8)
(
   input  [W-1:0] a,
   input  [W-1:0] b,
   output [W-1:0] big,
   output [W-1:0] sme
   );

wire a_is_bigger;

   assign a_is_bigger = a>b;
   assign big= a_is_bigger ? a : b;
   assign sme= a_is_bigger ? b : a;
   
   // assign {big,sme} = a>b ? {a,b} : {b,a};

endmodule   
   
   