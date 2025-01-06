/**************************************************************************/
// Copyright (c) 2024, OASIS Lab
// MODULE: TETRIS
// FILE NAME: TETRIS.v
// VERSRION: 1.0
// DATE: August 15, 2024
// AUTHOR: Yu-Hsuan Hsu, NYCU IEE
// DESCRIPTION: ICLAB2024FALL / LAB3 / TETRIS
// MODIFICATION HISTORY:
// Date                 Description
//
/**************************************************************************/
module TETRIS (
	//INPUT
	rst_n,
	clk,
	in_valid,
	tetrominoes,
	position,
	//OUTPUT
	tetris_valid,
	score_valid,
	fail,
	score,
	tetris
);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
input				rst_n, clk, in_valid;
input		[2:0]	tetrominoes;
input		[2:0]	position;
output reg			tetris_valid, score_valid, fail;
output reg	[3:0]	score;
output reg 	[71:0]	tetris;

reg	 n_tetris_valid;
reg	 n_score_valid;
reg	 n_fail;
reg	 [3:0]n_score;
reg [3:0] score_background,n_score_background;
reg [71:0]tetris_background;
reg [71:0] n_tetris;
reg	 [5:0] n_tetris_background[11:0];
wire [71:0] n_tetris_background_flatten;
reg valid_delay,n_valid_delay;
// reg  [3:0] score_count;
// reg  [3:0] n_score_count;
wire PatternEnd;
reg  [4:0]pattern_count,n_pattern_count;


reg [1:0] cs, ns;


	parameter idle =2'd0 ; //valid = 0
	parameter blockdown_state = 2'd1; // valid =1
	parameter eliminate = 2'd2; // valid = 0 , finish and out;
	parameter finsish = 2'd3;



//---------------------------------------------------------------------
//   					tetrominoes shape
//---------------------------------------------------------------------
//
//				*
// 				*				**
//	    **  	*				 *
//	    **  	*		****	 *
//		0		1		2		3
//
//		***		*		*
//		*		*		**		 **
//				**		 *		**
//		4		5		6		7

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------
integer i,j;

