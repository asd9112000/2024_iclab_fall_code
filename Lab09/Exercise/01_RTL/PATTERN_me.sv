/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory
Lab09: SystemVerilog Design and Verification
File Name   : PATTERN.sv
Module Name : PATTERN
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter PAT_NUM = 1000000 ;
parameter LIMIT_LAT = 1000 ;
parameter OUT_NUM = 1 ;
parameter ACTION_SEED = 48756 ;
parameter TYPE_SEED   = 48756 ;
parameter SIZE_SEED   = 48756 ;
parameter DATE_SEED   = 48756 ;
parameter BOXID_SEED  = 45879 ;
parameter INGFR_SEED  = 48812 ;
parameter INGRA_SEED  = 47849 ;

integer SEED        = 1253761253 ;
integer CYCLE_SEED  = 48756 ;
integer i_pat ;
integer catch ;
integer exe_lat ;
integer out_lat ;
//================================================================
// wire & registers
//================================================================
logic [10:0] count ;
logic [7:0]  golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box
logic [20:0] global_count ;
// Error_Msg pattern_err_msg ;

Data_No input_data_no ;



logic [19:0] d_Addr;
// logic [7:0] dram_data [0:7];
logic [7:0] d_Day;
logic [7:0] d_Month;
logic [11:0] d_IorV  [0:3]; //0:TA 1:TB 2:TC 3:TD
logic signed [12:0] d_IorVs [0:3]; //0:TA 1:TB 2:TC 3:TD //signed

logic [11:0] golden_Result;
logic [1:0]  golden_warn_msg;
logic [0:0]  golden_complete;
logic [11:0] Formula_Threshold_Table[2:0];
logic [11:0] Index_Check_Threshold;
logic Date_Warn_flag ;
logic Data_Warn_flag ;
logic Risk_Warn_flag ;



logic [11:0] d_IndexA;
logic [11:0] d_IndexB;
logic [11:0] d_IndexC;
logic [11:0] d_IndexD;
logic [11:0] GA;
logic [11:0] GB;
logic [11:0] GC;
logic [11:0] GD;
logic [11:0] Max;
logic [11:0] Min;
logic [11:0] MiddleBig;
logic [11:0] MiddleSmall;
logic [11:0] GMax;
logic [11:0] GMin;
logic [11:0] GMiddleBig;
logic [11:0] GMiddleSmall;




//========================================
//                  Update
//========================================

logic [12:0]Fixed_index[0:3]; // A, B, C, D = 0, 1, 2, 3
logic [12:0] E_Dram_Index_A, E_Dram_Index_B, E_Dram_Index_C, E_Dram_Index_D;
logic [0:3] MayOverflow;
logic [0:3] MayUnderflow;









assign d_Addr = 'h10000 + input_data_no*8;
assign d_Day    =  golden_DRAM[d_Addr];
assign d_IndexD = {golden_DRAM[d_Addr+2][3:0],golden_DRAM[d_Addr+1]};  //D
assign d_IndexC = {golden_DRAM[d_Addr+3],golden_DRAM[d_Addr+2][7:4]};  //C
assign d_Month  =  golden_DRAM[d_Addr+4];
assign d_IndexB = {golden_DRAM[d_Addr+6][3:0],golden_DRAM[d_Addr+5]};  //B
assign d_IndexA = {golden_DRAM[d_Addr+7],golden_DRAM[d_Addr+6][7:4]};  //A

