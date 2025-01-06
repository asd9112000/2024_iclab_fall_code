//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2024 Fall
//   Lab01 Exercise		: Snack Shopping Calculator
//   Author     		  : Yu-Hsiang Wang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SSC.v
//   Module Name : SSC
//   Release version : V1.0 (Release Date: 2024-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SSC(
    // Input signals
    card_num,
    input_money,
    snack_num,
    price,
    // Output signals
    out_valid,
    out_change
);

//================================================================
//   INPUT AND OUTPUT DECLARATION
//================================================================
input [63:0] card_num;
input [8:0] input_money;
input [31:0] snack_num;
input [31:0] price;
output out_valid;
output [8:0] out_change;

//================================================================
//    Wire & Registers
//================================================================
// Declare the wire/reg you would use in your circuit
// remember
// wire for port connection and cont. assignment
// reg for proc. assignment
reg out_valid_;
wire [6:0]ev_canm;
wire [6:0] od_canm;
wire [7:0]  total0,
            total1,
            total2,
            total3,
            total4,
            total5,
            total6,
            total7,
            list0,
            list1,
            list2,
            list3,
            list4,
            list5,
            list6,
            list7;
wire [9:0] change0,change1,change2,change3,change4,change5,change6,change7;


//================================================================
//    Card Number process
//================================================================
assign ev_canm =   {3'd0, card_num[3:0]  } + {3'd0, card_num[11:8] }+
                   {3'd0, card_num[19:16]} + {3'd0, card_num[27:24]}+
                   {3'd0, card_num[35:32]} + {3'd0, card_num[43:40]}+
                   {3'd0, card_num[51:48]} + {3'd0, card_num[59:56]};

odtable odtable (
    .od_in0(card_num[7:4]  ),
    .od_in1(card_num[15:12]),
    .od_in2(card_num[23:20]),
    .od_in3(card_num[31:28]),
    .od_in4(card_num[39:36]),
    .od_in5(card_num[47:44]),
    .od_in6(card_num[55:52]),
    .od_in7(card_num[63:60]),
    .od_canm(od_canm)
);


//================================================================
//    Check Card Number
//================================================================
always @(*) begin
    case ({1'd0,od_canm}+{1'd0,ev_canm})
        8'd10 :out_valid_=1'd1;
        8'd20 :out_valid_=1'd1;
        8'd30 :out_valid_=1'd1;
        8'd40 :out_valid_=1'd1;
        8'd50 :out_valid_=1'd1;
        8'd60 :out_valid_=1'd1;
        8'd70 :out_valid_=1'd1;
        8'd80 :out_valid_=1'd1;
        8'd90 :out_valid_=1'd1;
        8'd100:out_valid_=1'd1;
        8'd110:out_valid_=1'd1;
        8'd120:out_valid_=1'd1;
        8'd130:out_valid_=1'd1;
        8'd140:out_valid_=1'd1;
        default: out_valid_=1'd0;
    endcase
end
assign out_valid = out_valid_;



//================================================================
//     Buy Snack 1.total cost compu
//================================================================
// prodtab prodtab0(.num(snack_num[3:0]  ), .price(price[3:0]  ), .total(total0));
// prodtab prodtab1(.num(snack_num[7:4]  ), .price(price[7:4]  ), .total(total1));
// prodtab prodtab2(.num(snack_num[11:8] ), .price(price[11:8] ), .total(total2));
// prodtab prodtab3(.num(snack_num[15:12]), .price(price[15:12]), .total(total3));
// prodtab prodtab4(.num(snack_num[19:16]), .price(price[19:16]), .total(total4));
// prodtab prodtab5(.num(snack_num[23:20]), .price(price[23:20]), .total(total5));
// prodtab prodtab6(.num(snack_num[27:24]), .price(price[27:24]), .total(total6));
// prodtab prodtab7(.num(snack_num[31:28]), .price(price[31:28]), .total(total7));


assign total0 = snack_num[3:0]   * price[3:0]  ;
assign total1 = snack_num[7:4]   * price[7:4]  ;
assign total2 = snack_num[11:8]  * price[11:8] ;
assign total3 = snack_num[15:12] * price[15:12];
assign total4 = snack_num[19:16] * price[19:16];
assign total5 = snack_num[23:20] * price[23:20];
assign total6 = snack_num[27:24] * price[27:24];
assign total7 = snack_num[31:28] * price[31:28];


// max2max_sort max2max_sort0 (
//      total7, total6, total5, total4, total3, total2, total1, total0,
//      list7, list6, list5, list4, list3, list2, list1, list0
// );

