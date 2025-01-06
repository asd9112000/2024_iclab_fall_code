module Program(input clk, INF.Program_inf inf);
import usertype::*;

        // input rst_n, sel_action_valid, formula_valid, mode_valid, date_valid, data_no_valid, index_valid, D,
        //     AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
        // output out_valid, warn_msg, complete,
        //     AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY


parameter  IDLE                     = 3'd0;
parameter  INDEX_CHECK_INPUT              = 3'd1;
parameter  UPDATE_INPUT             = 3'd2;
parameter  CHECK_VALID_DATE_INPUT   = 3'd3;
parameter  INDEX_CHECK                    = 3'd4;
parameter  UPDATE                   = 3'd5;
parameter  CHECK_VALID_DATE         = 3'd6;

integer i, j, k, m ,n;
genvar  a, b, c, d ,e;


logic [1:0 ] Action_reg;







//============================================================
//
//                        Declaration
//
//============================================================




//  Dram Declaration
logic [11:0]Dram_Index_A, Dram_Index_B, Dram_Index_C, Dram_Index_D;
logic [12:0] E_Dram_Index_A, E_Dram_Index_B, E_Dram_Index_C, E_Dram_Index_D;
logic signed [12:0] SE_Dram_Index_A, SE_Dram_Index_B, SE_Dram_Index_C, SE_Dram_Index_D;
logic [12:0]Fixed_index[0:3]; // A, B, C, D = 0, 1, 2, 3
logic [4:0]Dram_Date;
logic [3:0]Dram_Month;


//  INPUT REGISTERS Declaration
logic [2:0 ] Formula_reg;
logic [1:0 ] Mode_reg;
logic [8:0 ] Date_reg;
logic [3:0 ] Month_reg;
logic [4:0 ] Day_reg;
logic [7:0 ] Data_No_reg;
logic signed [11:0] Input_Index_reg [0:3];
logic [11:0] uInput_Index_reg [0:3];
assign {Month_reg, Day_reg} = Date_reg;


//============================================================
//
//                          END　SIGNAL
//
//============================================================



logic  PAT_END;


logic  INDEX_CHECK_INPUT_END;
logic  UPDATE_INPUT_END;
logic  CHECK_VALID_DATE_INPUT_END;

logic  INDEX_CHECK_END ;
logic  UPDATE_END ;
logic  CHECK_VALID_DATE_END ;

logic [7:0] Index_Check_end;

logic sel_action_valid_delay;
logic formula_valid_delay;
logic mode_valid_delay;
logic date_valid_delay;
logic data_no_valid_delay;
logic index_valid_delay;


always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        sel_action_valid_delay <= 'd0;
        formula_valid_delay <= 'd0;
        mode_valid_delay <= 'd0;
        date_valid_delay <= 'd0;
        data_no_valid_delay <= 'd0;
        index_valid_delay <= 'd0;
    end
    else begin
        sel_action_valid_delay <= inf.sel_action_valid;
        formula_valid_delay <= inf.formula_valid;
        mode_valid_delay <= inf.mode_valid;
        date_valid_delay <= inf.date_valid;
        data_no_valid_delay <= inf.data_no_valid;
        index_valid_delay <= inf.index_valid;
    end
end




//============================================================
//
//                          FSM
//
//============================================================
logic [2:0] cs, ns;
logic [7:0] cnt256;
logic [3:0] cnt16_valid;
logic [1:0] cnt4_Index_reg;
logic R_DRAM_OK;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        cs <= IDLE;
    else
        cs <= ns;
end

always_comb  begin
    case ( cs)
        IDLE                    : ns =   ( ! inf.data_no_valid)      ? IDLE
                                        :(Action_reg == Index_Check) ? INDEX_CHECK_INPUT
                                        :(Action_reg == Update)      ? UPDATE_INPUT : CHECK_VALID_DATE_INPUT;

        INDEX_CHECK_INPUT       : ns = ( INDEX_CHECK_INPUT_END )    ? INDEX_CHECK             : INDEX_CHECK_INPUT;
        UPDATE_INPUT            : ns = ( UPDATE_INPUT_END )         ? UPDATE            : UPDATE_INPUT;
        CHECK_VALID_DATE_INPUT  : ns = (CHECK_VALID_DATE_INPUT_END )? IDLE  : CHECK_VALID_DATE_INPUT;

        // INDEX_CHECK                   : ns = (CHECK_END)  ? IDLE : INDEX_CHECK ;
        INDEX_CHECK             : ns = (INDEX_CHECK_END)    ? IDLE : INDEX_CHECK ;
        UPDATE                  : ns = (UPDATE_END)         ? IDLE : UPDATE;
        // CHECK_VALID_DATE        : ns = (CHECK_VALID_DATE_END) ? IDLE : CHECK_VALID_DATE;
        default: ns = IDLE;
    endcase
