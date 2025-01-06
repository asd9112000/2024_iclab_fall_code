/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: SA
// FILE NAME: SA_wocg.v
// VERSRION: 1.0
// DATE: Nov 06, 2024
// AUTHOR: Yen-Ning Tung, NYCU AIG
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2024 Spring IC Lab / Exersise Lab08 / SA_wocg
// MODIFICATION HISTORY:
// Date                 Description
//
/**************************************************************************/

module SA(
	// Input signals
	clk,
	rst_n,
	in_valid,
	T,
	in_data,
	w_Q,
	w_K,
	w_V,
	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input [3:0] T;
input signed [7:0] in_data;
input signed [7:0] w_Q;
input signed [7:0] w_K;
input signed [7:0] w_V;

output reg out_valid;
output reg signed [63:0] out_data;


//==============================================//
//       parameter & integer declaration        //
//==============================================//

parameter  IDLE = 3'd0;
parameter  T1 = 3'd1;
parameter  T4 = 3'd2;
parameter  T8 = 3'd3;
parameter  WORK2 = 3'd2;
integer i, j, k, m ,n;
genvar  a, b, c, d ,e;


//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [2:0] cs, ns;
reg [7:0] cnt256;
// reg [5:0] cnt64	;
reg [5:0] cnt64Q;
reg [5:0] cnt64KV;
reg [5:0] cnt64_x_reg;





//============================================================
//
//                          GATED_CLK
//
//============================================================




//============================================================
//
//                          END　SIGNAL
//
//============================================================
wire test;
assign test= 'd1;

reg  set_end;
reg  send_out;



always @( * ) begin
    set_end = ( 	(cs == T8 && cnt256 == 'd255)
				||	(cs == T4 && cnt256 == 'd223)
				|| 	(cs == T1 && cnt256 == 'd199));
end

always @ (*) begin
	if ( 	cs == T8 && (cnt256 >= 'd192 && cnt256 <= 'd255)
		||	cs == T4 && (cnt256 >= 'd192 && cnt256 <= 'd223)
		|| 	cs == T1 && (cnt256 >= 'd192 && cnt256 <= 'd199))
		send_out = 'd1;
	else
		send_out = 'd0;
end
//============================================================
//
//                          FSM
//
//============================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= IDLE;
    else
        cs <= ns;
end

always @(*) begin
    case ( cs)
        IDLE :if (in_valid)
					case (T)
						'd1:ns= T1;
						'd4:ns= T4;
						'd8:ns= T8;
						default: ns= IDLE;
					endcase
				else
					ns = IDLE;
        T1: ns = (set_end) ? IDLE : T1;
		T4: ns = (set_end) ? IDLE : T4;
		T8: ns = (set_end) ? IDLE : T8;
        default: ns = IDLE;
    endcase
end



//============================================================
//
//                          CNT
//
//============================================================
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt256 <= 'd0;
    else if (  set_end)
        cnt256 <= 'd0;
    else if ( in_valid || cnt256 != 'd0)
        cnt256 <= cnt256 +'d1;
end


// always @( posedge clk_64KV or negedge rst_n) begin
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt64KV <= 'd0;
    else if (  set_end)
        cnt64KV <= 'd0;
	else if (  cnt256 == 'd192 )
		cnt64KV <= 'd0;
    else if (  cnt256 != 'd0 )
        cnt64KV <= cnt64KV +'d1;
end

always @( posedge clk or negedge rst_n) begin
// always @( posedge clk_cnt64X or negedge rst_n) begin
    if (!rst_n)
        cnt64_x_reg <= 'd0;
    else if (  set_end)
        cnt64_x_reg <= 'd0;
    else if (   in_valid || cnt64_x_reg != 'd0 )
        cnt64_x_reg <= cnt64_x_reg +'d1;
end



always @( posedge clk or negedge rst_n) begin
// always @( posedge clk_cnt64Q or negedge rst_n) begin
    if (!rst_n)
        cnt64Q <= 'd0;
    else if (  set_end || cnt256 == 'd56 || cnt256 == 'd128 )
        cnt64Q <= 'd0;
    // else if (  cnt256 == 'd57 || cnt256 == 'd129 || cnt256 == 'd193 || cnt64Q != 'd0 )
    //     cnt64Q <= cnt64Q +'d1;
    else
        cnt64Q <= cnt64Q +'d1;
end


//============================================================
//
//                    INPUT REGISTERS
//
//============================================================
reg  signed [7:0] W_reg [0:7][0:7];
reg  signed [7:0] X_reg [0:7][0:7];
reg  signed [7:0] X_reg_t [0:7][0:7];


generate
for(a=0; a<8; a=a+1) begin :W_reg_y
	for(b=0; b<8; b=b+1) begin :W_reg_x
		// GATED_OR g_weight(.CLOCK(clk), .SLEEP_CTRL(sleep_W_reg), .RST_N(rst_n), .CLOCK_GATED(clk_W_reg[a][b]));
		//Store Weight
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)  begin
				W_reg[a][b] <= 'd0;
			end
			else if (in_valid )begin
				case (cnt256[7:6])
						0: if ( a == cnt256 [5:3] && b == cnt256[2:0]) W_reg[a][b] <= w_Q;
						1: if ( b == cnt256 [5:3] && a == cnt256[2:0]) W_reg[a][b] <= w_K;
						2: if ( a == cnt256 [5:3] && b == cnt256[2:0]) W_reg[a][b] <= w_V;
					default: ;
				endcase
			end
   		end
	end
end
endgenerate



generate
for(a=0; a<8; a=a+1) begin :X_reg_y
	for(b=0; b<8; b=b+1) begin :X_reg_x
		// GATED_OR g_X_reg(.CLOCK(clk), .SLEEP_CTRL(sleep_X_reg), .RST_N(rst_n), .CLOCK_GATED(clk_X_reg[a][b]));
		//Store Weight
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)  begin
				X_reg[a][b] <= 'd0;
			end
			else if (set_end)
						X_reg[a][b]<= 'd0;
			else if (in_valid ) begin
				if ( a == cnt64_x_reg[5:3] && b == cnt64_x_reg[2:0] ) begin
					if (cnt256 == 'd0)
						X_reg[a][b] <= in_data;
					else if ( cs == T1 && cnt256 <= 'd7    )
						X_reg[a][b] <= in_data;
					else if ( cs == T4 && (cnt256 <= 'd31) )
						X_reg[a][b] <= in_data;
					else if ( cs == T8 && (cnt256 <= 'd63) )
						X_reg[a][b] <= in_data;
				end
			end
		end
	end
end
endgenerate



always @(*) begin
	for ( i = 0; i <=7 ; i = i+1)
		for (j =0; j <=7; j=j+1 )
			X_reg_t[i][j] = X_reg[j][i];
end



//============================================================
//
//                    WORK REGISTERS
//
//============================================================
reg  signed [7:0] work[1:0][31:0]; // work [y][x]
reg  signed [18:0] K_reg [0:7][0:7], V_reg [0:7][0:7];
reg  signed [41:0] Q_reg [0:8][0:7];

reg  signed [40:0] add1[0:7];
reg  signed [40:0] add1_div [0:7];
reg  signed [40:0] add1_relu[0:7];
reg  signed [18:0] add2[0:7];
reg  signed [63:0] add3;

reg  signed [18:0] add1_mul0[0:7]; // Wq     8bits, Q 19bits
reg  signed [18:0] add1_mul1[0:7]; // X_reg  8bits, K 19bits
reg  signed [40:0] add1_add [0:7]; // Q,QK   19 bits, 41bits

reg  signed [7 :0] add2_mul0[0:7]; // Wv, Wk 8bits
reg  signed [7 :0] add2_mul1[0:7]; // X_reg  8bits
reg  signed [18:0] add2_add [0:7]; // V,K    19 bits


// reg  signed [7 :0] add1_mul0[0:7]; // Wq, Wv 8bits
// reg  signed [7 :0] add1_mul1[0:7]; // X_reg  8bits
// reg  signed [18:0] add1_add [0:7]; // Q, KV   19bits

// reg  signed [18:0] add2_mul0[0:7]; // Wk     8bits, Q 19bits
// reg  signed [18:0] add2_mul1[0:7]; // X_reg  8bits, K 19bits
// reg  signed [40:0] add2_add [0:7]; // K,QK   19 bits, 41bits

reg  signed [40:0] add3_in1 [0:7];
reg  signed [18:0] add3_in2 [0:7];


always @(*) begin
	for ( i = 0; i <=7; i = i+1) begin
		add1[i] = add1_mul0[i] * add1_mul1[i]+add1_add[i];
		add2[i] = add2_mul0[i] * add2_mul1[i]+add2_add[i];
	end
end



always @(*) begin
	add3 	= ((add3_in1[0] * add3_in2[0] + add3_in1[1] * add3_in2[1]) + (add3_in1[2] * add3_in2[2] + add3_in1[3] * add3_in2[3]))
			+ ((add3_in1[4] * add3_in2[4] + add3_in1[5] * add3_in2[5]) + (add3_in1[6] * add3_in2[6] + add3_in1[7] * add3_in2[7]));
end


always @(*) begin
	for ( i = 0; i <=7; i = i+1) begin
		add1_div[i] = add1[i] / 3;
		add1_relu[i] = (add1_div[i][40]) ? 'd0 : add1_div[i]; ////////////////////////////                        pos neg?????
	end
end




wire [7:0] cnt256_sub1;
wire [7:0] cnt256_sub65;
assign cnt256_sub1 = cnt256 - 'd1;
assign cnt256_sub65 = cnt256 - 'd65;


// add1 Q, QK
// Q_reg
// wire clk_Q_reg[0:8][0:7];
generate
for(a=0; a<8; a=a+1) begin :Q_reg_y
	for(b=0; b<8; b=b+1) begin :Q_reg_x
		// GATED_OR g_Q_reg(.CLOCK(clk), .SLEEP_CTRL((cnt256 <= 'd55 ) && cg_en), .RST_N(rst_n), .CLOCK_GATED(clk_Q_reg[a][b]));
			//Store Weight
			always @(posedge clk or negedge rst_n) begin
				if (!rst_n)  begin
					Q_reg[a][b] <= 'd0;
				end
				else if (set_end)
					Q_reg[a][b]<= 'd0;
				else if (cnt256 >= 'd57 && cnt256 <= 'd120) begin
						if ( b == cnt64Q[5:3])
								Q_reg[a][b]<= add1[a];
				end
				else if (cnt256 >= 'd129 && cnt256 <= 'd192) begin
					if 	(a*8 + 7 == cnt64Q  ) begin
						Q_reg[a][b] <= add1_relu[b];
					end
				end
			end
	end
end

endgenerate

generate
for(a=8; a<9; a=a+1) begin :Q8_reg_y
	for(b=0; b<8; b=b+1) begin :Q8_reg_x
		// GATED_OR g_Q_reg(.CLOCK(clk), .SLEEP_CTRL((cnt256 <= 'd55 ) && cg_en), .RST_N(rst_n), .CLOCK_GATED(clk_Q_reg[a][b]));
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)  begin
				Q_reg[8][b] <= 'd0;
			end
			else if (set_end)
				Q_reg[8][b]<= 'd0;
			else if (cnt256 >= 'd129 && cnt256 <= 'd192) begin
				Q_reg[8][b]<= add1[b];
			end
		end
	end
end

endgenerate


// add1, Q, QK
// for ( i = 0; i <=7; i = i+1)
// 		add1[i] = add1_mul0[i] * add1_mul1[i]+add1_add[i];
// 		add2[i] = add2_mul0[i] * add2_mul1[i]+add2_add[i];
always @(*) begin
		if  (cnt256 >= 'd57 && cnt256 <= 'd120)begin // 57~120 for Q
			for ( i = 0; i <=7; i = i+1	) begin
				add1_add [i] = Q_reg  [i][cnt64Q[5:3]];
				add1_mul0[i] = W_reg  [cnt64Q[2:0]][(cnt64Q[5:3])];
				add1_mul1[i] = X_reg  [i][ cnt64Q[2:0]];////////////////////////////////may need to paste 0
			end
		end
		// else if  (cnt256 >= 'd129 && cnt256 <= 'd192)begin //
		else begin
			for ( i = 0; i <=7; i = i+1	) begin
				add1_add [i] = ( cnt256 ==  'd137 || cnt256 == 'd145 || cnt256 == 'd153 || cnt256 == 'd161 || cnt256 == 'd169 || cnt256 == 'd177 || cnt256 == 'd185 )	?	'd0		: Q_reg  [8][i];
				add1_mul0[i] = Q_reg  [(cnt64Q[5:3])][cnt64Q[2:0]];
				add1_mul1[i] = K_reg  [ cnt64Q[2:0]][i];
			end
		end
end



// add2, V,K
// K_reg
// wire clk_K_reg[0:7][0:7];
generate
for(a=0; a<8; a=a+1) begin :K_reg_y
	for(b=0; b<8; b=b+1) begin :K_reg_x
		// GATED_OR g_K_reg(.CLOCK(clk), .SLEEP_CTRL( ((cnt256 <= 'd63) || (cnt256 >= 'd129) ) && cg_en  ), .RST_N(rst_n), .CLOCK_GATED(clk_K_reg[a][b]));
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)  begin
				K_reg[a][b] <= 'd0;
			end
			else if (set_end || cnt256 == 'd64 )
				K_reg[a][b]<= 'd0;
			else if (cnt256 >= 'd65 && cnt256 <= 'd128) begin
				if (a == cnt64KV[2:0]) begin
					K_reg[a][b]<= add2[b];
				end
			end
		end
	end
end
endgenerate

// V_reg
wire clk_V_reg[0:7][0:7];
generate
for(a=0; a<8; a=a+1) begin :V_reg_y
	for(b=0; b<8; b=b+1) begin :V_reg_x
		// GATED_OR g_K_reg(.CLOCK(clk), .SLEEP_CTRL( ((cnt256 <= 'd126) ) && cg_en  ), .RST_N(rst_n), .CLOCK_GATED(clk_V_reg[a][b]));
		always @(posedge clk or negedge rst_n) begin
			if (!rst_n)  begin
				V_reg[a][b] <= 'd0;
			end
			else if ( set_end || cnt256 == 'd128 )
				V_reg[a][b]<= 'd0;
			else if (cnt256 >= 'd129 && cnt256 <= 'd192) begin
				if (b == cnt64KV[2:0]) begin
					V_reg[a][b]<= add2[a];
				end
			end
		end
	end
end
endgenerate



always @(*) begin
	// if ( cs == T8 ) begin
		if  (cnt256 >= 'd65 && cnt256 <= 'd128)begin // 65~128 for K
			for ( i = 0; i <=7; i = i+1	) begin
				add2_add [i] = K_reg  [cnt64KV[2:0]][i];
				add2_mul0[i] = W_reg  [cnt64KV[2:0]][cnt64KV[5:3]];   //////////////////////////////////////////may use input reg!!!!!!!
				add2_mul1[i] = X_reg_t[cnt64KV[5:3]][i];


				// add2_add [i] = K_reg  [((cnt256 - 'd1 ) % 8 )][i];
				// add2_mul0[i] = W_reg  [((cnt256 - 'd1 ) % 8 )][((((cnt256 - 'd1 ) % 64) )>>3)];   //////////////////////////////////////////may use input reg!!!!!!!
				// add2_mul1[i] = X_reg_t[ ((cnt256 - 'd65)%64)>>3][i];


				// add2_add [i] = K_reg  [(cnt256_sub1[2:0] )][i];
				// add2_mul0[i] = W_reg  [(cnt256_sub1[2:0])][cnt256_sub1[5:3]];   //////////////////////////////////////////may use input reg!!!!!!!
				// add2_mul1[i] = X_reg_t[ cnt256_sub65[5:3]][i];
			end
		end
		else  begin // 129~192 for V
		// else if  (cnt256 >= 'd129 && cnt256 <= 'd192)begin // 129~192 for V
			for ( i = 0; i <=7; i = i+1	) begin
				add2_add [i] = V_reg  [i][cnt64KV[2:0]];
				add2_mul0[i] = W_reg  [(cnt64KV[5:3])][cnt64KV[2:0]];
				add2_mul1[i] = X_reg  [i][ cnt64KV[5:3]];
			end
		end

		// else if (cg_en) begin
		// 	for ( i = 0; i <=7; i = i+1	) begin
		// 		add2_add [i] ='d0;
		// 		add2_mul0[i] ='d0;
		// 		add2_mul1[i] ='d0;
		// 	end
		// end
		// else begin // 129~192 for V
		// 	for ( i = 0; i <=7; i = i+1	) begin
		// 		add2_add [i] = V_reg  [i][cnt64KV[2:0]];
		// 		add2_mul0[i] = W_reg  [(cnt64KV[5:3])][cnt64KV[2:0]];
		// 		add2_mul1[i] = X_reg  [i][ cnt64KV[5:3]];
		// 	end
		// end
end

// add3
// reg  signed [40:0] add3_in1 [0:7];  	QK
// reg  signed [18:0] add3_in2 [0:7];	V
wire  [5:0] cnt64Q_add1;
assign cnt64Q_add1 = cnt64Q + 'd1;
always @(*) begin
	for ( i = 0; i <=7; i = i+1	) begin
		add3_in1[i] = Q_reg[cnt64Q_add1[5:3]][i];
		add3_in2[i] = V_reg[i][cnt64Q_add1[2:0]];

	end
end

//==============================================//
//                  design                      //
//==============================================//

wire Q_ok, K_ok, V_ok,QK_ok;
assign Q_ok =  cnt256 >= 'd121;
assign K_ok = cnt256 >= 'd129;
assign V_ok = cnt256 >= 'd193;
assign QK_ok = cnt256 >= 'd193;




//==============================================//
//                OUT PUT                       //
//==============================================//
reg  out_valid_test;
reg  signed [63:0] out_data_test;


always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_valid<= 'd0;
		out_data<= 'd0;
	end
	else if ( send_out) begin
		out_valid <= 'd1;
		out_data <= add3;
	end
	else begin
		out_valid <= 'd0;
		out_data <= 'd0;
	end
end



endmodule