Sort_8 Sort_8(
    {total7, total6, total5, total4, total3, total2, total1, total0},
    //  {list7, list6, list5, list4, list3, list2, list1, list0}
     {list0, list1, list2, list3, list4, list5, list6, list7}

);


//================================================================
//     Buy Snack 3.Choice and Buy
//================================================================
reg  [8:0] _out_change ;   //Area of it is the same as above if else way

// assign change0 = ~{1'd0,input_money} + 10'd1 + {2'd0,list7};
// assign change1 = change0 + {2'd0,list6};
// assign change2 = change1 + {2'd0,list5};
// assign change3 = change2 + {2'd0,list4};
// assign change4 = change3 + {2'd0,list3};
// assign change5 = change4 + {2'd0,list2};
// assign change6 = change5 + {2'd0,list1};
// assign change7 = change6 + {2'd0,list0};


// always @(*) begin
//     casex ({ change0[9],
//             change1[9],
//             change2[9],
//             change3[9],
//             change4[9],
//             change5[9],
//             change6[9],
//             change7[9]
//             })
//         8'b0XXXXXXX:_out_change = (|change0)? input_money : 10'd0 ;
//         8'b10XXXXXX:_out_change = (|change1)? ~change0[8:0]+10'd1:10'd0 ;
//         8'b110XXXXX:_out_change = (|change2)? ~change1[8:0]+10'd1:10'd0 ;
//         8'b1110XXXX:_out_change = (|change3)? ~change2[8:0]+10'd1:10'd0 ;
//         8'b11110XXX:_out_change = (|change4)? ~change3[8:0]+10'd1:10'd0 ;
//         8'b111110XX:_out_change = (|change5)? ~change4[8:0]+10'd1:10'd0 ;
//         8'b1111110X:_out_change = (|change6)? ~change5[8:0]+10'd1:10'd0 ;
//         8'b11111110:_out_change = (|change7)? ~change6[8:0]+10'd1:10'd0 ;
//         8'b11111111:_out_change = ~change7[8:0]+10'd1;
//         default: _out_change = 9'dX;
//     endcase
// end



