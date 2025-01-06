


// ================================================================
// Bubblesort
// ================================================================
// This has byg because of ignoring tied case.!!!!!


module bubble (
    total0,
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
    list7
);

input [7:0]
    total0,
    total1,
    total2,
    total3,
    total4,
    total5,
    total6,
    total7;

output [7:0]  //list7 is the biggest one .
    list0,
    list1,
    list2,
    list3,
    list4,
    list5,
    list6,
    list7;

wire [6:0]  comp0,  // comp[6:0] stand total0 vs to7, 6....1, every 1 means total0 win.
            comp1,
            comp2,
            comp3,
            comp4,
            comp5,
            comp6,
            comp7;  //acctually, we can igmore one of total by apart it frmo compare because you will know its order while geting others.

assign comp0 [6:0] = {total0 > total7, total0 > total6,
                      total0 > total5, total0 > total4,
                      total0 > total3, total0 > total2,
                      total0 > total1};

assign comp1 [6:0] = {total1 > total7, total1 > total6,
                      total1 > total5, total1 > total4,
                      total1 > total3, total1 > total2,
                      total1 > total0};

assign comp2 [6:0] = {total2 > total7, total2 > total6,
                      total2 > total5, total2 > total4,
                      total2 > total3, total2 > total1,
                      total2 > total0};

assign comp3 [6:0] = {total3 > total7, total3 > total6,
                      total3 > total5, total3 > total4,
                      total3 > total2, total3 > total1,
                      total3 > total0};

assign comp4 [6:0] = {total4 > total7, total4 > total6,
                      total4 > total5, total4 > total3,
                      total4 > total2, total4 > total1,
                      total4 > total0};

assign comp5 [6:0] = {total5 > total7, total5 > total6,
                      total5 > total4, total5 > total3,
                      total5 > total2, total5 > total1,
                      total5 > total0};

assign comp6 [6:0] = {total6 > total7, total6 > total5,
                      total6 > total4, total6 > total3,
                      total6 > total2, total6 > total1,
                      total6 > total0};

assign comp7 [6:0] = {total7 > total6, total7 > total5,
                      total7 > total4, total7 > total3,
                      total7 > total2, total7 > total1,
                      total7 > total0};



wire [2:0]  onecount0,
            onecount1,
            onecount2,
            onecount3,
            onecount4,
            onecount5,
            onecount6,
            onecount7;