end


always_comb begin
    PAT_END = UPDATE_END || CHECK_VALID_DATE_INPUT_END || INDEX_CHECK_END;
end

always_comb begin
    INDEX_CHECK_INPUT_END       = R_DRAM_OK && cnt16_valid == 'd9 && cs == INDEX_CHECK_INPUT;
    UPDATE_INPUT_END            = R_DRAM_OK && cnt16_valid == 'd7 && cs == UPDATE_INPUT;
    CHECK_VALID_DATE_INPUT_END  = R_DRAM_OK && cnt16_valid == 'd3 && cs == CHECK_VALID_DATE_INPUT;

    INDEX_CHECK_END = (Index_Check_end [0] || Index_Check_end[1] || Index_Check_end[2] || Index_Check_end[3] ||  Index_Check_end[4] || Index_Check_end[5]|| Index_Check_end[6] ||  Index_Check_end[7]) && cs == INDEX_CHECK;
    UPDATE_END = inf.B_READY && inf.B_VALID && cs == UPDATE;
    // CHECK_VALID_DATE_END =  cs == CHECK_VALID_DATE ;
end

always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)
        R_DRAM_OK <= 'd0;
    else if ( PAT_END)
        R_DRAM_OK <= 'd0;
    else if (inf.R_VALID)
        R_DRAM_OK <= 'd1;
end

//============================================================
//
//                          CNT
//
//============================================================



always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)
        cnt256 <= 'd0;
    else
        cnt256 <=  cnt256 + 1;
end


always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)
        cnt16_valid <= 'd0;
    else if ( PAT_END)
        cnt16_valid <= 'd0;
    else if (
        inf.sel_action_valid ||
        inf.formula_valid    ||
        inf.mode_valid       ||
        inf.date_valid       ||
        inf.data_no_valid    ||
        inf.index_valid  )
        cnt16_valid <= cnt16_valid + 'd1;
end


logic [10:0] pat_cnt;
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)
        pat_cnt <= 'd0;
    else if ( inf.out_valid)
        pat_cnt <= pat_cnt +1;
end



//============================================================
//
//                    INPUT REGISTERS
//
//============================================================



        //   sel_action_valid, formula_valid, mode_valid, date_valid, data_no_valid, index_valid
        //   , D,
        //     AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,

always_ff @( posedge clk or negedge inf.rst_n ) begin : Action_reg_block
    if (!inf.rst_n)
        Action_reg <= 'd0;
    else if (inf.sel_action_valid)
        Action_reg <=  inf.D.d_act[0];
end

always_ff @( posedge clk or negedge inf.rst_n ) begin : Formula_reg_block
    if (!inf.rst_n)
        Formula_reg <= 'd0;
    else if (inf.formula_valid)
        Formula_reg <=  inf.D.d_formula;
end

always_ff @( posedge clk or negedge inf.rst_n ) begin : Mode_reg_block
    if (!inf.rst_n)
        Mode_reg <= 'd0;
    else if (inf.mode_valid)
        Mode_reg <=  inf.D.d_mode;
end

always_ff @( posedge clk or negedge inf.rst_n ) begin : Date_reg_block
    if (!inf.rst_n)
        Date_reg <= 'd0;
    else if (inf.date_valid)
        Date_reg <=  inf.D.d_date;
end

always_ff @( posedge clk or negedge inf.rst_n ) begin : Data_No_reg_block
    if (!inf.rst_n)
        Data_No_reg <= 'd0;
    else if (inf.data_no_valid)
        Data_No_reg <=  inf.D.d_data_no;
end

always_ff @( posedge clk or negedge inf.rst_n ) begin : Index_reg_block
    if (!inf.rst_n)
        for (j = 0; j < 4; j = j+1)
            Input_Index_reg [j]<= 'd0;
    else if (inf.index_valid)
        Input_Index_reg [ cnt4_Index_reg]<=  inf.D.d_index;
end

always_comb begin
    for (k = 0; k < 4; k = k+1)
        uInput_Index_reg[k] = Input_Index_reg[k];
end
// generate
// for (a = 0; a < 4; a = a+1)
//     assign uInput_Index_reg[j] = Input_Index_reg[j];
// endgenerate

