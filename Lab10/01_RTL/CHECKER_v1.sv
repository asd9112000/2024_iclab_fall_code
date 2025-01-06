/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2023 Autumn IC Design Laboratory
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: Nov-2023)
Author : Jui-Huang Tsai (erictsai.10@nycu.edu.tw)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

// integer fp_w;

// initial begin
// fp_w = $fopen("out_valid.txt", "w");
// end

/**
 * This section contains the definition of the class and the instantiation of the object.
 *  *
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */





class Formula_and_Mode;
    Formula_Type formula_type;
    Mode mode;
endclass

Formula_and_Mode formula_and_mode_info = new() ;

always_ff @(posedge clk) begin
	// $display ("%d", bev_info.bev_type) ;
    if (inf.formula_valid) begin
        formula_and_mode_info.formula_type = inf.D.d_formula[0] ;
    end
end

always_ff @(posedge clk) begin
    if (inf.mode_valid) begin
        formula_and_mode_info.mode = inf.D.d_mode[0];
    end
end

/*
1. Each case of Formula_Type should be select at least 150 times.
*/

covergroup Spec1 @(posedge clk iff(inf.formula_valid));
    option.per_instance = 1;
    option.at_least = 150;
    bformula_type:coverpoint inf.D.d_formula[0] {
        bins b_formula_type [] = {[Formula_A:Formula_H]};
    }
endgroup

Spec1 spec1_inst = new() ;

/*
2.	Each case of Mode should be select at least 150 times.
*/

covergroup Spec2 @(posedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 150;
    bmode : coverpoint inf.D.d_mode[0] {
        bins b_mode [] = {[Insensitive:Sensitive]};
    }
endgroup

Spec2 spec2_inst = new() ;



/*
3.	Create a cross bin for the SPEC1 and SPEC2. Each combination should be selected at least 150 times. (Formula_A,B,C,D,E,F,G,H) x (Insensitive, Normal, Sensitive)
	Total = 8*3*150 = 3600
*/

covergroup Spec3 @(negedge clk iff(inf.mode_valid));
    option.per_instance = 1;
    option.at_least = 150;
	cross formula_and_mode_info.mode, formula_and_mode_info.formula_type ;
endgroup

Spec3 spec3_inst = new() ;


/*
4. Output signal inf.warn_msg should be “No_Warn”, “Date_Warn”, “Data_Warn“,”Risk_Warn, each at least 50 times. (Sample the value when inf.out_valid is high)
*/

covergroup Spec4 @(negedge clk iff(inf.out_valid));
    option.per_instance = 1;
    option.at_least = 50;
	out : coverpoint inf.warn_msg {
		bins b_warn_msg [] = {[No_Warn:Data_Warn]} ;
	}
endgroup

Spec4 spec4_inst = new() ;

/*
5.	Create the transitions bin for the inf.D.act[0] signal from [Index_Check:Check_Valid_Date] to [Index_Check:Check_Valid_Date].
Each transition should be hit at least 300 times. (sample the value at posedge clk iff inf.sel_action_valid)
*/

covergroup Spec5 @(posedge clk iff(inf.sel_action_valid));
    option.per_instance = 1 ;
    option.at_least = 300 ;
	act : coverpoint inf.D.d_act[0] {
		bins a_act [] = ([Index_Check:Check_Valid_Date] => [Index_Check:Check_Valid_Date]) ;
	}
endgroup

Spec5 spec5_inst = new() ;

/*
6.	Create a covergroup for material of supply action with auto_bin_max = 32, and each bin have to hit at least one time.
Create a covergroup for variation of Update action with auto_bin_max = 32, and each bin have to hit at least one time.
*/

covergroup Spec6 @(posedge clk iff(inf.index_valid));
    option.per_instance = 1 ;
    option.at_least = 1 ;
	input_ing : coverpoint inf.D.d_index[0] {
		option.auto_bin_max = 32 ;
	}
endgroup


// covergroup Spec6 @(posedge clk iff(inf.box_sup_valid));
//     option.per_instance = 1 ;
//     option.at_least = 1 ;
// 	input_ing : coverpoint inf.D.d_ing[0] {
// 		option.auto_bin_max = 32 ;
// 	}
// endgroup


Spec6 spec6_inst = new() ;

/*
    Create instances of Spec1, Spec2, Spec3, Spec4, Spec5, and Spec6
*/
// Spec1_2_3 cov_inst_1_2_3 = new();

/*
    Asseration
*/

/*
    If you need, you can declare some FSM, logic, flag, and etc. here.
*/















Action store_action ;
logic last_invalid ;
logic store_cinvalid ;
logic [2:0] count ;

always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
		count = 0 ;
	end
	else begin
		if (inf.index_valid) count = count + 1 ;
		else if (count == 4) count = 0 ;
	end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) store_action = Index_Check ;
	else begin
		if (inf.sel_action_valid)
			store_action = inf.D.d_act[0] ;
	end
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) last_invalid = 0 ;
	else begin
		case (store_action)
			Index_Check : begin
				if (inf.data_no_valid) last_invalid = 1 ;
				else last_invalid = 0 ;
			end
			Update : begin
				if (count == 4) last_invalid = 1 ;
				else last_invalid = 0 ;
			end
			Check_Valid_Date : begin
				if (inf.data_no_valid) last_invalid = 1 ;
				else last_invalid = 0 ;
			end
		endcase
	end
