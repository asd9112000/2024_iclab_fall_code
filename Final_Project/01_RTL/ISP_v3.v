module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input [1:0] in_mode,
    input [1:0] in_ratio_mode,

    // Output Signals
    output out_valid,
    output [7:0] out_data,

    // DRAM Signals
    // axi write address channel
    // src master
    output [3:0]  awid_s_inf,
    output [31:0] awaddr_s_inf,
    output [2:0]  awsize_s_inf,
    output [1:0]  awburst_s_inf,
    output [7:0]  awlen_s_inf,
    output        awvalid_s_inf,
    // src slave
    input         awready_s_inf,
    // -----------------------------

    // axi write data channel
    // src master
    output [127:0] wdata_s_inf,
    output         wlast_s_inf,
    output         wvalid_s_inf,
    // src slave
    input          wready_s_inf,

    // axi write response channel
    // src slave
    input [3:0]    bid_s_inf,
    input [1:0]    bresp_s_inf,
    input          bvalid_s_inf,
    // src master
    output         bready_s_inf,
    // -----------------------------

    // axi read address channel
    // src master
    output [3:0]   arid_s_inf,
    output [31:0]  araddr_s_inf,
    output [7:0]   arlen_s_inf,
    output [2:0]   arsize_s_inf,
    output [1:0]   arburst_s_inf,
    output         arvalid_s_inf,
    // src slave
    input          arready_s_inf,
    // -----------------------------

    // axi read data channel
    // slave
    input [3:0]    rid_s_inf,
    input [127:0]  rdata_s_inf,
    input [1:0]    rresp_s_inf,
    input          rlast_s_inf,
    input          rvalid_s_inf,
    // master
    output         rready_s_inf

);



parameter  IDLE = 3'd0;
parameter  WAIT_DRAM = 3'd1;
parameter  SKIP_DRAM = 3'd2;
parameter  DIRECT_OUT = 3'd3;
integer i, j, k, m ,n;
genvar  a, b, c, d ,e;


reg  out_valid;
reg  [7:0] out_data;
// reg  out_valid_test;
// reg  [7:0] out_data_test;

//============================================================
//
//                     DRAM DECLARATION
//============================================================

// DRAM Signals
// axi write address channel
// src master
reg  [3 :0 ]  awid_s_inf = 4'b0000;
reg  [31:0 ]  awaddr_s_inf;   //32'h10000 + 3072*pic no.
reg  [2 :0 ]  awsize_s_inf = 'b100;
reg  [1 :0 ]  awburst_s_inf = 'b01;
reg  [7 :0 ]  awlen_s_inf = 'd191;
reg           awvalid_s_inf;

// src slave
// input         awready_s_inf,


// -----------------------------
// axi write data channel
// src master
reg  [127:0] wdata_s_inf;
reg          wlast_s_inf;
reg          wvalid_s_inf;
// src slave
// input          wready_s_inf,


// -----------------------------
// axi write response channel
// src slave
// input [3:0]    bid_s_inf,
// input [1:0]    bresp_s_inf,
// input          bvalid_s_inf,
// src master
reg         bready_s_inf;


// -----------------------------
// // axi read address channel
// // src master
reg [3:0 ]arid_s_inf    ;
reg [31:0]araddr_s_inf  ;
reg [7:0 ]arlen_s_inf   ;
reg [2:0 ]arsize_s_inf  ;
reg [1:0 ]arburst_s_inf ;
reg  arvalid_s_inf;
// // src slave
// input          arready_s_inf,


// -----------------------------
// axi read data channel
// slave
// input [3:0]    rid_s_inf,
// input [127:0]  rdata_s_inf,
// input [1:0]    rresp_s_inf,
// input          rlast_s_inf,
// input          rvalid_s_inf,
// master
reg  rready_s_inf;

wire [7:0] rdata_arr[0:15];
reg  [7:0] rdata_arr_reg[0:15];
// rdata_arr[15~0] = rdata_s_inf[127:0];

reg  [2:0] cs, ns;
reg  [7:0] cnt256, cnt256_avg, cnt256_work;
reg  all_zero_check [16:0];
// reg  all_zero_check_temp [15:0];
reg  all_zero_check_temp [15:0];
reg [3:0] in_pic_no_reg;
reg [1:0] in_mode_reg;
reg [1:0] in_ratio_mode_reg;




// Your Design

//============================================================
//
//                          END　SIGNAL
//
//============================================================


reg  pat_end;
reg  Dcontrast2X2_plus_end, Dcontrast2X2_plus_end_delay;
reg  Dcontrast4X4_plus_end, Dcontrast4X4_plus_end_delay;
reg  Dcontrast6X6_plus_end, Dcontrast6X6_plus_end_delay;
reg  auto_focus_end, auto_exp_end, avg_end;
reg  exp_cal_delay, exp_cal_delay2, exp_cal_delay3, exp_cal_delay4;
reg  in_valid_delay;
reg  skip_dram_end;
reg  Dcontrast6X6_div9_done, Dcontrast6X6_div9_done_delay, Dcontrast6X6_div9_done_delay2;

reg  [7:0]  avg_record[15:0];
reg  [1:0]  focus_record[15:0];
reg  [15:0] val_tag;

always @( * ) begin
    // pat_end =  auto_focus_end || auto_exp_end || skip_dram_end || avg_end;

    pat_end =  cs == WAIT_DRAM && cnt256 == 'd207 || cs == SKIP_DRAM || cs == DIRECT_OUT;
    Dcontrast2X2_plus_end = cnt256 == 'd169 && cs == WAIT_DRAM  ;
    // Dcontrast2X2_plus_end = cnt256 == 'd168 && cs == WAIT_DRAM  ;
    Dcontrast4X4_plus_end = cnt256 == 'd170 && cs == WAIT_DRAM  ;
    // Dcontrast4X4_plus_end = cnt256 == 'd169 && cs == WAIT_DRAM  ;
    Dcontrast6X6_plus_end = cnt256 == 'd173 && cs == WAIT_DRAM  ;
    // Dcontrast6X6_plus_end = cnt256 == 'd172 && cs == WAIT_DRAM  ;
    auto_focus_end =  cs == WAIT_DRAM && in_mode_reg == 'd0 && cnt256 == 'd192 ;             //Dcontrast6X6_plus_end + 2, cnt256 ==158

    auto_exp_end   =  cs == WAIT_DRAM && in_mode_reg == 'd1 && !exp_cal_delay3 && exp_cal_delay4; // cnt ==198
    avg_end        =  cs == WAIT_DRAM && in_mode_reg == 'd2 && cnt256_avg == 'd207 ;// cnt ==205
    skip_dram_end  =  cs == SKIP_DRAM ;

end


reg  wait_dram_st;
reg  wait_dram_st_delay;