assign change0 = {1'd0,input_money} - {2'd0,list7};
assign change1 = change0 - {2'd0,list6};
assign change2 = change1 - {2'd0,list5};
assign change3 = change2 - {2'd0,list4};
assign change4 = change3 - {2'd0,list3};
assign change5 = change4 - {2'd0,list2};
assign change6 = change5 - {2'd0,list1};
assign change7 = change6 - {2'd0,list0};
always @(*) begin
    casex ({ change0[9],
            change1[9],
            change2[9],
            change3[9],
            change4[9],
            change5[9],
            change6[9],
            change7[9]
            })
        8'b1XXXXXXX:_out_change = input_money;
        8'b01XXXXXX:_out_change = change0[8:0];
        8'b001XXXXX:_out_change = change1[8:0];
        8'b0001XXXX:_out_change = change2[8:0];
        8'b00001XXX:_out_change = change3[8:0];
        8'b000001XX:_out_change = change4[8:0];
        8'b0000001X:_out_change = change5[8:0];
        8'b00000001:_out_change = change6[8:0];
        8'b00000000:_out_change = change7[8:0];
        default: _out_change = 9'dX;
    endcase
end

assign out_change = (out_valid)?_out_change:input_money;

endmodule





module odtable (
    od_in0,
    od_in1,
    od_in2,
    od_in3,
    od_in4,
    od_in5,
    od_in6,
    od_in7,
    od_canm
);

input [3:0] od_in0,
            od_in1,
            od_in2,
            od_in3,
            od_in4,
            od_in5,
            od_in6,
            od_in7;

output [6:0] od_canm;
wire [3:0]od_out0, od_out1, od_out2, od_out3, od_out4, od_out5, od_out6, od_out7;
// wire [4:0] od_canm0, od_canm1, od_canm2, od_canm3;
// wire [5:0] od_canm0_, od_canm1_;

odmux odmux0 (.od_in(od_in0), .od_out(od_out0));
odmux odmux1 (.od_in(od_in1), .od_out(od_out1));
odmux odmux2 (.od_in(od_in2), .od_out(od_out2));
odmux odmux3 (.od_in(od_in3), .od_out(od_out3));
odmux odmux4 (.od_in(od_in4), .od_out(od_out4));
odmux odmux5 (.od_in(od_in5), .od_out(od_out5));
odmux odmux6 (.od_in(od_in6), .od_out(od_out6));
odmux odmux7 (.od_in(od_in7), .od_out(od_out7));


assign od_canm =    {2'd0,od_out0}+
                    {2'd0,od_out1}+
                    {2'd0,od_out2}+
                    {2'd0,od_out3}+
                    {2'd0,od_out4}+
                    {2'd0,od_out5}+
                    {2'd0,od_out6}+
                    {2'd0,od_out7};
endmodule



module odmux (
    od_in,
    od_out
);

input [3:0] od_in;
output [3:0] od_out;



// reg [3:0] od_out;
// always @(*) begin
//     case (od_in)
//     4'd0 :od_out<=4'd0;
//     4'd1 :od_out<=4'd2;
//     4'd2 :od_out<=4'd4;
//     4'd3 :od_out<=4'd6;
//     4'd4 :od_out<=4'd8;
//     4'd5 :od_out<=4'd1;
//     4'd6 :od_out<=4'd3;
//     4'd7 :od_out<=4'd5;
//     4'd8 :od_out<=4'd7;
//     4'd9 :od_out<=4'd9;
//     default:od_out<=4'dX;
//     endcase
// end

reg [3:0] od_a;
wire [4:0] od_b;
always @(*) begin
    case (od_in)
    4'd0 :od_a<=4'd0;
    4'd1 :od_a<=4'd2;
    4'd2 :od_a<=4'd4;
    4'd3 :od_a<=4'd6;
    4'd4 :od_a<=4'd8;
    default:od_a<=4'dX;
    endcase
end

assign od_b = ({1'd0,od_in}<<1) - 5'd9;
assign od_out = (od_in<=4)?od_a:od_b[3:0];



endmodule



// area 4054*8=32000  timing 3.09
module prodtab (
    num,price,total
);

input   [3:0] num,price;
output reg  [7:0] total;

always @(*) begin
    case ({num,price})
    8'b00000000:total= 8'd0   ; //1
    8'b00000001:total= 8'd0   ; //2
    8'b00000010:total= 8'd0   ; //3
    8'b00000011:total= 8'd0   ; //4
    8'b00000100:total= 8'd0   ; //5
    8'b00000101:total= 8'd0   ; //6
    8'b00000110:total= 8'd0   ; //7
    8'b00000111:total= 8'd0   ; //8
    8'b00001000:total= 8'd0   ; //9
    8'b00001001:total= 8'd0   ; //10
    8'b00001010:total= 8'd 0   ; //11
    8'b00001011:total= 8'd 0   ; //12
    8'b00001100:total= 8'd 0   ; //13
    8'b00001101:total= 8'd 0   ; //14
    8'b00001110:total= 8'd 0   ; //15
    8'b00001111:total= 8'd 0   ; //16
    8'b00010000:total= 8'd0   ; //17
    8'b00010001:total= 8'd1   ; //18
    8'b00010010:total= 8'd2   ; //19
    8'b00010011:total= 8'd3   ; //20
    8'b00010100:total= 8'd4   ; //21
    8'b00010101:total= 8'd5   ; //22
    8'b00010110:total= 8'd6   ; //23
    8'b00010111:total= 8'd7   ; //24
    8'b00011000:total= 8'd8   ; //25
    8'b00011001:total= 8'd9   ; //26
    8'b00011010:total= 8'd 10   ; //27
    8'b00011011:total= 8'd 11   ; //28
    8'b00011100:total= 8'd 12   ; //29
    8'b00011101:total= 8'd 13   ; //30
    8'b00011110:total= 8'd 14   ; //31
    8'b00011111:total= 8'd 15   ; //32
    8'b00100000:total= 8'd0   ; //33
    8'b00100001:total= 8'd2   ; //34
    8'b00100010:total= 8'd4   ; //35
    8'b00100011:total= 8'd6   ; //36
    8'b00100100:total= 8'd8   ; //37
    8'b00100101:total= 8'd10   ; //38
    8'b00100110:total= 8'd12   ; //39
    8'b00100111:total= 8'd14   ; //40
    8'b00101000:total= 8'd16   ; //41
    8'b00101001:total= 8'd18   ; //42
    8'b00101010:total= 8'd 20   ; //43
    8'b00101011:total= 8'd 22   ; //44
    8'b00101100:total= 8'd 24   ; //45
    8'b00101101:total= 8'd 26   ; //46
    8'b00101110:total= 8'd 28   ; //47
    8'b00101111:total= 8'd 30   ; //48
    8'b00110000:total= 8'd0   ; //49
    8'b00110001:total= 8'd3   ; //50
    8'b00110010:total= 8'd6   ; //51
    8'b00110011:total= 8'd9   ; //52
    8'b00110100:total= 8'd12   ; //53
    8'b00110101:total= 8'd15   ; //54
    8'b00110110:total= 8'd18   ; //55
    8'b00110111:total= 8'd21   ; //56
    8'b00111000:total= 8'd24   ; //57
    8'b00111001:total= 8'd27   ; //58
    8'b00111010:total= 8'd 30   ; //59
    8'b00111011:total= 8'd 33   ; //60
    8'b00111100:total= 8'd 36   ; //61
    8'b00111101:total= 8'd 39   ; //62
    8'b00111110:total= 8'd 42   ; //63
    8'b00111111:total= 8'd 45   ; //64
    8'b01000000:total= 8'd0   ; //65
    8'b01000001:total= 8'd4   ; //66
    8'b01000010:total= 8'd8   ; //67
    8'b01000011:total= 8'd12   ; //68
    8'b01000100:total= 8'd16   ; //69
    8'b01000101:total= 8'd20   ; //70
    8'b01000110:total= 8'd24   ; //71
    8'b01000111:total= 8'd28   ; //72
    8'b01001000:total= 8'd32   ; //73
    8'b01001001:total= 8'd36   ; //74
    8'b01001010:total= 8'd 40   ; //75
    8'b01001011:total= 8'd 44   ; //76
    8'b01001100:total= 8'd 48   ; //77
    8'b01001101:total= 8'd 52   ; //78
    8'b01001110:total= 8'd 56   ; //79
    8'b01001111:total= 8'd 60   ; //80
    8'b01010000:total= 8'd0   ; //81
    8'b01010001:total= 8'd5   ; //82
    8'b01010010:total= 8'd10   ; //83
    8'b01010011:total= 8'd15   ; //84
    8'b01010100:total= 8'd20   ; //85
    8'b01010101:total= 8'd25   ; //86
    8'b01010110:total= 8'd30   ; //87
    8'b01010111:total= 8'd35   ; //88
    8'b01011000:total= 8'd40   ; //89
    8'b01011001:total= 8'd45   ; //90
    8'b01011010:total= 8'd 50   ; //91
    8'b01011011:total= 8'd 55   ; //92
    8'b01011100:total= 8'd 60   ; //93
    8'b01011101:total= 8'd 65   ; //94
    8'b01011110:total= 8'd 70   ; //95
    8'b01011111:total= 8'd 75   ; //96
    8'b01100000:total= 8'd0   ; //97
    8'b01100001:total= 8'd6   ; //98
    8'b01100010:total= 8'd12   ; //99
    8'b01100011:total= 8'd18   ; //100
    8'b01100100:total= 8'd24   ; //101
    8'b01100101:total= 8'd30   ; //102
    8'b01100110:total= 8'd36   ; //103
    8'b01100111:total= 8'd42   ; //104
    8'b01101000:total= 8'd48   ; //105
    8'b01101001:total= 8'd54   ; //106
    8'b01101010:total= 8'd 60   ; //107
    8'b01101011:total= 8'd 66   ; //108
    8'b01101100:total= 8'd 72   ; //109
    8'b01101101:total= 8'd 78   ; //110
    8'b01101110:total= 8'd 84   ; //111
    8'b01101111:total= 8'd 90   ; //112
    8'b01110000:total= 8'd0   ; //113
    8'b01110001:total= 8'd7   ; //114
    8'b01110010:total= 8'd14   ; //115
    8'b01110011:total= 8'd21   ; //116
    8'b01110100:total= 8'd28   ; //117
    8'b01110101:total= 8'd35   ; //118
    8'b01110110:total= 8'd42   ; //119
    8'b01110111:total= 8'd49   ; //120
    8'b01111000:total= 8'd56   ; //121
    8'b01111001:total= 8'd63   ; //122
    8'b01111010:total= 8'd 70   ; //123
    8'b01111011:total= 8'd 77   ; //124
    8'b01111100:total= 8'd 84   ; //125
    8'b01111101:total= 8'd 91   ; //126
    8'b01111110:total= 8'd 98   ; //127
    8'b01111111:total= 8'd 105   ; //128
    8'b10000000:total= 8'd0   ; //129
    8'b10000001:total= 8'd8   ; //130
    8'b10000010:total= 8'd16   ; //131
    8'b10000011:total= 8'd24   ; //132
    8'b10000100:total= 8'd32   ; //133
    8'b10000101:total= 8'd40   ; //134
    8'b10000110:total= 8'd48   ; //135
    8'b10000111:total= 8'd56   ; //136
    8'b10001000:total= 8'd64   ; //137
    8'b10001001:total= 8'd72   ; //138
    8'b10001010:total= 8'd 80   ; //139
    8'b10001011:total= 8'd 88   ; //140
    8'b10001100:total= 8'd 96   ; //141
    8'b10001101:total= 8'd 104   ; //142
    8'b10001110:total= 8'd 112   ; //143
    8'b10001111:total= 8'd 120   ; //144
    8'b10010000:total= 8'd0   ; //145
    8'b10010001:total= 8'd9   ; //146
    8'b10010010:total= 8'd18   ; //147
    8'b10010011:total= 8'd27   ; //148
    8'b10010100:total= 8'd36   ; //149
    8'b10010101:total= 8'd45   ; //150
    8'b10010110:total= 8'd54   ; //151
    8'b10010111:total= 8'd63   ; //152
    8'b10011000:total= 8'd72   ; //153
    8'b10011001:total= 8'd81   ; //154
    8'b10011010:total= 8'd90   ; //155
    8'b10011011:total= 8'd99   ; //156
    8'b10011100:total= 8'd108   ; //157
    8'b10011101:total= 8'd117   ; //158
    8'b10011110:total= 8'd126   ; //159
    8'b10011111:total= 8'd135   ; //160
    8'b10100000:total= 8'd0   ; //161
    8'b10100001:total= 8'd10   ; //162
    8'b10100010:total= 8'd20   ; //163
    8'b10100011:total= 8'd30   ; //164
    8'b10100100:total= 8'd40   ; //165
    8'b10100101:total= 8'd50   ; //166
    8'b10100110:total= 8'd60   ; //167
    8'b10100111:total= 8'd70   ; //168
    8'b10101000:total= 8'd80   ; //169
    8'b10101001:total= 8'd90   ; //170
    8'b10101010:total= 8'd 100   ; //171
    8'b10101011:total= 8'd 110   ; //172
    8'b10101100:total= 8'd 120   ; //173
    8'b10101101:total= 8'd 130   ; //174
    8'b10101110:total= 8'd 140   ; //175
    8'b10101111:total= 8'd 150   ; //176
    8'b10110000:total= 8'd0   ; //177
    8'b10110001:total= 8'd11   ; //178
    8'b10110010:total= 8'd22   ; //179
    8'b10110011:total= 8'd33   ; //180
    8'b10110100:total= 8'd44   ; //181
    8'b10110101:total= 8'd55   ; //182
    8'b10110110:total= 8'd66   ; //183
    8'b10110111:total= 8'd77   ; //184
    8'b10111000:total= 8'd88   ; //185
    8'b10111001:total= 8'd99   ; //186
    8'b10111010:total= 8'd 110   ; //187
    8'b10111011:total= 8'd 121   ; //188
    8'b10111100:total= 8'd 132   ; //189
    8'b10111101:total= 8'd 143   ; //190
    8'b10111110:total= 8'd 154   ; //191
    8'b10111111:total= 8'd 165   ; //192
    8'b11000000:total= 8'd0   ; //193
    8'b11000001:total= 8'd12   ; //194
    8'b11000010:total= 8'd24   ; //195
    8'b11000011:total= 8'd36   ; //196
    8'b11000100:total= 8'd48   ; //197
    8'b11000101:total= 8'd60   ; //198
    8'b11000110:total= 8'd72   ; //199
    8'b11000111:total= 8'd84   ; //200
    8'b11001000:total= 8'd96   ; //201
    8'b11001001:total= 8'd108   ; //202
    8'b11001010:total= 8'd 120   ; //203
    8'b11001011:total= 8'd 132   ; //204
    8'b11001100:total= 8'd 144   ; //205
    8'b11001101:total= 8'd 156   ; //206
    8'b11001110:total= 8'd 168   ; //207
    8'b11001111:total= 8'd 180   ; //208
    8'b11010000:total= 8'd0   ; //209
    8'b11010001:total= 8'd13   ; //210
    8'b11010010:total= 8'd26   ; //211
    8'b11010011:total= 8'd39   ; //212
    8'b11010100:total= 8'd52   ; //213
    8'b11010101:total= 8'd65   ; //214
    8'b11010110:total= 8'd78   ; //215
    8'b11010111:total= 8'd91   ; //216
    8'b11011000:total= 8'd104   ; //217
    8'b11011001:total= 8'd117   ; //218
    8'b11011010:total= 8'd 130   ; //219
    8'b11011011:total= 8'd 143   ; //220
    8'b11011100:total= 8'd 156   ; //221
    8'b11011101:total= 8'd 169   ; //222
    8'b11011110:total= 8'd 182   ; //223
    8'b11011111:total= 8'd 195   ; //224
    8'b11100000:total= 8'd0   ; //225
    8'b11100001:total= 8'd14   ; //226
    8'b11100010:total= 8'd28   ; //227
    8'b11100011:total= 8'd42   ; //228
    8'b11100100:total= 8'd56   ; //229
    8'b11100101:total= 8'd70   ; //230
    8'b11100110:total= 8'd84   ; //231
    8'b11100111:total= 8'd98   ; //232
    8'b11101000:total= 8'd112   ; //233
    8'b11101001:total= 8'd126   ; //234
    8'b11101010:total= 8'd 140   ; //235
    8'b11101011:total= 8'd 154   ; //236
    8'b11101100:total= 8'd 168   ; //237
    8'b11101101:total= 8'd 182   ; //238
    8'b11101110:total= 8'd 196   ; //239
    8'b11101111:total= 8'd 210   ; //240
    8'b11110000:total= 8'd0   ; //241
    8'b11110001:total= 8'd15   ; //242
    8'b11110010:total= 8'd30   ; //243
    8'b11110011:total= 8'd45   ; //244
    8'b11110100:total= 8'd60   ; //245
    8'b11110101:total= 8'd75   ; //246
    8'b11110110:total= 8'd90   ; //247
    8'b11110111:total= 8'd105   ; //248
    8'b11111000:total= 8'd120   ; //249
    8'b11111001:total= 8'd135   ; //250
    8'b11111010:total= 8'd 150   ; //251
    8'b11111011:total= 8'd 165   ; //252
    8'b11111100:total= 8'd 180   ; //253
    8'b11111101:total= 8'd 195   ; //254
    8'b11111110:total= 8'd 210   ; //255
    8'b11111111:total= 8'd 225   ; //256
    default:total=8'd0;
    endcase
end

endmodule

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




module Sort_8(
    input [63:0] in_8x8,
    output [63:0] out_8x8
);

    wire [15:0] Merge1_0, Merge1_1, Merge1_2, Merge1_3;
    wire [31:0] Merge2_0, Merge2_1;

    Merge_1x1 merge_1x1_0(
        .a(in_8x8[7:0]),
        .b(in_8x8[15:8]),
        .out(Merge1_0)
    );
    Merge_1x1 merge_1x1_1(
        .a(in_8x8[23:16]),
        .b(in_8x8[31:24]),
        .out(Merge1_1)
    );
    Merge_1x1 merge_1x1_2(
        .a(in_8x8[39:32]),
        .b(in_8x8[47:40]),
        .out(Merge1_2)
    );
    Merge_1x1 merge_1x1_3(
        .a(in_8x8[55:48]),
        .b(in_8x8[63:56]),
        .out(Merge1_3)
    );

    Merge_2x2 merge_2x2_0(
        .a(Merge1_0),
        .b(Merge1_1),
        .out(Merge2_0)
    );
    Merge_2x2 merge_2x2_1(
        .a(Merge1_2),
        .b(Merge1_3),
        .out(Merge2_1)
    );

    Merge_4x4 merge_4x4(
        .a(Merge2_0),
        .b(Merge2_1),
        .out(out_8x8)
    );

endmodule

module Merge_1x1(
    input [7:0] a,
    input [7:0] b,
    output [15:0] out
);

    wire cmp;
    assign cmp = (a < b);
    assign out = cmp ? {a, b} : {b, a};

endmodule

module Merge_2x2(
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] out
);

    wire [7:0] a0;
    wire [7:0] a1;
    wire [7:0] b0;
    wire [7:0] b1;
    wire cmp_a0_b0;
    wire cmp_a0_b1;
    wire cmp_a1_b0;
    wire cmp_a1_b1;

    assign a0 = a[15:8];
    assign a1 = a[7:0];
    assign b0 = b[15:8];
    assign b1 = b[7:0];

    assign cmp_a0_b0 = (a0 < b0);
    assign cmp_a0_b1 = (a0 < b1);
    assign cmp_a1_b0 = (a1 < b0);
    assign cmp_a1_b1 = (a1 < b1);

    always @(*) begin
        case ({cmp_a0_b0, cmp_a0_b1, cmp_a1_b0, cmp_a1_b1})
            4'b0000: out = {b0, b1, a0, a1};
            4'b0100: out = {b0, a0, b1, a1};
            4'b0101: out = {b0, a0, a1, b1};
            4'b1100: out = {a0, b0, b1, a1};
            4'b1101: out = {a0, b0, a1, b1};
            4'b1111: out = {a0, a1, b0, b1};
            default: out = 32'bX;
        endcase
    end

endmodule

module Merge_4x4(
    input [31:0] a,
    input [31:0] b,
    output reg [63:0] out
);

    wire [7:0] a0, a1, a2, a3;
    wire [7:0] b0, b1, b2, b3;

    assign a0 = a[31:24];
    assign a1 = a[23:16];
    assign a2 = a[15:8];
    assign a3 = a[7:0];

    assign b0 = b[31:24];
    assign b1 = b[23:16];
    assign b2 = b[15:8];
    assign b3 = b[7:0];

    wire cmp_a0_b0, cmp_a0_b1, cmp_a0_b2, cmp_a0_b3;
    wire cmp_a1_b0, cmp_a1_b1, cmp_a1_b2, cmp_a1_b3;
    wire cmp_a2_b0, cmp_a2_b1, cmp_a2_b2, cmp_a2_b3;
    wire cmp_a3_b0, cmp_a3_b1, cmp_a3_b2, cmp_a3_b3;

    assign cmp_a0_b0 = (a0 < b0);
    assign cmp_a0_b1 = (a0 < b1);
    assign cmp_a0_b2 = (a0 < b2);
    assign cmp_a0_b3 = (a0 < b3);

    assign cmp_a1_b0 = (a1 < b0);
    assign cmp_a1_b1 = (a1 < b1);
    assign cmp_a1_b2 = (a1 < b2);
    assign cmp_a1_b3 = (a1 < b3);

    assign cmp_a2_b0 = (a2 < b0);
    assign cmp_a2_b1 = (a2 < b1);
    assign cmp_a2_b2 = (a2 < b2);
    assign cmp_a2_b3 = (a2 < b3);

    assign cmp_a3_b0 = (a3 < b0);
    assign cmp_a3_b1 = (a3 < b1);
    assign cmp_a3_b2 = (a3 < b2);
    assign cmp_a3_b3 = (a3 < b3);

    always @(*) begin
        case ({cmp_a0_b0, cmp_a0_b1, cmp_a0_b2, cmp_a0_b3,
               cmp_a1_b0, cmp_a1_b1, cmp_a1_b2, cmp_a1_b3,
               cmp_a2_b0, cmp_a2_b1, cmp_a2_b2, cmp_a2_b3,
               cmp_a3_b0, cmp_a3_b1, cmp_a3_b2, cmp_a3_b3})
            16'b1111111111111111: out = { a0, a1, a2, a3, b0, b1, b2, b3 };
            16'b1111111111110111: out = { a0, a1, a2, b0, a3, b1, b2, b3 };
            16'b1111111111110011: out = { a0, a1, a2, b0, b1, a3, b2, b3 };
            16'b1111111111110001: out = { a0, a1, a2, b0, b1, b2, a3, b3 };
            16'b1111111111110000: out = { a0, a1, a2, b0, b1, b2, b3, a3 };
            16'b1111111101110111: out = { a0, a1, b0, a2, a3, b1, b2, b3 };
            16'b1111111101110011: out = { a0, a1, b0, a2, b1, a3, b2, b3 };
            16'b1111111101110001: out = { a0, a1, b0, a2, b1, b2, a3, b3 };
            16'b1111111101110000: out = { a0, a1, b0, a2, b1, b2, b3, a3 };
            16'b1111111100110011: out = { a0, a1, b0, b1, a2, a3, b2, b3 };
            16'b1111111100110001: out = { a0, a1, b0, b1, a2, b2, a3, b3 };
            16'b1111111100110000: out = { a0, a1, b0, b1, a2, b2, b3, a3 };
            16'b1111111100010001: out = { a0, a1, b0, b1, b2, a2, a3, b3 };
            16'b1111111100010000: out = { a0, a1, b0, b1, b2, a2, b3, a3 };
            16'b1111111100000000: out = { a0, a1, b0, b1, b2, b3, a2, a3 };
            16'b1111011101110111: out = { a0, b0, a1, a2, a3, b1, b2, b3 };
            16'b1111011101110011: out = { a0, b0, a1, a2, b1, a3, b2, b3 };
            16'b1111011101110001: out = { a0, b0, a1, a2, b1, b2, a3, b3 };
            16'b1111011101110000: out = { a0, b0, a1, a2, b1, b2, b3, a3 };
            16'b1111011100110011: out = { a0, b0, a1, b1, a2, a3, b2, b3 };
            16'b1111011100110001: out = { a0, b0, a1, b1, a2, b2, a3, b3 };
            16'b1111011100110000: out = { a0, b0, a1, b1, a2, b2, b3, a3 };
            16'b1111011100010001: out = { a0, b0, a1, b1, b2, a2, a3, b3 };
            16'b1111011100010000: out = { a0, b0, a1, b1, b2, a2, b3, a3 };
            16'b1111011100000000: out = { a0, b0, a1, b1, b2, b3, a2, a3 };
            16'b1111001100110011: out = { a0, b0, b1, a1, a2, a3, b2, b3 };
            16'b1111001100110001: out = { a0, b0, b1, a1, a2, b2, a3, b3 };
            16'b1111001100110000: out = { a0, b0, b1, a1, a2, b2, b3, a3 };
            16'b1111001100010001: out = { a0, b0, b1, a1, b2, a2, a3, b3 };
            16'b1111001100010000: out = { a0, b0, b1, a1, b2, a2, b3, a3 };
            16'b1111001100000000: out = { a0, b0, b1, a1, b2, b3, a2, a3 };
            16'b1111000100010001: out = { a0, b0, b1, b2, a1, a2, a3, b3 };
            16'b1111000100010000: out = { a0, b0, b1, b2, a1, a2, b3, a3 };
            16'b1111000100000000: out = { a0, b0, b1, b2, a1, b3, a2, a3 };
            16'b1111000000000000: out = { a0, b0, b1, b2, b3, a1, a2, a3 };
            16'b0111011101110111: out = { b0, a0, a1, a2, a3, b1, b2, b3 };
            16'b0111011101110011: out = { b0, a0, a1, a2, b1, a3, b2, b3 };
            16'b0111011101110001: out = { b0, a0, a1, a2, b1, b2, a3, b3 };
            16'b0111011101110000: out = { b0, a0, a1, a2, b1, b2, b3, a3 };
            16'b0111011100110011: out = { b0, a0, a1, b1, a2, a3, b2, b3 };
            16'b0111011100110001: out = { b0, a0, a1, b1, a2, b2, a3, b3 };
            16'b0111011100110000: out = { b0, a0, a1, b1, a2, b2, b3, a3 };
            16'b0111011100010001: out = { b0, a0, a1, b1, b2, a2, a3, b3 };
            16'b0111011100010000: out = { b0, a0, a1, b1, b2, a2, b3, a3 };
            16'b0111011100000000: out = { b0, a0, a1, b1, b2, b3, a2, a3 };
            16'b0111001100110011: out = { b0, a0, b1, a1, a2, a3, b2, b3 };
            16'b0111001100110001: out = { b0, a0, b1, a1, a2, b2, a3, b3 };
            16'b0111001100110000: out = { b0, a0, b1, a1, a2, b2, b3, a3 };
            16'b0111001100010001: out = { b0, a0, b1, a1, b2, a2, a3, b3 };
            16'b0111001100010000: out = { b0, a0, b1, a1, b2, a2, b3, a3 };
            16'b0111001100000000: out = { b0, a0, b1, a1, b2, b3, a2, a3 };
            16'b0111000100010001: out = { b0, a0, b1, b2, a1, a2, a3, b3 };
            16'b0111000100010000: out = { b0, a0, b1, b2, a1, a2, b3, a3 };
            16'b0111000100000000: out = { b0, a0, b1, b2, a1, b3, a2, a3 };
            16'b0111000000000000: out = { b0, a0, b1, b2, b3, a1, a2, a3 };
            16'b0011001100110011: out = { b0, b1, a0, a1, a2, a3, b2, b3 };
            16'b0011001100110001: out = { b0, b1, a0, a1, a2, b2, a3, b3 };
            16'b0011001100110000: out = { b0, b1, a0, a1, a2, b2, b3, a3 };
            16'b0011001100010001: out = { b0, b1, a0, a1, b2, a2, a3, b3 };
            16'b0011001100010000: out = { b0, b1, a0, a1, b2, a2, b3, a3 };
            16'b0011001100000000: out = { b0, b1, a0, a1, b2, b3, a2, a3 };
            16'b0011000100010001: out = { b0, b1, a0, b2, a1, a2, a3, b3 };
            16'b0011000100010000: out = { b0, b1, a0, b2, a1, a2, b3, a3 };
            16'b0011000100000000: out = { b0, b1, a0, b2, a1, b3, a2, a3 };
            16'b0011000000000000: out = { b0, b1, a0, b2, b3, a1, a2, a3 };
            16'b0001000100010001: out = { b0, b1, b2, a0, a1, a2, a3, b3 };
            16'b0001000100010000: out = { b0, b1, b2, a0, a1, a2, b3, a3 };
            16'b0001000100000000: out = { b0, b1, b2, a0, a1, b3, a2, a3 };
            16'b0001000000000000: out = { b0, b1, b2, a0, b3, a1, a2, a3 };
            16'b0000000000000000: out = { b0, b1, b2, b3, a0, a1, a2, a3 };
            default: out = 64'bX;
        endcase
    end

endmodule