assign onecount0 = {2'd0,comp0[0]}+{2'd0,comp0[1]}+{2'd0,comp0[2]}+{2'd0,comp0[3]}+{2'd0,comp0[4]}+{2'd0,comp0[5]}+{2'd0,comp0[6]};
assign onecount1 = {2'd0,comp1[0]}+{2'd0,comp1[1]}+{2'd0,comp1[2]}+{2'd0,comp1[3]}+{2'd0,comp1[4]}+{2'd0,comp1[5]}+{2'd0,comp1[6]};
assign onecount2 = {2'd0,comp2[0]}+{2'd0,comp2[1]}+{2'd0,comp2[2]}+{2'd0,comp2[3]}+{2'd0,comp2[4]}+{2'd0,comp2[5]}+{2'd0,comp2[6]};
assign onecount3 = {2'd0,comp3[0]}+{2'd0,comp3[1]}+{2'd0,comp3[2]}+{2'd0,comp3[3]}+{2'd0,comp3[4]}+{2'd0,comp3[5]}+{2'd0,comp3[6]};
assign onecount4 = {2'd0,comp4[0]}+{2'd0,comp4[1]}+{2'd0,comp4[2]}+{2'd0,comp4[3]}+{2'd0,comp4[4]}+{2'd0,comp4[5]}+{2'd0,comp4[6]};
assign onecount5 = {2'd0,comp5[0]}+{2'd0,comp5[1]}+{2'd0,comp5[2]}+{2'd0,comp5[3]}+{2'd0,comp5[4]}+{2'd0,comp5[5]}+{2'd0,comp5[6]};
assign onecount6 = {2'd0,comp6[0]}+{2'd0,comp6[1]}+{2'd0,comp6[2]}+{2'd0,comp6[3]}+{2'd0,comp6[4]}+{2'd0,comp6[5]}+{2'd0,comp6[6]};
assign onecount7 = {2'd0,comp7[0]}+{2'd0,comp7[1]}+{2'd0,comp7[2]}+{2'd0,comp7[3]}+{2'd0,comp7[4]}+{2'd0,comp7[5]}+{2'd0,comp7[6]};

assign list7 =  (onecount0 == 3'd7)?total0:
                (onecount1 == 3'd7)?total1:
                (onecount2 == 3'd7)?total2:
                (onecount3 == 3'd7)?total3:
                (onecount4 == 3'd7)?total4:
                (onecount5 == 3'd7)?total5:
                (onecount6 == 3'd7)?total6:total7;

assign list6 =  (onecount0 == 3'd6)?total0:
                (onecount1 == 3'd6)?total1:
                (onecount2 == 3'd6)?total2:
                (onecount3 == 3'd6)?total3:
                (onecount4 == 3'd6)?total4:
                (onecount5 == 3'd6)?total5:
                (onecount6 == 3'd6)?total6:total7;

assign list5 =  (onecount0 == 3'd5)?total0:
                (onecount1 == 3'd5)?total1:
                (onecount2 == 3'd5)?total2:
                (onecount3 == 3'd5)?total3:
                (onecount4 == 3'd5)?total4:
                (onecount5 == 3'd5)?total5:
                (onecount6 == 3'd5)?total6:total7;

assign list4 =  (onecount0 == 3'd4)?total0:
                (onecount1 == 3'd4)?total1:
                (onecount2 == 3'd4)?total2:
                (onecount3 == 3'd4)?total3:
                (onecount4 == 3'd4)?total4:
                (onecount5 == 3'd4)?total5:
                (onecount6 == 3'd4)?total6:total7;

assign list3 =  (onecount0 == 3'd3)?total0:
                (onecount1 == 3'd3)?total1:
                (onecount2 == 3'd3)?total2:
                (onecount3 == 3'd3)?total3:
                (onecount4 == 3'd3)?total4:
                (onecount5 == 3'd3)?total5:
                (onecount6 == 3'd3)?total6:total7;

assign list2 =  (onecount0 == 3'd2)?total0:
                (onecount1 == 3'd2)?total1:
                (onecount2 == 3'd2)?total2:
                (onecount3 == 3'd2)?total3:
                (onecount4 == 3'd2)?total4:
                (onecount5 == 3'd2)?total5:
                (onecount6 == 3'd2)?total6:total7;

assign list1 =  (onecount0 == 3'd1)?total0:
                (onecount1 == 3'd1)?total1:
                (onecount2 == 3'd1)?total2:
                (onecount3 == 3'd1)?total3:
                (onecount4 == 3'd1)?total4:
                (onecount5 == 3'd1)?total5:
                (onecount6 == 3'd1)?total6:total7;

assign list0 =  (onecount0 == 3'd0)?total0:
                (onecount1 == 3'd0)?total1:
                (onecount2 == 3'd0)?total2:
                (onecount3 == 3'd0)?total3:
                (onecount4 == 3'd0)?total4:
                (onecount5 == 3'd0)?total5:
                (onecount6 == 3'd0)?total6:total7;




endmodule








//================================================================
//     Bellow part is bubblesort comb from CSDN, but it looks weird
//================================================================

// module bubble (
//     total0,
//     total1,
//     total2,
//     total3,
//     total4,
//     total5,
//     total6,
//     total7,
//     list0,
//     list1,
//     list2,
//     list3,
//     list4,
//     list5,
//     list6,
//     list7,
// );

// input [7:0]
//     total0,
//     total1,
//     total2,
//     total3,
//     total4,
//     total5,
//     total6,
//     total7;

// output [7:0]  //list7 is the biggest one .
//     list0,
//     list1,
//     list2,
//     list3,
//     list4,
//     list5,
//     list6,
//     list7;

// reg [7:0]temp;

// always @(*) begin
//     if (total0 > total1) begin
//         temp  = total0;
//         total0 = total1;
//         total1 = temp;
//     end
//     if (total1 > total2) begin
//         temp  = total1;
//         total1 = total2;
//         total2 = temp;
//     end
//     if (total2 > total3) begin
//         temp  = total2;
//         total2 = total3;
//         total3 = temp;
//     end
//     if (total3 > total4) begin
//         temp  = total3;
//         total3 = total4;
//         total4 = temp;
//     end
//     if (total4 > total5) begin
//         temp  = total4;
//         total4 = total5;
//         total5 = temp;
//     end
//     if (total5 > total6) begin
//         temp  = total5;
//         total5 = total6;
//         total6 = temp;
//     end
//     if (total6 > total7) begin
//         temp  = total6;
//         total6 = total7;
//         total7 = temp;
//     end
// end

// assign    list0 = total0;
// assign    list1 = total1;
// assign    list2 = total2;
// assign    list3 = total3;
// assign    list4 = total4;
// assign    list5 = total5;
// assign    list6 = total6;
// assign    list7 = total7;

// endmodule

