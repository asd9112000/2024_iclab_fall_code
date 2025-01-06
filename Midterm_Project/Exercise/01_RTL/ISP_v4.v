module ISP(
    // Input Signals
    input clk,
    input rst_n,
    input in_valid,
    input [3:0] in_pic_no,
    input       in_mode,
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
parameter  WORK2 = 3'd2;
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

reg [2:0] cs, ns;
reg [7:0] cnt256;
reg [7:0] cnt256_pre;

reg [3:0] in_pic_no_reg;
reg       in_mode_reg;
reg [1:0] in_ratio_mode_reg;




// Your Design

//============================================================
//
//                          END　SIGNAL
//
//============================================================


reg  set_end;
reg  pat_end;
reg  Dcontrast2X2_plus_end, Dcontrast2X2_plus_end_delay;
reg  Dcontrast4X4_plus_end, Dcontrast4X4_plus_end_delay;
reg  Dcontrast6X6_plus_end, Dcontrast6X6_plus_end_delay;
reg  auto_focus_end, auto_exp_end;
reg  exp_cal_delay, exp_cal_delay2, exp_cal_delay3, exp_cal_delay4;

always @( * ) begin
    set_end =  auto_focus_end || auto_exp_end;
    pat_end =  auto_focus_end || auto_exp_end;
    Dcontrast2X2_plus_end = cnt256 == 'd140 && cs == WAIT_DRAM && in_mode_reg == 'd0 ;
    Dcontrast4X4_plus_end = cnt256 == 'd143 && cs == WAIT_DRAM && in_mode_reg == 'd0 ;
    Dcontrast6X6_plus_end = cnt256 == 'd146 && cs == WAIT_DRAM && in_mode_reg == 'd0 ;
    auto_focus_end =  cs == WAIT_DRAM && in_mode_reg == 'd0 && cnt256 == 'd148 ;             //Dcontrast6X6_plus_end + 2

    // Dcontrast2X2_plus_end = cnt256 == 'd139 && cs == WAIT_DRAM && in_mode_reg == 'd0 ;
    // Dcontrast4X4_plus_end = cnt256 == 'd142 && cs == WAIT_DRAM && in_mode_reg == 'd0 ;
    // Dcontrast6X6_plus_end = cnt256 == 'd145 && cs == WAIT_DRAM && in_mode_reg == 'd0 ;
    // auto_focus_end =  cs == WAIT_DRAM && in_mode_reg == 'd0 && cnt256 == 'd147 ;             //Dcontrast6X6_plus_end + 2
    auto_exp_end   =  cs == WAIT_DRAM && in_mode_reg == 'd1 && !exp_cal_delay3 && exp_cal_delay4;
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
    end
    else begin
        Dcontrast2X2_plus_end_delay <= Dcontrast2X2_plus_end;
        Dcontrast4X4_plus_end_delay <= Dcontrast4X4_plus_end;
        Dcontrast6X6_plus_end_delay <= Dcontrast6X6_plus_end;
        wait_dram_st_delay <= wait_dram_st;
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
        IDLE :      ns = (in_valid) ? WAIT_DRAM : IDLE;
        WAIT_DRAM:  ns = (set_end || pat_end )? IDLE : WAIT_DRAM;
        WORK2: ns = IDLE;
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
    else if ( pat_end || set_end)
        cnt256 <= 'd0;
    else if ( rvalid_s_inf ||  cnt256 != 'd0 )
        cnt256 <= cnt256 +'d1;
end

// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         cnt256 <= 'd0;
//     else
//         cnt256 <= cnt256_pre;
// end



always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt256_pre <= 'd0;
    else if ( pat_end || set_end)
        cnt256_pre <= 'd0;
    else if ( rvalid_s_inf ||  cnt256 != 'd0 )
        cnt256_pre <= cnt256_pre +'d1;
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
        in_ratio_mode_reg   <= (in_mode) ? (in_ratio_mode) : 'd0;
    end
end



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


reg   [7:0] auto_focus_work_add [0:1][0:1][17:0]; // (G, RB) x (0, 1) x (0~5)
generate
for ( a=0; a<=1; a=a+1) begin :auto_focus_work_add_01
    for ( b=0; b<=17; b=b+1) begin : auto_focus_work_add_05
        always @(*) begin
                auto_focus_work_add[0][a][b] =  (rdata_arr_reg[b%6 ] >> 2) + work[a][b];
                auto_focus_work_add[1][a][b] =  (rdata_arr_reg[b%6 ] >> 1) + work[a][b];
        end
    end
end
endgenerate




// rdata_arr_reg[0~15] = rdata_s_inf[127:0];
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for ( i = 0; i <= 3; i = i + 1) begin
//             for ( j = 0; j <= 17; j = j + 1) begin
//                 work[i][j] <= 'd0;
//             end
//         end
//     end
//     else if ( pat_end || set_end) begin
//         for ( i = 0; i <= 3; i = i + 1) begin
//             for ( j = 0; j <= 17; j = j + 1) begin
//                 work[i][j] <= 'd0;
//             end
//         end
//     end
//     else if ( cs == WAIT_DRAM && in_mode_reg == 'd0) begin // auto focus
//         case (cnt256)
//         // for R
//         0 : begin
//             for ( i = 0; i <= 5; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][0][i];
//         end
//         2 : begin
//             for ( i = 6; i <= 11; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][0][i];
//         end
//         4 : begin
//             for ( i = 12; i <= 17; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][0][i];
//         end

//         6 :begin
//             for ( i = 0; i <= 5; i = i + 1)
//                 work[1][i ] <= auto_focus_work_add[0][1][i];
//         end
//         8 : begin
//             for ( i = 6; i <= 11; i = i + 1)
//                 work[1][i ] <= auto_focus_work_add[0][1][i];
//         end
//         10 : begin
//             for ( i = 12; i <= 17; i = i + 1)
//                 work[1][i ] <= auto_focus_work_add[0][1][i];
//         end

//         // for G
//         64 : begin
//             for ( i = 0; i <= 5; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[1][0][i];
//         end
//         66: begin
//             for ( i = 6; i <= 11; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[1][0][i];
//         end
//         68: begin
//             for ( i = 12; i <= 17; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[1][0][i];
//         end
//         70:begin
//             for ( i = 0; i <= 5; i = i + 1)
//                 work[1][i ] <= auto_focus_work_add[1][1][i];
//         end
//         72: begin
//             for ( i = 6; i <= 11; i = i + 1)
//                 work[1][i ] <= auto_focus_work_add[1][1][i];
//         end
//         74: begin
//             for ( i = 12; i <= 17; i = i + 1)
//                 work[1][i ] <= auto_focus_work_add[1][1][i];
//         end

//         // for B
//         128 : begin
//             for ( i = 0; i <= 5; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][0][i];
//         end
//         130: begin
//             for ( i = 6; i <= 11; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][0][i];
//         end

//         132: begin
//             work[0][0 ] <= work[0][6 ];
//             work[0][1 ] <= work[0][7 ];
//             work[0][2 ] <= work[0][8 ];
//             work[0][3 ] <= work[0][9 ];
//             work[0][4 ] <= work[0][10];
//             work[0][5 ] <= work[0][11];


//             for ( i = 6; i <= 11; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][0][i+6];
//         end
//         134:begin
//             work[0][0 ] <= work[0][6 ];
//             work[0][1 ] <= work[0][7 ];
//             work[0][2 ] <= work[0][8 ];
//             work[0][3 ] <= work[0][9 ];
//             work[0][4 ] <= work[0][10];
//             work[0][5 ] <= work[0][11];

//             for ( i = 6; i <= 11; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][1][i-6];
//         end
//         136: begin
//             work[0][0 ] <= work[0][6 ];
//             work[0][1 ] <= work[0][7 ];
//             work[0][2 ] <= work[0][8 ];
//             work[0][3 ] <= work[0][9 ];
//             work[0][4 ] <= work[0][10];
//             work[0][5 ] <= work[0][11];

//             for ( i = 6; i <= 11; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][1][i];
//         end
//         138: begin
//             work[0][0 ] <= work[0][6 ];
//             work[0][1 ] <= work[0][7 ];
//             work[0][2 ] <= work[0][8 ];
//             work[0][3 ] <= work[0][9 ];
//             work[0][4 ] <= work[0][10];
//             work[0][5 ] <= work[0][11];

//             for ( i = 6; i <= 11; i = i + 1)
//                 work[0][i ] <= auto_focus_work_add[0][1][i+6];
//         end
//         endcase
//     end
//     else if ( cs == WAIT_DRAM && in_mode_reg == 'd1) begin // auto exposure
//         if (  cnt256 < 'd192) begin
//             case ( in_ratio_mode_reg)
//             0: begin
//                 for ( i = 0; i <= 15; i = i + 1)
//                     work[0][i ] <= (rdata_arr_reg[i ] >> 2) ;
//                 end
//             1: begin
//                 for ( i = 0; i <= 15; i = i + 1)
//                     work[0][i ] <= (rdata_arr_reg[i ] >> 1 );
//             end
//             2: begin
//                 for ( i = 0; i <= 15; i = i + 1)
//                     work[0][i ] <= (rdata_arr_reg[i ]      );
//             end
//             3: begin
//                 for ( i = 0; i <= 15; i = i + 1)
//                     work[0][i ] <=  (rdata_arr_reg[i ][7]) ? 'd255 : (rdata_arr_reg[i ] << 1 );
//             end
//             endcase

//             for ( i = 0; i <= 2; i = i + 1) begin
//                 for ( j = 0; j < 32; j = j + 1) begin
//                     work[i+1][j ] <= work[i][j ] ;
//                 end
//             end
//         end
//         else if ( cnt256 == 'd192 || cnt256 == 'd193 || cnt256 == 'd194 || cnt256 == 'd195 ) begin
//             for ( j = 0; j < 32; j = j + 1) begin
//                 work[0][j ] <= 'd0 ;
//             end
//             for ( i = 0; i <= 2; i = i + 1) begin
//                 for ( j = 0; j < 32; j = j + 1) begin
//                     work[i+1][j ] <= work[i][j ] ;
//                 end
//             end
//         end
//     end
// end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i <= 2; i = i + 1) begin
            for ( j = 0; j <= 17; j = j + 1) begin
                work[i][j] <= 'd0;
            end
        end
    end
    else if ( pat_end || set_end) begin
        for ( i = 0; i <= 2; i = i + 1) begin
            for ( j = 0; j <= 17; j = j + 1) begin
                work[i][j] <= 'd0;
            end
        end
    end
    else if ( cs == WAIT_DRAM && in_mode_reg == 'd0) begin // auto focus
        case (cnt256)
        // for R
        1 : begin
            for ( i = 0; i <= 5; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][0][i];
        end
        3 : begin
            for ( i = 6; i <= 11; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][0][i];
        end
        5 : begin
            for ( i = 12; i <= 17; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][0][i];
        end

        7 :begin
            for ( i = 0; i <= 5; i = i + 1)
                work[1][i ] <= auto_focus_work_add[0][1][i];
        end
        9 : begin
            for ( i = 6; i <= 11; i = i + 1)
                work[1][i ] <= auto_focus_work_add[0][1][i];
        end
        11 : begin
            for ( i = 12; i <= 17; i = i + 1)
                work[1][i ] <= auto_focus_work_add[0][1][i];
        end

        // for G
        65 : begin
            for ( i = 0; i <= 5; i = i + 1)
                work[0][i ] <= auto_focus_work_add[1][0][i];
        end
        67: begin
            for ( i = 6; i <= 11; i = i + 1)
                work[0][i ] <= auto_focus_work_add[1][0][i];
        end
        69: begin
            for ( i = 12; i <= 17; i = i + 1)
                work[0][i ] <= auto_focus_work_add[1][0][i];
        end
        71:begin
            for ( i = 0; i <= 5; i = i + 1)
                work[1][i ] <= auto_focus_work_add[1][1][i];
        end
        73: begin
            for ( i = 6; i <= 11; i = i + 1)
                work[1][i ] <= auto_focus_work_add[1][1][i];
        end
        75: begin
            for ( i = 12; i <= 17; i = i + 1)
                work[1][i ] <= auto_focus_work_add[1][1][i];
        end

        // for B
        129 : begin
            for ( i = 0; i <= 5; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][0][i];
        end
        131: begin
            for ( i = 6; i <= 11; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][0][i];
        end

        133: begin
            work[0][0 ] <= work[0][6 ];
            work[0][1 ] <= work[0][7 ];
            work[0][2 ] <= work[0][8 ];
            work[0][3 ] <= work[0][9 ];
            work[0][4 ] <= work[0][10];
            work[0][5 ] <= work[0][11];


            for ( i = 6; i <= 11; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][0][i+6];
        end
        135:begin
            work[0][0 ] <= work[0][6 ];
            work[0][1 ] <= work[0][7 ];
            work[0][2 ] <= work[0][8 ];
            work[0][3 ] <= work[0][9 ];
            work[0][4 ] <= work[0][10];
            work[0][5 ] <= work[0][11];

            for ( i = 6; i <= 11; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][1][i-6];
        end
        137: begin
            work[0][0 ] <= work[0][6 ];
            work[0][1 ] <= work[0][7 ];
            work[0][2 ] <= work[0][8 ];
            work[0][3 ] <= work[0][9 ];
            work[0][4 ] <= work[0][10];
            work[0][5 ] <= work[0][11];

            for ( i = 6; i <= 11; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][1][i];
        end
        139: begin
            work[0][0 ] <= work[0][6 ];
            work[0][1 ] <= work[0][7 ];
            work[0][2 ] <= work[0][8 ];
            work[0][3 ] <= work[0][9 ];
            work[0][4 ] <= work[0][10];
            work[0][5 ] <= work[0][11];

            for ( i = 6; i <= 11; i = i + 1)
                work[0][i ] <= auto_focus_work_add[0][1][i+6];
        end
        endcase
    end
    else if ( cs == WAIT_DRAM && in_mode_reg == 'd1) begin // auto exposure
        if (  cnt256 < 'd194) begin
            case ( in_ratio_mode_reg)
            0: begin
                for ( i = 0; i <= 15; i = i + 1)
                    work[0][i ] <= (rdata_arr_reg[i ] >> 2) ;
                end
            1: begin
                for ( i = 0; i <= 15; i = i + 1)
                    work[0][i ] <= (rdata_arr_reg[i ] >> 1 );
            end
            2: begin
                for ( i = 0; i <= 15; i = i + 1)
                    work[0][i ] <= (rdata_arr_reg[i ]      );
            end
            3: begin
                for ( i = 0; i <= 15; i = i + 1)
                    work[0][i ] <=  (rdata_arr_reg[i ][7]) ? 'd255 : (rdata_arr_reg[i ] << 1 );
            end
            endcase

            for ( i = 0; i <= 2; i = i + 1) begin
                for ( j = 0; j < 32; j = j + 1) begin
                    work[i+1][j ] <= work[i][j ] ;
                end
            end
        end
        else if ( cnt256 == 'd193 || cnt256 == 'd194 || cnt256 == 'd195 ||  cnt256 == 'd196) begin
            for ( j = 0; j < 32; j = j + 1) begin
                work[0][j ] <= 'd0 ;
            end
            for ( i = 0; i <= 1; i = i + 1) begin
                for ( j = 0; j < 32; j = j + 1) begin
                    work[i+1][j ] <= work[i][j ] ;
                end
            end
        end
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
reg  [5:0]  cntDcontrast;
reg  [7:0]  DiffH[0:4], DiffV[0:5];
reg  [8:0]  DiffSum[0:2];
reg  [7:0]  DiffR[0:4], DiffL[0:4],DiffUP[0:5];

reg  [4:0] DiffH_PreCmp;
reg  [5:0] DiffV_PreCmp;

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cntDcontrast <= 'd0;
    else if ( pat_end || set_end)
        cntDcontrast <= 'd0;
    else if ( cs == WAIT_DRAM && cnt256 == 'd129 || cntDcontrast != 'd0) begin
        cntDcontrast <= cntDcontrast + 'd1;
    end
end
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         cntDcontrast <= 'd0;
//     else if ( pat_end || set_end)
//         cntDcontrast <= 'd0;
//     else if ( cs == WAIT_DRAM && cnt256 == 'd128 || cntDcontrast != 'd0) begin
//         cntDcontrast <= cntDcontrast + 'd1;
//     end
// end



// DiffH_PreCmp
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        DiffH_PreCmp <= 'd0;
    else if ( pat_end || set_end)
        DiffH_PreCmp <= 'd0;
    else if ( cnt256 == 'd129 ) begin
        for ( i=0 ; i<= 4 ;i=i+1)
            DiffH_PreCmp [i] <= (auto_focus_work_add[0][0][i]) >= (auto_focus_work_add[0][0][i+1]);
            // DiffH_PreCmp [i] <= ((rdata_arr[i ] >> 2) + work[0][i] ) >= ( (rdata_arr[i+1 ] >> 2) + work[0][i+1]);
    end
    else if ( cnt256 == 'd131 ) begin
        for ( i=0 ; i<= 4 ;i=i+1)
            DiffH_PreCmp [i] <= (auto_focus_work_add[0][0][i+6] ) >= (auto_focus_work_add[0][0][i+7]);
    end
    else if ( cnt256 == 'd133 ) begin
        for ( i=0 ; i<= 4 ;i=i+1)
            DiffH_PreCmp [i] <= (auto_focus_work_add[0][0][i+12] ) >= ( auto_focus_work_add[0][0][i+13]);
    end
    else if ( cnt256 == 'd135 ) begin
        for ( i=0 ; i<= 4 ;i=i+1)
            DiffH_PreCmp [i] <= (auto_focus_work_add[0][1][i] ) >= ( auto_focus_work_add[0][1][i+1]);
    end
    else if ( cnt256 == 'd137 ) begin
        for ( i=0 ; i<= 4 ;i=i+1)
            DiffH_PreCmp [i] <= (auto_focus_work_add[0][1][i+6] ) >= ( auto_focus_work_add[0][1][i+7]);
    end
    else if ( cnt256 == 'd139 ) begin
        for ( i=0 ; i<= 4 ;i=i+1)
            DiffH_PreCmp [i] <= (auto_focus_work_add[0][1][i+12] ) >= ( auto_focus_work_add[0][1][i+13]);
    end
end


// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         DiffH_PreCmp <= 'd0;
//     else if ( pat_end || set_end)
//         DiffH_PreCmp <= 'd0;
//     else if ( cnt256 == 'd128 ) begin
//         for ( i=0 ; i<= 4 ;i=i+1)
//             DiffH_PreCmp [i] <= (auto_focus_work_add[0][0][i]) >= (auto_focus_work_add[0][0][i+1]);
//             // DiffH_PreCmp [i] <= ((rdata_arr[i ] >> 2) + work[0][i] ) >= ( (rdata_arr[i+1 ] >> 2) + work[0][i+1]);
//     end
//     else if ( cnt256 == 'd130 ) begin
//         for ( i=0 ; i<= 4 ;i=i+1)
//             DiffH_PreCmp [i] <= (auto_focus_work_add[0][0][i+6] ) >= (auto_focus_work_add[0][0][i+7]);
//     end
//     else if ( cnt256 == 'd132 ) begin
//         for ( i=0 ; i<= 4 ;i=i+1)
//             DiffH_PreCmp [i] <= (auto_focus_work_add[0][0][i+12] ) >= ( auto_focus_work_add[0][0][i+13]);
//     end
//     else if ( cnt256 == 'd134 ) begin
//         for ( i=0 ; i<= 4 ;i=i+1)
//             DiffH_PreCmp [i] <= (auto_focus_work_add[0][1][i] ) >= ( auto_focus_work_add[0][1][i+1]);
//     end
//     else if ( cnt256 == 'd136 ) begin
//         for ( i=0 ; i<= 4 ;i=i+1)
//             DiffH_PreCmp [i] <= (auto_focus_work_add[0][1][i+6] ) >= ( auto_focus_work_add[0][1][i+7]);
//     end
//     else if ( cnt256 == 'd138 ) begin
//         for ( i=0 ; i<= 4 ;i=i+1)
//             DiffH_PreCmp [i] <= (auto_focus_work_add[0][1][i+12] ) >= ( auto_focus_work_add[0][1][i+13]);
//     end
// end


// DiffV_PreCmp
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        DiffV_PreCmp <= 'd0;
    else if ( pat_end || set_end)
        DiffV_PreCmp <= 'd0;
    else if ( cnt256 == 'd131 ) begin
        for ( i=0 ; i<= 5 ;i=i+1)
            DiffV_PreCmp [i] <= (work[0][i   ] ) >= (auto_focus_work_add[0][0][i+6]);
//             DiffV_PreCmp [i] <= (work[0][i   ] ) >= ( (rdata_arr[i ] >> 2) + work[0][i+6]);
    end
    else if ( cnt256 == 'd133 ) begin
        for ( i=0 ; i<= 5 ;i=i+1)
            DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= (auto_focus_work_add[0][0][i+12]);
//             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= ( (rdata_arr[i ] >> 2) + work[0][i+12]);
    end
    else if ( cnt256 == 'd135 ) begin
        for ( i=0 ; i<= 5 ;i=i+1)
            DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= (auto_focus_work_add[0][1][i]);
//             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= ( (rdata_arr[i ] >> 2) + work[1][i]);
    end
    else if ( cnt256 == 'd137 ) begin
        for ( i=0 ; i<= 5 ;i=i+1)
            DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= (auto_focus_work_add[0][1][i+6]);
//             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= ( (rdata_arr[i ] >> 2) + work[1][i+6]);
    end
    else if ( cnt256 == 'd139 ) begin
        for ( i=0 ; i<= 5 ;i=i+1)
            DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= (auto_focus_work_add[0][1][i+12]);
//             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= ( (rdata_arr[i ] >> 2) + work[1][i+12]);
    end
end













// // DiffV_PreCmp
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         DiffV_PreCmp <= 'd0;
//     else if ( pat_end || set_end)
//         DiffV_PreCmp <= 'd0;
//     else if ( cnt256 == 'd130 ) begin
//         for ( i=0 ; i<= 5 ;i=i+1)
//             DiffV_PreCmp [i] <= (work[0][i   ] ) >= (auto_focus_work_add[0][0][i+6]);
// //             DiffV_PreCmp [i] <= (work[0][i   ] ) >= ( (rdata_arr[i ] >> 2) + work[0][i+6]);
//     end
//     else if ( cnt256 == 'd132 ) begin
//         for ( i=0 ; i<= 5 ;i=i+1)
//             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= (auto_focus_work_add[0][0][i+12]);
// //             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= ( (rdata_arr[i ] >> 2) + work[0][i+12]);
//     end
//     else if ( cnt256 == 'd134 ) begin
//         for ( i=0 ; i<= 5 ;i=i+1)
//             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= (auto_focus_work_add[0][1][i]);
// //             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= ( (rdata_arr[i ] >> 2) + work[1][i]);
//     end
//     else if ( cnt256 == 'd136 ) begin
//         for ( i=0 ; i<= 5 ;i=i+1)
//             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= (auto_focus_work_add[0][1][i+6]);
// //             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= ( (rdata_arr[i ] >> 2) + work[1][i+6]);
//     end
//     else if ( cnt256 == 'd138 ) begin
//         for ( i=0 ; i<= 5 ;i=i+1)
//             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= (auto_focus_work_add[0][1][i+12]);
// //             DiffV_PreCmp [i] <= (work[0][i+6 ] ) >= ( (rdata_arr[i ] >> 2) + work[1][i+12]);
//     end
// end



// DiffH : 6,4,2 use DiffH [i] 0~4, 1~3, 2, 6 sets,
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( i =0 ; i<=4 ; i=i+1) begin
            DiffH [i] <= 'd0 ;
        end
    else if ( set_end || pat_end )
        for ( i =0 ; i<=4 ; i=i+1) begin
            DiffH [i] <= 'd0 ;
        end
    else if ( cnt256 == 'd130 ) begin
        for ( i =0 ; i<=4 ; i=i+1) begin
            // DiffH [i] <= (work[0][i] >= work[0][i+1]) ? work[0][i] - work[0][i+1] : work[0][i+1] - work[0][i];
            DiffH [i] <= (DiffH_PreCmp[i]) ? work[0][i] - work[0][i+1] : work[0][i+1] - work[0][i];
        end
    end
    else if (   cnt256 == 'd132 || cnt256 == 'd134 || cnt256 == 'd136 ||  cnt256 == 'd138 || cnt256 == 'd140  )begin
        for ( i =0 ; i<=4 ; i=i+1) begin
            // DiffH [i] <= (work[0][i+6] >= work[0][i+7]) ? work[0][i+6] - work[0][i+7] : work[0][i+7] - work[0][i+6];
            DiffH [i] <= (DiffH_PreCmp[i]) ? work[0][i+6] - work[0][i+7] : work[0][i+7] - work[0][i+6];
        end
    end
end





// // DiffH : 6,4,2 use DiffH [i] 0~4, 1~3, 2, 6 sets,
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         for ( i =0 ; i<=4 ; i=i+1) begin
//             DiffH [i] <= 'd0 ;
//         end
//     else if ( set_end || pat_end )
//         for ( i =0 ; i<=4 ; i=i+1) begin
//             DiffH [i] <= 'd0 ;
//         end
//     else if ( cnt256 == 'd129 ) begin
//         for ( i =0 ; i<=4 ; i=i+1) begin
//             // DiffH [i] <= (work[0][i] >= work[0][i+1]) ? work[0][i] - work[0][i+1] : work[0][i+1] - work[0][i];
//             DiffH [i] <= (DiffH_PreCmp[i]) ? work[0][i] - work[0][i+1] : work[0][i+1] - work[0][i];
//         end
//     end
//     else if (   cnt256 == 'd131 || cnt256 == 'd133 || cnt256 == 'd135
//             ||  cnt256 == 'd137 || cnt256 == 'd139  )begin
//         for ( i =0 ; i<=4 ; i=i+1) begin
//             // DiffH [i] <= (work[0][i+6] >= work[0][i+7]) ? work[0][i+6] - work[0][i+7] : work[0][i+7] - work[0][i+6];
//             DiffH [i] <= (DiffH_PreCmp[i]) ? work[0][i+6] - work[0][i+7] : work[0][i+7] - work[0][i+6];
//         end
//     end
// end



// DiffV : 6,4,2 use DiffH [i] 0~5, 1~4, 2~3, 5 sets
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( j =0 ; j<=5 ; j=j+1) begin
            DiffV [j] <= 'd0 ;
        end
    else if ( set_end || pat_end )
        for (  j =0 ; j<=5 ; j=j+1) begin
            DiffV [j] <= 'd0 ;
        end
    else if (   cnt256 == 'd132 || cnt256 == 'd134 || cnt256 == 'd136 ||  cnt256 == 'd138 || cnt256 == 'd140  )begin
        for (  j =0 ; j<=5 ; j=j+1) begin
            // DiffV [j] <= (work[0][j] >= work[0][j+6]) ? work[0][j] - work[0][j+6] : work[0][j+6] - work[0][j] ;
            DiffV [j] <= (DiffV_PreCmp [j]) ? work[0][j] - work[0][j+6] : work[0][j+6] - work[0][j] ;
        end
    end
end




// // DiffV : 6,4,2 use DiffH [i] 0~5, 1~4, 2~3, 5 sets
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         for ( j =0 ; j<=5 ; j=j+1) begin
//             DiffV [j] <= 'd0 ;
//         end
//     else if ( set_end || pat_end )
//         for (  j =0 ; j<=5 ; j=j+1) begin
//             DiffV [j] <= 'd0 ;
//         end
//     else if (   cnt256 == 'd131 || cnt256 == 'd133 || cnt256 == 'd135
//             ||  cnt256 == 'd137 || cnt256 == 'd139  )begin
//         for (  j =0 ; j<=5 ; j=j+1) begin
//             // DiffV [j] <= (work[0][j] >= work[0][j+6]) ? work[0][j] - work[0][j+6] : work[0][j+6] - work[0][j] ;
//             DiffV [j] <= (DiffV_PreCmp [j]) ? work[0][j] - work[0][j+6] : work[0][j+6] - work[0][j] ;
//         end
//     end
// end



reg  [8 :0 ] DcontrastL1 [5:0];
reg  [9 :0 ] DcontrastL2 [2:0];
reg  [10:0 ] DcontrastL3 [1:0];
reg  [11:0 ] DcontrastL4 ;

reg  [9:0 ] DcontrastL2NoV [2:1];
reg  [10:0 ] DcontrastL3NoV ;


//DcontrastL1
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for ( i = 0; i <= 5; i = i + 1)
            DcontrastL1[i] <= 'd0;
    else if ( pat_end || set_end)
        for ( i = 0; i <= 5; i = i + 1)
            DcontrastL1[i] <= 'd0;
    else if ( cs == WAIT_DRAM  && cnt256 >= 'd131 &&  cnt256 <= 'd141) begin
            DcontrastL1[0] <= DiffV[0] + DiffV[5];
            DcontrastL1[1] <= DiffV[1] + DiffV[4];
            DcontrastL1[2] <= DiffV[2] + DiffV[3];
            DcontrastL1[3] <= DiffH[0] + DiffH[4];
            DcontrastL1[4] <= DiffH[1] + DiffH[3];
            DcontrastL1[5] <= DiffH[2] ;
    end
end


// //DcontrastL1
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         for ( i = 0; i <= 5; i = i + 1)
//             DcontrastL1[i] <= 'd0;
//     else if ( pat_end || set_end)
//         for ( i = 0; i <= 5; i = i + 1)
//             DcontrastL1[i] <= 'd0;
//     else if ( cs == WAIT_DRAM  && cnt256 >= 'd130 &&  cnt256 <= 'd140) begin
//             DcontrastL1[0] <= DiffV[0] + DiffV[5];
//             DcontrastL1[1] <= DiffV[1] + DiffV[4];
//             DcontrastL1[2] <= DiffV[2] + DiffV[3];
//             DcontrastL1[3] <= DiffH[0] + DiffH[4];
//             DcontrastL1[4] <= DiffH[1] + DiffH[3];
//             DcontrastL1[5] <= DiffH[2] ;
//     end
// end

//DcontrastL2
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i <= 2; i = i + 1)
            DcontrastL2[i] <= 'd0;
        DcontrastL2NoV[1] <= 'd0;
        DcontrastL2NoV[2] <= 'd0;
    end
    else if ( pat_end || set_end)begin
        for ( i = 0; i <= 2; i = i + 1)
            DcontrastL2[i] <= 'd0;
        DcontrastL2NoV[1] <= 'd0;
        DcontrastL2NoV[2] <= 'd0;
    end
    else if ( cs == WAIT_DRAM  && cnt256 >= 'd132 &&  cnt256 <= 'd142) begin
            DcontrastL2[0] <= DcontrastL1[0] + DcontrastL1[3];
            DcontrastL2[1] <= DcontrastL1[1] + DcontrastL1[4];
            DcontrastL2[2] <= DcontrastL1[2] + DcontrastL1[5];
            DcontrastL2NoV[1] <= DcontrastL1[4];
            DcontrastL2NoV[2] <= DcontrastL1[5];
    end
end

// //DcontrastL2
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for ( i = 0; i <= 2; i = i + 1)
//             DcontrastL2[i] <= 'd0;
//         DcontrastL2NoV[1] <= 'd0;
//         DcontrastL2NoV[2] <= 'd0;
//     end
//     else if ( pat_end || set_end)begin
//         for ( i = 0; i <= 2; i = i + 1)
//             DcontrastL2[i] <= 'd0;
//         DcontrastL2NoV[1] <= 'd0;
//         DcontrastL2NoV[2] <= 'd0;
//     end
//     else if ( cs == WAIT_DRAM  && cnt256 >= 'd131 &&  cnt256 <= 'd141) begin
//             DcontrastL2[0] <= DcontrastL1[0] + DcontrastL1[3];
//             DcontrastL2[1] <= DcontrastL1[1] + DcontrastL1[4];
//             DcontrastL2[2] <= DcontrastL1[2] + DcontrastL1[5];
//             DcontrastL2NoV[1] <= DcontrastL1[4];
//             DcontrastL2NoV[2] <= DcontrastL1[5];
//     end
// end



//DcontrastL3
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i <= 1; i = i + 1)
            DcontrastL3[i] <= 'd0;
        DcontrastL3NoV <= 'd0;
    end
    else if ( pat_end || set_end) begin
        for ( i = 0; i <= 1; i = i + 1)
            DcontrastL3[i] <= 'd0;
        DcontrastL3NoV <= 'd0;
    end
    else if ( cs == WAIT_DRAM && cnt256 >= 'd133 &&  cnt256 <= 'd143) begin
        DcontrastL3[0] <= {1'd0, DcontrastL2[0]};
        DcontrastL3[1] <= DcontrastL2[1] + DcontrastL2[2];
        DcontrastL3NoV <= DcontrastL2NoV[1] + DcontrastL2NoV[2];
    end
end




// //DcontrastL3
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         for ( i = 0; i <= 1; i = i + 1)
//             DcontrastL3[i] <= 'd0;
//         DcontrastL3NoV <= 'd0;
//     end
//     else if ( pat_end || set_end) begin
//         for ( i = 0; i <= 1; i = i + 1)
//             DcontrastL3[i] <= 'd0;
//         DcontrastL3NoV <= 'd0;
//     end
//     else if ( cs == WAIT_DRAM && cnt256 >= 'd132 &&  cnt256 <= 'd142) begin
//         DcontrastL3[0] <= {1'd0, DcontrastL2[0]};
//         DcontrastL3[1] <= DcontrastL2[1] + DcontrastL2[2];
//         DcontrastL3NoV <= DcontrastL2NoV[1] + DcontrastL2NoV[2];
//     end
// end




//DcontrastL4
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
            DcontrastL4 <= 'd0;
    else if ( pat_end || set_end)
            DcontrastL4 <= 'd0;
    else if ( cs == WAIT_DRAM  && cnt256 >= 'd134 &&  cnt256 <= 'd144) begin
            DcontrastL4 <= DcontrastL3[0]+DcontrastL3[1];
    end
end


// //DcontrastL4
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//             DcontrastL4 <= 'd0;
//     else if ( pat_end || set_end)
//             DcontrastL4 <= 'd0;
//     else if ( cs == WAIT_DRAM  && cnt256 >= 'd133 &&  cnt256 <= 'd143) begin
//             DcontrastL4 <= DcontrastL3[0]+DcontrastL3[1];
//     end
// end




reg  [13:0] Dcontrast6X6;
reg  [12:0] Dcontrast4X4;
reg  [10:0] Dcontrast2X2;

//Dcontrast6X6;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        Dcontrast6X6 <= 'd0;
    else if ( pat_end || set_end)
        Dcontrast6X6 <= 'd0;
    else if (  Dcontrast6X6_plus_end) begin // avalible from cnt256 == 146
        Dcontrast6X6 <= {2'd0, (Dcontrast6X6[13:2] / 'd9)};
    end
    else if ( cs == WAIT_DRAM  &&
        (cnt256 == 'd135 || cnt256 == 'd137 || cnt256 == 'd139 || cnt256 == 'd141 || cnt256 == 'd143 || cnt256 == 'd145 )) begin
        Dcontrast6X6 <= DcontrastL4 + (Dcontrast6X6);
    end
end

// //Dcontrast6X6;
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         Dcontrast6X6 <= 'd0;
//     else if ( pat_end || set_end)
//         Dcontrast6X6 <= 'd0;
//     else if (  Dcontrast6X6_plus_end) begin // avalible from cnt256 == 146
//         Dcontrast6X6 <= {2'd0, (Dcontrast6X6[13:2] / 'd9)};
//     end
//     else if ( cs == WAIT_DRAM  &&
//         (cnt256 == 'd134 || cnt256 == 'd136 || cnt256 == 'd138 || cnt256 == 'd140 || cnt256 == 'd142 || cnt256 == 'd144 )) begin
//         Dcontrast6X6 <= DcontrastL4 + (Dcontrast6X6);
//     end
// end


//Dcontrast4X4
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        Dcontrast4X4 <= 'd0;
    else if ( pat_end || set_end)
        Dcontrast4X4 <= 'd0;
    else if (  Dcontrast4X4_plus_end) begin  // avalible from cnt256 == 143
        Dcontrast4X4 <= Dcontrast4X4 >> 4;
    end
    else if ( cs == WAIT_DRAM  && cnt256 == 'd136) begin
        Dcontrast4X4 <=  Dcontrast4X4 + DcontrastL3NoV;
    end
    else if ( cs == WAIT_DRAM  && ( cnt256 == 'd138 || cnt256 == 'd140 || cnt256 == 'd142 )) begin
        Dcontrast4X4 <=  Dcontrast4X4 + DcontrastL3[1];
    end
end


// //Dcontrast4X4
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         Dcontrast4X4 <= 'd0;
//     else if ( pat_end || set_end)
//         Dcontrast4X4 <= 'd0;
//     else if (  Dcontrast4X4_plus_end) begin  // avalible from cnt256 == 143
//         Dcontrast4X4 <= Dcontrast4X4 >> 4;
//     end
//     else if ( cs == WAIT_DRAM  && cnt256 == 'd135) begin
//         Dcontrast4X4 <=  Dcontrast4X4 + DcontrastL3NoV;
//     end
//     else if ( cs == WAIT_DRAM  && ( cnt256 == 'd137 || cnt256 == 'd139 || cnt256 == 'd141 )) begin
//         Dcontrast4X4 <=  Dcontrast4X4 + DcontrastL3[1];
//     end
// end




//Dcontrast2X2
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        Dcontrast2X2 <= 'd0;
    else if ( pat_end || set_end)
        Dcontrast2X2 <= 'd0;
    else if (  Dcontrast2X2_plus_end) begin // avalible from cnt256 == 140
        Dcontrast2X2 <= Dcontrast2X2 >> 2;
    end
    else if ( cs == WAIT_DRAM  && cnt256 == 'd137 ) begin
        Dcontrast2X2 <=  Dcontrast2X2 + DcontrastL2NoV[2];
    end
    else if ( cs == WAIT_DRAM  && cnt256 == 'd139 ) begin
        Dcontrast2X2 <=  Dcontrast2X2 + DcontrastL2[2];
    end
end


// //Dcontrast2X2
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         Dcontrast2X2 <= 'd0;
//     else if ( pat_end || set_end)
//         Dcontrast2X2 <= 'd0;
//     else if (  Dcontrast2X2_plus_end) begin // avalible from cnt256 == 140
//         Dcontrast2X2 <= Dcontrast2X2 >> 2;
//     end
//     else if ( cs == WAIT_DRAM  && cnt256 == 'd136 ) begin
//         Dcontrast2X2 <=  Dcontrast2X2 + DcontrastL2NoV[2];
//     end
//     else if ( cs == WAIT_DRAM  && cnt256 == 'd138 ) begin
//         Dcontrast2X2 <=  Dcontrast2X2 + DcontrastL2[2];
//     end
// end


reg  [2:0] output_pick_focus;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        output_pick_focus <= 'd0;
    else if ( pat_end || set_end)
        output_pick_focus <= 'd0;
    else if (  Dcontrast4X4_plus_end_delay) begin
        output_pick_focus <= (Dcontrast2X2 >= Dcontrast4X4) ? 'd0 : 'd1;
    end
    else if ( Dcontrast6X6_plus_end_delay ) begin
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
assign exp_cal =  cs == WAIT_DRAM && in_mode_reg == 'd1 && cnt256 >= 'd1 && cnt256 <= 'd192;

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
reg  [7:0] cnt256_delay;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt256_delay <= 'd0;
    else
        cnt256_delay <= cnt256;

end
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for (i=0; i <= 7 ; i=i+1)
            Exp_9bL1[i] <= 'd0;
    else if ( pat_end || set_end)
        for (i=0; i <= 7 ; i=i+1)
            Exp_9bL1[i] <= 'd0;
    else if ( exp_cal ) begin
        case (cnt256_delay[7:6])
            0: begin
                for (i=0; i <= 7; i=i+1)
                    Exp_9bL1[i] <= (work[0][2*i] >> 2 )+ (work[0][2*i+1] >>2);
            end
            1: begin
                for (i=0; i <= 7; i=i+1)
                    Exp_9bL1[i] <= (work[0][2*i] >> 1 )+ (work[0][2*i+1] >>1);
            end
            2: begin
                for (i=0; i <= 7; i=i+1)
                    Exp_9bL1[i] <= (work[0][2*i] >> 2 )+ (work[0][2*i+1] >>2);
            end
            default: ;
        endcase
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for (i=0; i <= 3 ; i=i+1)
            Exp_10bL2[i] <= 'd0;
    else if ( pat_end || set_end)
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
    else if ( pat_end || set_end)
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
    else if ( pat_end || set_end)
            Exp_12bL4 <= 'd0;
    else if ( exp_cal_delay3) begin
            Exp_12bL4 <= Exp_11bL3 [0] + Exp_11bL3 [1];
    end
end

// reg  [17:0]Exp_18b_Total;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
            Exp_18b_Total <= 'd0;
    else if ( pat_end || set_end)
            Exp_18b_Total <= 'd0;
    else if ( exp_cal_delay4) begin
            Exp_18b_Total <= Exp_12bL4  +Exp_18b_Total;
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

// always @(*) begin
//     if ( in_mode_reg == 'd0 && cs == WAIT_DRAM  && cnt256 == 'd147) begin
//         out_valid_test = 'd1;
//         out_data_test = output_pick_focus;
//     end
//     else if (in_mode_reg == 'd0 && cs == WAIT_DRAM  && exp_cal_delay4 && !exp_cal_delay3)begin
//         out_valid_test =  'd1;
//         out_data_test = Exp_18b_Total[7:0];
//     end
// end


always @(*) begin
    if (auto_focus_end) begin
        out_valid = 'd1;
        out_data  = output_pick_focus;
    end
    else if ( auto_exp_end)begin
        out_valid  =  'd1;
        out_data   = Exp_18b_Total[17:10];
    end
    else begin
        out_valid = 'd0;
        out_data  = 'd0;
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
            arlen_s_inf   <= (in_mode) ? 'd191 : 'd139;

        arsize_s_inf  <= 'b100;
        arburst_s_inf <= 'b01;

    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        araddr_s_inf <= 'd0;
    end
    else if ( cs == WAIT_DRAM && wait_dram_st_delay) begin
        if ( in_mode_reg)
            araddr_s_inf <= 32'h10000 + (({{26'd0},(in_pic_no_reg*3)})<<10) ; //3072 = 32*32*3,  araddr_s_inf is available at cnt256 == 2
            // araddr_s_inf <= 32'h10000 + in_pic_no_reg* 'd3072 ; //3072 = 32*32*3,  araddr_s_inf is available at cnt256 == 2
        else
            araddr_s_inf <= 32'h10000 + (({{26'd0},(in_pic_no_reg*3)})<<10) + 'd429; //3072 = 32*32*3,  araddr_s_inf is available at cnt256 == 2
            // araddr_s_inf <= 32'h10000 +  in_pic_no_reg* 'd3072 + 'd429; //3072 = 32*32*3,  araddr_s_inf is available at cnt256 == 2
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
always @( * ) begin
    wdata_s_inf[31 :0 ] = { work[2][3 ], work[2][2 ], work[2][1 ], work[2][0 ]} ;
    wdata_s_inf[63 :32] = { work[2][7 ], work[2][6 ], work[2][5 ], work[2][4 ]} ;
    wdata_s_inf[95 :64] = { work[2][11], work[2][10], work[2][9 ], work[2][8 ]} ;
    wdata_s_inf[127:96] = { work[2][15], work[2][14], work[2][13], work[2][12]} ;
    // wdata_s_inf = cnt256;
end

assign { wdata_arr[3 ], wdata_arr[2 ], wdata_arr[1 ], wdata_arr[0 ]} = wdata_s_inf[31 :0 ];
assign { wdata_arr[7 ], wdata_arr[6 ], wdata_arr[5 ], wdata_arr[4 ]} = wdata_s_inf[63 :32];
assign { wdata_arr[11], wdata_arr[10], wdata_arr[9 ], wdata_arr[8 ]} = wdata_s_inf[95 :64];
assign { wdata_arr[15], wdata_arr[14], wdata_arr[13], wdata_arr[12]} = wdata_s_inf[127:96];

reg  [7:0] wcnt256;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        wcnt256 <= 'd0;
    else if ( pat_end || set_end)
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