always_ff @( posedge clk or negedge inf.rst_n ) begin : cnt4_Index_reg_block
    if (!inf.rst_n)
        cnt4_Index_reg <= 'd0;
    else if (PAT_END)
        cnt4_Index_reg <= 'd0;
    else if (inf.index_valid)
        cnt4_Index_reg <=  cnt4_Index_reg + 1;
end


//============================================================
//
//                    WARNING CHECK
//
//============================================================
logic [1:0] warn_reg;
always_ff @( posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n)
        warn_reg <= 'd0;
    else if ( PAT_END)
        warn_reg <= 'd0;
    else if ( cs == UPDATE_INPUT && cs != ns)
        warn_reg <=  (Fixed_index[0][12] || Fixed_index[1][12] || Fixed_index[2][12] || Fixed_index[3][12]) ? Data_Warn : No_Warn;
end








// +==============================================================================================+
// |                                                                                              |
// |  __  .__   __.  _______   __________   ___      ______  __    __   _______   ______  __  ___ |
// | |  | |  \ |  | |       \ |   ____\  \ /  /     /      ||  |  |  | |   ____| /      ||  |/  / |
// | |  | |   \|  | |  .--.  ||  |__   \  V  /     |  ,----'|  |__|  | |  |__   |  ,----'|  '  /  |
// | |  | |  . `  | |  |  |  ||   __|   >   <      |  |     |   __   | |   __|  |  |     |    <   |
// | |  | |  |\   | |  '--'  ||  |____ /  .  \     |  `----.|  |  |  | |  |____ |  `----.|  .  \  |
// | |__| |__| \__| |_______/ |_______/__/ \__\     \______||__|  |__| |_______| \______||__|\__\ |
// |                                                                                              |
// +==============================================================================================+
// Index check



logic [3:0] cnt16_index_check;
always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        cnt16_index_check <= 'd0;
    else if ( PAT_END)
        cnt16_index_check <= 'd0;
    else if ( cs == INDEX_CHECK )
        cnt16_index_check <= cnt16_index_check + 1;
end

always_comb begin
    Index_Check_end[0] = cs == INDEX_CHECK && Formula_reg == Formula_A;
    Index_Check_end[1] = cs == INDEX_CHECK && Formula_reg == Formula_B && cnt16_index_check == 'd4;
    Index_Check_end[2] = cs == INDEX_CHECK && Formula_reg == Formula_C && cnt16_index_check == 'd4;
    Index_Check_end[3] = cs == INDEX_CHECK && Formula_reg == Formula_D;
    Index_Check_end[4] = cs == INDEX_CHECK && Formula_reg == Formula_E && cnt16_index_check == 'd3;

    Index_Check_end[5] = cs == INDEX_CHECK && Formula_reg == Formula_F && cnt16_index_check == 'd6;
    Index_Check_end[6] = cs == INDEX_CHECK && Formula_reg == Formula_G && cnt16_index_check == 'd6;
    Index_Check_end[7] = cs == INDEX_CHECK && Formula_reg == Formula_H && cnt16_index_check == 'd3;
end



//============================================================
//
//                      Sorting
//
//============================================================
logic en_soting, en_soting_delay, en_soting_delay2;
logic [11:0] sorting_inA, sorting_inB, sorting_inC, sorting_inD;
logic [11:0] Big1, Small1, Big2, Small2, Max, Min, MiddleB, MiddleS;
logic sorting_inA_Beq_sorting_inB, sorting_inC_Beq_sorting_inD;

assign sorting_inA_Beq_sorting_inB = (sorting_inA >= sorting_inB);
assign sorting_inC_Beq_sorting_inD = (sorting_inC >= sorting_inD);
assign {Big1, Small1} = ( sorting_inA_Beq_sorting_inB ) ? {sorting_inA, sorting_inB} : {sorting_inB, sorting_inA};
assign {Big2, Small2} = ( sorting_inC_Beq_sorting_inD ) ? {sorting_inC, sorting_inD} : {sorting_inD, sorting_inC};

// assign en_soting =  cs == INDEX_CHECK && cnt16_index_check == 'd0;

