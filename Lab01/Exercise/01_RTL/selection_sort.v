module selection_sort (
    input  [7:0] total7, total6, total5, total4, total3, total2, total1, total0,
    output [7:0] list7, list6, list5, list4, list3, list2, list1, list0
);


wire [7:0] l1 [7:0], l2 [5:0], l3 [7:0], l4 [7:0], l5 [7:0];  // 宣告五個 8x8 的 wire 陣列
wire [7:0] l1_ [1:0], l2_[1:0], l3_[1:0];

pick4 pick400(
    .a(total7),
    .b(total6),
    .c(total5),
    .d(total4),
    .max (l1[7]),
    .mid0(l1[6]),
    .mid1(l1[5]),
    .min(l1[4])
);

pick4 pick401(
    .a(total3),
    .b(total2),
    .c(total1),
    .d(total0),
    .max (l1[3]),
    .mid0(l1[2]),
    .mid1(l1[1]),
    .min(l1[0])
);

wire a,b;
assign a=l1[7]>l1[3];
assign b=l1[4]>l1[0];
assign list7 = (a)?l1[7]:l1[3]; //max of list
assign list0 = (b)?l1[0]:l1[4]; //min
assign l1_[0]= (a)?l1[3]:l1[7];
assign l1_[1]= (b)?l1[4]:l1[0];


pick3 pick301 (
    .a(l1_[0]),
    .b(l1[6]),
    .c(l1[5]),
    .max(l2[5]),
    .mid(l2[4]),
    .min(l2[3])
);

pick3 pick302 (
    .a(l1_[1]),
    .b(l1[2]),
    .c(l1[1]),
    .max(l2[2]),
    .mid(l2[1]),
    .min(l2[0])
);

wire c,d;
assign c=l2[5]>l2[2];
assign d=l2[3]>l2[0];
assign list6 = (c)?l2[5]:l2[2]; //max of list
assign list1 = (d)?l2[0]:l2[3]; //min
assign l2_[0]= (c)?l2[2]:l2[5];
assign l2_[1]= (d)?l2[3]:l2[0];

pick4 pick410(
    .a(l2_[0]),
    .b(l2_[1]),
    .c(l2[4]),
    .d(l2[1]),
    .max (list5),
    .mid0(l3_[0]),
    .mid1(l3_[1]),
    .min(list2)
);


assign list4= (l3_[1]>l3_[0])?l3_[1]:l3_[0];
assign list3= (l3_[0]>l3_[1])?l3_[1]:l3_[0];

endmodule




//mid0,mid1 may have order error, but they are't inportant.
module pick4 (
    a,b,c,d,max,mid0,mid1,min
);
input [7:0] a,b,c,d;
output [7:0] max,mid0,mid1,min;


wire [7:0] l0 [3:0];
sort2 sort00(.a(a), .b(b), .big(l0[3]), .sme(l0[2]));
sort2 sort01(.a(c), .b(d), .big(l0[1]), .sme(l0[0]));
sort2 sort10(.a(l0[3]), .b(l0[1]), .big(max), .sme(mid0));
sort2 sort11(.a(l0[2]), .b(l0[0]), .big(mid1), .sme(min));

endmodule






//mid may have error, but it's not inportant.
module pick3 (
    a,b,c,max,mid,min
);
input [7:0] a,b,c;
output [7:0] max,mid,min;

wire [7:0] l0 [3:0];
sort2 sort00(.a(a), .b(b), .big(l0[1]), .sme(l0[0]));

sort2 sort10(.a(l0[1]), .b(c), .big(max), .sme(l0[2])); //it's known as l0[1] > l0[0]
sort2 sort11(.a(l0[0]), .b(c), .big(l0[3]), .sme(min));
assign mid = (max== l0[1])?l0[3]:l0[1];

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