always @( * ) begin
    wait_dram_st = cs == IDLE && in_valid;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        Dcontrast2X2_plus_end_delay <= 'd0;
        Dcontrast4X4_plus_end_delay <= 'd0;
        Dcontrast6X6_plus_end_delay <= 'd0;
        wait_dram_st_delay <= 'd0;
        in_valid_delay <= 'd0;
        Dcontrast6X6_div9_done_delay <= 'd0;
        Dcontrast6X6_div9_done_delay2 <= 'd0;
    end
    else begin
        Dcontrast2X2_plus_end_delay <= Dcontrast2X2_plus_end;
        Dcontrast4X4_plus_end_delay <= Dcontrast4X4_plus_end;
        Dcontrast6X6_plus_end_delay <= Dcontrast6X6_plus_end;
        wait_dram_st_delay <= wait_dram_st;
        in_valid_delay <= in_valid;
        Dcontrast6X6_div9_done_delay <= Dcontrast6X6_div9_done;
        Dcontrast6X6_div9_done_delay2 <= Dcontrast6X6_div9_done_delay;
    end
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
        // IDLE :      ns = (!in_valid) ? IDLE :
        //                  (all_zero_check[16] ) ? SKIP_DRAM : WAIT_DRAM; val_tag[in_pic_no]
        IDLE :      ns = (!in_valid) ? IDLE :
                         (all_zero_check[16] ) ? SKIP_DRAM :
                         ( in_mode != 'd1 &&  (val_tag[in_pic_no]) ) ? DIRECT_OUT : WAIT_DRAM;
        WAIT_DRAM:  ns = ( pat_end )? IDLE : WAIT_DRAM;
        SKIP_DRAM:  ns = ( pat_end )? IDLE : SKIP_DRAM;
        DIRECT_OUT: ns = ( pat_end )? IDLE : DIRECT_OUT;
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
    else if ( pat_end)
        cnt256 <= 'd0;
    else if ( rvalid_s_inf ||  cnt256 != 'd0 )
        cnt256 <= cnt256 +'d1;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt256_avg <= 'd0;
    else if ( pat_end)
        cnt256_avg <= 'd0;
    else if ( rvalid_s_inf ||  cnt256_avg != 'd0 )
        cnt256_avg <= cnt256_avg +'d1;
end




wire rdata_arr_reg_or;
assign  rdata_arr_reg_or =         |(({ rdata_arr_reg[3 ], rdata_arr_reg[2 ], rdata_arr_reg[1 ], rdata_arr_reg[0 ],
                                        rdata_arr_reg[7 ], rdata_arr_reg[6 ], rdata_arr_reg[5 ], rdata_arr_reg[4 ],
                                        rdata_arr_reg[11], rdata_arr_reg[10], rdata_arr_reg[9 ], rdata_arr_reg[8 ],
                                        rdata_arr_reg[15], rdata_arr_reg[14], rdata_arr_reg[13], rdata_arr_reg[12]}));



generate
    for ( a=0; a<=0; a=a+1) begin :all_zero_check_temp_generate
        always @( posedge clk or negedge rst_n) begin
            if (!rst_n)
                all_zero_check_temp[a] <= 'd0;
            else if  (  in_mode_reg == 'd1  && (cnt256 == 'd1)  ) begin
                all_zero_check_temp[a] <= rdata_arr_reg_or ;
            end
            else if  (  in_mode_reg == 'd1  && (cnt256 >= 'd2) && (cnt256 <= 'd191) ) begin
                all_zero_check_temp[a] <= (all_zero_check_temp[a] || rdata_arr_reg_or);
            end
            else if  (  in_mode_reg == 'd1  && (cnt256 == 'd192) ) begin
                all_zero_check_temp[a] <= (all_zero_check_temp[a] || rdata_arr_reg_or);
            end
        end
    end
endgenerate




generate
    for ( a=0; a<=15; a=a+1) begin :all_zero_check_generate
        always @( posedge clk or negedge rst_n) begin
            if (!rst_n)
                all_zero_check[a] <= 'd0;
            else if (  all_zero_check[a] ) begin
                all_zero_check[a] <= 'd1;
            end
            else if  (  in_mode_reg == 'd1 && in_pic_no_reg == a && (cnt256 == 'd192) ) begin
                all_zero_check[a] <= !(all_zero_check_temp[0] || rdata_arr_reg_or);
            end
        end
    end
endgenerate


always @(*) begin
  all_zero_check[16] =  (((     all_zero_check[0 ] && in_pic_no == 'd0  || all_zero_check[1 ] && in_pic_no == 'd1  )|| (all_zero_check[2 ] && in_pic_no == 'd2  )|| (all_zero_check[3 ] && in_pic_no == 'd3 ))
                          ||  ((all_zero_check[4 ] && in_pic_no == 'd4  || all_zero_check[5 ] && in_pic_no == 'd5  )|| (all_zero_check[6 ] && in_pic_no == 'd6  )|| (all_zero_check[7 ] && in_pic_no == 'd7 )))
                          || (((all_zero_check[8 ] && in_pic_no == 'd8  || all_zero_check[9 ] && in_pic_no == 'd9  )|| (all_zero_check[10] && in_pic_no == 'd10 )|| (all_zero_check[11] && in_pic_no == 'd11))
                          ||  ((all_zero_check[12] && in_pic_no == 'd12 || all_zero_check[13] && in_pic_no == 'd13 )|| (all_zero_check[14] && in_pic_no == 'd14 )|| (all_zero_check[15] && in_pic_no == 'd15)));
end


//============================================================
//
//                    INPUT REGISTERS
//
//============================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_pic_no_reg       <= 'd0;
        in_mode_reg         <= 'd0;
        in_ratio_mode_reg   <= 'd0;
    end
    else if (cs == IDLE && in_valid) begin
        in_pic_no_reg       <= in_pic_no;
        in_mode_reg         <= in_mode;
        in_ratio_mode_reg   <= (in_mode == 'd1 ) ? (in_ratio_mode) : 'd0;
    end
end

wire signed [3:0]add_test1, add_test2;
wire signed [4:0]add_testp, add_testn;
assign add_test1 = {1'b0, 4'd14};
assign add_test2 = {1'b0, 4'd13};
assign add_testp = add_test1 - add_test2;
assign add_testn = add_test2 - add_test1;

//============================================================
//
//                    WORK REGISTERS
//
//============================================================
reg [7:0] work[2:0][17:0]; // work [y][x]
// reg [7:0] work[1:0][17:0]; // work [y][x]
// reg [7:0] work[3:2][15:0]; // work [y][x]

// work shape for auto exposure
// x =   0 1 2 3 4 5 6 7 .... 31
// y = 0
// y = 1

// work shape for auto  focus
// x =   0 1 2 3 4 5 6 7 .... 31
// y = 0  0~5   6~11 12~17
// y = 1 18~23 24~29 30~35

// work
// [0][0 ] [0][1 ] [0][2 ] [0][3 ] [0][4 ] [0][5 ]
// [0][6 ] [0][7 ] [0][8 ] [0][9 ] [0][10] [0][11]
// [0][12] [0][13] [0][14] [0][15] [0][16] [0][17]
// [1][18] [1][19] [1][20] [1][21] [1][22] [1][23]
// [1][24] [1][25] [1][26] [1][27] [1][28] [1][29]
// [1][30] [1][31] [1][32] [1][33] [1][34] [1][35]

reg [7:0] work_avg [15:0];
reg [7:0] work_exposure [2:0][15:0];
reg [7:0] work_focus[1:0][17:0]; // work [y][x]

reg [1:0] auto_focus_work_add_ctrl;
reg [7:0] auto_focus_work_add_in0 [0:2];
reg [7:0] auto_focus_work_add_in1 [0:2];
reg [3:0] cnt16_auto_focus_work_add_in0;



// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         auto_focus_work_add_ctrl[1] <= 'd0;
//     else if ( pat_end)
//         auto_focus_work_add_ctrl[1] <= 'd0;
//     else if  ( cs == WAIT_DRAM && (cnt256 == 'd11 || cnt256 == 'd75)) begin
//         auto_focus_work_add_ctrl[1] <= ~ auto_focus_work_add_ctrl[1];
//     end
// end

// auto_focus_work_add_in1
always @( posedge clk or negedge rst_n) begin
     if ( !rst_n) begin
            auto_focus_work_add_in1[0] <= 'd0;
            auto_focus_work_add_in1[1] <= 'd0;
            auto_focus_work_add_in1[2] <= 'd0;
        end
    else if (cnt256 >= 'd91 && cnt256 <= 'd102) begin
        if ( cnt256 [0]) begin
            auto_focus_work_add_in1[0] <= rdata_arr_reg [13] >> 1;
            auto_focus_work_add_in1[1] <= rdata_arr_reg [14] >> 1;
            auto_focus_work_add_in1[2] <= rdata_arr_reg [15] >> 1;
        end
        else begin
            auto_focus_work_add_in1[0] <= rdata_arr_reg [0] >> 1;
            auto_focus_work_add_in1[1] <= rdata_arr_reg [1] >> 1;
            auto_focus_work_add_in1[2] <= rdata_arr_reg [2] >> 1;
        end
    end
    else begin
        if ( cnt256 [0]) begin
            auto_focus_work_add_in1[0] <= rdata_arr_reg [13] >> 2;
            auto_focus_work_add_in1[1] <= rdata_arr_reg [14] >> 2;
            auto_focus_work_add_in1[2] <= rdata_arr_reg [15] >> 2;
        end
        else begin
            auto_focus_work_add_in1[0] <= rdata_arr_reg [0] >> 2;
            auto_focus_work_add_in1[1] <= rdata_arr_reg [1] >> 2;
            auto_focus_work_add_in1[2] <= rdata_arr_reg [2] >> 2;
        end
    end
end




// cnt16_auto_focus_work_add_in0
always @( posedge clk or negedge rst_n) begin
    if ( !rst_n)
        cnt16_auto_focus_work_add_in0 <= 'd0;
    else if ( pat_end)
        cnt16_auto_focus_work_add_in0 <= 'd0;
    else if (cnt256 >= 'd27  ) begin
        cnt16_auto_focus_work_add_in0 <= cnt16_auto_focus_work_add_in0 + 'd1;
    end
end

// auto_focus_work_add_in0
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        auto_focus_work_add_in0[0] <= 'd0 ;
        auto_focus_work_add_in0[1] <= 'd0 ;
        auto_focus_work_add_in0[2] <= 'd0 ;
    end
    else
    case (cnt16_auto_focus_work_add_in0)
        0: begin
            auto_focus_work_add_in0[0] <= work_focus[0] [0] ;
            auto_focus_work_add_in0[1] <= work_focus[0] [1] ;
            auto_focus_work_add_in0[2] <= work_focus[0] [2] ;
        end
        1: begin
            auto_focus_work_add_in0[0] <= work_focus[0] [3] ;
            auto_focus_work_add_in0[1] <= work_focus[0] [4] ;
            auto_focus_work_add_in0[2] <= work_focus[0] [5] ;
        end
        2: begin
            auto_focus_work_add_in0[0] <= work_focus[0] [6] ;
            auto_focus_work_add_in0[1] <= work_focus[0] [7] ;
            auto_focus_work_add_in0[2] <= work_focus[0] [8] ;
        end
        3: begin
            auto_focus_work_add_in0[0] <= work_focus[0] [9] ;
            auto_focus_work_add_in0[1] <= work_focus[0] [10] ;
            auto_focus_work_add_in0[2] <= work_focus[0] [11] ;
        end
        4: begin
            auto_focus_work_add_in0[0] <= work_focus[0] [12] ;
            auto_focus_work_add_in0[1] <= work_focus[0] [13] ;
            auto_focus_work_add_in0[2] <= work_focus[0] [14] ;
        end
        5: begin
            auto_focus_work_add_in0[0] <= work_focus[0] [15] ;
            auto_focus_work_add_in0[1] <= work_focus[0] [16] ;
            auto_focus_work_add_in0[2] <= work_focus[0] [17] ;
        end
        6: begin
            auto_focus_work_add_in0[0] <= work_focus[1] [0] ;
            auto_focus_work_add_in0[1] <= work_focus[1] [1] ;
            auto_focus_work_add_in0[2] <= work_focus[1] [2] ;
        end
        7: begin
            auto_focus_work_add_in0[0] <= work_focus[1] [3] ;
            auto_focus_work_add_in0[1] <= work_focus[1] [4] ;
            auto_focus_work_add_in0[2] <= work_focus[1] [5] ;
        end
        8: begin
            auto_focus_work_add_in0[0] <= work_focus[1] [6] ;
            auto_focus_work_add_in0[1] <= work_focus[1] [7] ;
            auto_focus_work_add_in0[2] <= work_focus[1] [8] ;
        end
        9: begin
            auto_focus_work_add_in0[0] <= work_focus[1] [9] ;
            auto_focus_work_add_in0[1] <= work_focus[1] [10] ;
            auto_focus_work_add_in0[2] <= work_focus[1] [11] ;
        end
        10: begin
            auto_focus_work_add_in0[0] <= work_focus[1] [12] ;
            auto_focus_work_add_in0[1] <= work_focus[1] [13] ;
            auto_focus_work_add_in0[2] <= work_focus[1] [14] ;
        end
        11: begin
            auto_focus_work_add_in0[0] <= work_focus[1] [15] ;
            auto_focus_work_add_in0[1] <= work_focus[1] [16] ;
            auto_focus_work_add_in0[2] <= work_focus[1] [17] ;
        end
        default: begin
            auto_focus_work_add_in0[0] <= 'd0 ;
            auto_focus_work_add_in0[1] <= 'd0 ;
            auto_focus_work_add_in0[2] <= 'd0 ;
        end
    endcase
end


reg   [7:0] auto_focus_work_add [2:0]; // (G, RB) x (0, 1) x (0~2)
generate
// for ( a=0; a<=1; a=a+1) begin :auto_focus_work_add_01
    for ( b=0; b<=2; b=b+1) begin : auto_focus_work_add_05
        always @(*) begin
                auto_focus_work_add[b] =  auto_focus_work_add_in1[b] + auto_focus_work_add_in0[b];
        end
    end
// end
endgenerate


// work_focus
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i <= 1; i = i + 1) begin
            for ( j = 0; j <= 17; j = j + 1) begin
                work_focus[i][j] <= 'd0;
            end
        end
    end
    else if ( pat_end) begin
        for ( i = 0; i <= 1; i = i + 1) begin
            for ( j = 0; j <= 17; j = j + 1) begin
                work_focus[i][j] <= 'd0;
            end
        end
    end
    else if ( cs == WAIT_DRAM ) begin // auto focus
        case (cnt256)
        // for R
        28 : begin
            for ( i = 0; i <= 2; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i];
        end
        29 : begin
            for ( i = 3; i <= 5; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-3];
        end
        30 : begin
            for ( i = 6; i <= 8; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-6];
        end
        31 : begin
            for ( i = 9; i <= 11; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-9];
        end
        32 : begin
            for ( i = 12; i <= 14; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-12];
        end
        33 :begin
            for ( i = 15; i <= 17; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-15];
        end


        34 :begin
            for ( i = 0; i <= 2; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i];
        end
        35 :begin
            for ( i = 3; i <= 5; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-3];
        end
        36 :begin
            for ( i = 6; i <= 8; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-6];
        end
        37 :begin
            for ( i = 9; i <= 11; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-9];
        end
        38 :begin
            for ( i = 12; i <= 14; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-12];
        end
        39 :begin
            for ( i = 15; i <= 17; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-15];
        end


        // for G
        92 : begin
            for ( i = 0; i <= 2; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i];
        end
        93 : begin
            for ( i = 3; i <= 5; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-3];
        end
        94 : begin
            for ( i = 6; i <= 8; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-6];
        end
        95 : begin
            for ( i = 9; i <= 11; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-9];
        end
        96 : begin
            for ( i = 12; i <= 14; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-12];
        end
        97 : begin
            for ( i = 15; i <= 17; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-15];
        end


        98 :begin
            for ( i = 0; i <=2; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i];
        end
        99 :begin
            for ( i = 3; i <=5; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-3];
        end
        100:begin
            for ( i = 6; i <=8; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-6];
        end
        101:begin
            for ( i = 9; i <=11; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-9];
        end
        102:begin
            for ( i = 12; i <=14; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-12];
        end
        103:begin
            for ( i = 15; i <=17; i = i + 1)
                work_focus[1][i ] <= auto_focus_work_add[i-15];
        end



        // for B
        156 : begin
            for ( i = 0; i <= 2; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i];
        end
        157: begin
            for ( i = 3; i <= 5; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-3];
        end
        158: begin
            for ( i = 6; i <= 8; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-6];
        end
        159: begin
            for ( i = 9; i <= 11; i = i + 1)
                work_focus[0][i ] <= auto_focus_work_add[i-9];
        end

        160, 162, 164, 166: begin
            work_focus[0][0 ] <= work_focus[0][6 ];
            work_focus[0][1 ] <= work_focus[0][7 ];
            work_focus[0][2 ] <= work_focus[0][8 ];
            work_focus[0][3 ] <= work_focus[0][9 ];
            work_focus[0][4 ] <= work_focus[0][10];
            work_focus[0][5 ] <= work_focus[0][11];


            work_focus[0][6 ] <= auto_focus_work_add[0 ];
            work_focus[0][7 ] <= auto_focus_work_add[1 ];
            work_focus[0][8 ] <= auto_focus_work_add[2 ];
        end
        161, 163, 165, 167: begin
            work_focus[0][9 ] <= auto_focus_work_add[0 ];
            work_focus[0][10] <= auto_focus_work_add[1 ];
            work_focus[0][11] <= auto_focus_work_add[2 ];
        end
        endcase
    end
end


// work_exposure
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( j=0; j<=2; j=j+1) begin
            for ( i = 0; i <= 15; i = i + 1) begin
                work_exposure[j][i] <= 'd0;
            end
        end
    end
    else if ( pat_end) begin
        for ( j=0; j<=2; j=j+1) begin
            for ( i = 0; i <= 15; i = i + 1) begin
                work_exposure[j][i] <= 'd0;
            end
        end
    end
    else if ( cs == WAIT_DRAM ) begin
        if (  cnt256 < 'd194) begin
            case ( in_ratio_mode_reg)
            0: begin
                for ( i = 0; i <= 15; i = i + 1)
                    work_exposure[0][i ] <= (rdata_arr_reg[i ] >> 2) ;
                end
            1: begin
                for ( i = 0; i <= 15; i = i + 1)
                    work_exposure[0][i ] <= (rdata_arr_reg[i ] >> 1 );
            end
            2: begin
                for ( i = 0; i <= 15; i = i + 1)
                    work_exposure[0][i ] <= (rdata_arr_reg[i ]      );
            end
            3: begin
                for ( i = 0; i <= 15; i = i + 1)
                    work_exposure[0][i ] <=  (rdata_arr_reg[i ][7]) ? 'd255 : (rdata_arr_reg[i ] << 1 );
            end
            endcase

            for ( i = 0; i <= 2; i = i + 1) begin
                for ( j = 0; j <= 15; j = j + 1) begin
                    work_exposure[i+1][j ] <= work_exposure[i][j ] ;
                end
            end
        end
        else if (  cnt256 == 'd194 || cnt256 == 'd195 ||  cnt256 == 'd196) begin   //  193??????
            for ( j = 0; j <= 15; j = j + 1) begin
                work_exposure[0][j ] <= 'd0 ;
            end
            for ( i = 0; i <= 1; i = i + 1) begin
                for ( j = 0; j <= 15; j = j + 1) begin
                    work_exposure[i+1][j ] <= work_exposure[i][j ] ;
                end
            end
        end
    end
end
// work_avg
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i <= 15; i = i + 1) begin
            work_avg[i] <= 'd0;
        end
    end
    else if ( pat_end) begin
        for ( i = 0; i <= 15; i = i + 1) begin
            work_avg[i] <= 'd0;
        end
    end
    else if ( cs == WAIT_DRAM  && cnt256_avg < 'd194) begin // Average of Min and Max
        for ( i = 0; i <= 15; i = i + 1)
            work_avg[i] <= (rdata_arr_reg[i ]      );
    end
end



// /==============================================================================================\
// ||                                                                                            ||
// ||   _______   ______     ______  __    __       _______.     ______     ___       __         ||
// ||  |   ____| /  __  \   /      ||  |  |  |     /       |    /      |   /   \     |  |        ||
// ||  |  |__   |  |  |  | |  ,----'|  |  |  |    |   (----`   |  ,----'  /  ^  \    |  |        ||
// ||  |   __|  |  |  |  | |  |     |  |  |  |     \   \       |  |      /  /_\  \   |  |        ||
// ||  |  |     |  `--'  | |  `----.|  `--'  | .----)   |      |  `----./  _____  \  |  `----.   ||
// ||  |__|      \______/   \______| \______/  |_______/        \______/__/     \__\ |_______|   ||
// ||                                                                                            ||
// \==============================================================================================/

// work
// [0][0 ] [0][1 ] [0][2 ] [0][3 ] [0][4 ] [0][5 ]
// [0][6 ] [0][7 ] [0][8 ] [0][9 ] [0][10] [0][11]
// [0][12] [0][13] [0][14] [0][15] [0][16] [0][17]
// [1][18] [1][19] [1][20] [1][21] [1][22] [1][23]
// [1][24] [1][25] [1][26] [1][27] [1][28] [1][29]
// [1][30] [1][31] [1][32] [1][33] [1][34] [1][35]


// AUTO FOCUS : Dcontrast
// reg  [5:0]  cntDcontrast;
reg  [7:0]  DiffH[0:2], DiffV[0:2];
reg  [8:0]  DiffSum[0:2];
reg  [7:0]  DiffR[0:4], DiffL[0:4],DiffUP[0:5];
reg  [7:0]  DiffH_in0[2:0], DiffH_in1[2:0];
reg  [7:0]  DiffV_in0[2:0], DiffV_in1[2:0];
reg  [3:0]  cnt16_DiffH;

// cnt16_DiffH =  1 2 3 ... 12  cnt256 = 157 158 .........168
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt16_DiffH <= 'd0;
    else if ( pat_end)
        cnt16_DiffH <= 'd0;
    else if ( cnt256 >= 'd156 && cnt256 <= 'd167) begin
        cnt16_DiffH <= cnt16_DiffH + 'd1;
    end
end

always @(*) begin
    if ( cnt16_DiffH == 'd1) begin
    // if ( cnt256 == 'd157) begin
        DiffH_in0[0] = work_focus[0][0];
        DiffH_in1[0] = work_focus[0][1];
        DiffH_in0[1] = work_focus[0][1];
        DiffH_in1[1] = work_focus[0][2];
        DiffH_in0[2] = 'd0;
        DiffH_in1[2] = 'd0;
        // DiffH_in0[2] = work_focus[0][1];
        // DiffH_in1[2] = work_focus[0][2];
    end
    else if ( cnt16_DiffH == 'd2) begin
    // else if ( cnt256 == 'd158) begin
        DiffH_in0[0] = work_focus[0][2];
        DiffH_in1[0] = work_focus[0][3];
        DiffH_in0[1] = work_focus[0][3];
        DiffH_in1[1] = work_focus[0][4];
        DiffH_in0[2] = work_focus[0][4];
        DiffH_in1[2] = work_focus[0][5];
        // DiffH_in0[2] = work_focus[0][4];
        // DiffH_in1[2] = work_focus[0][5];
    end
    else if ( cnt16_DiffH[0]) begin
    // else if ( cnt256[0]) begin
        DiffH_in0[0] = work_focus[0][6];
        DiffH_in1[0] = work_focus[0][7];
        DiffH_in0[1] = work_focus[0][7];
        DiffH_in1[1] = work_focus[0][8];
        DiffH_in0[2] = 'd0;
        DiffH_in1[2] = 'd0;
        // DiffH_in0[2] = work_focus[1][1];
        // DiffH_in1[2] = work_focus[1][2];
    end
    else begin
        DiffH_in0[0] = work_focus[0][8];
        DiffH_in1[0] = work_focus[0][9];
        DiffH_in0[1] = work_focus[0][9];
        DiffH_in1[1] = work_focus[0][10];
        DiffH_in0[2] = work_focus[0][10];
        DiffH_in1[2] = work_focus[0][11];
    end
end

// DiffH : 6,4,2 use DiffH [i] 0~4, 1~3, 2, 6 sets,
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( i =0 ; i<=2 ; i=i+1) begin
            DiffH [i] <= 'd0 ;
        end
    else if ( pat_end )
        for ( i =0 ; i<=2 ; i=i+1) begin
            DiffH [i] <= 'd0 ;
        end
    else if ( cnt16_DiffH >= 'd1 && cnt16_DiffH <= 'd12) begin
    // else if ( cnt256 >= 'd157 && cnt256 <= 'd168) begin
        for ( i =0 ; i<=2 ; i=i+1) begin
            DiffH [i] <= (DiffH_in0[i] >= DiffH_in1[i]) ? (DiffH_in0[i] - DiffH_in1[i]) : (DiffH_in1[i] - DiffH_in0[i]) ;
        end
    end
end




// DiffV : 6,4,2 use DiffH [i] 0~5, 1~4, 2~3, 5 sets
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( j =0 ; j<=5 ; j=j+1) begin
            DiffV [j] <= 'd0 ;
        end
    else if ( pat_end )
        for (  j =0 ; j<=5 ; j=j+1) begin
            DiffV [j] <= 'd0 ;
        end
    else if (   cnt16_DiffH >= 'd3 && cnt16_DiffH <= 'd12)begin
    // else if (   cnt256 >= 'd159 && cnt256 <= 'd168)begin
        if (  cnt16_DiffH[0]) begin
            for (  j =0 ; j<=2 ; j=j+1) begin
                DiffV [j] <= (work_focus[0][j] >= work_focus[0][j+6]) ? work_focus[0][j] - work_focus[0][j+6] : work_focus[0][j+6] - work_focus[0][j] ;
            end
        end
        else begin
            for (  j =0 ; j<=2 ; j=j+1) begin
                DiffV [j] <= (work_focus[0][j+3] >= work_focus[0][j+6+3]) ? work_focus[0][j+3] - work_focus[0][j+6+3] : work_focus[0][j+6+3] - work_focus[0][j+3] ;
            end
        end
    end
end


reg  [8 :0 ] DcontrastL1 [2:0];
reg  [9 :0 ] DcontrastL2 ;
reg  [8 :0 ] DcontrastL2_;
reg  [10:0 ] DcontrastL3 ;
// reg  [11:0 ] DcontrastL4 ;

reg  [9:0 ] DcontrastL2NoV [2:1];
reg  [10:0 ] DcontrastL3NoV ;

reg  en_DcontrastL1, en_DcontrastL2, en_DcontrastL3, en_DcontrastL4;
always @(*) en_DcontrastL1 = cs == WAIT_DRAM  && cnt256 >= 'd158 &&  cnt256 <= 'd169;
// always @(*) en_DcontrastL1 = cs == WAIT_DRAM  && cnt256 >= 'd157 &&  cnt256 <= 'd168;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        en_DcontrastL2 <= 'd0;
        en_DcontrastL3 <= 'd0;
        en_DcontrastL4 <= 'd0;
    end
    else begin
        en_DcontrastL2 <= en_DcontrastL1;
        en_DcontrastL3 <= en_DcontrastL2;
        en_DcontrastL4 <= en_DcontrastL3;
    end
end

//DcontrastL1
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( i = 0; i <= 2; i = i + 1)
            DcontrastL1[i] <= 'd0;
    else if ( pat_end)
        for ( i = 0; i <= 2; i = i + 1)
            DcontrastL1[i] <= 'd0;
    else if ( en_DcontrastL1) begin
            DcontrastL1[0] <= DiffH[0] + DiffV[0];
            DcontrastL1[1] <= DiffH[1] + DiffV[1];
            DcontrastL1[2] <= DiffH[2] + DiffV[2];
    end
end


//DcontrastL2
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        DcontrastL2_ <= 'd0;
        DcontrastL2 <= 'd0;
    end
    else if ( pat_end)begin
        DcontrastL2_ <= 'd0;
        DcontrastL2 <= 'd0;
    end
    else if ( en_DcontrastL2) begin
            DcontrastL2 <= DcontrastL1[0] + DcontrastL1[1];
            DcontrastL2_ <= DcontrastL1[2] ;

    end
end


//DcontrastL3
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        DcontrastL3 <= 'd0;
    end
    else if ( pat_end) begin
        DcontrastL3 <= 'd0;
    end
    else if ( en_DcontrastL3) begin
        DcontrastL3 <= DcontrastL2 + DcontrastL2_;
    end
end



reg  [13:0] Dcontrast6X6;
reg  [12:0] Dcontrast4X4;
reg  [10:0] Dcontrast2X2;
wire [7:0] Dcontrast6X6_div9;

//Dcontrast6X6;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        Dcontrast6X6 <= 'd0;
    else if ( pat_end)
        Dcontrast6X6 <= 'd0;
    else if (  Dcontrast6X6_div9_done) begin // avalible from cnt256 == 146
        Dcontrast6X6 <= {6'd0, Dcontrast6X6_div9};
    end
    else if ( cs == WAIT_DRAM  && (cnt256 >= 'd161 && cnt256 <= 'd172 )) begin
    // else if ( cs == WAIT_DRAM  && (cnt256 >= 'd160 && cnt256 <= 'd171 )) begin
        Dcontrast6X6 <= DcontrastL3 + (Dcontrast6X6);
    end

end


div9 div9 (
    .clk(clk),
    .rst_n(rst_n),
    .enable(Dcontrast6X6_plus_end),
    .big(Dcontrast6X6[13:2]),
    .shang(Dcontrast6X6_div9),
    // .  [3:0] yushu,
    .done(Dcontrast6X6_div9_done)
);


reg [8:0] Dcontrast4X4_L1[1:0];
reg [9:0] Dcontrast4X4_L2;
reg  en_Dcontrast4X4_L2, en_Dcontrast4X4;

wire en_Dcontrast4X4_L1;
assign en_Dcontrast4X4_L1 = cnt256 >= 'd160 && cnt256 <= 'd167;
// assign en_Dcontrast4X4_L1 = cnt256 >= 'd159 && cnt256 <= 'd166;


always @( posedge clk or negedge rst_n) begin
    if ( !rst_n) begin
        en_Dcontrast4X4_L2 <= 'd0;
        en_Dcontrast4X4 <= 'd0;
    end
    else begin
        en_Dcontrast4X4_L2 <= en_Dcontrast4X4_L1;
        en_Dcontrast4X4 <= en_Dcontrast4X4_L2;
    end
end
//Dcontrast4X4_L1
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( i = 0; i <= 1; i = i + 1)
            Dcontrast4X4_L1[i] <= 'd0;
    else if ( pat_end)
        for ( i = 0; i <= 1; i = i + 1)
            Dcontrast4X4_L1[i] <= 'd0;
    else if ( en_Dcontrast4X4_L1) begin
        if (cnt256 == 'd160) begin
        // if (cnt256 == 'd159) begin
            Dcontrast4X4_L1[0] <= 'd0 + DiffH[1];
            Dcontrast4X4_L1[1] <= 'd0;
        end
        else if ( cnt256 == 'd161)begin
        // else if ( cnt256 == 'd160)begin
            Dcontrast4X4_L1[0] <= DiffH[0] + DiffH[1];
            Dcontrast4X4_L1[1] <= 'd0;
        end
        else if (!cnt256 [0])begin
        // else if (!cnt256 [0])begin
            Dcontrast4X4_L1[0] <= 'd0 + DiffH[1];
            Dcontrast4X4_L1[1] <= DiffV[1] + DiffV[2];
        end
        else begin
            Dcontrast4X4_L1[0] <= DiffH[0] + DiffH[1];
            Dcontrast4X4_L1[1] <= DiffV[0] + DiffV[1];
        end
    end
end



always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        Dcontrast4X4_L2 <= 'd0;
    else if ( pat_end)
        Dcontrast4X4_L2 <= 'd0;
    else if ( en_Dcontrast4X4_L2) begin
        Dcontrast4X4_L2 <= Dcontrast4X4_L1[0] + Dcontrast4X4_L1[1];
    end
end

//Dcontrast4X4
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        Dcontrast4X4 <= 'd0;
    else if ( pat_end)
        Dcontrast4X4 <= 'd0;
    else if (  Dcontrast4X4_plus_end) begin  // avalible from cnt256 == 143
        Dcontrast4X4 <= Dcontrast4X4 >> 4;
    end
    else if ( cs == WAIT_DRAM  && ( en_Dcontrast4X4 )) begin
        Dcontrast4X4 <=  Dcontrast4X4 + Dcontrast4X4_L2;
    end
end



reg [8:0] Dcontrast2X2_L1;


//Dcontrast2X2_L1
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        Dcontrast2X2_L1 <= 'd0;
    else if ( pat_end)
        Dcontrast2X2_L1 <= 'd0;

    else if ( cnt256 == 'd163)begin
    // else if ( cnt256 == 'd162)begin
        Dcontrast2X2_L1 <= DiffH[0] + 'd0;
    end
    else if ( cnt256 == 'd164)begin
    // else if ( cnt256 == 'd163)begin
        Dcontrast2X2_L1 <= 'd0 + DiffV[2];
    end
    else if ( cnt256 == 'd165)begin
    // else if ( cnt256 == 'd164)begin
        Dcontrast2X2_L1 <= DiffH[0] + DiffV[0];
    end

end




//Dcontrast2X2
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        Dcontrast2X2 <= 'd0;
    else if ( pat_end)
        Dcontrast2X2 <= 'd0;
    else if (  Dcontrast2X2_plus_end) begin // avalible from cnt256 == 140
        Dcontrast2X2 <= Dcontrast2X2 >> 2;
    end
    else if ( cs == WAIT_DRAM  &&  ( cnt256 == 'd166 || cnt256 == 'd164 || cnt256 == 'd165 )) begin
    // else if ( cs == WAIT_DRAM  &&  ( cnt256 == 'd163 || cnt256 == 'd164 || cnt256 == 'd165 )) begin
        Dcontrast2X2 <=  Dcontrast2X2 + Dcontrast2X2_L1 ;
    end
end


reg  [1:0] output_pick_focus;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        output_pick_focus <= 'd0;
    else if ( pat_end)
        output_pick_focus <= 'd0;
    else if (  Dcontrast4X4_plus_end_delay) begin
        output_pick_focus <= (Dcontrast2X2 >= Dcontrast4X4) ? 'd0 : 'd1;
    end
    // else if ( Dcontrast6X6_plus_end_delay ) begin
    else if ( Dcontrast6X6_div9_done_delay ) begin
        if (output_pick_focus[0]) begin
            output_pick_focus <= (Dcontrast4X4 >= Dcontrast6X6) ? 'd1 : 'd2;
        end
        else begin
            output_pick_focus <= (Dcontrast2X2 >= Dcontrast6X6) ? 'd0 : 'd2;
        end
    end
end




// /==============================================================================================================================\
// ||                                                                                                                            ||
// ||   __________   ___ .______     ______        _______. __    __  .______       _______      ______     ___       __         ||
// ||  |   ____\  \ /  / |   _  \   /  __  \      /       ||  |  |  | |   _  \     |   ____|    /      |   /   \     |  |        ||
// ||  |  |__   \  V  /  |  |_)  | |  |  |  |    |   (----`|  |  |  | |  |_)  |    |  |__      |  ,----'  /  ^  \    |  |        ||
// ||  |   __|   >   <   |   ___/  |  |  |  |     \   \    |  |  |  | |      /     |   __|     |  |      /  /_\  \   |  |        ||
// ||  |  |____ /  .  \  |  |      |  `--'  | .----)   |   |  `--'  | |  |\  \----.|  |____    |  `----./  _____  \  |  `----.   ||
// ||  |_______/__/ \__\ | _|       \______/  |_______/     \______/  | _| `._____||_______|    \______/__/     \__\ |_______|   ||
// ||                                                                                                                            ||
// \==============================================================================================================================/


reg  [8:0 ]Exp_9bL1 [7:0];
reg  [9:0 ]Exp_10bL2[3:0];
reg  [10:0]Exp_11bL3[1:0];
reg  [11:0]Exp_12bL4;
reg  [17:0]Exp_18b_Total;

wire exp_cal;
assign exp_cal =  cs == WAIT_DRAM  && cnt256 >= 'd1 && cnt256 <= 'd194;


reg  [15:0] pat_cnt;

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pat_cnt <= 'd0;

    end
    else if ( pat_end ) begin

        pat_cnt <= pat_cnt + 'd1;
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        exp_cal_delay <= 'd0;
        exp_cal_delay2 <= 'd0;
        exp_cal_delay3 <= 'd0;
        exp_cal_delay4 <= 'd0;
    end
    else  begin
        exp_cal_delay  <= exp_cal;
        exp_cal_delay2 <= exp_cal_delay  ;
        exp_cal_delay3 <= exp_cal_delay2 ;
        exp_cal_delay4 <= exp_cal_delay3 ;
    end
end
reg  [7:0] cnt256_delay, cnt256_delay2;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt256_delay <= 'd0;
        cnt256_delay2 <= 'd0;
    end
    else begin
        cnt256_delay <= cnt256;
        cnt256_delay2 <= cnt256_delay;
    end
end
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for (i=0; i <= 7 ; i=i+1)
            Exp_9bL1[i] <= 'd0;
    else if ( pat_end)
        for (i=0; i <= 7 ; i=i+1)
            Exp_9bL1[i] <= 'd0;
    else if ( exp_cal ) begin
        // for (i=0; i <= 7; i=i+1)
                // Exp_9bL1[i] <=  ( (cnt256_delay2[7:6] == 'd3))  Exp_9bL1[i]:
                //                 ( (cnt256_delay2[7:6] == 'd1) ? (work[0][2*i] >> 1 ) : (work[0][2*i] >> 2 ) ) + ((cnt256_delay2[7:6] == 'd1) ?(work[0][2*i+1] >>2) :(work[0][2*i+1] >>2));
        case (cnt256_delay2[7:6])
            0: begin
                for (i=0; i <= 7; i=i+1)
                    Exp_9bL1[i] <= (work_exposure[0][2*i] >> 2 )+ (work_exposure[0][2*i+1] >>2);
            end
            1: begin
                for (i=0; i <= 7; i=i+1)
                    Exp_9bL1[i] <= (work_exposure[0][2*i] >> 1 )+ (work_exposure[0][2*i+1] >>1);
            end
            2: begin
                for (i=0; i <= 7; i=i+1)
                    Exp_9bL1[i] <= (work_exposure[0][2*i] >> 2 )+ (work_exposure[0][2*i+1] >>2);
            end
            default: ;
        endcase
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for (i=0; i <= 3 ; i=i+1)
            Exp_10bL2[i] <= 'd0;
    else if ( pat_end)
        for (i=0; i <= 3 ; i=i+1)
            Exp_10bL2[i] <= 'd0;
    else if ( exp_cal_delay) begin
        for (i=0; i <= 3; i=i+1)
            Exp_10bL2[i] <= Exp_9bL1[2*i] + Exp_9bL1[2*i+1];
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for (i=0; i <= 1 ; i=i+1)
            Exp_11bL3[i] <= 'd0;
    else if ( pat_end)
        for (i=0; i <= 1 ; i=i+1)
            Exp_11bL3[i] <= 'd0;
    else if ( exp_cal_delay2) begin
        for (i=0; i <= 1; i=i+1)
            Exp_11bL3[i] <= Exp_10bL2[2*i] + Exp_10bL2[2*i+1];
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
            Exp_12bL4 <= 'd0;
    else if ( pat_end)
            Exp_12bL4 <= 'd0;
    else if ( exp_cal_delay3) begin
            Exp_12bL4 <= Exp_11bL3 [0] + Exp_11bL3 [1];
    end
end

// reg  [17:0]Exp_18b_Total;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
            Exp_18b_Total <= 'd0;
    else if ( pat_end)
            Exp_18b_Total <= 'd0;
    else if ( exp_cal_delay4) begin
            Exp_18b_Total <= Exp_12bL4  +Exp_18b_Total;
    end
end


// +=======================================================================================================================================+
// |                                                                                                                                       |
// |      ___   ____    ____  _______      ______    _______    .___  ___.  __  .__   __.               .___  ___.      ___      ___   ___ |
// |     /   \  \   \  /   / |   ____|    /  __  \  |   ____|   |   \/   | |  | |  \ |  |      ___      |   \/   |     /   \     \  \ /  / |
// |    /  ^  \  \   \/   /  |  |__      |  |  |  | |  |__      |  \  /  | |  | |   \|  |     ( _ )     |  \  /  |    /  ^  \     \  V  /  |
// |   /  /_\  \  \      /   |   __|     |  |  |  | |   __|     |  |\/|  | |  | |  . `  |     / _ \/\   |  |\/|  |   /  /_\  \     >   <   |
// |  /  _____  \  \    /    |  |____    |  `--'  | |  |        |  |  |  | |  | |  |\   |    | (_>  <   |  |  |  |  /  _____  \   /  .  \  |
// | /__/     \__\  \__/     |_______|    \______/  |__|        |__|  |__| |__| |__| \__|     \___/\/   |__|  |__| /__/     \__\ /__/ \__\ |
// |                                                                                                                                       |
// +=======================================================================================================================================+

reg  [7:0] avg_big_L1 [7:0], avg_small_L1 [7:0];
reg  [7:0] avg_big_L2 [3:0], avg_small_L2 [3:0];
reg  [7:0] avg_big_L3 [1:0], avg_small_L3 [1:0];
reg  [7:0] avg_big_L4, avg_small_L4;
reg  [7:0] avg_biggest, avg_smallest;
reg  en_avg_L1, en_avg_L2, en_avg_L3, en_avg_L4, en_avg_L5;
reg  [9:0] MaxRGB_sum, MinRGB_sum; // 255*3 need 10 bit, add 1 bit for div 3. qutient only 8 bit
reg  [8:0] Max_add_Min;
wire [2:0] MaxRGB_sub_of_div, MinRGB_sub_of_div;

assign en_avg_L1 = cs == WAIT_DRAM  && cnt256_avg != 'd0 && cnt256_avg < 'd195;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        en_avg_L2 <= 'd0;
        en_avg_L3 <= 'd0;
        en_avg_L4 <= 'd0;
        en_avg_L5 <= 'd0;
    end
    else  begin
        en_avg_L2 <= en_avg_L1;
        en_avg_L3 <= en_avg_L2;
        en_avg_L4 <= en_avg_L3;
        en_avg_L5 <= en_avg_L4;
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( i = 0; i <= 7; i = i + 1) begin
            avg_big_L1[i] <= 'd0;
            avg_small_L1[i] <= 'd0;
        end
    else if ( en_avg_L1 ) begin  //  you don't need else if
        for ( i = 0; i <= 7; i = i + 1) begin
            // {avg_big_L1[i] ,avg_small_L1[i] } <= (work[0][2*i] >= work[0][2*i+1]) ? {work[0][2*i], work[0][2*i+1]} : {work[0][2*i+1], work[0][2*i]};
            {avg_big_L1[i] ,avg_small_L1[i] } <= (work_avg[2*i] >= work_avg[2*i+1]) ? {work_avg[2*i], work_avg[2*i+1]} : {work_avg[2*i+1], work_avg[2*i]};
        end
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( i = 0; i <= 3; i = i + 1) begin
            avg_big_L2[i] <= 'd0;
            avg_small_L2[i] <= 'd0;
        end
    else if ( en_avg_L2) begin
        for ( i = 0; i <= 3; i = i + 1) begin
            avg_big_L2[i]    <= (avg_big_L1[2*i] >= avg_big_L1[2*i+1] ) ? avg_big_L1[2*i] : avg_big_L1[2*i+1];
            avg_small_L2[i]  <= (avg_small_L1[2*i] <= avg_small_L1[2*i+1] ) ? avg_small_L1[2*i] : avg_small_L1[2*i+1];
        end
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( i = 0; i <= 1; i = i + 1) begin
            avg_big_L3[i] <= 'd0;
            avg_small_L3[i] <= 'd0;
        end
    else if ( en_avg_L3) begin
        for ( i = 0; i <= 1; i = i + 1) begin
            avg_big_L3[i]    <= (avg_big_L2[2*i] >= avg_big_L2[2*i+1] ) ? avg_big_L2[2*i] : avg_big_L2[2*i+1];
            avg_small_L3[i]  <= (avg_small_L2[2*i] <= avg_small_L2[2*i+1] ) ? avg_small_L2[2*i] : avg_small_L2[2*i+1];
        end
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        avg_big_L4 <= 'd0;
        avg_small_L4 <= 'd0;
    end
    else if ( en_avg_L4) begin
        avg_big_L4    <= (avg_big_L3[0] >= avg_big_L3[1] ) ? avg_big_L3[0] : avg_big_L3[1];
        avg_small_L4  <= (avg_small_L3[0] <= avg_small_L3[1] ) ? avg_small_L3[0] : avg_small_L3[1];
    end
end


// when cnt256_avg == 68, 132, 196, R(max, min), G(max, min), B(max, min) are available
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        avg_biggest  <= 'd0;
        avg_smallest <= 'd255;
    end
    else if ( pat_end) begin
        avg_biggest  <= 'd0;
        avg_smallest <= 'd255;
    end
    else if ( en_avg_L4) begin
        avg_biggest   <= (avg_biggest  >= avg_big_L4 && cnt256_avg != 'd6 && cnt256_avg != 'd70 && cnt256_avg != 'd134 )   ? avg_biggest : avg_big_L4;
        avg_smallest  <= (avg_smallest <= avg_small_L4 && cnt256_avg != 'd6 && cnt256_avg != 'd70 && cnt256_avg != 'd134 ) ? avg_smallest : avg_small_L4;
        // avg_biggest   <= (avg_biggest  >= avg_big_L4 && cnt256_avg != 'd69 && cnt256_avg != 'd133 )   ? avg_biggest : avg_big_L4;
        // avg_smallest  <= (avg_smallest <= avg_small_L4 && cnt256_avg != 'd69 && cnt256_avg != 'd133 ) ? avg_smallest : avg_small_L4;
    end
end


assign MaxRGB_sub_of_div = MaxRGB_sum[9:7] - 3'd3 ;
assign MinRGB_sub_of_div = MinRGB_sum[9:7] - 3'd3 ;
assign Max_add_Min       = (MaxRGB_sum[7:0] + MinRGB_sum[7:0]) >> 1  ;

wire [7:0] Max_quotient, Min_quotient;
assign Max_quotient      = MaxRGB_sum[7:0];
assign Min_quotient      = MinRGB_sum[7:0];
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        MaxRGB_sum  <= 'd0;
    end
    else if ( pat_end) begin
        MaxRGB_sum  <= 'd0;
    end
    else if ( cnt256_avg == 'd70 || cnt256_avg == 'd134 || cnt256_avg == 'd198) begin
        MaxRGB_sum  <= MaxRGB_sum + avg_biggest;
    end
    else if ( cnt256_avg >= 'd199 && cnt256_avg <= 'd206) begin
        if(MaxRGB_sub_of_div[2]) begin
            MaxRGB_sum  <= {MaxRGB_sum[8:0], 1'd0 };
        end
        else begin
            MaxRGB_sum  <= {MaxRGB_sub_of_div[1:0], MaxRGB_sum[6:0], 1'd1 };
        end
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        MinRGB_sum  <= 'd0;
    end
    else if ( pat_end) begin
        MinRGB_sum  <= 'd0;
    end
    else if ( cnt256_avg == 'd70 || cnt256_avg == 'd134 || cnt256_avg == 'd198) begin
        MinRGB_sum  <= MinRGB_sum + avg_smallest;
    end
    else if ( cnt256_avg >= 'd199 && cnt256_avg <= 'd206) begin
        if(MinRGB_sub_of_div[2]) begin
            MinRGB_sum  <= {MinRGB_sum[8:0], 1'd0 };
        end
        else begin
            MinRGB_sum  <= {MinRGB_sub_of_div[1:0], MinRGB_sum[6:0], 1'd1 };
        end
    end
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
reg  out_valid_bkg;
reg  [7:0] out_data_bkg;



generate
for ( a = 0; a <= 15; a = a + 1) begin: val_tag_loop
    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            val_tag [a]    <= 'd0;
            avg_record [a] <= 'd0;
            focus_record [a] <= 'd0;
        end
        else if ( pat_end && cs == WAIT_DRAM && in_pic_no_reg == a ) begin
            if (in_mode_reg == 'd1) begin
                val_tag [a]    <= 'd0;
                avg_record [a] <= 'd0;
                focus_record [a] <= 'd0;
            end
            else begin
                val_tag [a]<= 'd1;
                avg_record [a] <= Max_add_Min;
                focus_record [a] <= output_pick_focus;
            end
        end
    end
end
endgenerate





always @(*) begin
    if (pat_end) begin
        if (cs == SKIP_DRAM  ) begin
            out_valid_bkg  = 'd1;
            out_data_bkg   = 'd0;
        end
        else if ( cs == DIRECT_OUT) begin
            case (in_mode_reg)
                0: begin
                    out_valid_bkg = 'd1;
                    out_data_bkg  = focus_record[in_pic_no_reg];
                end
                2: begin
                    out_valid_bkg  = 'd1;
                    out_data_bkg   = avg_record[in_pic_no_reg];
                end
                default: begin
                    out_valid_bkg  = 'd0;
                    out_data_bkg   = 'd0;
            end
            endcase
        end
        else begin
            case (in_mode_reg)
                0: begin
                    out_valid_bkg = 'd1;
                    out_data_bkg  = output_pick_focus;
                end
                1: begin
                    out_valid_bkg  =  'd1;
                    out_data_bkg   = Exp_18b_Total[17:10];
                end
                2: begin
                    out_valid_bkg  = 'd1;
                    out_data_bkg   = Max_add_Min;
                end
                default: begin
                    out_valid_bkg  = 'd1;
                    out_data_bkg   = 'd0;
            end
            endcase
        end
    end
    else begin
        out_valid_bkg = 'd0;
        out_data_bkg  = 'd0;
    end
end


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 'd0;
        out_data  <= 'd0;
    end
    else begin
        out_valid <= out_valid_bkg;
        out_data  <= out_data_bkg;
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

//============================================================
//
//                      READ DRAM
//
//============================================================

// -----------------------------
// // axi read address channel
// // src master
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        arid_s_inf      <= 'd0;
        arlen_s_inf     <= 'd0;
        arsize_s_inf    <= 'd0;
        arburst_s_inf   <= 'd0;
    end
    else begin
        arid_s_inf    <= 'b0000;
        if (in_valid)
            // arlen_s_inf   <= (in_mode != 'd0) ? 'd191 : 'd139;
            arlen_s_inf   <=  'd191 ;

        arsize_s_inf  <= 'b100;
        arburst_s_inf <= 'b01;

    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        araddr_s_inf <= 'd0;
    end
    else if ( cs == WAIT_DRAM && wait_dram_st_delay) begin
        araddr_s_inf <= 32'h10000 + (({{26'd0},(in_pic_no_reg*3)})<<10) ; //3072 = 32*32*3,  araddr_s_inf is available at cnt256 == 2
    end
end



always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        arvalid_s_inf <= 'd0;
    end
    else if ( cs == WAIT_DRAM && wait_dram_st_delay )begin
        arvalid_s_inf <= 'd1;
    end
    else if ( arvalid_s_inf == 'd1 && arready_s_inf == 'd1)begin
        arvalid_s_inf <= 'd0;
    end
end


// // src slave
// input          arready_s_inf,
// -----------------------------
// axi read data channel
// slave
// input [3:0]    rid_s_inf,
// input [127:0]  rdata_s_inf,
// input [1:0]    rresp_s_inf,
// input          rlast_s_inf,
// input          rvalid_s_inf,
// master
// reg  rready_s_inf;

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        rready_s_inf <= 'd0;
    else if ( cs == WAIT_DRAM &&  arready_s_inf == 'd1)
        rready_s_inf <= 'd1;
    else if ( rvalid_s_inf == 'd1)
        rready_s_inf <= !rlast_s_inf;
end
assign { rdata_arr[3 ], rdata_arr[2 ], rdata_arr[1 ], rdata_arr[0 ]} = rdata_s_inf[31 :0 ];
assign { rdata_arr[7 ], rdata_arr[6 ], rdata_arr[5 ], rdata_arr[4 ]} = rdata_s_inf[63 :32];
assign { rdata_arr[11], rdata_arr[10], rdata_arr[9 ], rdata_arr[8 ]} = rdata_s_inf[95 :64];
assign { rdata_arr[15], rdata_arr[14], rdata_arr[13], rdata_arr[12]} = rdata_s_inf[127:96];

always @( posedge clk ) begin
    for ( i = 0; i <= 15; i = i + 1)
        rdata_arr_reg[i] <= rdata_s_inf[8*i +: 8];
end

//============================================================
//
//                      WRITE DRAM
//
//============================================================

// axi write address channel
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awid_s_inf  <= 'd0;
        awsize_s_inf  <= 'b0;
        awburst_s_inf <= 'b0;
        awlen_s_inf   <= 'd0;
    end
    else begin
        awid_s_inf <= 'd0;
        awsize_s_inf <= 'b100;
        awburst_s_inf <= 'b01;
        awlen_s_inf <= 'd191;
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        awaddr_s_inf <= 'd0;
    else if (cs == WAIT_DRAM && wait_dram_st_delay)
        awaddr_s_inf <= 32'h10000 + (({{26'd0},(in_pic_no_reg*3)})<<10); //3072 = 32*32*3,  araddr_s_inf is available at cnt256 == 2
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        awvalid_s_inf <= 'd0;
    else if ( awvalid_s_inf == 'd1 && awready_s_inf == 'd1)
        awvalid_s_inf <= 'd0;
    else if (cs == WAIT_DRAM && wait_dram_st_delay && in_mode_reg == 'd1)
        awvalid_s_inf <= 'd1;

end





// axi write data channel
// reg  [127:0] wdata_s_inf;
// reg          wlast_s_inf;
// reg          wvalid_s_inf;


always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        wvalid_s_inf <= 'd0;
    else if ( wvalid_s_inf )
        wvalid_s_inf <= ~wlast_s_inf;
    else if ( cs == WAIT_DRAM && in_mode_reg == 'd1 )
        wvalid_s_inf <= rvalid_s_inf;
end

wire [7:0] wdata_arr[0:15];
// reg  [127:0]wdata_arr_work;
always @( * ) begin
    wdata_s_inf[31 :0 ] = { work_exposure[2][3 ], work_exposure[2][2 ], work_exposure[2][1 ], work_exposure[2][0 ]} ;
    wdata_s_inf[63 :32] = { work_exposure[2][7 ], work_exposure[2][6 ], work_exposure[2][5 ], work_exposure[2][4 ]} ;
    wdata_s_inf[95 :64] = { work_exposure[2][11], work_exposure[2][10], work_exposure[2][9 ], work_exposure[2][8 ]} ;
    wdata_s_inf[127:96] = { work_exposure[2][15], work_exposure[2][14], work_exposure[2][13], work_exposure[2][12]} ;
end


// always @( * ) begin
//     wdata_arr_work[31 :0 ] = { work[2][3 ], work[2][2 ], work[2][1 ], work[2][0 ]} ;
//     wdata_arr_work[63 :32] = { work[2][7 ], work[2][6 ], work[2][5 ], work[2][4 ]} ;
//     wdata_arr_work[95 :64] = { work[2][11], work[2][10], work[2][9 ], work[2][8 ]} ;
//     wdata_arr_work[127:96] = { work[2][15], work[2][14], work[2][13], work[2][12]} ;

// end
assign { wdata_arr[3 ], wdata_arr[2 ], wdata_arr[1 ], wdata_arr[0 ]} = wdata_s_inf[31 :0 ];
assign { wdata_arr[7 ], wdata_arr[6 ], wdata_arr[5 ], wdata_arr[4 ]} = wdata_s_inf[63 :32];
assign { wdata_arr[11], wdata_arr[10], wdata_arr[9 ], wdata_arr[8 ]} = wdata_s_inf[95 :64];
assign { wdata_arr[15], wdata_arr[14], wdata_arr[13], wdata_arr[12]} = wdata_s_inf[127:96];

reg  [7:0] wcnt256;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        wcnt256 <= 'd0;
    else if ( pat_end)
        wcnt256 <= 'd0;
    else if ( cs == WAIT_DRAM && in_mode_reg == 'd1 && wvalid_s_inf == 'd1 && wready_s_inf == 'd1 || wcnt256 != 'd0)
        wcnt256 <= wcnt256 + 'd1;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        wlast_s_inf <= 'd0;
    else if (wlast_s_inf)
        wlast_s_inf <= 'd0;
    else if ( cs == WAIT_DRAM && in_mode_reg == 'd1) begin
        wlast_s_inf <= (wcnt256 == 'd190 ) ? 'd1 :'d0;
    end
end


// -----------------------------
// axi write response channel
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        bready_s_inf <= 'd0;
    else if ( wvalid_s_inf == 'd1 && wready_s_inf == 'd1 )
        bready_s_inf <= 'd1;
    else if ( bready_s_inf == 'd1 && bvalid_s_inf == 'd1)
        bready_s_inf <= 'd0;
end




endmodule



module div9 (
    input clk,
    input rst_n,
    input enable,
    input [11:0] big,
    output  [7:0] shang,
    output  [3:0] yushu,
    output   done
);


reg [3:0] div_cnt;
reg [12:0] div_work;
always @( posedge clk or  negedge rst_n) begin
    if (!rst_n) begin
        div_cnt <= 'd0;
    end
    else if ( div_cnt == 'd10 ) begin
        div_cnt <= 'd0;
    end
    else if ( enable || div_cnt != 'd0 ) begin
        div_cnt <= div_cnt + 'd1;
    end
end

wire [4:0]div_work_sub9;
assign  div_work_sub9 = div_work[12:8] - 5'd9;

always @( posedge clk or  negedge rst_n) begin
    if (!rst_n) begin
        div_work <= 'd0;
    end
    else if ( enable && div_cnt == 'd0 ) begin
        div_work <= {1'd0, big };
    end
    else if ( div_cnt != 'd0 && div_cnt != 'd10) begin
        if ((div_work[12])|| (div_work[11] && ( | div_work[10:8])) )begin//  div_work[12:8] >= 5'd9 equals to (div_work[12] && ( | div_work[11:8]))            div_work[12:8] = 8 + any number
            div_work[12:9] <= (div_work_sub9[3:0]);
            div_work[8:0 ] <= {div_work[7:0 ], 1'd1};
        end
        else begin
            div_work[12:0] <= {div_work[11:0], 1'd0};
        end
    end
end

assign shang = div_work[7:0];
assign yushu = div_work[11:8];

assign done = (div_cnt == 'd10);

endmodule