assign en_soting =  ( cs == INDEX_CHECK && cnt16_index_check == 'd0 && (Formula_reg == Formula_B || Formula_reg == Formula_C || Formula_reg == Formula_E)) ||
                    ( cs == INDEX_CHECK && cnt16_index_check == 'd2 && (Formula_reg == Formula_F || Formula_reg == Formula_G));


// sorting_inA, sorting_inB, sorting_inC, sorting_inD
always_comb begin
case (Formula_reg)
    Formula_B, Formula_C:  if (en_soting_delay2) begin
        sorting_inA = MiddleB;
        sorting_inB = MiddleS;
        sorting_inC = Min;
        sorting_inD = MiddleB;
    end
    else if (en_soting_delay) begin
        sorting_inA = Max;
        sorting_inB = MiddleS;
        sorting_inC = Min;
        sorting_inD = MiddleB;
    end
    else  begin
        sorting_inA = Dram_Index_A;
        sorting_inB = Dram_Index_B;
        sorting_inC = Dram_Index_C;
        sorting_inD = Dram_Index_D;
    end

    Formula_E:  if (en_soting_delay2) begin
        sorting_inA = MiddleB;
        sorting_inB = MiddleS;
        sorting_inC = Min;
        sorting_inD = MiddleB;
    end
    else if (en_soting_delay) begin
        sorting_inA = Dram_Index_C;
        sorting_inB = Input_Index_reg[2];
        sorting_inC = Dram_Index_D;
        sorting_inD = Input_Index_reg[3];
    end
    else  begin
        sorting_inA = Dram_Index_A;
        sorting_inB = Input_Index_reg[0];
        sorting_inC = Dram_Index_B;
        sorting_inD = Input_Index_reg[1];
    end

    Formula_F, Formula_G:  if (en_soting_delay2) begin // need all step
        sorting_inA = MiddleB;
        sorting_inB = MiddleS;
        sorting_inC = Min;
        sorting_inD = MiddleB;
    end
    else if (en_soting_delay) begin
        sorting_inA = Max;
        sorting_inB = MiddleS;
        sorting_inC = Min;
        sorting_inD = MiddleB;
    end
    else  begin
        sorting_inA = Dram_Index_A;
        sorting_inB = Dram_Index_B;
        sorting_inC = Dram_Index_C;
        sorting_inD = Dram_Index_D;
    end


    default:begin
        sorting_inA = Dram_Index_A;
        sorting_inB = Dram_Index_B;
        sorting_inC = Dram_Index_C;
        sorting_inD = Dram_Index_D;
    end
endcase
end

// en_soting_delay
always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        en_soting_delay <= 'd0;
        en_soting_delay2 <= 'd0;
    end
    else begin
        en_soting_delay <= en_soting;
        en_soting_delay2 <= en_soting_delay;
    end
end

// soting
always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        Max <= 'd0;
        Min <= 'd0;
        MiddleB <= 'd0;
        MiddleS <= 'd0;
    end
    else if (en_soting_delay2) begin
        MiddleB <= Big1;
        MiddleS <= Small1;
    end
    else if (en_soting_delay) begin
        Max <= Big1 ;
        MiddleB <= Small1;
        MiddleS <= Big2;
        Min <= Small2;
    end
    else if (en_soting) begin
        Max <= Big1 ;
        MiddleB <= Small1;
        MiddleS <= Big2;
        Min <= Small2;
    end
end



//============================================================
//
//                      Index_Check_temp
//
//============================================================

logic [13:0] Index_Check_temp[3:0];

logic [10:0] Formula_Threshold_Table [2:0] ; // Insensitive , Normal, Sensitive = mode ( 00, 01, 11)
logic [10:0] Mode_Threshold;
// Threshold Table
always_comb begin
    case (Formula_reg)
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
end
always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        Mode_Threshold <= 'd0;
    else
        case (Mode_reg)
            0: Mode_Threshold <= Formula_Threshold_Table[0];
            1: Mode_Threshold <= Formula_Threshold_Table[1];
            3: Mode_Threshold <= Formula_Threshold_Table[2];
            default: ;
        endcase
end



//============================================================
//
//                      Index_Check_add
//
//============================================================
logic [11:0] Index_Check_add_in1[3:0];
logic [12:0] Index_Check_add1 [1:0];
logic [13:0] Index_Check_add ;

always_comb begin
    Index_Check_add1[0] = Index_Check_add_in1[0] + Index_Check_add_in1[1];
    Index_Check_add1[1] = Index_Check_add_in1[2] + Index_Check_add_in1[3];
    Index_Check_add = Index_Check_add1[1] + Index_Check_add1[0];
end

// Index_Check_add_in1
always_comb begin
    case (Formula_reg)
        Formula_A, Formula_H:  begin
            Index_Check_add_in1[0] = Dram_Index_A;
            Index_Check_add_in1[1] = Dram_Index_B;
            Index_Check_add_in1[2] = Dram_Index_C;
            Index_Check_add_in1[3] = Dram_Index_D;
        end
        Formula_F:  begin
            Index_Check_add_in1[0] = 'd0;
            Index_Check_add_in1[1] = MiddleB;
            Index_Check_add_in1[2] = MiddleS;
            Index_Check_add_in1[3] = Min;
        end
        Formula_G:  begin
            Index_Check_add_in1[0] = 'd0;
            Index_Check_add_in1[1] = MiddleB >> 2;
            Index_Check_add_in1[2] = MiddleS >> 2;
            Index_Check_add_in1[3] = Min >>1 ;
        end
        default:begin
            Index_Check_add_in1[0] = 'd0;
            Index_Check_add_in1[1] = 'd0;
            Index_Check_add_in1[2] = 'd0;
            Index_Check_add_in1[3] = 'd0;
        end
    endcase
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        for ( i=0; i<4; i++)
            Index_Check_temp[i] <= 'd0;
    else if ( Formula_reg == Formula_A )
        Index_Check_temp[0] <= {2'b0, Index_Check_add[13:2] };
    else if (Formula_reg == Formula_F  && cnt16_index_check == 'd4 )
        Index_Check_temp[0] <= Index_Check_add;
    else if (Formula_reg == Formula_E  )
        if ( cnt16_index_check == 'd0)
            Index_Check_temp[0][1:0] <= {  sorting_inC_Beq_sorting_inD, sorting_inA_Beq_sorting_inB};
        else if ( cnt16_index_check == 'd1)
            Index_Check_temp[0][3:2] <= { sorting_inC_Beq_sorting_inD, sorting_inA_Beq_sorting_inB};

end

//============================================================
//
//                      Index_Check_sub1
//
//============================================================
// Index_Check_sub_in1
logic [11:0] Index_Check_sub_in1[3:0];
logic [11:0] Index_Check_sub1 [1:0];
always_comb begin
    case (Formula_reg)
        Formula_F, Formula_H, Formula_G:  begin
            if ( cnt16_index_check == 'd0 ) begin
                {Index_Check_sub_in1[0] , Index_Check_sub_in1[1] } = (Dram_Index_A >= Input_Index_reg[0]) ? {Dram_Index_A, Input_Index_reg[0]} : {Input_Index_reg[0], Dram_Index_A};
                {Index_Check_sub_in1[2] , Index_Check_sub_in1[3] } = (Dram_Index_B >= Input_Index_reg[1]) ? {Dram_Index_B, Input_Index_reg[1]} : {Input_Index_reg[1], Dram_Index_B};
            end
            else begin
                {Index_Check_sub_in1[0] , Index_Check_sub_in1[1] } = (Dram_Index_C >= Input_Index_reg[2]) ? {Dram_Index_C, Input_Index_reg[2]} : {Input_Index_reg[2], Dram_Index_C};
                {Index_Check_sub_in1[2] , Index_Check_sub_in1[3] } = (Dram_Index_D >= Input_Index_reg[3]) ? {Dram_Index_D, Input_Index_reg[3]} : {Input_Index_reg[3], Dram_Index_D};
            end
            end
        Formula_B : begin
            Index_Check_sub_in1[0] = Max ;
            Index_Check_sub_in1[1] = Min ;
            Index_Check_sub_in1[2] = 'd0 ;
            Index_Check_sub_in1[3] = 'd0 ;
        end
        default: begin
            Index_Check_sub_in1[0] = 'd0 ;
            Index_Check_sub_in1[1] = 'd0 ;
            Index_Check_sub_in1[2] = 'd0 ;
            Index_Check_sub_in1[3] = 'd0 ;
        end
    endcase
end
always_comb begin
    Index_Check_sub1[0] = Index_Check_sub_in1[0] - Index_Check_sub_in1[1];
    Index_Check_sub1[1] = Index_Check_sub_in1[2] - Index_Check_sub_in1[3];
end


//============================================================
//
//                      Result
//
//============================================================
logic [11:0] Result;
always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        Result <= 'd0;
    else if ( Formula_reg == Formula_A ) begin
        Result <= Index_Check_add[13:2] ;
    end
    else if (Formula_reg == Formula_B ) begin
        Result <= Index_Check_sub1[0] ;
    end
    else if (Formula_reg == Formula_C ) begin
        Result <= Min;
    end
    else if (Formula_reg == Formula_D ) begin
        // Result <= {8'd0, Dram_Index_A[11], Dram_Index_B[11], Dram_Index_C[11], Dram_Index_D[11] };
        case ({ Dram_Index_A[11] || (&Dram_Index_A[10:0]), Dram_Index_B[11]  || (&Dram_Index_B[10:0]), Dram_Index_C[11]  || (&Dram_Index_C[10:0]), Dram_Index_D[11] || (&Dram_Index_D[10:0]) })
            4'b0000: Result <= 11'd0;
            4'b0001: Result <= 11'd1;
            4'b0010: Result <= 11'd1;
            4'b0100: Result <= 11'd1;
            4'b1000: Result <= 11'd1;
            4'b0011: Result <= 11'd2;
            4'b0101: Result <= 11'd2;
            4'b1001: Result <= 11'd2;
            4'b0110: Result <= 11'd2;
            4'b1010: Result <= 11'd2;
            4'b1100: Result <= 11'd2;
            4'b0111: Result <= 11'd3;
            4'b1011: Result <= 11'd3;
            4'b1101: Result <= 11'd3;
            4'b1110: Result <= 11'd3;
            4'b1111: Result <= 11'd3;
            default: Result <= 11'd4;
        endcase
    end
        else if (Formula_reg == Formula_E ) begin
        // Result <= {8'd0, Dram_Index_A[11], Dram_Index_B[11], Dram_Index_C[11], Dram_Index_D[11] };
        case ({Index_Check_temp[0][3:0] })
            4'b0000: Result <= 11'd0;
            4'b0001: Result <= 11'd1;
            4'b0010: Result <= 11'd1;
            4'b0100: Result <= 11'd1;
            4'b1000: Result <= 11'd1;
            4'b0011: Result <= 11'd2;
            4'b0101: Result <= 11'd2;
            4'b1001: Result <= 11'd2;
            4'b0110: Result <= 11'd2;
            4'b1010: Result <= 11'd2;
            4'b1100: Result <= 11'd2;
            4'b0111: Result <= 11'd3;
            4'b1011: Result <= 11'd3;
            4'b1101: Result <= 11'd3;
            4'b1110: Result <= 11'd3;
            4'b1111: Result <= 11'd3;
            default: Result <= 11'd4;
        endcase
    end

    else if (Formula_reg == Formula_F  && cnt16_index_check == 'd5 )
        Result <= Index_Check_temp[0] / 3;
    else if (Formula_reg == Formula_G )
        Result <= Index_Check_add[11:0];
    else if (Formula_reg == Formula_H && cnt16_index_check == 'd2) begin
        Result <= Index_Check_add[13:2] ;
    end

end




// +==================================================================+
// |                                                                  |
// |  __    __  .______    _______       ___   .___________. _______  |
// | |  |  |  | |   _  \  |       \     /   \  |           ||   ____| |
// | |  |  |  | |  |_)  | |  .--.  |   /  ^  \ `---|  |----`|  |__    |
// | |  |  |  | |   ___/  |  |  |  |  /  /_\  \    |  |     |   __|   |
// | |  `--'  | |  |      |  '--'  | /  _____  \   |  |     |  |____  |
// |  \______/  | _|      |_______/ /__/     \__\  |__|     |_______| |
// |                                                                  |
// +==================================================================+
logic [0:3] MayOverflow;
logic [0:3] MayUnderflow;


always_comb begin
    Fixed_index[0] = E_Dram_Index_A + {Input_Index_reg[0][11], Input_Index_reg[0]};
    Fixed_index[1] = E_Dram_Index_B + {Input_Index_reg[1][11], Input_Index_reg[1]};
    Fixed_index[2] = E_Dram_Index_C + {Input_Index_reg[2][11], Input_Index_reg[2]};
    Fixed_index[3] = E_Dram_Index_D + {Input_Index_reg[3][11], Input_Index_reg[3]};
end

always_comb begin
    MayOverflow [0] =  Dram_Index_A[11] ;
    MayOverflow [1] =  Dram_Index_B[11] ;
    MayOverflow [2] =  Dram_Index_C[11] ;
    MayOverflow [3] =  Dram_Index_D[11] ;
    MayUnderflow[0] = ~Dram_Index_A[11] ;
    MayUnderflow[1] = ~Dram_Index_B[11] ;
    MayUnderflow[2] = ~Dram_Index_C[11] ;
    MayUnderflow[3] = ~Dram_Index_D[11] ;
end














// /============================================================================\
// ||                                                                          ||
// ||    ______    __    __  .___________..______    __    __  .___________.   ||
// ||   /  __  \  |  |  |  | |           ||   _  \  |  |  |  | |           |   ||
// ||  |  |  |  | |  |  |  | `---|  |----`|  |_)  | |  |  |  | `---|  |----`   ||
// ||  |  |  |  | |  |  |  |     |  |     |   ___/  |  |  |  |     |  |        ||
// ||  |  `--'  | |  `--'  |     |  |     |  |      |  `--'  |     |  |        ||
// ||   \______/   \______/      |__|     | _|       \______/      |__|        ||
// ||                                                                          ||
// \============================================================================/
// output
// logic ResultThreshold;
// assign ResultThreshold = Result >= Mode_Threshold;

always_ff @( posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.out_valid <= 'd0;
        inf.warn_msg  <= 'd0;
        inf.complete  <= 'd0;
    end
    else if ( UPDATE_END ) begin
        inf.out_valid <= 'd1;
        inf.warn_msg  <= warn_reg;
        inf.complete  <= (warn_reg == No_Warn ) ? 'd1 : 'd0;
    end
    else if ( CHECK_VALID_DATE_INPUT_END ) begin
    // else if ( CHECK_VALID_DATE_END ) begin
        inf.out_valid <= 'd1;
        inf.warn_msg  <=    (Month_reg < Dram_Month) ? Date_Warn :
                            (Month_reg == Dram_Month && Day_reg < Dram_Date ) ? Date_Warn : No_Warn;
        inf.complete  <=    (Month_reg < Dram_Month) ? 'd0 :
                            (Month_reg == Dram_Month && Day_reg < Dram_Date ) ? 'd0 : 'd1;
    end
    else if ( INDEX_CHECK_END ) begin
        inf.out_valid <= 'd1;
        if ( (Month_reg < Dram_Month) || ((Month_reg == Dram_Month) && (Day_reg < Dram_Date) ) ) begin
            inf.warn_msg  <= Date_Warn;
            inf.complete  <= 'd0;
        end
        else begin
                    inf.warn_msg  <= (Result >= Mode_Threshold) ? Risk_Warn : No_Warn;
                    inf.complete  <= (Result >= Mode_Threshold) ? 'd0 : 'd1;
            // case (Formula_reg)
            //     Formula_A: begin
            //         inf.warn_msg  <= (Result >= Mode_Threshold) ? Risk_Warn : No_Warn;
            //         inf.complete  <= (Result >= Mode_Threshold) ? 'd0 : 'd1;
            //     end

            //     Formula_D: begin
            //         inf.warn_msg  <= (Result >= Mode_Threshold) ? Risk_Warn : No_Warn;
            //         inf.complete  <= (Result >= Mode_Threshold) ? 'd0 : 'd1;
            //     end

            //     Formula_H: begin
            //         inf.warn_msg  <= (Result >= Mode_Threshold) ? Risk_Warn : No_Warn;
            //         inf.complete  <= (Result >= Mode_Threshold) ? 'd0 : 'd1;
            //     end
            //     default: ;
            // endcase
        end

    end
    else begin
        inf.out_valid <= 'd0;
        inf.warn_msg  <= 'd0;
        // inf.warn_msg  <= warn_reg;
        inf.complete  <= 'd0;
    end
end










// /====================================================\
// ||                                                  ||
// ||   _______  .______          ___      .___  ___.  ||
// ||  |       \ |   _  \        /   \     |   \/   |  ||
// ||  |  .--.  ||  |_)  |      /  ^  \    |  \  /  |  ||
// ||  |  |  |  ||      /      /  /_\  \   |  |\/|  |  ||
// ||  |  '--'  ||  |\  \----./  _____  \  |  |  |  |  ||
// ||  |_______/ | _| `._____/__/     \__\ |__|  |__|  ||
// ||                                                  ||
// \====================================================/

// modport DRAM(
//     input  AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY,
//     output AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP
// );



// ============================================================
//
//                      READ DRAM
//
// ============================================================


always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.AR_VALID <= 'd0;
    else if ( inf.AR_VALID  )
        inf.AR_VALID <= ~inf.AR_READY;
    else if ( data_no_valid_delay )
        inf.AR_VALID <= 'd1;
end


always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AR_ADDR <= 'd0;
    end
    else if (data_no_valid_delay )
        inf.AR_ADDR <= 17'b1_0000_0000_0000_0000 + Data_No_reg *8;
end

// Read Data
always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.R_READY <= 'd0;
    else if ( inf.R_READY  )
        inf.R_READY <= ~inf.R_VALID;
    else if (data_no_valid_delay)
        inf.R_READY <= 'd1;
end




always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        Dram_Index_A <= 'd0;
        Dram_Index_B <= 'd0;
        Dram_Index_C <= 'd0;
        Dram_Index_D <= 'd0;
        Dram_Month <= 'd0;
        Dram_Date <= 'd0;
    end
    else if (inf.R_VALID) begin
        Dram_Index_A <= inf.R_DATA[63:52];
        Dram_Index_B <= inf.R_DATA[51:40];
        Dram_Month   <= inf.R_DATA[35:32];
        Dram_Index_C <= inf.R_DATA[31:20];
        Dram_Index_D <= inf.R_DATA[19:8];
        Dram_Date    <= inf.R_DATA[4:0];
    end
    // else if (cs == INDEX_CHECK_INPUT && (Formula_reg == Formula_B || Formula_reg == Formula_F || Formula_reg == Formula_H )) begin
    else if (cs == INDEX_CHECK && (Formula_reg == Formula_B || Formula_reg == Formula_F || Formula_reg == Formula_G || Formula_reg == Formula_H )) begin
        // if (Formula_reg == Formula_B ) begin
            if  ( cnt16_index_check == 'd0 ) begin
                Dram_Index_A <= Index_Check_sub1[0];
                Dram_Index_B <= Index_Check_sub1[1];
            end
            else if ( cnt16_index_check == 'd1 )begin
                Dram_Index_C <= Index_Check_sub1[0];
                Dram_Index_D <= Index_Check_sub1[1];
            end
        // end
    end
end

always_comb begin
    SE_Dram_Index_A ={1'b0, Dram_Index_A};
    SE_Dram_Index_B ={1'b0, Dram_Index_B};
    SE_Dram_Index_C ={1'b0, Dram_Index_C};
    SE_Dram_Index_D ={1'b0, Dram_Index_D};
end
always_comb begin
    E_Dram_Index_A ={1'b0, Dram_Index_A};
    E_Dram_Index_B ={1'b0, Dram_Index_B};
    E_Dram_Index_C ={1'b0, Dram_Index_C};
    E_Dram_Index_D ={1'b0, Dram_Index_D};
end

//============================================================
//
//                      WRITE DRAM
//
//============================================================


always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.AW_VALID <= 'd0;
    else if ( inf.AW_VALID  )
        inf.AW_VALID <= ~inf.AW_READY;
    else if (cs == UPDATE_INPUT && cs != ns )
        inf.AW_VALID <= 'd1;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.AW_ADDR <= 'd0;
    else if  (cs == UPDATE_INPUT && cs != ns )begin   //   you may do this with read address
        inf.AW_ADDR <= 17'b1_0000_0000_0000_0000 + Data_No_reg *8;
    end
end



always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.W_VALID <= 'd0;
    else if ( inf.W_VALID  )
        inf.W_VALID <= ~inf.W_READY;
    else if ( cs == UPDATE_INPUT && cs != ns )
        inf.W_VALID <= 'd1;
end




always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.W_DATA <= 'd0;
    end
    else if ( cs == UPDATE_INPUT && cs != ns)begin
        inf.W_DATA[63:52]<= (MayOverflow [0] && Fixed_index[0][12]) ? 12'd4095 :
                            (MayUnderflow[0] && Fixed_index[0][12]) ? 12'd0    : Fixed_index[0][11:0] ;
        inf.W_DATA[51:40]<= (MayOverflow [1] && Fixed_index[1][12]) ? 12'd4095 :
                            (MayUnderflow[1] && Fixed_index[1][12]) ? 12'd0    : Fixed_index[1][11:0] ;
        inf.W_DATA[39:32]<= {4'd0, Month_reg};
        inf.W_DATA[31:20]<= (MayOverflow [2] && Fixed_index[2][12]) ? 12'd4095 :
                            (MayUnderflow[2] && Fixed_index[2][12]) ? 12'd0    : Fixed_index[2][11:0] ;
        inf.W_DATA[19:8 ]<= (MayOverflow [3] && Fixed_index[3][12]) ? 12'd4095 :
                            (MayUnderflow[3] && Fixed_index[3][12]) ? 12'd0    : Fixed_index[3][11:0] ;
        inf.W_DATA[7 :0 ]<= {3'd0, Day_reg} ;
    end
end


logic W_VALID_done;
logic AW_VALID_done;
always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        W_VALID_done <= 'd0;
    else if ( PAT_END  )
        W_VALID_done <= 'd0;
    else if (inf.W_VALID && inf.W_READY)
        W_VALID_done <= 'd1;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        AW_VALID_done <= 'd0;
    else if ( PAT_END || inf.B_READY )
        AW_VALID_done <= 'd0;
    else if (inf.W_VALID && inf.W_READY)
        AW_VALID_done <= 'd1;
end

always_ff @ (posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)
        inf.B_READY <= 'd0;
    else if ( inf.B_READY  )
        inf.B_READY <= ~inf.B_VALID;
    else if ( W_VALID_done && AW_VALID_done )
        inf.B_READY <= 'd1;
end



endmodule