assign d_IorVs[0] = {1'b0, d_IorV[0]};
assign d_IorVs[1] = {1'b0, d_IorV[1]};
assign d_IorVs[2] = {1'b0, d_IorV[2]};
assign d_IorVs[3] = {1'b0, d_IorV[3]};







//================================================================
// class random
//================================================================



class random_act_num ;
	randc logic [3:0] act_id ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		act_id inside {[1:14]} ;
	}
endclass

logic [3:0] action_num ;
Action input_action ;
random_act_num action_rand = new(ACTION_SEED) ;


// class random_act;
//     randc Action act_id;
//     constraint range{
//         act_id inside{Index_Check, Update, Check_Valid_Date};
//     }
// endclass




// Formula_Type
class random_formula_type ;
	randc logic [2:0] formula_type ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		formula_type inside {   Formula_A, Formula_B, Formula_C, Formula_D,
                                Formula_E, Formula_F, Formula_G, Formula_H };
	}
endclass

logic [2:0] input_formula_type ;
random_formula_type formula_type_rand = new(TYPE_SEED) ;





// input data_no.
class random_data_no ;
	randc Data_No data_no ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		data_no inside {[0:255]} ;
	}
endclass

// Data_No input_data_no ;
random_data_no data_no_rand = new(BOXID_SEED) ;

// input today
class random_today ;
	randc Day   today_day ;
	randc Month today_mon ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		today_mon inside {[1:12]} ;
		today_day inside {[1:31]} ;
		if (today_mon == 2) {
			today_day inside {[1:28]} ;
		}
		else if (today_mon == 4 || today_mon == 6 || today_mon == 9 || today_mon == 11) {
			today_day inside {[1:30]} ;
		}
	}
endclass

Day   input_day ;
Month input_month ;
random_today today_rand = new(DATE_SEED) ;

// input index
class random_index ;
	randc Index Index_A ;
    randc Index Index_B ;
    randc Index Index_C ;
    randc Index Index_D ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		Index_A inside {[0:4095]} ;
        Index_B inside {[0:4095]} ;
        Index_C inside {[0:4095]} ;
        Index_D inside {[0:4095]} ;
	}
endclass

Index input_indexA, input_indexB, input_indexC, input_indexD ;
logic signed [11:0] s_input_indexA, s_input_indexB, s_input_indexC, s_input_indexD ;
random_index index_rand = new(BOXID_SEED) ;


// input mode.
class random_mode ;
	randc Mode mode ;
	function new (int seed) ;
		this.srandom(seed) ;
	endfunction
	constraint range {
		mode inside { Insensitive, Normal, Sensitive } ;
	}
endclass

Mode input_mode ;
random_mode mode_rand = new(BOXID_SEED) ;


// class random_ing_rare ;
// 	randc bit [6:0] ingredient_rare ;
// 	function new (int seed) ;
// 		this.srandom(seed) ;
// 	endfunction
// endclass

// ING input_bt, input_gt, input_m, input_p ;
// bit [4:0] ing_front ;
// bit [6:0] ing_rare  ;
// random_ing_front ing_front_rand = new(INGFR_SEED) ;
// random_ing_rare  ing_rare_rand  = new(INGRA_SEED) ;


//================================================================
// initial
//================================================================
initial begin
	$readmemh (DRAM_p_r, golden_DRAM) ;
	reset_task ;
	global_count = 0 ;
	count = 0 ;
	for (i_pat = 0 ; i_pat < PAT_NUM ; i_pat = i_pat + 1) begin
		input_task ;
		cal_task ;
		wait_task ;  // msg is ok
		check_task ; // complete  => check
		$display ("pass No.%d pattern", i_pat) ;
		global_count = global_count + 1 ;
	end
	pass_task ;
	$finish ;
end

//================================================================
// tasks
//================================================================
task reset_task ; begin
	inf.rst_n            = 1;
    inf.sel_action_valid = 0;
    inf.formula_valid       = 0;
    inf.mode_valid       = 0;
    inf.date_valid       = 0;
    inf.data_no_valid     = 0;
    inf.index_valid    = 0;
    inf.D                = 'dx;

    #(10) inf.rst_n = 0;
	repeat (5) @(negedge clk) ;
    inf.rst_n = 1;
end endtask

