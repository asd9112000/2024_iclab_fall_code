module max2max_sort (
    input  [7:0] total7, total6, total5, total4, total3, total2, total1, total0,
    output [7:0] list7, list6, list5, list4, list3, list2, list1, list0
);


wire [7:0] w [7:0],i [3:0];

compb compb0(
    .a(total7),
    .b(total6),
    .c(total5),
    .d(total4),
    .out0(w[0]),
    .out1(w[1]),
    .out2(w[2]),
    .out3(w[3])
);

compb compb1(
    .a(total3),
    .b(total2),
    .c(total1),
    .d(total0),
    .out0(w[4]),
    .out1(w[5]),
    .out2(w[6]),
    .out3(w[7])
);


compa compa0(
    .a(w[0]),
    .b(w[1]),
    .c(w[4]),
    .d(w[5]),
    .out0(list7),
    .out1(list6),
    .out2(i[0]),
    .out3(i[1])
);


compa compa1(
    .a(w[2]),
    .b(w[3]),
    .c(w[6]),
    .d(w[7]),
    .out0(i[2]),
    .out1(i[3]),
    .out2(list1),
    .out3(list0)
);


compa compa2(
    .a(i[0]),
    .b(i[1]),
    .c(i[2]),
    .d(i[3]),
    .out0(list5),
    .out1(list4),
    .out2(list3),
    .out3(list2)
);


endmodule




module compb (
     a,b,c,d,out0,out1,out2,out3
);
input [7:0] a,b,c,d;
output [7:0] out0,out1,out2,out3; //from big to small out0~out3

wire [7:0] w [3:0];
sort2 sort00(.a(a), .b(b), .big(w[0]), .sme(w[1]));
sort2 sort01(.a(c), .b(d), .big(w[2]), .sme(w[3]));

compa compa0 (
    .a(w[0]),
    .b(w[1]),
    .c(w[2]),
    .d(w[3]),
    .out0(out0),
    .out1(out1),
    .out2(out2),
    .out3(out3)
);

endmodule


module compa (
    a,b,c,d,out0,out1,out2,out3
);
input [7:0] a,b,c,d;
output [7:0] out0,out1,out2,out3; //from big to small out0~out3


wire [7:0] w0,w1;
sort2 sort00(.a(a), .b(c), .big(out0), .sme(w0));
sort2 sort01(.a(b), .b(d), .big(w1), .sme(out3));
sort2 sort02(.a(w0), .b(w1), .big(out1), .sme(out2));

endmodule




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
