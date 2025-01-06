module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning,   // Current inning number
    input half,           // 0: top of the inning, 1: bottom of the inning
    input [2:0] action,   // Action code

    //Output Ports
    output reg out_valid,  // Result output valid
    output reg [7:0] score_A,  // Score of team A (guest team)
    output reg [7:0] score_B,  // Score of team B (home team)
    output reg [1:0] result    // 0: Team A wins, 1: Team B wins, 2: Darw
);

//==============================================//
//             Action Memo for Students         //
// Action code interpretation:
// 3’d0: Walk (BB)
// 3’d1: 1H (single hit)
// 3’d2: 2H (double hit)
// 3’d3: 3H (triple hit)
// 3’d4: HR (home run)
// 3’d5: Bunt (short hit)
// 3’d6: Ground ball
// 3’d7: Fly ball
//==============================================//

//==============================================//
//             Parameter and Integer            //
//==============================================//
// State declaration for FSM
// Example: parameter IDLE = 3'b000;

parameter Walk = 3'd0 ;
parameter H1   = 3'd1 ;
parameter H2   = 3'd2 ;
parameter H3   = 3'd3 ;
parameter HR   = 3'd4 ;
parameter Bunt = 3'd5 ;
parameter GB   = 3'd6 ;
parameter FB   = 3'd7 ;

parameter out0 = 2'd0 ;
parameter out1 = 2'd1 ;
parameter out2 = 2'd2 ;
parameter rest_time = 2'd3 ;


//==============================================//
//                 reg declaration              //
//==============================================//
reg [1:0] cs ; // number of out player dominate state

wire [3:0] score;

reg [2:0] base ;
wire [2:0] n_base;
wire [2:0]nn_base;
reg n_out_valid,nn_out_valid;
reg [1:0] ns, n_result;
reg [7:0] n_score_A, n_score_B;
wire [3:0]count;
wire last_game,action_out,GBDB;
wire wakeup;
wire [3:0]  n_score;
wire ChaSide, go_rest;
wire [3:0] true_score_A,true_score_B;


//==============================================//
//            special flag
//==============================================//
//  3 inning is a match. every inning includes two games.

assign action_out = action[2] & (action[1] | action[0]);  // Only Bunt, GB, FB can make players out.(action = 101 110 111 )
assign GBDB = (action == GB) & base[0] ;                  // Only occur when someone is at 1base, makes 2 out
assign last_game = (& inning) & half ;
assign ChaSide = (cs == out2 & action_out) | (cs == out1 & GBDB ); // stnad for evey time change team
assign go_rest =  last_game & ChaSide;
// assign out_start = action_out & &cs;                    //Game may start with out = 0 or 1, ns has to know it when cs = out3(2'b11)


//==============================================//
//             Current State Block              //
//==============================================//

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        cs <= 2'd0;
        out_valid <= 1'd0;
    end

    else begin
        cs <= (in_valid)?ns:cs;
        out_valid <=n_out_valid;
    end
end


always @( posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        score_A[3:0] <= 4'd0;
    end

    else begin
        score_A[3:0] <=true_score_A;

    end
end

always @( *) begin
    score_A[7:4] <=4'd0;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)begin
        score_B[3:0]<= 4'd0;
    end

    else begin
        score_B[3:0] <=true_score_B;

    end
end

always @( *) begin
    score_B[7:4] =4'd0;
end
//==============================================//
//              Next State Block                //
//==============================================//


counter_v0 counter_v00 (.clk(clk), .rst_n(rst_n), .in_valid(in_valid), .count(count), .wakeup(wakeup));

always @(*) begin
    case (cs)
        out0:      ns = GBDB ?out2:
                        action_out ? out1:out0;
        out1:      ns = go_rest     ? rest_time:
                        ChaSide     ? out0:
                        action_out  ? out2:out1;
        out2:      ns = go_rest ? rest_time : (action_out ? out0 : out2);
        rest_time: ns = (wakeup)?(action_out?out1:out0):rest_time;
        default: ns = 2'dx;
    endcase
end

//twp ways to controll n_outvalid: 1.specil flag and count 2.invalid and count
always @ (*) begin
    n_out_valid = ( cs == rest_time) & (count == 4'd0) ;
end


//==============================================//
//                  Base      Logic             //
//==============================================//
// Handle base runner movements and score calculation.
// Update bases and score depending on the action:
// Example: Walk, Hits (1H, 2H, 3H), Home Runs, etc.
// base machine


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) base <= 3'd0;
    else base <= (in_valid)? n_base:base;
end


//==============================================
//                  n_base logic
//==============================================


n_base_table n_base_table0 ( ChaSide, cs, base, action, n_base);


//==============================================
//                    n_score
//==============================================


assign score =(half)?score_B[3:0]:score_A[3:0];

n_score_tab n_score_tab0 (cs, action, base, score, n_score);

n_score n_score0( .clk(clk), .rst_n(rst_n), .in_valid(in_valid), .inning(inning),
.half(half), .ChaSide(ChaSide), .score_A(score_A[3:0]), .score_B(score_B[3:0]), .count(count),
.n_score(n_score), .true_score_A(true_score_A), .true_score_B(true_score_B));

//==============================================//
//                Output Block                  //
//==============================================//
// Decide when to set out_valid high, and output score_A, score_B, and result.


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) result <= 2'd0;
    else if (score_A > score_B) result <= 2'd0;
    else if (score_A < score_B) result <= 2'd1;
    else result <= 2'd2;