end

// always_ff @ (posedge clk or negedge inf.rst_n) begin
// 	if (!inf.rst_n) store_cinvalid = 0 ;
// 	else begin
// 		if (inf.C_in_valid) store_cinvalid = 1 ;
// 		else if (inf.C_out_valid) store_cinvalid = 0 ;
// 	end
// end



    // modport Program_inf(
    //     input rst_n, sel_action_valid, formula_valid, mode_valid, date_valid, data_no_valid, index_valid, D,
    //         AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    //     output out_valid, warn_msg, complete,
    //         AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY
    // );


/*
    1. All outputs signals (including BEV.sv and bridge.sv) should be zero after reset.
*/

always @ (negedge inf.rst_n) begin
	#(5) ;
	Assertion1 : assert (inf.out_valid === 0 && inf.warn_msg === 0 && inf.complete === 0 &&
						//    inf.C_addr === 0 && inf.C_data_w === 0 && inf.C_in_valid === 0 && inf.C_r_wb === 0 &&
						//    inf.C_out_valid === 0 && inf.C_data_r === 0 &&
                           inf.AR_VALID === 0 && inf.AR_ADDR === 0 &&
						   inf.R_READY === 0 && inf.AW_VALID === 0 && inf.AW_ADDR === 0 && inf.W_VALID === 0 &&
						   inf.W_DATA === 0 && inf.B_READY === 0)
				else begin
					$display("==========================================================================") ;
					$display("                       Assertion 1 is violated                            ") ;
					$display("==========================================================================") ;
					$fatal ;
				end
end

/*
    2.	Latency should be less than 1000 cycles for each operation.
*/
always @ (posedge clk)
	Assertion2 : assert property (p_last_invalid)
				 else begin
					$display("==========================================================================") ;
					$display("                       Assertion 2 is violated                            ") ;
					$display("==========================================================================") ;
					$fatal ;
				 end