task input_task ; begin
	@(negedge clk) ;
	//=========================================================
	// input action
	//=========================================================
	// random action
	catch = action_rand.randomize() ;
	action_num = action_rand.act_id ;
	if (global_count < 2000) begin
		input_action = Update ;
	end
	else if (global_count <= 2200 && global_count >= 2000) begin
		input_action = Check_Valid_Date ;
	end
	else if (global_count <= 2401 && global_count >= 2201) begin
		input_action = Index_Check ;
	end
	else if (global_count == 3599) begin
		input_action = Update ;
	end
	else begin
		// $display("%d", global_count) ;
		case (global_count % 6)
			0 : input_action = Index_Check ;
			1 : input_action = Update ;
			2 : input_action = Check_Valid_Date ;
			3 : input_action = Update ;
			4 : input_action = Index_Check ;
			5 : input_action = Check_Valid_Date ;
		endcase
	end

	inf.sel_action_valid = 1 ;
	inf.D.d_act[0] = input_action ;
	@(negedge clk) ;
	inf.sel_action_valid = 0 ;
	inf.D = 'dx ;
	// margin cycle
	@(negedge clk) ;
	//========================================================

	case (input_action)
		Update : begin
			//=========================================================
			// Input Date data
			//=========================================================
			catch = today_rand.randomize() ;
			input_day   = today_rand.today_day ;
			input_month = today_rand.today_mon ;
			// $display ("%d/%d", input_month, input_day) ;
			// give input
			inf.date_valid = 1 ;
			inf.D.d_date[0] = {input_month, input_day} ;
			@(negedge clk) ;
			// pull down input
			inf.date_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================


			//=========================================================
			// Input Dram No.
			//=========================================================

            repeat ($urandom_range(0,3)) @(negedge clk);
			catch = data_no_rand.randomize() ;
			input_data_no = data_no_rand.data_no ;
			// $display ("%d", input_box) ;
			// give input
			inf.data_no_valid = 1 ;
			inf.D.d_data_no[0] = input_data_no ;
			@(negedge clk) ;
			// pull down input
			inf.data_no_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================



			//=========================================================
			// Input Variations of the indices data.
			//=========================================================
            repeat ($urandom_range(0,3)) @(negedge clk);
            catch = index_rand.randomize() ;
            // catch = index_rand.randomize() ;
			// $display ("catch is %d", catch) ;
			s_input_indexA = index_rand.Index_A ;
            s_input_indexB = index_rand.Index_B ;
            s_input_indexC = index_rand.Index_C ;
            s_input_indexD = index_rand.Index_D ;

			input_indexA = index_rand.Index_A ;
            input_indexB = index_rand.Index_B ;
            input_indexC = index_rand.Index_C ;
            input_indexD = index_rand.Index_D ;
			// $display ("s_input_indexA is %d", s_input_indexA) ;

			inf.index_valid = 1 ;
			inf.D.d_index[0] = s_input_indexA ;
			@(negedge clk) ;
			inf.index_valid = 0 ;
			inf.D = 'dx ;
            // repeat ($urandom_range(0,3)) @(negedge clk)

			inf.index_valid = 1 ;
			inf.D.d_index[0] = s_input_indexB ;
			@(negedge clk) ;
			inf.index_valid = 0 ;
			inf.D = 'dx ;
            // repeat ($urandom_range(0,3)) @(negedge clk)

			inf.index_valid = 1 ;
			inf.D.d_index[0] = s_input_indexC ;
			@(negedge clk) ;
			inf.index_valid = 0 ;
			inf.D = 'dx ;
            // repeat ($urandom_range(0,3)) @(negedge clk)

			inf.index_valid = 1 ;
			inf.D.d_index[0] = s_input_indexD ;
			@(negedge clk) ;
			inf.index_valid = 0 ;
			inf.D = 'dx ;
		end
		Check_Valid_Date : begin
			//=========================================================
			// Input Date data
			//=========================================================
			catch = today_rand.randomize() ;
			input_day   = today_rand.today_day ;
			input_month = today_rand.today_mon ;
			// $display ("%d/%d", input_month, input_day) ;
			// give input
			inf.date_valid = 1 ;
			inf.D.d_date[0] = {input_month, input_day} ;
			@(negedge clk) ;
			// pull down input
			inf.date_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle

			//=========================================================
			// Input Dram No.
			//=========================================================

            repeat ($urandom_range(0,3)) @(negedge clk);
			catch = data_no_rand.randomize() ;
			input_data_no = data_no_rand.data_no ;
			// $display ("%d", input_box) ;
			// give input
			inf.data_no_valid = 1 ;
			inf.D.d_data_no[0] = input_data_no ;
			@(negedge clk) ;
			// pull down input
			inf.data_no_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================

			//=========================================================
		end
		Index_Check : begin
			//=========================================================
			// Input Formula Type
			//=========================================================
			catch = formula_type_rand.randomize() ;
			input_formula_type   = formula_type_rand.formula_type ;
			// $display ("%d/%d", input_month, input_day) ;
			// give input
			inf.formula_valid = 1 ;
			inf.D.d_formula[0] = input_formula_type ;
			@(negedge clk) ;
			// pull down input
			inf.formula_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================


			//=========================================================
			// Input Mode
			//=========================================================
			catch = mode_rand.randomize() ;
			input_mode   = mode_rand.mode ;
			// $display ("%d/%d", input_month, input_day) ;
			// give input
			inf.mode_valid = 1 ;
			inf.D.d_mode[0] = input_mode ;
			@(negedge clk) ;
			// pull down input
			inf.mode_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================


			//=========================================================
			// Input Date data
			//=========================================================
			catch = today_rand.randomize() ;
			input_day   = today_rand.today_day ;
			input_month = today_rand.today_mon ;
			// $display ("%d/%d", input_month, input_day) ;
			// give input
			inf.date_valid = 1 ;
			inf.D.d_date[0] = {input_month, input_day} ;
			@(negedge clk) ;
			// pull down input
			inf.date_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================


			//=========================================================
			// Input Dram No.
			//=========================================================

            repeat ($urandom_range(0,3)) @(negedge clk);
			catch = data_no_rand.randomize() ;
			input_data_no = data_no_rand.data_no ;
			// $display ("%d", input_box) ;
			// give input
			inf.data_no_valid = 1 ;
			inf.D.d_data_no[0] = input_data_no ;
			@(negedge clk) ;
			// pull down input
			inf.data_no_valid = 0 ;
			inf.D = 'dx ;
			// margin cycle
			//=========================================================


			//=========================================================
			// Input Today's indices in late trading session
			//=========================================================
            repeat ($urandom_range(0,3)) @(negedge clk);
            catch = index_rand.randomize() ;
			input_indexA = index_rand.Index_A ;
            input_indexB = index_rand.Index_B ;
            input_indexC = index_rand.Index_C ;
            input_indexD = index_rand.Index_D ;
			// $display ("%d", input_box) ;
			// give input
			inf.index_valid = 1 ;
			inf.D.d_index[0] = input_indexA ;
			@(negedge clk) ;
			// pull down input
			inf.index_valid = 0 ;
			inf.D = 'dx ;
            repeat ($urandom_range(0,3)) @(negedge clk);

			inf.index_valid = 1 ;
			inf.D.d_index[0] = input_indexB ;
			@(negedge clk) ;
			// pull down input
			inf.index_valid = 0 ;
			inf.D = 'dx ;
            repeat ($urandom_range(0,3)) @(negedge clk);

			inf.index_valid = 1 ;
			inf.D.d_index[0] = input_indexC ;
			@(negedge clk) ;
			// pull down input
			inf.index_valid = 0 ;
			inf.D = 'dx ;
            repeat ($urandom_range(0,3)) @(negedge clk);

			inf.index_valid = 1 ;
			inf.D.d_index[0] = input_indexD ;
			@(negedge clk) ;
			// pull down input
			inf.index_valid = 0 ;
			inf.D = 'dx ;
		end
	endcase