end

endmodule



module counter_v0 (clk, rst_n, in_valid, count, wakeup);
input clk,rst_n,in_valid;
output reg [3:0] count;
output wakeup;
// wire [3:0] _count;
parameter Walk = 3'd0 ;
parameter H1   = 3'd1 ;
parameter H2   = 3'd2 ;
parameter H3   = 3'd3 ;
parameter HR   = 3'd4 ;
parameter Bunt = 3'd5 ;
parameter GB   = 3'd6 ;
parameter FB   = 3'd7 ;

parameter out0 = 2'd0 ;
parameter out1 = 2'd1 ;
parameter out2 = 2'd2 ;
parameter rest_time = 2'd3 ;


reg wakeup;
wire [3:0] _count;
assign _count = (!in_valid)?count + 4'd1:4'd0;

always @(posedge clk or negedge rst_n) begin

    if(!rst_n) count <= 4'd0;
    else count <= _count;

end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) wakeup <= 1'd0;
    else wakeup <= (count >= 4'd11);
end

endmodule


module n_score_tab (
    cs, action, base, score, n_score
);
input [1:0]cs;
input [2:0] action, base;
input [3:0] score;
output  [3:0]n_score;

parameter Walk = 3'd0 ;
parameter H1   = 3'd1 ;
parameter H2   = 3'd2 ;
parameter H3   = 3'd3 ;
parameter HR   = 3'd4 ;
parameter Bunt = 3'd5 ;
parameter GB   = 3'd6 ;
parameter FB   = 3'd7 ;
parameter out0 = 2'd0 ;
parameter out1 = 2'd1     ;
parameter out2 = 2'd2 ;
parameter rest_time = 2'd3 ;


wire HR4score;
assign HR4score = &base & action == HR;
wire [2:0]score_plus_HR4score;

reg [1:0]score_plus;
assign score_plus_HR4score = {1'd0,score_plus}+{2'd0,HR4score};
assign n_score = {1'd0,score_plus_HR4score} +score;
// assign n_score = {1'd0, score_plus} +(score+{3'd0,HR4score});

always @(*) begin
    if (cs == out2) begin
        case(action)
            Walk : begin
                score_plus = {2'd0,&base};
            end
            H1   : begin
                case (base)
                    3'b000:  score_plus = 2'd0 ;
                    3'b001:  score_plus = 2'd0 ;
                    3'b010:  score_plus = 2'd1;
                    3'b011:  score_plus = 2'd1;
                    3'b100:  score_plus = 2'd1;
                    3'b101:  score_plus = 2'd1;
                    3'b110:  score_plus = 2'd2;
                    3'b111:  score_plus = 2'd2;
                    default: score_plus = 2'bx;
                endcase
            end
            H2   : begin
                case (base)
                    3'b000: score_plus = 2'd0 ;
                    3'b001: score_plus = 2'd1;
                    3'b010: score_plus = 2'd1;
                    3'b011: score_plus = 2'd2;
                    3'b100: score_plus = 2'd1;
                    3'b101: score_plus = 2'd2;
                    3'b110: score_plus = 2'd2;
                    3'b111: score_plus = 2'd3;
                    default:score_plus = 2'bx;
                endcase
            end
            H3   : begin
                case (base)
                    3'b000:  score_plus = 2'd0;
                    3'b001:  score_plus = 2'd1;
                    3'b010:  score_plus = 2'd1;
                    3'b011:  score_plus = 2'd2;
                    3'b100:  score_plus = 2'd1;
                    3'b101:  score_plus = 2'd2;
                    3'b110:  score_plus = 2'd2;
                    3'b111:  score_plus = 2'd3;
                    default: score_plus = 2'bx;
                endcase
            end
            HR   : begin
                case (base)
                    3'b000:  score_plus = 2'd1;
                    3'b001:  score_plus = 2'd2;
                    3'b010:  score_plus = 2'd2;
                    3'b011:  score_plus = 2'd3;
                    3'b100:  score_plus = 2'd2;
                    3'b101:  score_plus = 2'd3;
                    3'b110:  score_plus = 2'd3;
                    3'b111:  score_plus = 2'd3;
                    default: score_plus = 2'bx;
                endcase
            end
            Bunt : score_plus = 2'bx;
            GB   : begin
                    score_plus = 2'd0;
            end
            FB   : begin
                    score_plus = 2'd0;
            end
        endcase
    end

    else begin
        case(action)
            Walk : begin
                score_plus = {1'd0,&base};
            end
            H1   : begin
                score_plus = {1'd0,base[2]};
            end
            H2   : begin
                case (base)
                    3'b000: score_plus = 2'd0 ;
                    3'b001: score_plus = 2'd0 ;
                    3'b010: score_plus = 2'd1;
                    3'b011: score_plus = 2'd1;
                    3'b100: score_plus = 2'd1;
                    3'b101: score_plus = 2'd1;
                    3'b110: score_plus = 2'd2;
                    3'b111: score_plus = 2'd2;
                    default:score_plus = 2'bx;
                endcase
            end
            H3   : begin
                case (base)
                    3'b000:  score_plus = 2'd0;
                    3'b001:  score_plus = 2'd1;
                    3'b010:  score_plus = 2'd1;
                    3'b011:  score_plus = 2'd2;
                    3'b100:  score_plus = 2'd1;
                    3'b101:  score_plus = 2'd2;
                    3'b110:  score_plus = 2'd2;
                    3'b111:  score_plus = 2'd3;
                    default: score_plus = 2'bx;
                endcase
            end
            HR   : begin
                case (base)
                    3'b000:  score_plus = 2'd1;
                    3'b001:  score_plus = 2'd2;
                    3'b010:  score_plus = 2'd2;
                    3'b011:  score_plus = 2'd3;
                    3'b100:  score_plus = 2'd2;
                    3'b101:  score_plus = 2'd3;
                    3'b110:  score_plus = 2'd3;
                    3'b111:  score_plus = 2'd3;
                    default: score_plus = 2'bx;
                endcase
            end
            Bunt : begin
                score_plus = {1'd0,base[2]};
            end
            GB   : begin
                score_plus = {1'd0,base[2]};
            end
            FB   : begin
                score_plus = {1'd0,base[2]};
            end
        endcase
    end
end


endmodule



module n_score (
    input clk,
    input rst_n,
    input in_valid,
    input half,
    input ChaSide,
    input [1:0] inning,
    input [3:0] score_A,
    input [3:0] score_B,
    input [3:0] count,
    input [3:0] n_score,
    output reg[3:0] true_score_A,
    output reg[3:0] true_score_B
);

reg [3:0]n_score_A,n_score_B;
reg stopBscore;

//only two state, playing(valid=1) and rest_time (valid=0).
//while rest time, your score will be kept until count == 4'd5, then be cleared .
//when playing, score will not update if chaSide=1 or you aren't the hitter.

always @(*) begin
    if (in_valid) begin //playing, score will update or keep.
        true_score_A=n_score_A; //we will deal with chaSide=1 or you aren't the hitter in n_score_A.
        true_score_B=n_score_B;
    end
    else begin //rest time
        if (count == 4'd5) begin
            true_score_A=4'd0;
            true_score_B=4'd0;
        end
        else  begin
            true_score_A = score_A;
            true_score_B = score_B;
        end
    end

end

// score will update or keep.
// deal with chaSide=1 or you aren't the hitter
always @(*) begin
    n_score_A = (half  | ChaSide)?score_A[3:0]: n_score;  //half == 1, bottom inning, score_A doesn't change.
    n_score_B = (!half | ChaSide)?score_B[3:0]:                  //half == 0, top inning, score_B doesn't change.
                ((&inning)&stopBscore)?score_B[3:0]:n_score;
end

// stopBscore only changes at 5th game, but after rising, it shouldn't immediately work until 6th games.
always @(posedge clk  or negedge rst_n) begin
    if (!rst_n) begin
        stopBscore <= 1'd0;
    end
    else if ( &inning & !half & in_valid)
        stopBscore <= score_A < score_B;
    else stopBscore <= stopBscore;
end

endmodule



module n_base_table (
    input ChaSide,
    input [1:0] cs,
    input [2:0] base,
    input [2:0] action,
    output reg [2:0] n_base
);

parameter Walk = 3'd0 ;
parameter H1   = 3'd1 ;
parameter H2   = 3'd2 ;
parameter H3   = 3'd3 ;
parameter HR   = 3'd4 ;
parameter Bunt = 3'd5 ;
parameter GB   = 3'd6 ;
parameter FB   = 3'd7 ;
parameter out0 = 2'd0 ;
parameter out1 = 2'd1 ;
parameter out2 = 2'd2 ;
parameter rest_time = 2'd3 ;

//cs-act-base
always @(*) begin
    if (ChaSide) begin
        n_base =3'b000;
    end

    else begin
        if (cs == out2) begin
            casex(action)
                Walk : begin
                    casex (base)
                        3'b000:  n_base = 3'b001;
                        3'b001:  n_base = 3'b011;
                        3'b010:  n_base = 3'b011;
                        3'b011:  n_base = 3'b111;
                        3'b100:  n_base = 3'b101;
                        3'b101:  n_base = 3'b111;
                        3'b110:  n_base = 3'b111;
                        3'b111:  n_base = 3'b111;
                        default: n_base = 3'bx  ;
                    endcase
                end
                H1   : begin
                    // n_base[1:0] = 2'b01;
                    // n_base[2] = base [0]; // worse than MUX ??????
                    casex (base)
                        3'b000:  n_base = 3'b001;
                        3'b001:  n_base = 3'b101;
                        3'b010:  n_base = 3'b001;
                        3'b011:  n_base = 3'b101;
                        3'b100:  n_base = 3'b001;
                        3'b101:  n_base = 3'b101;
                        3'b110:  n_base = 3'b001;
                        3'b111:  n_base = 3'b101;
                        default: n_base = 3'bx   ;
                    endcase
                end
                H2   : begin
                        n_base = 3'b010;
                end
                H3   : begin
                        n_base = 3'b100;
                end
                HR   : begin
                        n_base = 3'b000;
                end
                Bunt : n_base = 3'bX  ;

                GB   : begin
                        n_base = 3'b000;
                end
                FB   : begin
                    n_base = 3'b0;
                end
            endcase
        end

        else begin
            casex(action)
                Walk : begin
                    casex (base)
                        3'b000:  n_base = 3'b001;
                        3'b001:  n_base = 3'b011;
                        3'b010:  n_base = 3'b011;
                        3'b011:  n_base = 3'b111;
                        3'b100:  n_base = 3'b101;
                        3'b101:  n_base = 3'b111;
                        3'b110:  n_base = 3'b111;
                        3'b111:  n_base = 3'b111;
                        default: n_base = 3'bx  ;
                    endcase
                end
                H1   : begin
                    casex (base)
                        3'b000:  n_base = 3'b001;
                        3'b001:  n_base = 3'b011;
                        3'b010:  n_base = 3'b101;
                        3'b011:  n_base = 3'b111;
                        3'b100:  n_base = 3'b001;
                        3'b101:  n_base = 3'b011;
                        3'b110:  n_base = 3'b101;
                        3'b111:  n_base = 3'b111;
                        default: n_base = 3'bx   ;
                    endcase
                end
                H2   : begin
                    casex (base)
                        3'b000:n_base = 3'b010;
                        3'b001:n_base = 3'b110;
                        3'b010:n_base = 3'b010;
                        3'b011:n_base = 3'b110;
                        3'b100:n_base = 3'b010;
                        3'b101:n_base = 3'b110;
                        3'b110:n_base = 3'b010;
                        3'b111:n_base = 3'b110;
                        default: n_base = 3'bx;
                    endcase
                end
                H3   : begin
                    casex (base)
                        3'b000:  n_base = 3'b100;
                        3'b001:  n_base = 3'b100;
                        3'b010:  n_base = 3'b100;
                        3'b011:  n_base = 3'b100;
                        3'b100:  n_base = 3'b100;
                        3'b101:  n_base = 3'b100;
                        3'b110:  n_base = 3'b100;
                        3'b111:  n_base = 3'b100;
                        default: n_base = 3'bx  ;
                    endcase
                end
                HR   : begin
                    casex (base)
                        3'b000:  n_base = 3'b000;
                        3'b001:  n_base = 3'b000;
                        3'b010:  n_base = 3'b000;
                        3'b011:  n_base = 3'b000;
                        3'b100:  n_base = 3'b000;
                        3'b101:  n_base = 3'b000;
                        3'b110:  n_base = 3'b000;
                        3'b111:  n_base = 3'b000;
                        default: n_base = 3'bx  ;
                    endcase
                end
                Bunt : begin
                    casex (base)
                        3'b000:  n_base = 3'bX  ;
                        3'b001:  n_base = 3'b010;
                        3'b010:  n_base = 3'b100;
                        3'b011:  n_base = 3'b110;
                        3'b100:  n_base = 3'b000;
                        3'b101:  n_base = 3'b010;
                        3'b110:  n_base = 3'b100;
                        3'b111:  n_base = 3'b110;
                        default: n_base = 3'bX  ;
                    endcase
                end
                GB   : begin
                    casex (base)
                        3'b000:  n_base = 3'b000;
                        3'b001:  n_base = 3'b000;
                        3'b010:  n_base = 3'b100;
                        3'b011:  n_base = 3'b100;
                        3'b100:  n_base = 3'b000;
                        3'b101:  n_base = 3'b000;
                        3'b110:  n_base = 3'b100;
                        3'b111:  n_base = 3'b100;
                        default: n_base = 3'bX  ;
                    endcase
                end
                FB   : begin
                    casex (base)
                        3'b000:  n_base = 3'b000;
                        3'b001:  n_base = 3'b001;
                        3'b010:  n_base = 3'b010;
                        3'b011:  n_base = 3'b011;
                        3'b100:  n_base = 3'b000;
                        3'b101:  n_base = 3'b001;
                        3'b110:  n_base = 3'b010;
                        3'b111:  n_base = 3'b011;
                        default: n_base = 3'bx;
                    endcase
                end
            endcase

        end
    end
end

endmodule


//cs-base-act
// module n_base_table (
//     input ChaSide,
//     input [1:0] cs,
//     input [2:0] base,
//     input [2:0] action,
//     output reg [2:0] n_base
// );

// parameter Walk = 3'd0 ;
// parameter H1   = 3'd1 ;
// parameter H2   = 3'd2 ;
// parameter H3   = 3'd3 ;
// parameter HR   = 3'd4 ;
// parameter Bunt = 3'd5 ;
// parameter GB   = 3'd6 ;
// parameter FB   = 3'd7 ;
// parameter out0 = 2'd0 ;
// parameter out1 = 2'd1 ;
// parameter out2 = 2'd2 ;
// parameter rest_time = 2'd3 ;

// // base-act-cs
// always @(*) begin
//     if (ChaSide) begin
//         n_base =3'b000;
//     end

//     else begin
//         case (base)
//             3'b000: begin
//                 case (action)
//                     Walk: begin
//                         if (cs == out2) n_base = 3'b001;
//                         else n_base = 3'b001;
//                     end
//                     H1  : begin
//                         if (cs == out2) n_base = 3'b001;
//                         else n_base = 3'b001;
//                     end
//                     H2  : begin
//                         if (cs == out2) n_base = 3'b010;
//                         else n_base = 3'b010;
//                     end
//                     H3  : begin
//                         if (cs == out2) n_base = 3'b100;
//                         else n_base = 3'b100;
//                     end
//                     HR  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     Bunt: begin
//                         if (cs == out2) n_base = 3'bX  ;
//                         else n_base = 3'bX  ;
//                     end
//                     GB  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     FB  : begin
//                         if (cs == out2) n_base = 3'b0;
//                         else n_base = 3'b000;
//                     end
//                 endcase
//             end
//             3'b001: begin
//                 case (action)
//                     Walk: begin
//                         if (cs == out2) n_base = 3'b011;
//                         else n_base = 3'b011;
//                     end
//                     H1  : begin
//                         if (cs == out2) n_base = 3'b101;
//                         else n_base = 3'b011;
//                     end
//                     H2  : begin
//                         if (cs == out2) n_base = 3'b010;
//                         else n_base = 3'b110;
//                     end
//                     H3  : begin
//                         if (cs == out2) n_base = 3'b100;
//                         else n_base = 3'b100;
//                     end
//                     HR  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     Bunt: begin
//                         if (cs == out2) n_base = 3'bX  ;
//                         else n_base = 3'b010;
//                     end
//                     GB  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     FB  : begin
//                         if (cs == out2) n_base = 3'b0;
//                         else n_base = 3'b001;
//                     end
//                 endcase
//             end
//             3'b010: begin
//                 case (action)
//                     Walk: begin
//                         if (cs == out2) n_base = 3'b011;
//                         else n_base = 3'b011;
//                     end
//                     H1  : begin
//                         if (cs == out2) n_base = 3'b001;
//                         else n_base = 3'b101;
//                     end
//                     H2  : begin
//                         if (cs == out2) n_base = 3'b010;
//                         else n_base = 3'b010;
//                     end
//                     H3  : begin
//                         if (cs == out2) n_base = 3'b100;
//                         else n_base = 3'b100;
//                     end
//                     HR  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     Bunt: begin
//                         if (cs == out2) n_base = 3'bX  ;
//                         else n_base = 3'b100;
//                     end
//                     GB  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b100;
//                     end
//                     FB  : begin
//                         if (cs == out2) n_base = 3'b0;
//                         else n_base = 3'b010;
//                     end
//                 endcase
//             end
//             3'b011: begin
//                 case (action)
//                     Walk: begin
//                         if (cs == out2) n_base = 3'b111;
//                         else n_base = 3'b111;
//                     end
//                     H1  : begin
//                         if (cs == out2) n_base = 3'b101;
//                         else n_base = 3'b111;
//                     end
//                     H2  : begin
//                         if (cs == out2) n_base = 3'b010;
//                         else n_base = 3'b110;
//                     end
//                     H3  : begin
//                         if (cs == out2) n_base = 3'b100;
//                         else n_base = 3'b100;
//                     end
//                     HR  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     Bunt: begin
//                         if (cs == out2) n_base = 3'bX  ;
//                         else n_base = 3'b110;
//                     end
//                     GB  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b100;
//                     end
//                     FB  : begin
//                         if (cs == out2) n_base = 3'b0;
//                         else n_base = 3'b011;
//                     end
//                 endcase
//             end
//             3'b100: begin
//                 case (action)
//                     Walk: begin
//                         if (cs == out2) n_base = 3'b101;
//                         else n_base = 3'b101;
//                     end
//                     H1  : begin
//                         if (cs == out2) n_base = 3'b001;
//                         else n_base = 3'b001;
//                     end
//                     H2  : begin
//                         if (cs == out2) n_base = 3'b010;
//                         else n_base = 3'b010;
//                     end
//                     H3  : begin
//                         if (cs == out2) n_base = 3'b100;
//                         else n_base = 3'b100;
//                     end
//                     HR  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     Bunt: begin
//                         if (cs == out2) n_base = 3'bX  ;
//                         else n_base = 3'b000;
//                     end
//                     GB  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     FB  : begin
//                         if (cs == out2) n_base = 3'b0;
//                         else n_base = 3'b000;
//                     end
//                 endcase
//             end
//             3'b101: begin
//                 case (action)
//                     Walk: begin
//                         if (cs == out2) n_base = 3'b111;
//                         else n_base = 3'b111;
//                     end
//                     H1  : begin
//                         if (cs == out2) n_base = 3'b101;
//                         else n_base = 3'b011;
//                     end
//                     H2  : begin
//                         if (cs == out2) n_base = 3'b010;
//                         else n_base = 3'b110;
//                     end
//                     H3  : begin
//                         if (cs == out2) n_base = 3'b100;
//                         else n_base = 3'b100;
//                     end
//                     HR  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     Bunt: begin
//                         if (cs == out2) n_base = 3'bX  ;
//                         else n_base = 3'b010;
//                     end
//                     GB  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     FB  : begin
//                         if (cs == out2) n_base = 3'b0;
//                         else n_base = 3'b001;
//                     end
//                 endcase
//             end
//             3'b110: begin
//                 case (action)
//                     Walk: begin
//                         if (cs == out2) n_base = 3'b111;
//                         else n_base = 3'b111;
//                     end
//                     H1  : begin
//                         if (cs == out2) n_base = 3'b001;
//                         else n_base = 3'b101;
//                     end
//                     H2  : begin
//                         if (cs == out2) n_base = 3'b010;
//                         else n_base = 3'b010;
//                     end
//                     H3  : begin
//                         if (cs == out2) n_base = 3'b100;
//                         else n_base = 3'b100;
//                     end
//                     HR  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     Bunt: begin
//                         if (cs == out2) n_base = 3'bX  ;
//                         else n_base = 3'b100;
//                     end
//                     GB  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b100;
//                     end
//                     FB  : begin
//                         if (cs == out2) n_base = 3'b0;
//                         else n_base = 3'b010;
//                     end
//                 endcase
//             end
//             3'b111: begin
//                 case (action)
//                     Walk: begin
//                         if (cs == out2) n_base = 3'b111;
//                         else n_base = 3'b111;
//                     end
//                     H1  : begin
//                         if (cs == out2) n_base = 3'b101;
//                         else n_base = 3'b111;
//                     end
//                     H2  : begin
//                         if (cs == out2) n_base = 3'b010;
//                         else n_base = 3'b110;
//                     end
//                     H3  : begin
//                         if (cs == out2) n_base = 3'b100;
//                         else n_base = 3'b100;
//                     end
//                     HR  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b000;
//                     end
//                     Bunt: begin
//                         if (cs == out2) n_base = 3'bX  ;
//                         else n_base = 3'b110;
//                     end
//                     GB  : begin
//                         if (cs == out2) n_base = 3'b000;
//                         else n_base = 3'b100;
//                     end
//                     FB  : begin
//                         if (cs == out2) n_base = 3'b0;
//                         else n_base = 3'b011;
//                     end
//                 endcase
//             end
//         endcase
//     end
// end

// endmodule




// //cs-base-act
// module n_base_table (
//     input ChaSide,
//     input [1:0] cs,
//     input [2:0] base,
//     input [2:0] action,
//     output reg [2:0] n_base
// );

// parameter Walk = 3'd0 ;
// parameter H1   = 3'd1 ;
// parameter H2   = 3'd2 ;
// parameter H3   = 3'd3 ;
// parameter HR   = 3'd4 ;
// parameter Bunt = 3'd5 ;
// parameter GB   = 3'd6 ;
// parameter FB   = 3'd7 ;
// parameter out0 = 2'd0 ;
// parameter out1 = 2'd1 ;
// parameter out2 = 2'd2 ;
// parameter rest_time = 2'd3 ;


// always @(*) begin
//     if (ChaSide) begin
//         n_base =3'b000;
//     end

//     else begin
//         if (cs == out2) begin
//             case (base)
//                 3'b000:begin
//                     case (action)
//                         Walk:   n_base = 3'b001;
//                         H1  :   n_base = 3'b001;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b0;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b001:begin
//                     case (action)
//                         Walk:   n_base = 3'b011;
//                         H1  :   n_base = 3'b101;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b0;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b010:begin
//                     case (action)
//                         Walk:   n_base = 3'b011;
//                         H1  :   n_base = 3'b001;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b0;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b011:begin
//                     case (action)
//                         Walk:   n_base = 3'b111;
//                         H1  :   n_base = 3'b101;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b0;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b100:begin
//                     case (action)
//                         Walk:   n_base = 3'b101;
//                         H1  :   n_base = 3'b001;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b0;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b101:begin
//                     case (action)
//                         Walk:   n_base = 3'b111;
//                         H1  :   n_base = 3'b101;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b0;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b110:begin
//                     case (action)
//                         Walk:   n_base = 3'b111;
//                         H1  :   n_base = 3'b001;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b0;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b111:begin
//                     case (action)
//                         Walk:   n_base = 3'b111;
//                         H1  :   n_base = 3'b101;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b0;
//                         default:n_base = 3'bX;
//                     endcase
//                 end

//             endcase
//         end

//         else begin
//             case (base)
//                 3'b000:begin
//                     case (action)
//                         Walk:   n_base = 3'b001;
//                         H1  :   n_base = 3'b001;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'bX  ;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b000;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b001:begin
//                     case (action)
//                         Walk:   n_base = 3'b011;
//                         H1  :   n_base = 3'b011;
//                         H2  :   n_base = 3'b110;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'b010;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b001;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b010:begin
//                     case (action)
//                         Walk:   n_base = 3'b011;
//                         H1  :   n_base = 3'b101;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'b100;
//                         GB  :   n_base = 3'b100;
//                         FB  :   n_base = 3'b010;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b011:begin
//                     case (action)
//                         Walk:   n_base = 3'b111;
//                         H1  :   n_base = 3'b111;
//                         H2  :   n_base = 3'b110;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'b110;
//                         GB  :   n_base = 3'b100;
//                         FB  :   n_base = 3'b011;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b100:begin
//                     case (action)
//                         Walk:   n_base = 3'b101;
//                         H1  :   n_base = 3'b001;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'b000;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b000;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b101:begin
//                     case (action)
//                         Walk:   n_base = 3'b111;
//                         H1  :   n_base = 3'b011;
//                         H2  :   n_base = 3'b110;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'b010;
//                         GB  :   n_base = 3'b000;
//                         FB  :   n_base = 3'b001;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b110:begin
//                     case (action)
//                         Walk:   n_base = 3'b111;
//                         H1  :   n_base = 3'b101;
//                         H2  :   n_base = 3'b010;
//                         H3  :   n_base = 3'b100;
//                         HR  :   n_base = 3'b000;
//                         Bunt:   n_base = 3'b100;
//                         GB  :   n_base = 3'b100;
//                         FB  :   n_base = 3'b010;
//                         default:n_base = 3'bX;
//                     endcase
//                 end
//                 3'b111:begin
//                     case (action)
//                         Walk:    n_base = 3'b111;
//                         H1  :    n_base = 3'b111;
//                         H2  :    n_base = 3'b110;
//                         H3  :    n_base = 3'b100;
//                         HR  :    n_base = 3'b000;
//                         Bunt:    n_base = 3'b110;
//                         GB  :    n_base = 3'b100;
//                         FB  :    n_base = 3'b011;
//                         default: n_base = 3'bX;
//                     endcase
//                 end
//             endcase

//         end
//     end
// end

// endmodule








//act-cs-base
// module n_base_table (
//     input ChaSide,
//     input [1:0] cs,
//     input [2:0] base,
//     input [2:0] action,
//     output reg [2:0] n_base
// );

// parameter Walk = 3'd0 ;
// parameter H1   = 3'd1 ;
// parameter H2   = 3'd2 ;
// parameter H3   = 3'd3 ;
// parameter HR   = 3'd4 ;
// parameter Bunt = 3'd5 ;
// parameter GB   = 3'd6 ;
// parameter FB   = 3'd7 ;
// parameter out0 = 2'd0 ;
// parameter out1 = 2'd1 ;
// parameter out2 = 2'd2 ;
// parameter rest_time = 2'd3 ;


// always @(*) begin
//     if (ChaSide) begin
//         n_base =3'b000;
//     end

//     else begin
//         case (action)
//             Walk:begin
//                 if (cs == out2) begin
//                     case (base)
//                         3'b000:  n_base = 3'b001;
//                         3'b001:  n_base = 3'b011;
//                         3'b010:  n_base = 3'b011;
//                         3'b011:  n_base = 3'b111;
//                         3'b100:  n_base = 3'b101;
//                         3'b101:  n_base = 3'b111;
//                         3'b110:  n_base = 3'b111;
//                         3'b111:  n_base = 3'b111;
//                         default: n_base = 3'bx  ;
//                     endcase
//                 end
//                 else begin
//                     case (base)
//                         3'b000:  n_base = 3'b001;
//                         3'b001:  n_base = 3'b011;
//                         3'b010:  n_base = 3'b011;
//                         3'b011:  n_base = 3'b111;
//                         3'b100:  n_base = 3'b101;
//                         3'b101:  n_base = 3'b111;
//                         3'b110:  n_base = 3'b111;
//                         3'b111:  n_base = 3'b111;
//                         default: n_base = 3'bx  ;
//                     endcase
//                 end
//             end
//             H1  :begin
//                 if (cs == out2) begin
//                     case (base)
//                         3'b000:  n_base = 3'b001;
//                         3'b001:  n_base = 3'b101;
//                         3'b010:  n_base = 3'b001;
//                         3'b011:  n_base = 3'b101;
//                         3'b100:  n_base = 3'b001;
//                         3'b101:  n_base = 3'b101;
//                         3'b110:  n_base = 3'b001;
//                         3'b111:  n_base = 3'b101;
//                         default: n_base = 3'bx   ;
//                     endcase
//                 end
//                 else begin
//                     case (base)
//                         3'b000:  n_base = 3'b001;
//                         3'b001:  n_base = 3'b011;
//                         3'b010:  n_base = 3'b101;
//                         3'b011:  n_base = 3'b111;
//                         3'b100:  n_base = 3'b001;
//                         3'b101:  n_base = 3'b011;
//                         3'b110:  n_base = 3'b101;
//                         3'b111:  n_base = 3'b111;
//                         default: n_base = 3'bx  ;
//                     endcase
//                 end
//             end
//             H2  :begin
//                 if (cs == out2) begin
//                     n_base = 3'b010;
//                 end
//                 else begin
//                     case (base)
//                         3'b000:n_base = 3'b010;
//                         3'b001:n_base = 3'b110;
//                         3'b010:n_base = 3'b010;
//                         3'b011:n_base = 3'b110;
//                         3'b100:n_base = 3'b010;
//                         3'b101:n_base = 3'b110;
//                         3'b110:n_base = 3'b010;
//                         3'b111:n_base = 3'b110;
//                         default: n_base = 3'bx;
//                     endcase
//                 end
//             end
//             H3  :begin
//                 if (cs == out2) begin
//                     n_base = 3'b100;
//                 end
//                 else begin
//                     case (base)
//                         3'b000:  n_base = 3'b100;
//                         3'b001:  n_base = 3'b100;
//                         3'b010:  n_base = 3'b100;
//                         3'b011:  n_base = 3'b100;
//                         3'b100:  n_base = 3'b100;
//                         3'b101:  n_base = 3'b100;
//                         3'b110:  n_base = 3'b100;
//                         3'b111:  n_base = 3'b100;
//                         default: n_base = 3'bx  ;
//                     endcase
//                 end
//             end
//             HR  :begin
//                 if (cs == out2) begin
//                     n_base = 3'b000;
//                 end
//                 else begin
//                     case (base)
//                         3'b000:  n_base = 3'b000;
//                         3'b001:  n_base = 3'b000;
//                         3'b010:  n_base = 3'b000;
//                         3'b011:  n_base = 3'b000;
//                         3'b100:  n_base = 3'b000;
//                         3'b101:  n_base = 3'b000;
//                         3'b110:  n_base = 3'b000;
//                         3'b111:  n_base = 3'b000;
//                         default: n_base = 3'bx  ;
//                     endcase
//                 end
//             end
//             Bunt:begin
//                 if (cs == out2) begin
//                     n_base = 3'bX  ;
//                 end
//                 else begin
//                     case (base)
//                         3'b000:  n_base = 3'bX  ;
//                         3'b001:  n_base = 3'b010;
//                         3'b010:  n_base = 3'b100;
//                         3'b011:  n_base = 3'b110;
//                         3'b100:  n_base = 3'b000;
//                         3'b101:  n_base = 3'b010;
//                         3'b110:  n_base = 3'b100;
//                         3'b111:  n_base = 3'b110;
//                         default: n_base = 3'bX  ;
//                     endcase
//                 end
//             end
//             GB  :begin
//                 if (cs == out2) begin
//                     n_base = 3'b000;
//                 end
//                 else begin
//                     case (base)
//                         3'b000:  n_base = 3'b000;
//                         3'b001:  n_base = 3'b000;
//                         3'b010:  n_base = 3'b100;
//                         3'b011:  n_base = 3'b100;
//                         3'b100:  n_base = 3'b000;
//                         3'b101:  n_base = 3'b000;
//                         3'b110:  n_base = 3'b100;
//                         3'b111:  n_base = 3'b100;
//                         default: n_base = 3'bX  ;
//                     endcase
//                 end
//             end
//             FB  :begin
//                 if (cs == out2) begin
//                     n_base = 3'b0;
//                 end
//                 else begin
//                     case (base)
//                         3'b000:  n_base = 3'b000;
//                         3'b001:  n_base = 3'b001;
//                         3'b010:  n_base = 3'b010;
//                         3'b011:  n_base = 3'b011;
//                         3'b100:  n_base = 3'b000;
//                         3'b101:  n_base = 3'b001;
//                         3'b110:  n_base = 3'b010;
//                         3'b111:  n_base = 3'b011;
//                         default: n_base = 3'bx;
//                     endcase
//                 end
//             end
//         endcase
//     end
// end

// endmodule