//---------------------------------------------------------------------
//   REG & WIRE DECLARATION
//---------------------------------------------------------------------
wire [95:0]  blockdown_tetris;
wire [71:0]	 eliminate_tetris;
wire [2:0] eliminate_level_num11;
wire rangeout,block_land_high,block_land_sec_high;
wire [3:0] highest_touch_level_ord;
wire EndEliminate;
reg [71:0]invert_n_tetris_background;
wire addsign;
wire nofull;
wire shape3_onlyL_ground;
//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
always @( posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		cs <= 'd0;
	end
	else cs <= ns;

end

always @( *) begin
	case (cs)
		idle:		ns = (in_valid)? eliminate:idle;
		// blockdown:	ns = eliminate;
		eliminate:	ns = (EndEliminate)?idle:eliminate;
		default:ns = 2'd3;
	endcase
end




always @( posedge clk or negedge rst_n ) begin
	if (!rst_n )begin
	tetris_valid <= 'd0;
	score_valid <= 'd0;
	fail<= 'd0;
	score  <= 'd0;
	tetris <= 'd0;
	valid_delay <= 1'd0;
	// score_count <=4'd0;
	pattern_count <= 5'd0;
	tetris_background <= 'd0;
	score_background <='d0;
	end
	else begin
	tetris_valid <= n_tetris_valid;
	tetris <= n_tetris;
	score_valid <= n_score_valid;
	fail<= n_fail;
	score  <= n_score;
	score_background <= n_score_background;
	// score_count <= n_score_count;
	tetris_background <= n_tetris_background_flatten;
	valid_delay <= n_valid_delay;
	pattern_count <=n_pattern_count;
	end
end

reg PatternEnd_delay, rangeout_delay;;
// assign PatternEnd =  ((pattern_count == 5'd16)&EndEliminate) |( (&pattern_count[3:0])&(!nofull)); // pattern_count = 15, and the last pattern is coming.
assign PatternEnd =  ((pattern_count == 5'd16)&EndEliminate) ; // pattern_count = 15, and the last pattern is coming.
// in_valid
always @( posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		PatternEnd_delay <= 1'd0;
		rangeout_delay <= 1'd0;
	end
	else begin
		PatternEnd_delay <=PatternEnd;
		rangeout_delay<= rangeout;
	end
end


always @(* ) begin
	n_tetris_valid= (PatternEnd & EndEliminate)|rangeout;
	n_score_valid = EndEliminate;
	n_valid_delay = (in_valid);
	n_fail  = rangeout;
	n_tetris = (PatternEnd|rangeout)? invert_n_tetris_background : 72'd0;
	// n_score = (PatternEnd|rangeout)?n_score_count:4'd0;
	n_score = (EndEliminate)? n_score_background:4'd0;
	n_score_background = (!in_valid & pattern_count == 'd0)? 'd0 :(rangeout_delay|PatternEnd_delay)?'d0:(score_background+{2'd0,addsign});
	n_pattern_count = (PatternEnd|rangeout)?'d0:
						(in_valid)?pattern_count + 'd1 :pattern_count;
end



touchcheck touchcheck (
	.tetrominoes(tetrominoes),
	.position(position),
	.tetris_background(tetris_background),
	.block_land_high(block_land_high),   //special block will land at high space.
	.block_land_sec_high(block_land_sec_high),
	.highest_touch_level_ord(highest_touch_level_ord),  //The altitude block will touch.
	.shape3_onlyL_ground(shape3_onlyL_ground)
);

blockdown blockdown (
	.tetrominoes(tetrominoes),
	.position(position),
	.tetris(tetris_background),
	.block_land_high(block_land_high),
	.block_land_sec_high(block_land_sec_high),
	.highest_touch_level_ord(highest_touch_level_ord),
	.blockdown_tetris(blockdown_tetris),
	.shape3_onlyL_ground(shape3_onlyL_ground)
);



wire [71:0]st_flatten;
shift_tetris shift_tetris (
		.clk(clk),
		.rst_n(rst_n),
		.in_valid(in_valid),
		.blockdown_tetris(blockdown_tetris),
		.cs(cs),
		.st_flatten(st_flatten),
		.rangeout(rangeout),
		.addsign(addsign),
		.EndEliminate(EndEliminate),
		.nofull(nofull)
	);



// eliminate eliminate (
// 	.blockdown_tetris(blockdown_tetris),
// 	.eliminate_tetris(eliminate_tetris),
// 	.rangeout(rangeout),
// 	.eliminate_level_num11(eliminate_level_num11)
// );

// always @(*)begin
// 	for (i=0 ; i<72 ; i=i+1) begin
// 		invert_eliminate_tetris[i] =  eliminate_tetris[71-i];
// 	end
// end

always @ (*) begin
	for (i=0; i<12 ; i=i+1) begin
		for (j=0; j<6 ; j=j+1) begin
			invert_n_tetris_background [i*6+j] = st_flatten[5+i*6-j];
		end
	end
end


always@(*) begin
	if (PatternEnd_delay | fail) begin
		for (i=0; i<12 ;i=i+1)
			n_tetris_background[i]= 6'd0;
	end
	else if (EndEliminate )begin
		n_tetris_background[11] = st_flatten [71:66];
		n_tetris_background[10] = st_flatten [65:60];
		n_tetris_background[9 ] = st_flatten [59:54];
		n_tetris_background[8 ] = st_flatten [53:48];
		n_tetris_background[7 ] = st_flatten [47:42];
		n_tetris_background[6 ] = st_flatten [41:36];
		n_tetris_background[5 ] = st_flatten [35:30];
		n_tetris_background[4 ] = st_flatten [29:24];
		n_tetris_background[3 ] = st_flatten [23:18];
		n_tetris_background[2 ] = st_flatten [17:12];
		n_tetris_background[1 ] = st_flatten [11:6 ];
		n_tetris_background[0 ] = st_flatten [5 :0 ];
	end
	else begin

		n_tetris_background[11] = tetris_background [71:66];
		n_tetris_background[10] = tetris_background [65:60];
		n_tetris_background[9 ] = tetris_background [59:54];
		n_tetris_background[8 ] = tetris_background [53:48];
		n_tetris_background[7 ] = tetris_background [47:42];
		n_tetris_background[6 ] = tetris_background [41:36];
		n_tetris_background[5 ] = tetris_background [35:30];
		n_tetris_background[4 ] = tetris_background [29:24];
		n_tetris_background[3 ] = tetris_background [23:18];
		n_tetris_background[2 ] = tetris_background [17:12];
		n_tetris_background[1 ] = tetris_background [11:6 ];
		n_tetris_background[0 ] = tetris_background [5 :0 ];
	end
end

assign n_tetris_background_flatten = {n_tetris_background[11],
										n_tetris_background[10],
										n_tetris_background[9 ],
										n_tetris_background[8 ],
										n_tetris_background[7 ],
										n_tetris_background[6 ],
										n_tetris_background[5 ],
										n_tetris_background[4 ],
										n_tetris_background[3 ],
										n_tetris_background[2 ],
										n_tetris_background[1 ],
										n_tetris_background[0 ]};
endmodule



//================================================================//
//
//							touchcheck
//
//================================================================//
module touchcheck (
		tetrominoes,
		position,
		tetris_background,
		block_land_high,
		block_land_sec_high,
		shape3_onlyL_ground,
		highest_touch_level_ord
	);

	input		[2:0]	tetrominoes;
	input		[2:0]	position;
	input    	[71:0]	tetris_background;
	output      block_land_high,block_land_sec_high;
	output [3:0] highest_touch_level_ord;
	output shape3_onlyL_ground;

	wire [5:0] checkwindow ;
	wire [5:0] checkwindow_high;
	reg  [5:0] row_touch_point [11:0];
	reg  [5:0] tetris_background_arr  [11:0];
	wire [71:0]row_touch_point_flatten;

	integer  i;
	genvar a;

	always @(*) begin
		// for (i=0; i<12; i=i+1)
		// tetris_background_arr[i] = tetris_background [7+i*8:0+i*8];
		tetris_background_arr[11] = tetris_background [71:66];
		tetris_background_arr[10] = tetris_background [65:60];
		tetris_background_arr[9 ] = tetris_background [59:54];
		tetris_background_arr[8 ] = tetris_background [53:48];
		tetris_background_arr[7 ] = tetris_background [47:42];
		tetris_background_arr[6 ] = tetris_background [41:36];
		tetris_background_arr[5 ] = tetris_background [35:30];
		tetris_background_arr[4 ] = tetris_background [29:24];
		tetris_background_arr[3 ] = tetris_background [23:18];
		tetris_background_arr[2 ] = tetris_background [17:12];
		tetris_background_arr[1 ] = tetris_background [11:6] ;
		tetris_background_arr[0 ] = tetris_background [5:0]  ;

	end

	// generate
	// 	for (a = 0; a<12; a=a+1) begin :checkwindow
	checkwindow_ckt checkwindow_ckt (.tetrominoes(tetrominoes), .position(position), .checkwindow(checkwindow), .checkwindow_high(checkwindow_high));
	// 	end
	// endgenerate


	always @(*) begin
		for (i=0; i<12; i=i+1) begin
			row_touch_point[i] = checkwindow  & tetris_background_arr[i];
		end
	end
	assign row_touch_point_flatten = {row_touch_point[11],row_touch_point[10],row_touch_point[9]
								,row_touch_point[8], row_touch_point[7], row_touch_point[6]
								,row_touch_point[5], row_touch_point[4], row_touch_point[3]
								,row_touch_point[2], row_touch_point[1], row_touch_point[0]};

	highest_touch_level_ord highest_touch_level_ord0(
		.row_touch_point_flatten(row_touch_point_flatten),
		.checkwindow_high(checkwindow_high),
		.tetrominoes(tetrominoes),
		.highest_touch_level_ord(highest_touch_level_ord),
		.block_land_high(block_land_high),
		.block_land_sec_high(block_land_sec_high),
		.shape3_onlyL_ground(shape3_onlyL_ground)
	);
endmodule



//================================================================//
//
//							checkwindow_ckt
//
//================================================================//
module checkwindow_ckt (
		tetrominoes,
		position,
		checkwindow,
		checkwindow_high
	);

	input [2:0] tetrominoes, position;
	// output touch;
	output reg [5:0] checkwindow;
	output reg [5:0] checkwindow_high;
	// high touch low touch
	always @(*) begin
		case (tetrominoes)
			3'd0:case (position)
				3'd0:checkwindow = 6'b110000;
				3'd1:checkwindow = 6'b011000;
				3'd2:checkwindow = 6'b001100;
				3'd3:checkwindow = 6'b000110;
				3'd4:checkwindow = 6'b000011;
				default: checkwindow = 6'b000000;
			endcase
			3'd1:case (position)
				3'd0:checkwindow = 6'b100000;
				3'd1:checkwindow = 6'b010000;
				3'd2:checkwindow = 6'b001000;
				3'd3:checkwindow = 6'b000100;
				3'd4:checkwindow = 6'b000010;
				3'd5:checkwindow = 6'b000001;
				default: checkwindow = 6'b000000;
			endcase
			3'd2:case (position)
				3'd0:checkwindow = 6'b111100;
				3'd1:checkwindow = 6'b011110;
				3'd2:checkwindow = 6'b001111;
				default: checkwindow = 6'b000000;
			endcase
			3'd3:case (position)
				3'd0:checkwindow = 6'b110000;
				3'd1:checkwindow = 6'b011000;
				3'd2:checkwindow = 6'b001100;
				3'd3:checkwindow = 6'b000110;
				3'd4:checkwindow = 6'b000011;
				default: checkwindow = 6'b000000;
			endcase
			3'd4:case (position)
				3'd0:checkwindow = 6'b111000;
				3'd1:checkwindow = 6'b011100;
				3'd2:checkwindow = 6'b001110;
				3'd3:checkwindow = 6'b000111;
				default: checkwindow = 6'b000000;
			endcase
			3'd5:case (position)
				3'd0:checkwindow = 6'b110000;
				3'd1:checkwindow = 6'b011000;
				3'd2:checkwindow = 6'b001100;
				3'd3:checkwindow = 6'b000110;
				3'd4:checkwindow = 6'b000011;
				default: checkwindow = 6'b000000;
			endcase
			3'd6:case (position)
				3'd0:checkwindow = 6'b110000;
				3'd1:checkwindow = 6'b011000;
				3'd2:checkwindow = 6'b001100;
				3'd3:checkwindow = 6'b000110;
				3'd4:checkwindow = 6'b000011;
				default: checkwindow = 6'b000000;
			endcase
			3'd7:case (position)
				3'd0:checkwindow = 6'b111000;
				3'd1:checkwindow = 6'b011100;
				3'd2:checkwindow = 6'b001110;
				3'd3:checkwindow = 6'b000111;
				default: checkwindow = 6'b000000;
			endcase
				default: checkwindow = 6'b000000;
		endcase
	end

	always @(*) begin
		case (tetrominoes)
			3'd3:case (position)
				3'd0:checkwindow_high = 6'b010000;
				3'd1:checkwindow_high = 6'b001000;
				3'd2:checkwindow_high = 6'b000100;
				3'd3:checkwindow_high = 6'b000010;
				3'd4:checkwindow_high = 6'b000001;
				default: checkwindow_high =  6'b0;
			endcase
			3'd4:case (position)
				3'd0:checkwindow_high = 6'b100000;
				3'd1:checkwindow_high = 6'b010000;
				3'd2:checkwindow_high = 6'b001000;
				3'd3:checkwindow_high = 6'b000100;
				default: checkwindow_high =  6'b0;
			endcase
			3'd6:case (position)
				3'd0:checkwindow_high = 6'b010000;
				3'd1:checkwindow_high = 6'b001000;
				3'd2:checkwindow_high = 6'b000100;
				3'd3:checkwindow_high = 6'b000010;
				3'd4:checkwindow_high = 6'b000001;
				default: checkwindow_high =  6'b0;
			endcase
			3'd7:case (position)
				3'd0:checkwindow_high = 6'b110000;
				3'd1:checkwindow_high = 6'b011000;
				3'd2:checkwindow_high = 6'b001100;
				3'd3:checkwindow_high = 6'b000110;
				default: checkwindow_high =  6'b0;
			endcase
				default: checkwindow_high =  6'b0;
		endcase
	end

endmodule



//================================================================//
//
//							highest_touch_level_ord
//
//================================================================//
module highest_touch_level_ord (
		row_touch_point_flatten,checkwindow_high,tetrominoes,highest_touch_level_ord,block_land_high,block_land_sec_high,shape3_onlyL_ground
	);
	input [71:0] row_touch_point_flatten;
	input [5:0] checkwindow_high;
	input [2:0]tetrominoes ;
	output reg [3:0] highest_touch_level_ord;
	output block_land_high,block_land_sec_high;
	output shape3_onlyL_ground;
	reg [5:0] row_touch_point [11:0];
	reg [5:0] row_touch_point_high, row_touch_point_sec_high;
	reg [11:0] row_touch_list;
	integer i;

	always @(*) begin

		// row_touch_point[i] = row_touch_point_flatten [5+i*6:i*6];
		// row_touch_point[i] = row_touch_point_flatten [i*6+:6];
		row_touch_point[11] = row_touch_point_flatten [71:66];
		row_touch_point[10] = row_touch_point_flatten [65:60];
		row_touch_point[9 ] = row_touch_point_flatten [59:54];
		row_touch_point[8 ] = row_touch_point_flatten [53:48];
		row_touch_point[7 ] = row_touch_point_flatten [47:42];
		row_touch_point[6 ] = row_touch_point_flatten [41:36];
		row_touch_point[5 ] = row_touch_point_flatten [35:30];
		row_touch_point[4 ] = row_touch_point_flatten [29:24];
		row_touch_point[3 ] = row_touch_point_flatten [23:18];
		row_touch_point[2 ] = row_touch_point_flatten [17:12];
		row_touch_point[1 ] = row_touch_point_flatten [11:6];
		row_touch_point[0 ] = row_touch_point_flatten [5:0];

		for (i=0; i<12; i=i+1)
			row_touch_list[i] = | row_touch_point[i];
	end


	always @ (*) begin
		case (1'b1)
		row_touch_list[11]: highest_touch_level_ord = 4'd12;
		row_touch_list[10]: highest_touch_level_ord = 4'd11;
		row_touch_list[9 ]: highest_touch_level_ord = 4'd10;
		row_touch_list[8 ]: highest_touch_level_ord = 4'd9 ;
		row_touch_list[7 ]: highest_touch_level_ord = 4'd8 ;
		row_touch_list[6 ]: highest_touch_level_ord = 4'd7 ;
		row_touch_list[5 ]: highest_touch_level_ord = 4'd6 ;
		row_touch_list[4 ]: highest_touch_level_ord = 4'd5 ;
		row_touch_list[3 ]: highest_touch_level_ord = 4'd4 ;
		row_touch_list[2 ]: highest_touch_level_ord = 4'd3 ;
		row_touch_list[1 ]: highest_touch_level_ord = 4'd2 ;
		row_touch_list[0 ]: highest_touch_level_ord = 4'd1 ;
		default:			 highest_touch_level_ord = 4'd0 ;
		endcase
	end



	always @ (*) begin
		case (1'b1)
		row_touch_list[11]:row_touch_point_high = row_touch_point [11];
		row_touch_list[10]:row_touch_point_high = row_touch_point [10];
		row_touch_list[9 ]:row_touch_point_high = row_touch_point [9 ];
		row_touch_list[8 ]:row_touch_point_high = row_touch_point [8 ];
		row_touch_list[7 ]:row_touch_point_high = row_touch_point [7 ];
		row_touch_list[6 ]:row_touch_point_high = row_touch_point [6 ];
		row_touch_list[5 ]:row_touch_point_high = row_touch_point [5 ];
		row_touch_list[4 ]:row_touch_point_high = row_touch_point [4 ];
		row_touch_list[3 ]:row_touch_point_high = row_touch_point [3 ];
		row_touch_list[2 ]:row_touch_point_high = row_touch_point [2 ];
		row_touch_list[1 ]:row_touch_point_high = row_touch_point [1 ];
		row_touch_list[0 ]:row_touch_point_high = row_touch_point [0 ];
		default:			row_touch_point_high =  6'b111111			;
		endcase
	end

	always @ (*) begin
		case (1'b1)
		row_touch_list[11]:row_touch_point_sec_high = row_touch_point [10];
		row_touch_list[10]:row_touch_point_sec_high = row_touch_point [9 ];
		row_touch_list[9 ]:row_touch_point_sec_high = row_touch_point [8 ];
		row_touch_list[8 ]:row_touch_point_sec_high = row_touch_point [7 ];
		row_touch_list[7 ]:row_touch_point_sec_high = row_touch_point [6 ];
		row_touch_list[6 ]:row_touch_point_sec_high = row_touch_point [5 ];
		row_touch_list[5 ]:row_touch_point_sec_high = row_touch_point [4 ];
		row_touch_list[4 ]:row_touch_point_sec_high = row_touch_point [3 ];
		row_touch_list[3 ]:row_touch_point_sec_high = row_touch_point [2 ];
		row_touch_list[2 ]:row_touch_point_sec_high = row_touch_point [1 ];
		row_touch_list[1 ]:row_touch_point_sec_high = row_touch_point [0 ];
		default:		   row_touch_point_sec_high =  6'd0			;
		endcase
	end


		// assign block_land_sec_high = (|(row_touch_point_sec_high & checkwindow_high)) | (!(|(row_touch_point_high & checkwindow_high))|(highest_touch_level_ord==0 & (tetrominoes ==  3'd3))) ;



	assign shape3_onlyL_ground = (highest_touch_level_ord== 'd1 )&(!(|(row_touch_point_high & checkwindow_high)))&((|(row_touch_point_high & checkwindow_high <<1)));
	assign block_land_sec_high = (|(row_touch_point_sec_high & checkwindow_high));
	assign block_land_high = (|(row_touch_point_high & checkwindow_high))|(highest_touch_level_ord==0 & (tetrominoes ==  3'd3 | tetrominoes ==  3'd4 |tetrominoes ==  3'd6 |tetrominoes ==  3'd7));

endmodule


//================================================================//
//
//							blockdown
//
//================================================================//
module blockdown (
		tetrominoes,
		position,
		tetris,
		block_land_high,
		block_land_sec_high,
		shape3_onlyL_ground,
		highest_touch_level_ord,
		blockdown_tetris
	);

	input [2:0]	tetrominoes;
	input [2:0]	position;
	input [71:0]	tetris;
	input block_land_high,block_land_sec_high;
	input shape3_onlyL_ground;
	input [3:0]highest_touch_level_ord;
	output reg  [95:0]  blockdown_tetris; // add 4 rows to cover survive after eliminating corner. But it may only need 2
	integer i ;
	reg [5:0] tetris_broaden[15:0],blockdown_tetris_arr[15:0];
	// reg [5:0] tetris_arr[11:0];
	always @(*) begin
		tetris_broaden[15] = 'd0;
		tetris_broaden[14] = 'd0;
		tetris_broaden[13] = 'd0;
		tetris_broaden[12] = 'd0;
		tetris_broaden[11] = tetris [71:66];
		tetris_broaden[10] = tetris [65:60];
		tetris_broaden[9 ] = tetris [59:54];
		tetris_broaden[8 ] = tetris [53:48];
		tetris_broaden[7 ] = tetris [47:42];
		tetris_broaden[6 ] = tetris [41:36];
		tetris_broaden[5 ] = tetris [35:30];
		tetris_broaden[4 ] = tetris [29:24];
		tetris_broaden[3 ] = tetris [23:18];
		tetris_broaden[2 ] = tetris [17:12];
		tetris_broaden[1 ] = tetris [11:6] ;
		tetris_broaden[0 ] = tetris [5:0]  ;
	end

	reg [5:0] influenced_data [5:0],update_data[5:0], add_data[3:0];

	//influenced data is chooce by the highest_touch_level_ord (The altitude block bottom will exist at.)
	always @(*) begin
		case (highest_touch_level_ord)
			4'd12:for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[12-2+i];
			end
			4'd11:for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[11-2+i];
			end
			4'd10:for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[10-2+i];
			end
			4'd9 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ 9-2+i];
			end
			4'd8 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ 8-2+i];
			end
			4'd7 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ 7-2+i];
			end
			4'd6 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ 6-2+i];
			end
			4'd5 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ 5-2+i];
			end
			4'd4 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ 4-2+i];
			end
			4'd3 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ 3-2+i];
			end
			4'd2 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ 2-2+i];
			end
			4'd1 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ i];
			end
			4'd0 :for (i=0;i<6;i=i+1) begin
				influenced_data[i]=tetris_broaden[ i];
			end
			default: for (i=0;i<6;i=i+1) begin
				influenced_data[i]='d0;
			end
		endcase
	end

	// horizontally slice the block into add_data[0~2]
	always @(*) begin
		case (tetrominoes)
			3'd0:case (position)
				3'd0:add_data[0] = 6'b110000;
				3'd1:add_data[0] = 6'b011000;
				3'd2:add_data[0] = 6'b001100;
				3'd3:add_data[0] = 6'b000110;
				3'd4:add_data[0] = 6'b000011;
				default: add_data[0] =  6'b0;
			endcase
			3'd1:case (position)
				3'd0:add_data[0] = 6'b100000;
				3'd1:add_data[0] = 6'b010000;
				3'd2:add_data[0] = 6'b001000;
				3'd3:add_data[0] = 6'b000100;
				3'd4:add_data[0] = 6'b000010;
				3'd5:add_data[0] = 6'b000001;
				default: add_data[0] =  6'bX;
			endcase
			3'd2:case (position)
				3'd0:add_data[0] = 6'b111100;
				3'd1:add_data[0] = 6'b011110;
				3'd2:add_data[0] = 6'b001111;
				default:add_data[0] =   6'bX;
			endcase
			3'd3:case (position)
					3'd0:add_data[0] = 6'b010000;
					3'd1:add_data[0] = 6'b001000;
					3'd2:add_data[0] = 6'b000100;
					3'd3:add_data[0] = 6'b000010;
					3'd4:add_data[0] = 6'b000001;
					default: add_data[0] =  6'bX;
				endcase
			3'd4:case (position)
					3'd0:add_data[0] = 6'b100000;
					3'd1:add_data[0] = 6'b010000;
					3'd2:add_data[0] = 6'b001000;
					3'd3:add_data[0] = 6'b000100;
					default: add_data[0] =  6'bX;
				endcase
			3'd5:case (position)
					3'd0:add_data[0] = 6'b110000;
					3'd1:add_data[0] = 6'b011000;
					3'd2:add_data[0] = 6'b001100;
					3'd3:add_data[0] = 6'b000110;
					3'd4:add_data[0] = 6'b000011;
					default: add_data[0] =  6'bX;
				endcase
			3'd6:case (position)
					3'd0:add_data[0] = 6'b010000;
					3'd1:add_data[0] = 6'b001000;
					3'd2:add_data[0] = 6'b000100;
					3'd3:add_data[0] = 6'b000010;
					3'd4:add_data[0] = 6'b000001;
					default: add_data[0] =  6'bX;
				endcase
			3'd7:case (position)
					3'd0:add_data[0] = 6'b110000;
					3'd1:add_data[0] = 6'b011000;
					3'd2:add_data[0] = 6'b001100;
					3'd3:add_data[0] = 6'b000110;
					default: add_data[0] =  6'bX;
				endcase
				default: add_data[0] =  6'bX;
		endcase

		case (tetrominoes)
			3'd0:case (position)
				3'd0:add_data[1] = 6'b110000;
				3'd1:add_data[1] = 6'b011000;
				3'd2:add_data[1] = 6'b001100;
				3'd3:add_data[1] = 6'b000110;
				3'd4:add_data[1] = 6'b000011;
				default: add_data[1] =  6'bX;
			endcase
			3'd1:case (position)
				3'd0:add_data[1] = 6'b100000;
				3'd1:add_data[1] = 6'b010000;
				3'd2:add_data[1] = 6'b001000;
				3'd3:add_data[1] = 6'b000100;
				3'd4:add_data[1] = 6'b000010;
				3'd5:add_data[1] = 6'b000001;
				default: add_data[1] =  6'bX;
			endcase
			3'd2:case (position)
				3'd0:add_data[1] = 6'b0;
				3'd1:add_data[1] = 6'b0;
				3'd2:add_data[1] = 6'b0;
				default:add_data[1] =   6'bX;
			endcase
			3'd3:case (position)
				3'd0:add_data[1] = 6'b010000;
				3'd1:add_data[1] = 6'b001000;
				3'd2:add_data[1] = 6'b000100;
				3'd3:add_data[1] = 6'b000010;
				3'd4:add_data[1] = 6'b000001;
				default: add_data[1] =  6'bX;
			endcase
			3'd4:case (position)
				3'd0:add_data[1] = 6'b111000;
				3'd1:add_data[1] = 6'b011100;
				3'd2:add_data[1] = 6'b001110;
				3'd3:add_data[1] = 6'b000111;
				default: add_data[1] =  6'bX;
			endcase
			3'd5:case (position)
				3'd0:add_data[1] = 6'b100000;
				3'd1:add_data[1] = 6'b010000;
				3'd2:add_data[1] = 6'b001000;
				3'd3:add_data[1] = 6'b000100;
				3'd4:add_data[1] = 6'b000010;
				default: add_data[1] =  6'bX;
			endcase
			3'd6:case (position)
				3'd0:add_data[1] = 6'b110000;
				3'd1:add_data[1] = 6'b011000;
				3'd2:add_data[1] = 6'b001100;
				3'd3:add_data[1] = 6'b000110;
				3'd4:add_data[1] = 6'b000011;
				default: add_data[1] =  6'bX;
			endcase
			3'd7:case (position)
				3'd0:add_data[1] = 6'b011000;
				3'd1:add_data[1] = 6'b001100;
				3'd2:add_data[1] = 6'b000110;
				3'd3:add_data[1] = 6'b000011;
				default: add_data[1] =  6'bX;
			endcase
			default: add_data[1] =  6'bX;
		endcase

		case (tetrominoes)
			3'd0:case (position)
				3'd0:add_data[2] = 6'b0;
				3'd1:add_data[2] = 6'b0;
				3'd2:add_data[2] = 6'b0;
				3'd3:add_data[2] = 6'b0;
				3'd4:add_data[2] = 6'b0;
				default: add_data[2] =  6'bX;
			endcase
			3'd1:case (position)
				3'd0:add_data[2] = 6'b100000;
				3'd1:add_data[2] = 6'b010000;
				3'd2:add_data[2] = 6'b001000;
				3'd3:add_data[2] = 6'b000100;
				3'd4:add_data[2] = 6'b000010;
				3'd5:add_data[2] = 6'b000001;
				default: add_data[2] =  6'bX;
			endcase
			3'd2:case (position)
				3'd0:add_data[2] = 6'b0;
				3'd1:add_data[2] = 6'b0;
				3'd2:add_data[2] = 6'b0;
				default:add_data[2] =   6'bX;
			endcase
			3'd3:case (position)
				3'd0:add_data[2] = 6'b110000;
				3'd1:add_data[2] = 6'b011000;
				3'd2:add_data[2] = 6'b001100;
				3'd3:add_data[2] = 6'b000110;
				3'd4:add_data[2] = 6'b000011;
				default: add_data[2] =  6'bX;
			endcase
			3'd4:case (position)
				3'd0:add_data[2] = 6'b0;
				3'd1:add_data[2] = 6'b0;
				3'd2:add_data[2] = 6'b0;
				3'd3:add_data[2] = 6'b0;
				default: add_data[2] =  6'bX;
			endcase
			3'd5:case (position)
				3'd0:add_data[2] = 6'b100000;
				3'd1:add_data[2] = 6'b010000;
				3'd2:add_data[2] = 6'b001000;
				3'd3:add_data[2] = 6'b000100;
				3'd4:add_data[2] = 6'b000010;
				default: add_data[2] =  6'bX;
			endcase
			3'd6:case (position)
				3'd0:add_data[2] = 6'b100000;
				3'd1:add_data[2] = 6'b010000;
				3'd2:add_data[2] = 6'b001000;
				3'd3:add_data[2] = 6'b000100;
				3'd4:add_data[2] = 6'b000010;
				default: add_data[2] =  6'bX;
			endcase
			3'd7:case (position)
				3'd0:add_data[2] = 6'b0;
				3'd1:add_data[2] = 6'b0;
				3'd2:add_data[2] = 6'b0;
				3'd3:add_data[2] = 6'b0;
				default: add_data[2] =  6'bX;
			endcase
			default: add_data[2] =  6'bX;
		endcase

		case (tetrominoes)
			3'd0:case (position)
				3'd0:add_data[3] = 6'b0;
				3'd1:add_data[3] = 6'b0;
				3'd2:add_data[3] = 6'b0;
				3'd3:add_data[3] = 6'b0;
				3'd4:add_data[3] = 6'b0;
				default: add_data[3] =  6'bX;
			endcase
			3'd1:case (position)
				3'd0:add_data[3] = 6'b100000;
				3'd1:add_data[3] = 6'b010000;
				3'd2:add_data[3] = 6'b001000;
				3'd3:add_data[3] = 6'b000100;
				3'd4:add_data[3] = 6'b000010;
				3'd5:add_data[3] = 6'b000001;
				default: add_data[3] =  6'bX;
			endcase
			3'd2:case (position)
				3'd0:add_data[3] = 6'b0;
				3'd1:add_data[3] = 6'b0;
				3'd2:add_data[3] = 6'b0;
				default:add_data[3] =   6'bX;
			endcase
			3'd3:case (position)
				3'd0:add_data[3] = 6'b0;
				3'd1:add_data[3] = 6'b0;
				3'd2:add_data[3] = 6'b0;
				3'd3:add_data[3] = 6'b0;
				3'd4:add_data[3] = 6'b0;
				default: add_data[3] =  6'bX;
			endcase
			3'd4:case (position)
				3'd0:add_data[3] = 6'b0;
				3'd1:add_data[3] = 6'b0;
				3'd2:add_data[3] = 6'b0;
				3'd3:add_data[3] = 6'b0;
				default: add_data[3] =  6'bX;
			endcase
			3'd5:case (position)
				3'd0:add_data[3] = 6'b0;
				3'd1:add_data[3] = 6'b0;
				3'd2:add_data[3] = 6'b0;
				3'd3:add_data[3] = 6'b0;
				3'd4:add_data[3] = 6'b0;
				default: add_data[3] =  6'bX;
			endcase
			3'd6:case (position)
				3'd0:add_data[3] = 6'b0;
				3'd1:add_data[3] = 6'b0;
				3'd2:add_data[3] = 6'b0;
				3'd3:add_data[3] = 6'b0;
				3'd4:add_data[3] = 6'b0;
				default: add_data[3] =  6'bX;
			endcase
			3'd7:case (position)
				3'd0:add_data[3] = 6'b0;
				3'd1:add_data[3] = 6'b0;
				3'd2:add_data[3] = 6'b0;
				3'd3:add_data[3] = 6'b0;
				default: add_data[3] =  6'bX;
			endcase
			default: add_data[3] =  6'bX;

		endcase
	end

	//update_data = influenced_data + add_data
	always @(*) begin
		if (shape3_onlyL_ground & tetrominoes == 3'd3) begin
			update_data[0] = influenced_data[0] | add_data[0];
			update_data[1] = influenced_data[1] | add_data[1];
			update_data[2] = influenced_data[2] | add_data[2];
			update_data[3] = influenced_data[3];
			update_data[4] = influenced_data[4];
			update_data[5] = influenced_data[5];
		end
		else if (block_land_high) begin
			case (tetrominoes)
				4'd3: case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2:begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2] | add_data[0];
						update_data[3] = influenced_data[3] | add_data[1];
						update_data[4] = influenced_data[4] | add_data[2];
						update_data[5] = influenced_data[5];
					end
					4'd1 :begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3] | add_data[2];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd0 :begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2] | add_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase


				4'd4: case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2:begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2] | add_data[0];
						update_data[3] = influenced_data[3] | add_data[1];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd1 :begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd0 :begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase

				4'd6: case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2:begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2] | add_data[0];
						update_data[3] = influenced_data[3] | add_data[1];
						update_data[4] = influenced_data[4] | add_data[2];
						update_data[5] = influenced_data[5];
					end
					4'd1 :begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3] | add_data[2];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd0 :begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2] | add_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase


				4'd7: case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2:begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2] | add_data[0];
						update_data[3] = influenced_data[3] | add_data[1];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd1 :begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd0 :begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase
				default :begin
					update_data[0] = 'dX;
					update_data[1] = 'dX;
					update_data[2] = 'dX;
					update_data[3] = 'dX;
					update_data[4] = 'dX;
					update_data[5] = 'dX;
				end
			endcase
		end

		else if (block_land_sec_high & (|highest_touch_level_ord[3:1])  & tetrominoes==4'd3)begin
			case (highest_touch_level_ord)
					// 4'd12:begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2] | add_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					// 4'd11:begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2] | add_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					// 4'd10:begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2] | add_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					// 4'd9 :begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2] | add_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					// 4'd8 :begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2] | add_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					// 4'd7 :begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2] | add_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					// 4'd6 :begin
					// 	update_data[0] = influenced_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[0];
					// 	update_data[2] = influenced_data[2] | add_data[1];
					// 	update_data[3] = influenced_data[3] | add_data[2];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					// 4'd5 :begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2] | add_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					// 4'd4 :begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2] | add_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end
					 4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2:begin
					// 4'd3 :begin
						update_data[0] = influenced_data[0] ;
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3] | add_data[2];
						update_data[4] = influenced_data[4] ;
						update_data[5] = influenced_data[5];
					end
					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
			endcase
		end


		else begin
			case (tetrominoes)
				4'd0: case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2:begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2] | add_data[0];
						update_data[3] = influenced_data[3] | add_data[1];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					4'd1 :begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd0 :begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase

				4'd1: case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2: begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2] | add_data[0];
						update_data[3] = influenced_data[3] | add_data[1];
						update_data[4] = influenced_data[4] | add_data[2];
						update_data[5] = influenced_data[5] | add_data[3];
					end
					4'd1: begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3] | add_data[2];
						update_data[4] = influenced_data[4] | add_data[3];
						update_data[5] = influenced_data[5];
					end
					4'd0: begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2] | add_data[2];
						update_data[3] = influenced_data[3] | add_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					default: begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase

				4'd2:  case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2: begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2] | add_data[0];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd1 :begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd0 :begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase

				4'd3:  case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2: begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2] | add_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase

				4'd4:	case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2: begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					4'd1 :begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					// 4'd0 :begin
					// 	update_data[0] = influenced_data[0] | add_data[0];
					// 	update_data[1] = influenced_data[1] | add_data[1];
					// 	update_data[2] = influenced_data[2];
					// 	update_data[3] = influenced_data[3];
					// 	update_data[4] = influenced_data[4];
					// 	update_data[5] = influenced_data[5];
					// end

					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase

				4'd5: case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2:
					begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1];
						update_data[2] = influenced_data[2] | add_data[0];
						update_data[3] = influenced_data[3] | add_data[1];
						update_data[4] = influenced_data[4] | add_data[2];
						update_data[5] = influenced_data[5];
					end
					4'd1 :
					begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3] | add_data[2];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					4'd0 :
					begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2] | add_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase

				4'd6:case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2: begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1]| add_data[0];
						update_data[2] = influenced_data[2]| add_data[1] ;
						update_data[3] = influenced_data[3]| add_data[2] ;
						update_data[4] = influenced_data[4] ;
						update_data[5] = influenced_data[5];
					end
					4'd1 :begin
						update_data[0] = influenced_data[0]| add_data[0];
						update_data[1] = influenced_data[1]| add_data[1];
						update_data[2] = influenced_data[2]| add_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase


				4'd7: case (highest_touch_level_ord)
					4'd12, 4'd11, 4'd10, 4'd9, 4'd8, 4'd7, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2: begin
						update_data[0] = influenced_data[0];
						update_data[1] = influenced_data[1] | add_data[0];
						update_data[2] = influenced_data[2] | add_data[1];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end
					4'd1 :begin
						update_data[0] = influenced_data[0] | add_data[0];
						update_data[1] = influenced_data[1] | add_data[1];
						update_data[2] = influenced_data[2];
						update_data[3] = influenced_data[3];
						update_data[4] = influenced_data[4];
						update_data[5] = influenced_data[5];
					end

					default:begin
						update_data[0] = 'dX;
						update_data[1] = 'dX;
						update_data[2] = 'dX;
						update_data[3] = 'dX;
						update_data[4] = 'dX;
						update_data[5] = 'dX;
					end
				endcase
			endcase
		end
	end

	//put update_data in blockdown_tetris_arr
	always @(*) begin
		case (highest_touch_level_ord)
			4'd12:begin
				blockdown_tetris_arr[15] = update_data   [ 5];
				blockdown_tetris_arr[14] = update_data   [ 4];
				blockdown_tetris_arr[13] = update_data   [ 3];
				blockdown_tetris_arr[12] = update_data   [ 2];
				blockdown_tetris_arr[11] = update_data   [ 1];
				blockdown_tetris_arr[10] = update_data   [ 0];
				blockdown_tetris_arr[9 ] = tetris_broaden[9 ];
				blockdown_tetris_arr[8 ] = tetris_broaden[8 ];
				blockdown_tetris_arr[7 ] = tetris_broaden[7 ];
				blockdown_tetris_arr[6 ] = tetris_broaden[6 ];
				blockdown_tetris_arr[5 ] = tetris_broaden[5 ];
				blockdown_tetris_arr[4 ] = tetris_broaden[4 ];
				blockdown_tetris_arr[3 ] = tetris_broaden[3 ];
				blockdown_tetris_arr[2 ] = tetris_broaden[2 ];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd11:begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = update_data   [ 5];
				blockdown_tetris_arr[13] = update_data   [ 4];
				blockdown_tetris_arr[12] = update_data   [ 3];
				blockdown_tetris_arr[11] = update_data   [ 2];
				blockdown_tetris_arr[10] = update_data   [ 1];
				blockdown_tetris_arr[9 ] = update_data   [ 0];
				blockdown_tetris_arr[8 ] = tetris_broaden[8 ];
				blockdown_tetris_arr[7 ] = tetris_broaden[7 ];
				blockdown_tetris_arr[6 ] = tetris_broaden[6 ];
				blockdown_tetris_arr[5 ] = tetris_broaden[5 ];
				blockdown_tetris_arr[4 ] = tetris_broaden[4 ];
				blockdown_tetris_arr[3 ] = tetris_broaden[3 ];
				blockdown_tetris_arr[2 ] = tetris_broaden[2 ];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd10:begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = update_data   [ 5];
				blockdown_tetris_arr[12] = update_data   [ 4];
				blockdown_tetris_arr[11] = update_data   [ 3];
				blockdown_tetris_arr[10] = update_data   [ 2];
				blockdown_tetris_arr[9 ] = update_data   [ 1];
				blockdown_tetris_arr[8 ] = update_data   [ 0];
				blockdown_tetris_arr[7 ] = tetris_broaden[7 ];
				blockdown_tetris_arr[6 ] = tetris_broaden[6 ];
				blockdown_tetris_arr[5 ] = tetris_broaden[5 ];
				blockdown_tetris_arr[4 ] = tetris_broaden[4 ];
				blockdown_tetris_arr[3 ] = tetris_broaden[3 ];
				blockdown_tetris_arr[2 ] = tetris_broaden[2 ];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];
			end
			4'd9 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = update_data   [ 5];
				blockdown_tetris_arr[11] = update_data   [ 4];
				blockdown_tetris_arr[10] = update_data   [ 3];
				blockdown_tetris_arr[9 ] = update_data   [ 2];
				blockdown_tetris_arr[8 ] = update_data   [ 1];
				blockdown_tetris_arr[7 ] = update_data   [ 0];
				blockdown_tetris_arr[6 ] = tetris_broaden[6 ];
				blockdown_tetris_arr[5 ] = tetris_broaden[5 ];
				blockdown_tetris_arr[4 ] = tetris_broaden[4 ];
				blockdown_tetris_arr[3 ] = tetris_broaden[3 ];
				blockdown_tetris_arr[2 ] = tetris_broaden[2 ];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd8 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = update_data   [ 5];
				blockdown_tetris_arr[10] = update_data   [ 4];
				blockdown_tetris_arr[9 ] = update_data   [ 3];
				blockdown_tetris_arr[8 ] = update_data   [ 2];
				blockdown_tetris_arr[7 ] = update_data   [ 1];
				blockdown_tetris_arr[6 ] = update_data   [ 0];
				blockdown_tetris_arr[5 ] = tetris_broaden[5 ];
				blockdown_tetris_arr[4 ] = tetris_broaden[4 ];
				blockdown_tetris_arr[3 ] = tetris_broaden[3 ];
				blockdown_tetris_arr[2 ] = tetris_broaden[2 ];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd7 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = tetris_broaden[11];
				blockdown_tetris_arr[10] = update_data   [ 5];
				blockdown_tetris_arr[9 ] = update_data   [ 4];
				blockdown_tetris_arr[8 ] = update_data   [ 3];
				blockdown_tetris_arr[7 ] = update_data   [ 2];
				blockdown_tetris_arr[6 ] = update_data   [ 1];
				blockdown_tetris_arr[5 ] = update_data   [ 0];
				blockdown_tetris_arr[4 ] = tetris_broaden[4 ];
				blockdown_tetris_arr[3 ] = tetris_broaden[3 ];
				blockdown_tetris_arr[2 ] = tetris_broaden[2 ];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd6 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = tetris_broaden[11];
				blockdown_tetris_arr[10] = tetris_broaden[10];
				blockdown_tetris_arr[9 ] = update_data   [ 5];
				blockdown_tetris_arr[8 ] = update_data   [ 4];
				blockdown_tetris_arr[7 ] = update_data   [ 3];
				blockdown_tetris_arr[6 ] = update_data   [ 2];
				blockdown_tetris_arr[5 ] = update_data   [ 1];
				blockdown_tetris_arr[4 ] = update_data   [ 0];
				blockdown_tetris_arr[3 ] = tetris_broaden[3 ];
				blockdown_tetris_arr[2 ] = tetris_broaden[2 ];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd5 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = tetris_broaden[11];
				blockdown_tetris_arr[10] = tetris_broaden[10];
				blockdown_tetris_arr[9 ] = tetris_broaden[9 ];
				blockdown_tetris_arr[8 ] = update_data   [ 5];
				blockdown_tetris_arr[7 ] = update_data   [ 4];
				blockdown_tetris_arr[6 ] = update_data   [ 3];
				blockdown_tetris_arr[5 ] = update_data   [ 2];
				blockdown_tetris_arr[4 ] = update_data   [ 1];
				blockdown_tetris_arr[3 ] = update_data   [ 0];
				blockdown_tetris_arr[2 ] = tetris_broaden[2 ];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd4 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = tetris_broaden[11];
				blockdown_tetris_arr[10] = tetris_broaden[10];
				blockdown_tetris_arr[9 ] = tetris_broaden[9 ];
				blockdown_tetris_arr[8 ] = tetris_broaden[8 ];
				blockdown_tetris_arr[7 ] = update_data   [ 5];
				blockdown_tetris_arr[6 ] = update_data   [ 4];
				blockdown_tetris_arr[5 ] = update_data   [ 3];
				blockdown_tetris_arr[4 ] = update_data   [ 2];
				blockdown_tetris_arr[3 ] = update_data   [ 1];
				blockdown_tetris_arr[2 ] = update_data   [ 0];
				blockdown_tetris_arr[1 ] = tetris_broaden[1 ];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd3 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = tetris_broaden[11];
				blockdown_tetris_arr[10] = tetris_broaden[10];
				blockdown_tetris_arr[9 ] = tetris_broaden[9 ];
				blockdown_tetris_arr[8 ] = tetris_broaden[8 ];
				blockdown_tetris_arr[7 ] = tetris_broaden[7 ];
				blockdown_tetris_arr[6 ] = update_data   [ 5];
				blockdown_tetris_arr[5 ] = update_data   [ 4];
				blockdown_tetris_arr[4 ] = update_data   [ 3];
				blockdown_tetris_arr[3 ] = update_data   [ 2];
				blockdown_tetris_arr[2 ] = update_data   [ 1];
				blockdown_tetris_arr[1 ] = update_data   [ 0];
				blockdown_tetris_arr[0 ] = tetris_broaden[0 ];

			end
			4'd2 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = tetris_broaden[11];
				blockdown_tetris_arr[10] = tetris_broaden[10];
				blockdown_tetris_arr[9 ] = tetris_broaden[9 ];
				blockdown_tetris_arr[8 ] = tetris_broaden[8 ];
				blockdown_tetris_arr[7 ] = tetris_broaden[7 ];
				blockdown_tetris_arr[6 ] = tetris_broaden[6 ];
				blockdown_tetris_arr[5 ] = update_data   [5 ];
				blockdown_tetris_arr[4 ] = update_data   [4 ];
				blockdown_tetris_arr[3 ] = update_data   [3 ];
				blockdown_tetris_arr[2 ] = update_data   [2 ];
				blockdown_tetris_arr[1 ] = update_data   [1 ];
				blockdown_tetris_arr[0 ] = update_data   [0 ];

			end
			4'd1 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = tetris_broaden[11];
				blockdown_tetris_arr[10] = tetris_broaden[10];
				blockdown_tetris_arr[9 ] = tetris_broaden[9 ];
				blockdown_tetris_arr[8 ] = tetris_broaden[8 ];
				blockdown_tetris_arr[7 ] = tetris_broaden[7 ];
				blockdown_tetris_arr[6 ] = tetris_broaden[6 ];
				blockdown_tetris_arr[5 ] = update_data   [5 ];
				blockdown_tetris_arr[4 ] = update_data   [4 ];
				blockdown_tetris_arr[3 ] = update_data   [3 ];
				blockdown_tetris_arr[2 ] = update_data   [2 ];
				blockdown_tetris_arr[1 ] = update_data   [1 ];
				blockdown_tetris_arr[0 ] = update_data   [0 ];

			end
			4'd0 :begin
				blockdown_tetris_arr[15] = tetris_broaden[15];
				blockdown_tetris_arr[14] = tetris_broaden[14];
				blockdown_tetris_arr[13] = tetris_broaden[13];
				blockdown_tetris_arr[12] = tetris_broaden[12];
				blockdown_tetris_arr[11] = tetris_broaden[11];
				blockdown_tetris_arr[10] = tetris_broaden[10];
				blockdown_tetris_arr[9 ] = tetris_broaden[9 ];
				blockdown_tetris_arr[8 ] = tetris_broaden[8 ];
				blockdown_tetris_arr[7 ] = tetris_broaden[7 ];
				blockdown_tetris_arr[6 ] = tetris_broaden[6 ];
				blockdown_tetris_arr[5 ] = update_data   [5 ];
				blockdown_tetris_arr[4 ] = update_data   [4 ];
				blockdown_tetris_arr[3 ] = update_data   [3 ];
				blockdown_tetris_arr[2 ] = update_data   [2 ];
				blockdown_tetris_arr[1 ] = update_data   [1 ];
				blockdown_tetris_arr[0 ] = update_data   [0 ];

			end
			default: begin
				blockdown_tetris_arr[15] = 'dX;
				blockdown_tetris_arr[14] = 'dX;
				blockdown_tetris_arr[13] = 'dX;
				blockdown_tetris_arr[12] = 'dX;
				blockdown_tetris_arr[11] = 'dX;
				blockdown_tetris_arr[10] = 'dX;
				blockdown_tetris_arr[9 ] = 'dX;
				blockdown_tetris_arr[8 ] = 'dX;
				blockdown_tetris_arr[7 ] = 'dX;
				blockdown_tetris_arr[6 ] = 'dX;
				blockdown_tetris_arr[5 ] = 'dX;
				blockdown_tetris_arr[4 ] = 'dX;
				blockdown_tetris_arr[3 ] = 'dX;
				blockdown_tetris_arr[2 ] = 'dX;
				blockdown_tetris_arr[1 ] = 'dX;
				blockdown_tetris_arr[0 ] = 'dX;

			end
		endcase
	end

	//flanten blockdown_tetris_arr
	always @(*) begin
		blockdown_tetris [95:90] = blockdown_tetris_arr [15] ;
		blockdown_tetris [89:84] = blockdown_tetris_arr [14] ;
		blockdown_tetris [83:78] = blockdown_tetris_arr [13] ;
		blockdown_tetris [77:72] = blockdown_tetris_arr [12] ;
		blockdown_tetris [71:66] = blockdown_tetris_arr [11] ;
		blockdown_tetris [65:60] = blockdown_tetris_arr [10] ;
		blockdown_tetris [59:54] = blockdown_tetris_arr [9 ] ;
		blockdown_tetris [53:48] = blockdown_tetris_arr [8 ] ;
		blockdown_tetris [47:42] = blockdown_tetris_arr [7 ] ;
		blockdown_tetris [41:36] = blockdown_tetris_arr [6 ] ;
		blockdown_tetris [35:30] = blockdown_tetris_arr [5 ] ;
		blockdown_tetris [29:24] = blockdown_tetris_arr [4 ] ;
		blockdown_tetris [23:18] = blockdown_tetris_arr [3 ] ;
		blockdown_tetris [17:12] = blockdown_tetris_arr [2 ] ;
		blockdown_tetris [11:6]  = blockdown_tetris_arr [1 ] ;
		blockdown_tetris [5:0]   = blockdown_tetris_arr [0 ] ;
	end

endmodule


module eliminate (
		input [95:0]blockdown_tetris,
		output  [71:0]eliminate_tetris,
		output rangeout,
		output [2:0] eliminate_level_num11
	);

	wire [11:0]eliminate_level;
	reg  [95:0] n_eliminate_tetris;
	wire [2:0] eliminate_level_num0, eliminate_level_num1, eliminate_level_num2 , eliminate_level_num3, eliminate_level_num4, eliminate_level_num5,
		eliminate_level_num6, eliminate_level_num7, eliminate_level_num8, eliminate_level_num9, eliminate_level_num10;


	eliminate_level eliminate_level0 (
		.blockdown_tetris(blockdown_tetris[71:0]),
		.eliminate_level(eliminate_level),
		.eliminate_level_num0(eliminate_level_num0 ),
		.eliminate_level_num1(eliminate_level_num1 ),
		.eliminate_level_num2(eliminate_level_num2 ),
		.eliminate_level_num3(eliminate_level_num3 ),
		.eliminate_level_num4(eliminate_level_num4 ),
		.eliminate_level_num5(eliminate_level_num5 ),
		.eliminate_level_num6(eliminate_level_num6 ),
		.eliminate_level_num7(eliminate_level_num7 ),
		.eliminate_level_num8(eliminate_level_num8 ),
		.eliminate_level_num9(eliminate_level_num9 ),
		.eliminate_level_num10(eliminate_level_num10),
		.eliminate_level_num11(eliminate_level_num11)
	);

	always @(*) begin
		case (eliminate_level_num0)
			3'd0:n_eliminate_tetris[5:0] = blockdown_tetris[5:0];
			3'd1:n_eliminate_tetris[5:0] = blockdown_tetris[11:6];
			default: n_eliminate_tetris[5:0] = 'dX;
		endcase
		case (eliminate_level_num1)
			3'd0:n_eliminate_tetris[11:6] = blockdown_tetris[11:6];
			3'd1:n_eliminate_tetris[11:6] = blockdown_tetris[17:12];
			3'd2:n_eliminate_tetris[11:6] = blockdown_tetris[23:18];
			default: n_eliminate_tetris[11:6] = 'dX;
		endcase
		case (eliminate_level_num2)
			3'd0:n_eliminate_tetris[17:12] = blockdown_tetris[17:12];
			3'd1:n_eliminate_tetris[17:12] = blockdown_tetris[23:18];
			3'd2:n_eliminate_tetris[17:12] = blockdown_tetris[29:24];
			3'd3:n_eliminate_tetris[17:12] = blockdown_tetris[35:30];
			default: n_eliminate_tetris[17:12] = 'dX;
		endcase
		case (eliminate_level_num3)
			3'd0:n_eliminate_tetris[23:18] = blockdown_tetris[23:18];
			3'd1:n_eliminate_tetris[23:18] = blockdown_tetris[29:24];
			3'd2:n_eliminate_tetris[23:18] = blockdown_tetris[35:30];
			3'd3:n_eliminate_tetris[23:18] = blockdown_tetris[41:36];
			3'd4:n_eliminate_tetris[23:18] = blockdown_tetris[47:42];
			default: n_eliminate_tetris[23:18] = 'dX;
		endcase
		case (eliminate_level_num4)
			3'd0:n_eliminate_tetris[29:24] = blockdown_tetris[29:24];
			3'd1:n_eliminate_tetris[29:24] = blockdown_tetris[35:30];
			3'd2:n_eliminate_tetris[29:24] = blockdown_tetris[41:36];
			3'd3:n_eliminate_tetris[29:24] = blockdown_tetris[47:42];
			3'd4:n_eliminate_tetris[29:24] = blockdown_tetris[52:48];
			default: n_eliminate_tetris[29:24] = 'dX;
		endcase
		case (eliminate_level_num5)
			3'd0:n_eliminate_tetris[35:30] = blockdown_tetris[35:30];
			3'd1:n_eliminate_tetris[35:30] = blockdown_tetris[41:36];
			3'd2:n_eliminate_tetris[35:30] = blockdown_tetris[47:42];
			3'd3:n_eliminate_tetris[35:30] = blockdown_tetris[53:48];
			3'd4:n_eliminate_tetris[35:30] = blockdown_tetris[59:54];
			default: n_eliminate_tetris[35:30] = 'dX;
		endcase
		case (eliminate_level_num6)
			3'd0:n_eliminate_tetris[41:36] = blockdown_tetris[41:36];
			3'd1:n_eliminate_tetris[41:36] = blockdown_tetris[47:42];
			3'd2:n_eliminate_tetris[41:36] = blockdown_tetris[53:48];
			3'd3:n_eliminate_tetris[41:36] = blockdown_tetris[59:54];
			3'd4:n_eliminate_tetris[41:36] = blockdown_tetris[65:60];
			default: n_eliminate_tetris[41:36] = 'dX;
		endcase
		case (eliminate_level_num7)
			3'd0:n_eliminate_tetris[47:42] = blockdown_tetris[47:42];
			3'd1:n_eliminate_tetris[47:42] = blockdown_tetris[53:48];
			3'd2:n_eliminate_tetris[47:42] = blockdown_tetris[59:54];
			3'd3:n_eliminate_tetris[47:42] = blockdown_tetris[65:60];
			3'd4:n_eliminate_tetris[47:42] = blockdown_tetris[71:66];
			default: n_eliminate_tetris[47:42] = 'dX;
		endcase
		case (eliminate_level_num8)
			3'd0:n_eliminate_tetris[53:48] = blockdown_tetris[53:48];
			3'd1:n_eliminate_tetris[53:48] = blockdown_tetris[59:54];
			3'd2:n_eliminate_tetris[53:48] = blockdown_tetris[65:60];
			3'd3:n_eliminate_tetris[53:48] = blockdown_tetris[71:66];
			3'd4:n_eliminate_tetris[53:48] = blockdown_tetris[77:72];
			default: n_eliminate_tetris[53:48] = 'dX;
		endcase
		case (eliminate_level_num9)
			3'd0:n_eliminate_tetris[59:54] = blockdown_tetris[59:54];
			3'd1:n_eliminate_tetris[59:54] = blockdown_tetris[65:60];
			3'd2:n_eliminate_tetris[59:54] = blockdown_tetris[71:66];
			3'd3:n_eliminate_tetris[59:54] = blockdown_tetris[77:72];
			3'd4:n_eliminate_tetris[59:54] = blockdown_tetris[83:78];
			default: n_eliminate_tetris[59:54] = 'dX;
		endcase
		case (eliminate_level_num10)
			3'd0:n_eliminate_tetris[65:60] = blockdown_tetris[65:60];
			3'd1:n_eliminate_tetris[65:60] = blockdown_tetris[71:66];
			3'd2:n_eliminate_tetris[65:60] = blockdown_tetris[77:72];
			3'd3:n_eliminate_tetris[65:60] = blockdown_tetris[83:78];
			3'd4:n_eliminate_tetris[65:60] = blockdown_tetris[89:84];
			default: n_eliminate_tetris[65:60] = 'dX;
		endcase
		case (eliminate_level_num11)
			3'd0:n_eliminate_tetris[71:66] = blockdown_tetris[71:66];
			3'd1:n_eliminate_tetris[71:66] = blockdown_tetris[77:72];
			3'd2:n_eliminate_tetris[71:66] = blockdown_tetris[83:78];
			3'd3:n_eliminate_tetris[71:66] = blockdown_tetris[89:84];
			3'd4:n_eliminate_tetris[71:66] = blockdown_tetris[95:90];
			default: n_eliminate_tetris[71:66] = 'dX;
		endcase
		case (eliminate_level_num11)
			3'd0:n_eliminate_tetris[71:66] = blockdown_tetris[71:66];
			3'd1:n_eliminate_tetris[71:66] = blockdown_tetris[77:72];
			3'd2:n_eliminate_tetris[71:66] = blockdown_tetris[83:78];
			3'd3:n_eliminate_tetris[71:66] = blockdown_tetris[89:84];
			3'd4:n_eliminate_tetris[71:66] = blockdown_tetris[95:90];
			default: n_eliminate_tetris[71:66] = 'dX;
		endcase




		case (eliminate_level_num11)
			3'd0:n_eliminate_tetris[77:72] = blockdown_tetris[77:72];
			3'd1:n_eliminate_tetris[77:72] = blockdown_tetris[83:78];
			3'd2:n_eliminate_tetris[77:72] = blockdown_tetris[89:84];
			3'd3:n_eliminate_tetris[77:72] = blockdown_tetris[95:90];
			3'd4:n_eliminate_tetris[77:72] = 'd0;
			default: n_eliminate_tetris[77:72] = 'dX;
		endcase
		case (eliminate_level_num11)
			3'd0:n_eliminate_tetris[83:78] = blockdown_tetris[83:78];
			3'd1:n_eliminate_tetris[83:78] = blockdown_tetris[89:84];
			3'd2:n_eliminate_tetris[83:78] = blockdown_tetris[95:90];
			3'd3:n_eliminate_tetris[83:78] = 'd0;
			3'd4:n_eliminate_tetris[83:78] = 'd0;
			default: n_eliminate_tetris[83:78] = 'dX;
		endcase
					case (eliminate_level_num11)
			3'd0:n_eliminate_tetris[89:84] = blockdown_tetris[89:84];
			3'd1:n_eliminate_tetris[89:84] = blockdown_tetris[95:90];
			3'd2:n_eliminate_tetris[89:84] = 'd0;
			3'd3:n_eliminate_tetris[89:84] = 'd0;
			3'd4:n_eliminate_tetris[89:84] = 'd0;
			default: n_eliminate_tetris[89:84] = 'dX;
		endcase
		case (eliminate_level_num11)
			3'd0:n_eliminate_tetris[95:90] = blockdown_tetris[95:90];
			3'd1:n_eliminate_tetris[95:90] = 'd0;
			3'd2:n_eliminate_tetris[95:90] = 'd0;
			3'd3:n_eliminate_tetris[95:90] = 'd0;
			3'd4:n_eliminate_tetris[95:90] = 'd0;
			default: n_eliminate_tetris[95:90] = 'dX;
		endcase
	end

	assign rangeout = (|n_eliminate_tetris[77:72]);
	assign eliminate_tetris[71:0] = n_eliminate_tetris[71:0];

endmodule



/// !!!!!!!!!!!!!!!!!!!!!![71:0] instead of [95:0]
module eliminate_level (
		input [71:0] blockdown_tetris,
		output [11:0]eliminate_level,
		output [2:0] eliminate_level_num0, eliminate_level_num1, eliminate_level_num2 , eliminate_level_num3, eliminate_level_num4, eliminate_level_num5,
		eliminate_level_num6, eliminate_level_num7, eliminate_level_num8, eliminate_level_num9, eliminate_level_num10, eliminate_level_num11
	);

	assign eliminate_level[11] = & (blockdown_tetris [71:66]);
	assign eliminate_level[10] = & (blockdown_tetris [65:60]);
	assign eliminate_level[9 ] = & (blockdown_tetris [59:54]);
	assign eliminate_level[8 ] = & (blockdown_tetris [53:48]);
	assign eliminate_level[7 ] = & (blockdown_tetris [47:42]);
	assign eliminate_level[6 ] = & (blockdown_tetris [41:36]);
	assign eliminate_level[5 ] = & (blockdown_tetris [35:30]);
	assign eliminate_level[4 ] = & (blockdown_tetris [29:24]);
	assign eliminate_level[3 ] = & (blockdown_tetris [23:18]);
	assign eliminate_level[2 ] = & (blockdown_tetris [17:12]);
	assign eliminate_level[1 ] = & (blockdown_tetris [11:6] );
	assign eliminate_level[0]  = & (blockdown_tetris [5:0]  );




	assign eliminate_level_num0 = {2'd0,eliminate_level[0 ]};


	assign eliminate_level_num1 = eliminate_level_num0+{2'd0,eliminate_level[1 ]};

	assign eliminate_level_num2 = eliminate_level_num1+{2'd0,eliminate_level[2 ]};

	assign eliminate_level_num3 = eliminate_level_num2+{2'd0,eliminate_level[3 ]};



	assign eliminate_level_num4 = eliminate_level_num3+{2'd0,eliminate_level[4 ]};

	assign eliminate_level_num5 = eliminate_level_num4+{2'd0,eliminate_level[5 ]};

	assign eliminate_level_num6 = eliminate_level_num5 +{2'd0,eliminate_level[6 ]};

	// assign eliminate_level_num7 = eliminate_level_num6 +{2'd0,eliminate_level[7 ]};

	assign eliminate_level_num7 = (({2'd0,eliminate_level[0 ]}+{2'd0,eliminate_level[1 ]})+({2'd0,eliminate_level[2 ]}+{2'd0,eliminate_level[3 ]}))+(({2'd0,eliminate_level[4 ]}+{2'd0,eliminate_level[5 ]}) +({2'd0,eliminate_level[6 ]} + {2'd0,eliminate_level[7 ]}));


	assign eliminate_level_num8 = eliminate_level_num7 +{2'd0,eliminate_level[8 ]};

	assign eliminate_level_num9 = eliminate_level_num8 +{2'd0,eliminate_level[9 ]};

	assign eliminate_level_num10= eliminate_level_num9 +{2'd0,eliminate_level[10 ]};

	assign eliminate_level_num11= eliminate_level_num10+{2'd0,eliminate_level[11]};

endmodule



module shift_tetris (
		clk, rst_n,in_valid,blockdown_tetris,cs,EndEliminate,st_flatten,rangeout,addsign,nofull
	);


	parameter idle =2'd0 ; //valid = 0
	parameter blockdown_state = 2'd1; // valid =1
	parameter eliminate = 2'd2; // valid = 0 , finish and out;
	parameter finsish = 2'd3;


		input clk, rst_n,in_valid;
		input [95:0]blockdown_tetris;
		input [1:0] cs;
		output EndEliminate;
		output [71:0] st_flatten;
		output rangeout;
		output addsign;
		output nofull;
		reg [5:0] st [15:0];
		reg [5:0] blockdown_tetris_arr[15:0];
		reg [15:0] list ;
		reg [5:0] Data_in [15:0];
		reg [15:0] eliminate_list;

		integer i ;
		always @(*) begin
			blockdown_tetris_arr[15] = blockdown_tetris [95:90];
			blockdown_tetris_arr[14] = blockdown_tetris [89:84];
			blockdown_tetris_arr[13] = blockdown_tetris [83:78];
			blockdown_tetris_arr[12] = blockdown_tetris [77:72];
			blockdown_tetris_arr[11] = blockdown_tetris [71:66];
			blockdown_tetris_arr[10] = blockdown_tetris [65:60];
			blockdown_tetris_arr[9 ] = blockdown_tetris [59:54];
			blockdown_tetris_arr[8 ] = blockdown_tetris [53:48];
			blockdown_tetris_arr[7 ] = blockdown_tetris [47:42];
			blockdown_tetris_arr[6 ] = blockdown_tetris [41:36];
			blockdown_tetris_arr[5 ] = blockdown_tetris [35:30];
			blockdown_tetris_arr[4 ] = blockdown_tetris [29:24];
			blockdown_tetris_arr[3 ] = blockdown_tetris [23:18];
			blockdown_tetris_arr[2 ] = blockdown_tetris [17:12];
			blockdown_tetris_arr[1 ] = blockdown_tetris [11:6 ];
			blockdown_tetris_arr[0 ] = blockdown_tetris [5 :0 ];
		end

		always @ (*)begin
			for(i=0;i<16;i=i+1)
			eliminate_list[i] = (cs == eliminate)? (&st[i]):(& blockdown_tetris_arr [i]);
		end

		always @(*) begin
			list[0] = eliminate_list[0];
			list[1] = eliminate_list[0] | eliminate_list[1];
			list[2] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2];
			list[3] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3];
			list[4] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4];
			list[5] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5];
			list[6] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6];
			list[7] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7];
			list[8] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7] | eliminate_list[8];
			list[9] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7] | eliminate_list[8] | eliminate_list[9];
			list[10] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7] | eliminate_list[8] | eliminate_list[9] | eliminate_list[10];
			list[11] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7] | eliminate_list[8] | eliminate_list[9] | eliminate_list[10] | eliminate_list[11];
			list[12] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7] | eliminate_list[8] | eliminate_list[9] | eliminate_list[10] | eliminate_list[11] | eliminate_list[12];
			list[13] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7] | eliminate_list[8] | eliminate_list[9] | eliminate_list[10] | eliminate_list[11] | eliminate_list[12] | eliminate_list[13];
			list[14] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7] | eliminate_list[8] | eliminate_list[9] | eliminate_list[10] | eliminate_list[11] | eliminate_list[12] | eliminate_list[13] | eliminate_list[14];
			list[15] = eliminate_list[0] | eliminate_list[1] | eliminate_list[2] | eliminate_list[3] | eliminate_list[4] | eliminate_list[5] | eliminate_list[6] | eliminate_list[7] | eliminate_list[8] | eliminate_list[9] | eliminate_list[10] | eliminate_list[11] | eliminate_list[12] | eliminate_list[13] | eliminate_list[14] | eliminate_list[15];

		end

		assign nofull = |list;
		assign addsign =(cs == eliminate)? nofull:1'd0;
		assign EndEliminate = (cs ==eliminate) & !addsign;
		assign rangeout = EndEliminate & ( | st[12]);

		always @(*) begin
				if (cs == eliminate ) begin
					for (i=0 ; i<15 ;i=i+1) begin
						Data_in[i] = ( list[i] )?st[i+1]:st[i];
					end
						Data_in[15] = ( list[15] )?'d0:st[15];
				end
				else if ( in_valid) begin
					for (i=0 ; i<15 ;i=i+1) begin
						Data_in[i] = blockdown_tetris_arr[i];
					end
						Data_in[15] = blockdown_tetris_arr[15];
				end
				else
					for (i=0 ; i<16 ;i=i+1) begin
						Data_in[i] = 'd0;
					end
			end





		// 		always @(*) begin
		// 	for (i=0 ; i<15 ;i=i+1) begin
		// 		if (cs == eliminate )
		// 		Data_in[i] = ( list[i] )?Data_in[i+1]:Data_in[i];
		// 		else if ( in_valid)
		// 		Data_in[i] = blockdown_tetris_arr[i];
		// 		else
		// 		Data_in[i] = 'd0;
		// 	end
		// 		if (cs == eliminate )
		// 			Data_in[15] = ( list[15] )?'d0:Data_in[i];
		// 		else if (in_valid)
		// 			Data_in[15] = blockdown_tetris_arr[15];
		// 		else
		// 			Data_in[15]= 'd0;


		// end

		always @( posedge clk or negedge rst_n) begin
			if (!rst_n)
				for (i=0 ; i<16 ;i=i+1)
					st [i] <= 6'd0;
			else
				for (i=0 ; i<16 ;i=i+1)
					st [i] <= Data_in[i];
		end

		assign st_flatten =  {st[11] ,st[10] ,st[9] ,st[8] ,st[7] ,st[6] ,st[5] ,st[4] ,st[3] ,st[2] ,st[1], st[0]};

	endmodule



















// 	//update_data = influenced_data + add_data
// always @(*) begin
// 	if (block_land_sec_high & (|highest_touch_level_ord[3:1])  & tetrominoes==4'd3)begin
// 		case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3] ;
// 					update_data[4] = influenced_data[4] ;
// 					update_data[5] = influenced_data[5];
// 				end
// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 		endcase
// 	end
// 	else if (block_land_high) begin
// 		case (tetrominoes)
// 			4'd3: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3] | add_data[2];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase


// 			4'd4: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end

// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase

// 			4'd6: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3] | add_data[2];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase


// 			4'd7: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end

// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase
// 			default :begin
// 				update_data[0] = 'dX;
// 				update_data[1] = 'dX;
// 				update_data[2] = 'dX;
// 				update_data[3] = 'dX;
// 				update_data[4] = 'dX;
// 				update_data[5] = 'dX;
// 			end
// 		endcase
// 	end

// 	else begin
// 		case (tetrominoes)
// 			4'd0: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase
// 			4'd1: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 					end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5] | add_data[3];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3] | add_data[2];
// 					update_data[4] = influenced_data[4] | add_data[3];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3] | add_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase

// 			4'd2: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end

// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase

// 			4'd3: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0]| add_data[0];
// 					update_data[1] = influenced_data[1]| add_data[1];
// 					update_data[2] = influenced_data[2]| add_data[2] ;
// 					update_data[3] = influenced_data[3] ;
// 					update_data[4] = influenced_data[4] ;
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3] | add_data[2];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase


// 			4'd4: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end

// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase

// 			4'd5: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3] | add_data[2];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase

// 			4'd6: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4] | add_data[2];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3] | add_data[2];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2] | add_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase


// 			4'd7: case (highest_touch_level_ord)
// 				4'd12:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd11:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd10:begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd9 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd8 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd7 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd6 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd5 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd4 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd3 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd2 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1];
// 					update_data[2] = influenced_data[2] | add_data[0];
// 					update_data[3] = influenced_data[3] | add_data[1];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd1 :begin
// 					update_data[0] = influenced_data[0];
// 					update_data[1] = influenced_data[1] | add_data[0];
// 					update_data[2] = influenced_data[2] | add_data[1];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end
// 				4'd0 :begin
// 					update_data[0] = influenced_data[0] | add_data[0];
// 					update_data[1] = influenced_data[1] | add_data[1];
// 					update_data[2] = influenced_data[2];
// 					update_data[3] = influenced_data[3];
// 					update_data[4] = influenced_data[4];
// 					update_data[5] = influenced_data[5];
// 				end

// 				default:begin
// 					update_data[0] = 'dX;
// 					update_data[1] = 'dX;
// 					update_data[2] = 'dX;
// 					update_data[3] = 'dX;
// 					update_data[4] = 'dX;
// 					update_data[5] = 'dX;
// 				end
// 			endcase
// 		endcase
// 	end
// end