end endtask

task cal_task ; begin
	Date_Warn_flag         = 0 ;
    Data_Warn_flag         = 0 ;
    Risk_Warn_flag         = 0 ;

    Index_Check_Threshold         = 0 ;
    Formula_Threshold_Table[0] = 0;
    Formula_Threshold_Table[1] = 0;
    Formula_Threshold_Table[2] = 0;
    golden_Result     = 0 ;
    golden_warn_msg   = 0 ;
    golden_complete   = 0 ;
	// if (input_action == Check_Valid_Date)
	// $display("golden_warn_msg = %d ", golden_warn_msg);
	// data        = 1 ;
	// bt_overflow       = 0 ;
	// gt_overflow       = 0 ;
	// milk_overflow     = 0 ;
	// pine_overflow     = 0 ;

	case (input_action)
		Index_Check : begin
			//=========================================================
			// Input date is early than dram ( Date_Warn_flag = 1)
			//=========================================================
			if (input_month < d_Month || (input_month == d_Month && input_day < d_Day))
                Date_Warn_flag = 1 ;
			else
                Date_Warn_flag = 0 ;

			//=========================================================
			// Index_Check_Threshold Table
			//=========================================================
            case (input_formula_type)
                0: begin // Formula_A
                    Formula_Threshold_Table[0] = 11'd2047;
                    Formula_Threshold_Table[1] = 11'd1023;
                    Formula_Threshold_Table[2] = 11'd511;
                end
                1: begin // Formula_B
                    Formula_Threshold_Table[0] = 11'd800;
                    Formula_Threshold_Table[1] = 11'd400;
                    Formula_Threshold_Table[2] = 11'd200;
                end
                2: begin // Formula_C
                    Formula_Threshold_Table[0] = 11'd2047;
                    Formula_Threshold_Table[1] = 11'd1023;
                    Formula_Threshold_Table[2] = 11'd511 ;
                end
                3: begin // Formula_D
                    Formula_Threshold_Table[0] = 11'd3;
                    Formula_Threshold_Table[1] = 11'd2;
                    Formula_Threshold_Table[2] = 11'd1;
                end
                4: begin // Formula_E
                    Formula_Threshold_Table[0] = 11'd3;
                    Formula_Threshold_Table[1] = 11'd2;
                    Formula_Threshold_Table[2] = 11'd1;
                end
                5: begin // Formula_F
                    Formula_Threshold_Table[0] = 11'd800;
                    Formula_Threshold_Table[1] = 11'd400;
                    Formula_Threshold_Table[2] = 11'd200;
                end
                6: begin // Formula_G
                    Formula_Threshold_Table[0] = 11'd800;
                    Formula_Threshold_Table[1] = 11'd400;
                    Formula_Threshold_Table[2] = 11'd200;
                end
                7: begin // Formula_H
                    Formula_Threshold_Table[0] = 11'd800;
                    Formula_Threshold_Table[1] = 11'd400;
                    Formula_Threshold_Table[2] = 11'd200;
                end
            endcase
            case (input_mode)
                0: Index_Check_Threshold = Formula_Threshold_Table[0];
                1: Index_Check_Threshold = Formula_Threshold_Table[1];
                3: Index_Check_Threshold = Formula_Threshold_Table[2];
                default: ;
            endcase

			//=========================================================
			// Compute Preparation Sorting & G
			//=========================================================
            GA = (d_IndexA >= input_indexA) ? d_IndexA - input_indexA : input_indexA - d_IndexA;
            GB = (d_IndexB >= input_indexB) ? d_IndexB - input_indexB : input_indexB - d_IndexB;
            GC = (d_IndexC >= input_indexC) ? d_IndexC - input_indexC : input_indexC - d_IndexC;
            GD = (d_IndexD >= input_indexD) ? d_IndexD - input_indexD : input_indexD - d_IndexD;

            {Max, MiddleBig}= (d_IndexA >= d_IndexB) ? {d_IndexA, d_IndexB} : {d_IndexB, d_IndexA};
            {MiddleSmall, Min}= (d_IndexC >= d_IndexD) ? {d_IndexC, d_IndexD} : {d_IndexD, d_IndexC};
            {Max, MiddleSmall}= (Max >= MiddleSmall) ? {Max, MiddleSmall} : {MiddleSmall, Max};
            {MiddleBig, Min}= (MiddleBig >= Min) ? {MiddleBig, Min} : {Min, MiddleBig};
            {MiddleBig, MiddleSmall}= (MiddleBig >= MiddleSmall) ? {MiddleBig, MiddleSmall} : {MiddleSmall, MiddleBig};

            {GMax, GMiddleBig} = ( GA >= GB ) ? {GA, GB} : {GB, GA};
            {GMiddleSmall, GMin} = ( GC >= GD ) ? {GC, GD} : {GD, GC};
            {GMax, GMiddleSmall} = ( GMax >= GMiddleSmall ) ? {GMax, GMiddleSmall} : {GMiddleSmall, GMax};
            {GMiddleBig, GMin} = ( GMiddleBig >= GMin ) ? {GMiddleBig, GMin} : {GMin, GMiddleBig};

            case (input_formula_type)
                Formula_A: golden_Result = ( d_IndexA + d_IndexB + d_IndexC + d_IndexD ) / 4;
                Formula_B: golden_Result = Max - Min;
                Formula_C: golden_Result = Min;
                Formula_D: golden_Result = (d_IndexA >= 2047) + (d_IndexB >= 2047) + (d_IndexC >= 2047) + (d_IndexD >= 2047);
                Formula_E: golden_Result = (d_IndexA >= input_indexA) + (d_IndexB >= input_indexB) + (d_IndexC >= input_indexC) + (d_IndexD >= input_indexD);
                Formula_F: golden_Result = (GMiddleBig + GMiddleSmall + GMin) /3;
                Formula_G: golden_Result = (GMin/2) + (GMiddleBig/4) + (GMiddleSmall/4);
                Formula_H: golden_Result = (GA + GB + GC + GD) / 4;
                default: ;
            endcase

			//=========================================================
			// Check Index_Check_Threshold
			//=========================================================
            Risk_Warn_flag = (golden_Result >= Index_Check_Threshold) ? 1 : 0;


			//=========================================================
			//                  golden_warn_msg
			//=========================================================
            golden_warn_msg =   (Date_Warn_flag) ? Date_Warn :
                                (Risk_Warn_flag) ? Risk_Warn : 2'b00 ;
		end

		Update : begin
			//=========================================================
			// Ingredient Overflow Or Not
			//=========================================================



            E_Dram_Index_A ={1'b0, d_IndexA};
            E_Dram_Index_B ={1'b0, d_IndexB};
            E_Dram_Index_C ={1'b0, d_IndexC};
            E_Dram_Index_D ={1'b0, d_IndexD};
			// $display("d_IndexA is =%d", d_IndexA);
			// $display("d_IndexB is =%d", d_IndexB);
			// $display("d_IndexC is =%d", d_IndexC);
			// $display("d_IndexD is =%d", d_IndexD);


            MayOverflow [0] =  d_IndexA[11] ;
            MayOverflow [1] =  d_IndexB[11] ;
            MayOverflow [2] =  d_IndexC[11] ;
            MayOverflow [3] =  d_IndexD[11] ;
            MayUnderflow[0] = ~d_IndexA[11] ;
            MayUnderflow[1] = ~d_IndexB[11] ;
            MayUnderflow[2] = ~d_IndexC[11] ;
            MayUnderflow[3] = ~d_IndexD[11] ;

            Fixed_index[0] = E_Dram_Index_A + {s_input_indexA[11], s_input_indexA};
            Fixed_index[1] = E_Dram_Index_B + {s_input_indexB[11], s_input_indexB};
            Fixed_index[2] = E_Dram_Index_C + {s_input_indexC[11], s_input_indexC};
            Fixed_index[3] = E_Dram_Index_D + {s_input_indexD[11], s_input_indexD};

			// $display("s_input_indexA is =%d", s_input_indexA);
			// $display("s_input_indexB is =%d", s_input_indexB);
			// $display("s_input_indexC is =%d", s_input_indexC);
			// $display("s_input_indexD is =%d", s_input_indexD);

			// $display("E_Dram_Index_A is =%d", E_Dram_Index_A);
			// $display("E_Dram_Index_B is =%d", E_Dram_Index_B);
			// $display("E_Dram_Index_C is =%d", E_Dram_Index_C);
			// $display("E_Dram_Index_D is =%d", E_Dram_Index_D);


			// $display("Fixed_index[0] is =%d", Fixed_index[0]);
			// $display("Fixed_index[1] is =%d", Fixed_index[1]);
			// $display("Fixed_index[2] is =%d", Fixed_index[2]);
			// $display("Fixed_index[3] is =%d", Fixed_index[3]);


            Data_Warn_flag =    (MayOverflow [0] && Fixed_index[0][12]) || (MayUnderflow[0] && Fixed_index[0][12]) ||
                                (MayOverflow [1] && Fixed_index[1][12]) || (MayUnderflow[1] && Fixed_index[1][12]) ||
                                (MayOverflow [2] && Fixed_index[2][12]) || (MayUnderflow[2] && Fixed_index[2][12]) ||
                                (MayOverflow [3] && Fixed_index[3][12]) || (MayUnderflow[3] && Fixed_index[3][12]) ;


            Fixed_index[0] = 	(MayOverflow [0] && Fixed_index[0][12]) ? 12'd4095 :
								(MayUnderflow[0] && Fixed_index[0][12]) ? 12'd0    : Fixed_index[0][11:0] ;
            Fixed_index[1] = 	(MayOverflow [1] && Fixed_index[1][12]) ? 12'd4095 :
                                (MayUnderflow[1] && Fixed_index[1][12]) ? 12'd0    : Fixed_index[1][11:0] ;
            Fixed_index[2] = 	(MayOverflow [2] && Fixed_index[2][12]) ? 12'd4095 :
                                (MayUnderflow[2] && Fixed_index[2][12]) ? 12'd0    : Fixed_index[2][11:0] ;
            Fixed_index[3] = 	(MayOverflow [3] && Fixed_index[3][12]) ? 12'd4095 :
                                (MayUnderflow[3] && Fixed_index[3][12]) ? 12'd0    : Fixed_index[3][11:0] ;
			// $display("=================================================");
			// $display("Fixed_index[0] is =%d", Fixed_index[0]);
			// $display("Fixed_index[1] is =%d", Fixed_index[1]);
			// $display("Fixed_index[2] is =%d", Fixed_index[2]);
			// $display("Fixed_index[3] is =%d", Fixed_index[3]);

			//=========================================================
			// Update Dram
			//=========================================================
            golden_DRAM[d_Addr]   = {3'd0, input_day};
            {golden_DRAM[d_Addr+2][3:0],golden_DRAM[d_Addr+1]} = Fixed_index[3][11:0];  //D
            {golden_DRAM[d_Addr+3],golden_DRAM[d_Addr+2][7:4]} = Fixed_index[2][11:0];  //C
            golden_DRAM[d_Addr+4] = {4'd0, input_month};
            {golden_DRAM[d_Addr+6][3:0],golden_DRAM[d_Addr+5]} = Fixed_index[1][11:0];  //B
            {golden_DRAM[d_Addr+7],golden_DRAM[d_Addr+6][7:4]} = Fixed_index[0][11:0];  //A

			// $display("d_IndexA is =%d", d_IndexA);
			// $display("d_IndexB is =%d", d_IndexB);
			// $display("d_IndexC is =%d", d_IndexC);
			// $display("d_IndexD is =%d", d_IndexD);
			// $display("");
			// $display("");
			// $display("");
			//=========================================================
			//                  golden_warn_msg
			//=========================================================
            golden_warn_msg = (Data_Warn_flag) ? 2'b11 : 2'b00 ;

		end
		Check_Valid_Date : begin
			//=========================================================
			// Input date is early than dram ( Date_Warn_flag = 1)
			//=========================================================
			if (input_month < d_Month || (input_month == d_Month && input_day < d_Day))
                Date_Warn_flag = 1 ;
			else
                Date_Warn_flag = 0 ;
            golden_warn_msg = (Date_Warn_flag == 1) ? Date_Warn : No_Warn ;
		end
	endcase
end endtask

task wait_task ; begin
	exe_lat = -1 ;
	while (inf.out_valid !== 1) begin
        exe_lat = exe_lat + 1;
        @(negedge clk);
	if ( exe_lat > 2000) begin
		$display("==========================================================================") ;
		$display("                            Time Out                                      ") ;
		$display("==========================================================================") ;
		$display("Pat num         = %d, Data No       = %d", i_pat[29:0], input_data_no) ;
		case (input_action)
			Update : begin
				$display("Action is Update") ;
			end
			Check_Valid_Date : begin
				$display("Action is Check_Valid_Date") ;
				case (input_formula_type)
					Formula_A: $display("Formula is Formula_A") ;
					Formula_B: $display("Formula is Formula_B") ;
					Formula_C: $display("Formula is Formula_C") ;
					Formula_D: $display("Formula is Formula_D") ;
					Formula_E: $display("Formula is Formula_E") ;
					Formula_F: $display("Formula is Formula_F") ;
					Formula_G: $display("Formula is Formula_G") ;
					Formula_H: $display("Formula is Formula_H") ;
					default:;
				endcase
			end
			Index_Check : begin
				$display("Action is Index_Check") ;
			end
			default: ;
		endcase
		$finish ;
	end
	end
end endtask

task check_task ; begin
    if (golden_warn_msg !== 2'b00)
        golden_complete = 0 ;
    else
        golden_complete = 1 ;


	if (inf.complete !== golden_complete || inf.warn_msg !== golden_warn_msg) begin
        $display("==========================================================================") ;
		$display("                            Wrong Answer                                  ") ;
        $display("==========================================================================") ;
		$display("golden_complete = %d, golden_warn_msg = %d", golden_complete, golden_warn_msg) ;
		$display("your complete   = %d, your warn_msg   = %d", inf.complete, inf.warn_msg) ;
		$display("Pat num         = %d, Data No       = %d", i_pat[29:0], input_data_no) ;
		case (input_action)
			Update : begin
				$display("Action is Update") ;
				$display("Fix_index[0] is =%d", Fixed_index[0]);
				$display("Fix_index[1] is =%d", Fixed_index[1]);
				$display("Fix_index[2] is =%d", Fixed_index[2]);
				$display("Fix_index[3] is =%d", Fixed_index[3]);
			end
			Check_Valid_Date : begin
				$display("Action is Check_Valid_Date") ;
				case (input_formula_type)
					Formula_A: $display("Formula is Formula_A") ;
					Formula_B: $display("Formula is Formula_B") ;
					Formula_C: $display("Formula is Formula_C") ;
					Formula_D: $display("Formula is Formula_D") ;
					Formula_E: $display("Formula is Formula_E") ;
					Formula_F: $display("Formula is Formula_F") ;
					Formula_G: $display("Formula is Formula_G") ;
					Formula_H: $display("Formula is Formula_H") ;
					default:;
				endcase
			end
			Index_Check : begin
				$display("Action is Index_Check") ;
			end
			default: ;
		endcase
		$finish ;
	end
end endtask

task pass_task ; begin
    $display("==========================================================================") ;
	$display("                            Congratulations                               ") ;
    $display("==========================================================================") ;
end endtask

endprogram