property p_last_invalid ;
	@ (posedge clk) last_invalid |-> (##[1:1000] inf.out_valid) ;
endproperty : p_last_invalid

/*
    3. If out_valid does not pull up, complete should be 0.
    If action is completed (complete=1), warn_msg should be 2’b0 (No_Warn).
*/

always @ (negedge clk)
	Assertion3 : assert property (p_complete)
				 else begin
					$display("==========================================================================") ;
					$display("                      Assertion 3 is violated                             ") ;
					$display("==========================================================================") ;
					$fatal ;
				 end

property p_complete ;
	@ (negedge clk) inf.complete |-> (inf.warn_msg == No_Warn) ;
endproperty : p_complete

/*
    4. Next input valid will be valid 1-4 cycles after previous input valid fall.
*/



    // modport Program_inf(
    //     input rst_n, sel_action_valid, formula_valid, mode_valid, date_valid, data_no_valid, index_valid, D,
    //         AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
    //     output out_valid, warn_msg, complete,
    //         AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY
    // );
always @ (posedge clk) begin

	if (inf.sel_action_valid) begin
		Asseration4 : assert property (p_begin)
				  else begin
					$display("==========================================================================") ;
					$display("                       Assertion 4 is violated                            ") ;
					$display("==========================================================================") ;
					$fatal ;
				  end
	end
	else if (store_action == Index_Check) begin
		Assertion4_Index_Check : assert property (p_index_check)
					 else begin
						$display("==========================================================================") ;
						$display("                       Assertion 4 is violated                            ") ;
						$display("==========================================================================") ;
						$fatal ;
					 end
	end
	else if (store_action == Update) begin
		Assertion4_Update : assert property (p_update)
					 else begin
						$display("==========================================================================") ;
						$display("                       Assertion 4 is violated                            ") ;
						$display("==========================================================================") ;
						$fatal ;
					 end
	end
	else if (store_action == Check_Valid_Date) begin
		Assertion4_CVD : assert property (p_check_date)
					 else begin
						$display("==========================================================================") ;
						$display("                       Assertion 4 is violated                            ") ;
						$display("==========================================================================") ;
						$fatal ;
					 end
	end
end

property p_begin ;
	@ (posedge clk) inf.sel_action_valid |-> (##[1:4] (inf.formula_valid | inf.date_valid)) ;
endproperty : p_begin

property p_index_check ;
	@ (posedge clk) inf.formula_valid |-> (##[1:4] inf.mode_valid ##[1:4] inf.date_valid ##[1:4] inf.data_no_valid  ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid) ;   /////!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
endproperty : p_index_check

property p_update ;
	@ (posedge clk) inf.date_valid |-> ( ##[1:4] inf.data_no_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid ##[1:4] inf.index_valid) ;////!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
endproperty : p_update

property p_check_date ;
	@ (posedge clk) inf.date_valid |-> (##[1:4] inf.data_no_valid) ;
endproperty : p_check_date

/*
    5. All input valid signals won't overlap with each other.
*/

always @ (posedge clk) begin
	Asseration_action_overlap : assert property (p_action_overlap)
							else begin
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_formula_overlap   : assert property (p_formula_overlap)
							else begin
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_mode_overlap   : assert property (p_mode_overlap)
							else begin
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_date_overlap   : assert property (p_date_overlap)
							else begin
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_data_no_overlap  : assert property (p_data_no_overlap)
							else begin
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
	Asseration_index_overlap : assert property (p_index_overlap)
							else begin
								$display("==========================================================================") ;
								$display("                        Assertion 5 is violated                           ") ;
								$display("==========================================================================") ;
							    $fatal ;
							end
end

property p_action_overlap ;
	@ (posedge clk) inf.sel_action_valid |-> ((inf.formula_valid | inf.mode_valid | inf.date_valid | inf.data_no_valid | inf.index_valid) == 0) ;
endproperty : p_action_overlap

property p_formula_overlap ;
	@ (posedge clk) inf.formula_valid |-> ((inf.sel_action_valid | inf.mode_valid | inf.date_valid | inf.data_no_valid | inf.index_valid) == 0) ;
endproperty : p_formula_overlap

property p_mode_overlap ;
	@ (posedge clk) inf.mode_valid |-> ((inf.sel_action_valid | inf.formula_valid | inf.date_valid | inf.data_no_valid | inf.index_valid) == 0) ;
endproperty : p_mode_overlap

property p_date_overlap ;
	@ (posedge clk) inf.date_valid |-> ((inf.sel_action_valid | inf.formula_valid | inf.mode_valid | inf.data_no_valid | inf.index_valid) == 0) ;
endproperty : p_date_overlap

property p_data_no_overlap ;
	@ (posedge clk) inf.data_no_valid |-> ((inf.sel_action_valid | inf.formula_valid | inf.mode_valid | inf.date_valid | inf.index_valid) == 0) ;
endproperty : p_data_no_overlap

property p_index_overlap ;
	@ (posedge clk) inf.index_valid |-> ((inf.sel_action_valid | inf.formula_valid | inf.mode_valid | inf.date_valid | inf.data_no_valid) == 0) ;
endproperty : p_index_overlap

/*
    6. Out_valid can only be high for exactly one cycle.
*/

always @ (posedge clk)
	Asseration_outvalid : assert property (p_outvalid)
						else begin
							$display("==========================================================================") ;
							$display("                        Assertion 6 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end

property p_outvalid ;
	@ (posedge clk) inf.out_valid |-> (##1 (inf.out_valid == 0)) ;
endproperty : p_outvalid

/*
    7. Next operation will be valid 1-4 cycles after out_valid fall.
*/

always @ (posedge clk)
	Asseration_gap : assert property (p_gap)
						else begin
							$display("==========================================================================") ;
							$display("                        Assertion 7 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end

property p_gap ;
	@ (posedge clk) inf.out_valid |-> (##[1:4] inf.sel_action_valid) ;
endproperty : p_gap

/*
    8. The input date from pattern should adhere to the real calendar. (ex: 2/29, 3/0, 4/31, 13/1 are illegal cases)
*/

always @ (posedge clk) begin
	Asseration_check_month : assert property (p_check_month)
						else begin
							$display("==========================================================================") ;
							$display("                        Assertion 8 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end

	Asseration_big_month : assert property (p_big_month)
						else begin
							$display("==========================================================================") ;
							$display("                        Assertion 8 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
	Asseration_small_month : assert property (p_small_month)
						else begin
							$display("==========================================================================") ;
							$display("                        Assertion 8 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
	Asseration_february : assert property (p_February)
						else begin
							$display("==========================================================================") ;
							$display("                        Assertion 8 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
end

property p_check_month ;
	@ (posedge clk) inf.date_valid |-> (inf.D.d_date[0].M <= 12 && inf.D.d_date[0].M >= 1) ;
endproperty : p_check_month ;

property p_big_month ;
	@ (posedge clk) (inf.date_valid && (inf.D.d_date[0].M == 1 | inf.D.d_date[0].M == 3 |inf.D.d_date[0].M == 5 |inf.D.d_date[0].M == 7 |inf.D.d_date[0].M == 8 |inf.D.d_date[0].M == 10 | inf.D.d_date[0].M == 12)) |-> (inf.D.d_date[0].D <= 31 && inf.D.d_date[0].D >= 1) ;
endproperty : p_big_month

property p_small_month ;
	@ (posedge clk) (inf.date_valid && (inf.D.d_date[0].M == 4 | inf.D.d_date[0].M == 6 |inf.D.d_date[0].M == 9 |inf.D.d_date[0].M == 11)) |-> (inf.D.d_date[0].D <= 30 && inf.D.d_date[0].D >= 1) ;
endproperty : p_small_month

property p_February ;
	@ (posedge clk) (inf.date_valid && (inf.D.d_date[0].M == 2)) |-> (inf.D.d_date[0].D <= 28 && inf.D.d_date[0].D >= 1) ;
endproperty : p_February

/*
    9. The AR_VALID signal should not overlap with the AW_VALID signal.
*/




always @ (posedge clk) begin
	Asseration_ARV_AWV : assert property (p_ARV_AWV)
						else begin
							$display("==========================================================================") ;
							$display("                        Assertion 9 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
	Asseration_AWV_ARV : assert property (p_AWV_ARV)
						else begin
							$display("==========================================================================") ;
							$display("                        Assertion 9 is violated                           ") ;
							$display("==========================================================================") ;
						    $fatal ;
						end
end




property p_ARV_AWV ;
	@ (posedge clk) inf.AR_VALID |-> (inf.AW_VALID == 0) ;
    // @ (posedge clk) inf.AW_VALID |-> (inf.AR_VALID == 0) ;
endproperty : p_ARV_AWV

property p_AWV_ARV ;
	// @ (posedge clk) inf.AR_VALID |-> (inf.AW_VALID == 0) ;
    @ (posedge clk) inf.AW_VALID |-> (inf.AR_VALID == 0) ;
endproperty : p_AWV_ARV


// Congratulations
// Wrong Answer
// Assertion 1 is violated
// Assertion 2 is violated
// Assertion 3 is violated
// Assertion 4 is violated
// Assertion 5 is violated
// Assertion 6 is violated
// Assertion 7 is violated
// Assertion 8 is violated
// Assertion 9 is violated
// Assertion 10 is violated



endmodule








