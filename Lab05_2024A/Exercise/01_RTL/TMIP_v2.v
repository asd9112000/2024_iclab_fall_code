module TMIP(
    // input signals
    clk,
    rst_n,
    in_valid,
    in_valid2,

    image,
    template,
    image_size,
	action,

    // output signals
    out_valid,
    out_value
    );

input            clk, rst_n;
input            in_valid, in_valid2;

input      [7:0] image;
input      [7:0] template;
input      [1:0] image_size;
input      [2:0] action;

output reg       out_valid;
output reg       out_value;

//==================================================================
// parameter & integer
//==================================================================

parameter  IDLE           = 4'd15;
parameter  INPUT_DATA     = 4'd14;
parameter  INPUT_ACT      = 4'd13;


parameter GRAY_MAX        = 4'd0 ;
parameter GRAY_AVG        = 4'd1 ;
parameter GRAY_WIGHT      = 4'd2 ;
parameter MAX_POOLING     = 4'd3 ;
parameter NEGATIVE        = 4'd4 ;
parameter HORIZONTAL_FLIP = 4'd5 ;
parameter IMAGE_FILTER    = 4'd6 ;
parameter CROSS_COR       = 4'd7 ;

integer i,j,k,l, m,n,o,p,q, a,b,c, x,y,z;
//==================================================================
// reg & wire
//==================================================================
reg WEBA,WEBB;
reg  [5:0]  MemA_adr, MemB_adr;
reg  [31:0] MemA_Di, MemB_Di;
wire [31:0] MemA_Do, MemB_Do;

reg  WEBGrayMax, WEBGrayAvg, WEBGrayWight;
reg  [5:0]  MemGrayMax_adr, MemGrayAvg_adr, MemGrayWight_adr;
reg  [31:0] MemGrayMax_Di, MemGrayAvg_Di, MemGrayWight_Di;
wire [31:0] MemGrayMax_Do, MemGrayAvg_Do, MemGrayWight_Do;

// reg [31:0] MemA_Do_reg, MemB_Do_reg, MemGrayMax_Do_reg, MemGrayAvg_Do_reg, MemGrayWight_Do_reg;
reg [31:0] MemA_Do_reg, MemB_Do_reg, MemGrayMax_Do_reg, MemGrayAvg_Do_reg, MemGrayWight_Do_reg;

reg [3:0] cs, ns;

//==================================================================
// design
//==================================================================




//MemA_Di
always @( * ) begin
    case (cs)

    endcase
end

//MemB_Di
always @( * ) begin

end


//Mem A B output port reg
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        MemA_Do_reg <= 'd0;
        MemB_Do_reg <= 'd0;
    end
    else begin
        MemA_Do_reg <= MemA_Do;
        MemB_Do_reg <= MemB_Do;
    end
end


MEM_TEST MemA(  .A0(MemA_adr[0]), .A1(MemA_adr[1]), .A2(MemA_adr[2]), .A3(MemA_adr[3]), .A4(MemA_adr[4]), .A5(MemA_adr[5]),
                .DO0 (MemA_Do[0 ]), .DO1 (MemA_Do[1 ]), .DO2 (MemA_Do[2 ]), .DO3 (MemA_Do[3 ]), .DO4 (MemA_Do[4 ]), .DO5 (MemA_Do[5 ]), .DO6 (MemA_Do[6 ]), .DO7 (MemA_Do[7 ]),
                .DO8 (MemA_Do[8 ]), .DO9 (MemA_Do[9 ]), .DO10(MemA_Do[10]), .DO11(MemA_Do[11]), .DO12(MemA_Do[12]), .DO13(MemA_Do[13]), .DO14(MemA_Do[14]), .DO15(MemA_Do[15]),
                .DO16(MemA_Do[16]), .DO17(MemA_Do[17]), .DO18(MemA_Do[18]), .DO19(MemA_Do[19]), .DO20(MemA_Do[20]), .DO21(MemA_Do[21]), .DO22(MemA_Do[22]), .DO23(MemA_Do[23]),
                .DO24(MemA_Do[24]), .DO25(MemA_Do[25]), .DO26(MemA_Do[26]), .DO27(MemA_Do[27]), .DO28(MemA_Do[28]), .DO29(MemA_Do[29]), .DO30(MemA_Do[30]), .DO31(MemA_Do[31]),
                .DI0 (MemA_Di[0 ]), .DI1 (MemA_Di[1 ]), .DI2 (MemA_Di[2 ]), .DI3 (MemA_Di[3 ]), .DI4 (MemA_Di[4 ]), .DI5 (MemA_Di[5 ]), .DI6 (MemA_Di[6] ), .DI7 (MemA_Di[7 ]),
                .DI8 (MemA_Di[8 ]), .DI9 (MemA_Di[9 ]), .DI10(MemA_Di[10]), .DI11(MemA_Di[11]), .DI12(MemA_Di[12]), .DI13(MemA_Di[13]), .DI14(MemA_Di[14]), .DI15(MemA_Di[15]),
                .DI16(MemA_Di[16]), .DI17(MemA_Di[17]), .DI18(MemA_Di[18]), .DI19(MemA_Di[19]), .DI20(MemA_Di[20]), .DI21(MemA_Di[21]), .DI22(MemA_Di[22]), .DI23(MemA_Di[23]),
                .DI24(MemA_Di[24]), .DI25(MemA_Di[25]), .DI26(MemA_Di[26]), .DI27(MemA_Di[27]), .DI28(MemA_Di[28]), .DI29(MemA_Di[29]), .DI30(MemA_Di[30]), .DI31(MemA_Di[31]),
                .CK(clk), .WEB(WEBA), .OE(1'd1), .CS(1'd1));

MEM_TEST MemB(  .A0(MemB_adr[0]), .A1(MemB_adr[1]), .A2(MemB_adr[2]), .A3(MemB_adr[3]), .A4(MemB_adr[4]), .A5(MemB_adr[5]),
                .DO0 (MemB_Do[0 ]), .DO1 (MemB_Do[1 ]), .DO2 (MemB_Do[2 ]), .DO3 (MemB_Do[3 ]), .DO4 (MemB_Do[4 ]), .DO5 (MemB_Do[5 ]), .DO6 (MemB_Do[6 ]), .DO7 (MemB_Do[7 ]),
                .DO8 (MemB_Do[8 ]), .DO9 (MemB_Do[9 ]), .DO10(MemB_Do[10]), .DO11(MemB_Do[11]), .DO12(MemB_Do[12]), .DO13(MemB_Do[13]), .DO14(MemB_Do[14]), .DO15(MemB_Do[15]),
                .DO16(MemB_Do[16]), .DO17(MemB_Do[17]), .DO18(MemB_Do[18]), .DO19(MemB_Do[19]), .DO20(MemB_Do[20]), .DO21(MemB_Do[21]), .DO22(MemB_Do[22]), .DO23(MemB_Do[23]),
                .DO24(MemB_Do[24]), .DO25(MemB_Do[25]), .DO26(MemB_Do[26]), .DO27(MemB_Do[27]), .DO28(MemB_Do[28]), .DO29(MemB_Do[29]), .DO30(MemB_Do[30]), .DO31(MemB_Do[31]),
                .DI0 (MemB_Di[0 ]), .DI1 (MemB_Di[1 ]), .DI2 (MemB_Di[2 ]), .DI3 (MemB_Di[3 ]), .DI4 (MemB_Di[4 ]), .DI5 (MemB_Di[5 ]), .DI6 (MemB_Di[6] ), .DI7 (MemB_Di[7 ]),
                .DI8 (MemB_Di[8 ]), .DI9 (MemB_Di[9 ]), .DI10(MemB_Di[10]), .DI11(MemB_Di[11]), .DI12(MemB_Di[12]), .DI13(MemB_Di[13]), .DI14(MemB_Di[14]), .DI15(MemB_Di[15]),
                .DI16(MemB_Di[16]), .DI17(MemB_Di[17]), .DI18(MemB_Di[18]), .DI19(MemB_Di[19]), .DI20(MemB_Di[20]), .DI21(MemB_Di[21]), .DI22(MemB_Di[22]), .DI23(MemB_Di[23]),
                .DI24(MemB_Di[24]), .DI25(MemB_Di[25]), .DI26(MemB_Di[26]), .DI27(MemB_Di[27]), .DI28(MemB_Di[28]), .DI29(MemB_Di[29]), .DI30(MemB_Di[30]), .DI31(MemB_Di[31]),
                .CK(clk), .WEB(WEBB), .OE(1'd1), .CS(1'd1));


reg input_data_end;
reg input_act_end;
reg set_end;
reg pattern_end;
reg gray_max_end;
reg gray_avg_end;
reg gray_wight_end;
reg max_pooling_end;
reg negative_end;
reg horizontal_flip_end;
reg image_filter_end;
reg cross_cor_end;


reg [9:0] img_cnt;
reg [1:0] img_size_reg;
reg [7:0] template_reg [8:0];
reg [2:0] act_cnt;
reg [2:0] act_reg [7:0];
wire [3:0] nact ;
assign nact = {1'd0,act_reg[0]};//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//==================================================================
// cs ns
//==================================================================

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cs <= INPUT_DATA;
    else cs <= ns;
end

always @( *) begin
    case (cs)
        // IDLE            : ns = in_valid ?
        INPUT_DATA      : ns = input_data_end      ? INPUT_ACT : cs ;
        INPUT_ACT       : ns = input_act_end       ? nact : cs ;
        // GRAY_MAX        : ns = GRAY_MAX_END        ? nact : cs ;
        // GRAY_AVG        : ns = GRAY_AVG_END        ? nact : cs ;
        // GRAY_WIGHT      : ns = GRAY_WIGHT_END      ? nact : cs ;
        MAX_POOLING     : ns = max_pooling_end     ? nact : cs ;
        NEGATIVE        : ns = negative_end        ? nact : cs ;
        HORIZONTAL_FLIP : ns = horizontal_flip_end ? nact : cs ;
        IMAGE_FILTER    : ns = image_filter_end    ? nact : cs ;
        CROSS_COR       : ns = cross_cor_end       ? nact : cs ;
    default:    ns = IDLE;
    endcase
end


//==================================================================
// img_cnt, img_size_reg, template_reg
//==================================================================


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) img_cnt <= 'd0;
    else if (pattern_end) img_cnt <= 'd0;
    else if (in_valid) img_cnt <= img_cnt + 'd1;
    else img_cnt <= img_cnt;
end


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) img_size_reg <= 'd0;
    else if ( cs == INPUT_DATA & img_cnt == 'd0) img_size_reg <= image_size ;
    else img_size_reg <= img_size_reg;
end


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for ( i=0 ; i<9 ; i=i+1) template_reg[i]  <= 'd0;
    else if ( cs == INPUT_DATA )
        case (img_cnt)
            0: template_reg [0] = template;
            1: template_reg [1] = template;
            2: template_reg [2] = template;
            3: template_reg [3] = template;
            4: template_reg [4] = template;
            5: template_reg [5] = template;
            6: template_reg [6] = template;
            7: template_reg [7] = template;
            8: template_reg [8] = template;
            default: for ( i=0 ; i<9 ; i=i+1) template_reg[i]  <= template_reg[i];
        endcase
end



//==================================================================
// act_reg
//==================================================================


always @( posedge clk or negedge rst_n) begin   // if act_reg = 5, it means there are 5 actions should be done.
    if (!rst_n) act_cnt <= 'd0;
    else if (set_end | pattern_end ) act_cnt <= 'd0;
    else if (in_valid2) act_cnt <= act_cnt + 'd1;
    else act_cnt <= act_cnt;
end


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for ( i=0 ; i<8 ; i=i+1) act_reg[i]  <= 'd0;
    // else if (set_end | pattern_end ) act_reg <= 'd0;
    else if ( cs == INPUT_ACT)
        case (act_cnt)
            0: act_reg [0] = action;
            1: act_reg [1] = action;
            2: act_reg [2] = action;
            3: act_reg [3] = action;
            4: act_reg [4] = action;
            5: act_reg [5] = action;
            6: act_reg [6] = action;
            7: act_reg [7] = action;
            default: for ( i=0 ; i<8 ; i=i+1) act_reg[i]  <= act_reg[i];
        endcase
    else if ( max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end ) begin
            act_reg [0] = act_reg [1] ;
            act_reg [1] = act_reg [2] ;
            act_reg [2] = act_reg [3] ;
            act_reg [3] = act_reg [4] ;
            act_reg [4] = act_reg [5] ;
            act_reg [5] = act_reg [6] ;
            act_reg [6] = act_reg [7] ;
            act_reg [7] = 'd0         ;
    end

end




//==================================================================
// work_reg
//==================================================================

reg [7:0] work_reg [0:3] [0:15];
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for (i=0 ;i<4;i=i+1)for(j=0;j<16;j=j+1)work_reg[i][j] <= 'd0;
    else if ( cs == INPUT_DATA)
        case (img_cnt%3)
            0: work_reg [0] <=  image;
            1: work_reg [1] <=  image;
            2: work_reg [2] <=  image;
            default:   for (i=0 ;i<4;i=i+1)for(j=0;j<16;j=j+1)work_reg[i][j] <= work_reg[i][j];
        endcase
end




//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
always @(*) begin
    out_valid = cs == MAX_POOLING;
end




//==================================================================
// GrayMax GrayAvg, GrayWeight
//==================================================================


//Mem Gray outptu port reg
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        MemGrayMax_Do_reg <= 'd0;
        MemGrayAvg_Do_reg <= 'd0;
        MemGrayWight_Do_reg <= 'd0;
    end
    else begin
        MemGrayMax_Do_reg <= MemGrayMax_Do;
        MemGrayAvg_Do_reg <= MemGrayAvg_Do;
        MemGrayWight_Do_reg <= MemGrayWight_Do;
    end
end


wire [7:0] gray_max_med_pe, gray_avg, gray_weight;
Med_PE Gray_Max_Med_PE (
    .A  (work_reg[0][0]),
    .B  (work_reg[0][1]),
    .C  (work_reg[0][2]),
    .max(gray_max_med_pe)
    );
assign gray_avg = (work_reg[0][0][31:0] + work_reg[0][1][31:0] + work_reg[0][2][31:0]) / 'd3;
assign gray_weight = (work_reg[0][0][31:0] >> 4) + (work_reg[0][1][31:0] >> 2 ) + ( work_reg[0][2][31:0] >> 4);


reg [7:0] mem_w_buf_gray_max [3:0], mem_w_buf_gray_avg [3:0], mem_w_buf_gray_weight [3:0];
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for (i=0 ;i<4;i=i+1) mem_w_buf_gray_max[i][j] <= 'd0;
    else if ( cs == INPUT_DATA)
        case (img_cnt)
            3 , 15, 27, 39, 51, 63, 75, 87, 99 , 111, 123, 135, 147, 159 : mem_w_buf_gray_max [0] <=  gray_max_med_pe;
            6 , 18, 30, 42, 54, 66, 78, 90, 102, 114, 126, 138, 150, 162 : mem_w_buf_gray_max [1] <=  gray_max_med_pe;
            9 , 21, 33, 45, 57, 69, 81, 93, 105, 117, 129, 141, 153, 165 : mem_w_buf_gray_max [2] <=  gray_max_med_pe;
            12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 132, 144, 156, 168 : mem_w_buf_gray_max [2] <=  gray_max_med_pe;
            default:   for (i=0 ;i<4;i=i+1)mem_w_buf_gray_max[i] <= mem_w_buf_gray_max[i];
        endcase
end


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for (i=0 ;i<4;i=i+1) mem_w_buf_gray_avg[i][j] <= 'd0;
    else if ( cs == INPUT_DATA)
        case (img_cnt)
            3 , 15, 27, 39, 51, 63, 75, 87, 99 , 111, 123, 135, 147, 159 : mem_w_buf_gray_avg [0] <=  gray_avg;
            6 , 18, 30, 42, 54, 66, 78, 90, 102, 114, 126, 138, 150, 162 : mem_w_buf_gray_avg [1] <=  gray_avg;
            9 , 21, 33, 45, 57, 69, 81, 93, 105, 117, 129, 141, 153, 165 : mem_w_buf_gray_avg [2] <=  gray_avg;
            12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 132, 144, 156, 168 : mem_w_buf_gray_avg [2] <=  gray_avg;
            default:   for (i=0 ;i<4;i=i+1)mem_w_buf_gray_avg[i] <= mem_w_buf_gray_avg[i];
        endcase
end


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for (i=0 ;i<4;i=i+1) mem_w_buf_gray_weight[i][j] <= 'd0;
    else if ( cs == INPUT_DATA)
        case (img_cnt)
            3 , 15, 27, 39, 51, 63, 75, 87, 99 , 111, 123, 135, 147, 159 : mem_w_buf_gray_weight[0] <= gray_weight;
            6 , 18, 30, 42, 54, 66, 78, 90, 102, 114, 126, 138, 150, 162 : mem_w_buf_gray_weight[1] <= gray_weight;
            9 , 21, 33, 45, 57, 69, 81, 93, 105, 117, 129, 141, 153, 165 : mem_w_buf_gray_weight[2] <= gray_weight;
            12, 24, 36, 48, 60, 72, 84, 96, 108, 120, 132, 144, 156, 168 : mem_w_buf_gray_weight[3] <= gray_weight;
            default: for (i = 0; i < 4; i = i + 1) em_w_buf_gray_weight[i] <= mem_w_buf_gray_weight[i];
        endcase
end





//MemGrayMax_Di & MemGrayMax_adr & WEBGrayMax
always @( * ) begin
    case (cs)
        INPUT_DATA: WEBGrayMax = img_cnt % 'd12 = 0
    endcase
end

always @( * ) begin
    case (cs)
        INPUT_DATA: MemGrayMax_Di = {gray_max_med_pe, mem_w_buf [2], mem_w_buf [1], mem_w_buf [0]}
    endcase
end

always @( * ) begin
    case (cs)
        INPUT_DATA: MemGrayMax_adr = {gray_max_med_pe, mem_w_buf [2], mem_w_buf [1], mem_w_buf [0]}
    endcase
end


//MemGrayAvg_Di
always @( * ) begin
    case (cs)
        INPUT_DATA: MemGrayAvg_Di = {gray_avg, mem_w_buf [2], mem_w_buf [1], mem_w_buf [0]}
    endcase
end

// MemGrayWight_Di
always @( * ) begin
    case (cs)
        INPUT_DATA: MemGrayWight_Di = {gray_weight, mem_w_buf [2], mem_w_buf [1], mem_w_buf [0]}
    endcase
end



MEM_TEST MemGrayMax(  .A0(MemGrayMax_adr[0]), .A1(MemGrayMax_adr[1]), .A2(MemGrayMax_adr[2]), .A3(MemGrayMax_adr[3]), .A4(MemGrayMax_adr[4]), .A5(MemGrayMax_adr[5]),
                .DO0 (MemGrayMax_Do[0 ]), .DO1 (MemGrayMax_Do[1 ]), .DO2 (MemGrayMax_Do[2 ]), .DO3 (MemGrayMax_Do[3 ]), .DO4 (MemGrayMax_Do[4 ]), .DO5 (MemGrayMax_Do[5 ]), .DO6 (MemGrayMax_Do[6 ]), .DO7 (MemGrayMax_Do[7 ]),
                .DO8 (MemGrayMax_Do[8 ]), .DO9 (MemGrayMax_Do[9 ]), .DO10(MemGrayMax_Do[10]), .DO11(MemGrayMax_Do[11]), .DO12(MemGrayMax_Do[12]), .DO13(MemGrayMax_Do[13]), .DO14(MemGrayMax_Do[14]), .DO15(MemGrayMax_Do[15]),
                .DO16(MemGrayMax_Do[16]), .DO17(MemGrayMax_Do[17]), .DO18(MemGrayMax_Do[18]), .DO19(MemGrayMax_Do[19]), .DO20(MemGrayMax_Do[20]), .DO21(MemGrayMax_Do[21]), .DO22(MemGrayMax_Do[22]), .DO23(MemGrayMax_Do[23]),
                .DO24(MemGrayMax_Do[24]), .DO25(MemGrayMax_Do[25]), .DO26(MemGrayMax_Do[26]), .DO27(MemGrayMax_Do[27]), .DO28(MemGrayMax_Do[28]), .DO29(MemGrayMax_Do[29]), .DO30(MemGrayMax_Do[30]), .DO31(MemGrayMax_Do[31]),
                .DI0 (MemGrayMax_Di[0 ]), .DI1 (MemGrayMax_Di[1 ]), .DI2 (MemGrayMax_Di[2 ]), .DI3 (MemGrayMax_Di[3 ]), .DI4 (MemGrayMax_Di[4 ]), .DI5 (MemGrayMax_Di[5 ]), .DI6 (MemGrayMax_Di[6] ), .DI7 (MemGrayMax_Di[7 ]),
                .DI8 (MemGrayMax_Di[8 ]), .DI9 (MemGrayMax_Di[9 ]), .DI10(MemGrayMax_Di[10]), .DI11(MemGrayMax_Di[11]), .DI12(MemGrayMax_Di[12]), .DI13(MemGrayMax_Di[13]), .DI14(MemGrayMax_Di[14]), .DI15(MemGrayMax_Di[15]),
                .DI16(MemGrayMax_Di[16]), .DI17(MemGrayMax_Di[17]), .DI18(MemGrayMax_Di[18]), .DI19(MemGrayMax_Di[19]), .DI20(MemGrayMax_Di[20]), .DI21(MemGrayMax_Di[21]), .DI22(MemGrayMax_Di[22]), .DI23(MemGrayMax_Di[23]),
                .DI24(MemGrayMax_Di[24]), .DI25(MemGrayMax_Di[25]), .DI26(MemGrayMax_Di[26]), .DI27(MemGrayMax_Di[27]), .DI28(MemGrayMax_Di[28]), .DI29(MemGrayMax_Di[29]), .DI30(MemGrayMax_Di[30]), .DI31(MemGrayMax_Di[31]),
                .CK(clk), .WEB(WEBGrayMax), .OE(1'd1), .CS(1'd1));

MEM_TEST MemGrayAvg(  .A0(MemGrayAvg_adr[0]), .A1(MemGrayAvg_adr[1]), .A2(MemGrayAvg_adr[2]), .A3(MemGrayAvg_adr[3]), .A4(MemGrayAvg_adr[4]), .A5(MemGrayAvg_adr[5]),
                .DO0 (MemGrayAvg_Do[0 ]), .DO1 (MemGrayAvg_Do[1 ]), .DO2 (MemGrayAvg_Do[2 ]), .DO3 (MemGrayAvg_Do[3 ]), .DO4 (MemGrayAvg_Do[4 ]), .DO5 (MemGrayAvg_Do[5 ]), .DO6 (MemGrayAvg_Do[6 ]), .DO7 (MemGrayAvg_Do[7 ]),
                .DO8 (MemGrayAvg_Do[8 ]), .DO9 (MemGrayAvg_Do[9 ]), .DO10(MemGrayAvg_Do[10]), .DO11(MemGrayAvg_Do[11]), .DO12(MemGrayAvg_Do[12]), .DO13(MemGrayAvg_Do[13]), .DO14(MemGrayAvg_Do[14]), .DO15(MemGrayAvg_Do[15]),
                .DO16(MemGrayAvg_Do[16]), .DO17(MemGrayAvg_Do[17]), .DO18(MemGrayAvg_Do[18]), .DO19(MemGrayAvg_Do[19]), .DO20(MemGrayAvg_Do[20]), .DO21(MemGrayAvg_Do[21]), .DO22(MemGrayAvg_Do[22]), .DO23(MemGrayAvg_Do[23]),
                .DO24(MemGrayAvg_Do[24]), .DO25(MemGrayAvg_Do[25]), .DO26(MemGrayAvg_Do[26]), .DO27(MemGrayAvg_Do[27]), .DO28(MemGrayAvg_Do[28]), .DO29(MemGrayAvg_Do[29]), .DO30(MemGrayAvg_Do[30]), .DO31(MemGrayAvg_Do[31]),
                .DI0 (MemGrayAvg_Di[0 ]), .DI1 (MemGrayAvg_Di[1 ]), .DI2 (MemGrayAvg_Di[2 ]), .DI3 (MemGrayAvg_Di[3 ]), .DI4 (MemGrayAvg_Di[4 ]), .DI5 (MemGrayAvg_Di[5 ]), .DI6 (MemGrayAvg_Di[6] ), .DI7 (MemGrayAvg_Di[7 ]),
                .DI8 (MemGrayAvg_Di[8 ]), .DI9 (MemGrayAvg_Di[9 ]), .DI10(MemGrayAvg_Di[10]), .DI11(MemGrayAvg_Di[11]), .DI12(MemGrayAvg_Di[12]), .DI13(MemGrayAvg_Di[13]), .DI14(MemGrayAvg_Di[14]), .DI15(MemGrayAvg_Di[15]),
                .DI16(MemGrayAvg_Di[16]), .DI17(MemGrayAvg_Di[17]), .DI18(MemGrayAvg_Di[18]), .DI19(MemGrayAvg_Di[19]), .DI20(MemGrayAvg_Di[20]), .DI21(MemGrayAvg_Di[21]), .DI22(MemGrayAvg_Di[22]), .DI23(MemGrayAvg_Di[23]),
                .DI24(MemGrayAvg_Di[24]), .DI25(MemGrayAvg_Di[25]), .DI26(MemGrayAvg_Di[26]), .DI27(MemGrayAvg_Di[27]), .DI28(MemGrayAvg_Di[28]), .DI29(MemGrayAvg_Di[29]), .DI30(MemGrayAvg_Di[30]), .DI31(MemGrayAvg_Di[31]),
                .CK(clk), .WEB(WEBGrayAvg), .OE(1'd1), .CS(1'd1));

MEM_TEST MemGrayWight(  .A0(MemGrayWight_adr[0]), .A1(MemGrayWight_adr[1]), .A2(MemGrayWight_adr[2]), .A3(MemGrayWight_adr[3]), .A4(MemGrayWight_adr[4]), .A5(MemGrayWight_adr[5]),
                .DO0 (MemGrayWight_Do[0 ]), .DO1 (MemGrayWight_Do[1 ]), .DO2 (MemGrayWight_Do[2 ]), .DO3 (MemGrayWight_Do[3 ]), .DO4 (MemGrayWight_Do[4 ]), .DO5 (MemGrayWight_Do[5 ]), .DO6 (MemGrayWight_Do[6 ]), .DO7 (MemGrayWight_Do[7 ]),
                .DO8 (MemGrayWight_Do[8 ]), .DO9 (MemGrayWight_Do[9 ]), .DO10(MemGrayWight_Do[10]), .DO11(MemGrayWight_Do[11]), .DO12(MemGrayWight_Do[12]), .DO13(MemGrayWight_Do[13]), .DO14(MemGrayWight_Do[14]), .DO15(MemGrayWight_Do[15]),
                .DO16(MemGrayWight_Do[16]), .DO17(MemGrayWight_Do[17]), .DO18(MemGrayWight_Do[18]), .DO19(MemGrayWight_Do[19]), .DO20(MemGrayWight_Do[20]), .DO21(MemGrayWight_Do[21]), .DO22(MemGrayWight_Do[22]), .DO23(MemGrayWight_Do[23]),
                .DO24(MemGrayWight_Do[24]), .DO25(MemGrayWight_Do[25]), .DO26(MemGrayWight_Do[26]), .DO27(MemGrayWight_Do[27]), .DO28(MemGrayWight_Do[28]), .DO29(MemGrayWight_Do[29]), .DO30(MemGrayWight_Do[30]), .DO31(MemGrayWight_Do[31]),
                .DI0 (MemGrayWight_Di[0 ]), .DI1 (MemGrayWight_Di[1 ]), .DI2 (MemGrayWight_Di[2 ]), .DI3 (MemGrayWight_Di[3 ]), .DI4 (MemGrayWight_Di[4 ]), .DI5 (MemGrayWight_Di[5 ]), .DI6 (MemGrayWight_Di[6] ), .DI7 (MemGrayWight_Di[7 ]),
                .DI8 (MemGrayWight_Di[8 ]), .DI9 (MemGrayWight_Di[9 ]), .DI10(MemGrayWight_Di[10]), .DI11(MemGrayWight_Di[11]), .DI12(MemGrayWight_Di[12]), .DI13(MemGrayWight_Di[13]), .DI14(MemGrayWight_Di[14]), .DI15(MemGrayWight_Di[15]),
                .DI16(MemGrayWight_Di[16]), .DI17(MemGrayWight_Di[17]), .DI18(MemGrayWight_Di[18]), .DI19(MemGrayWight_Di[19]), .DI20(MemGrayWight_Di[20]), .DI21(MemGrayWight_Di[21]), .DI22(MemGrayWight_Di[22]), .DI23(MemGrayWight_Di[23]),
                .DI24(MemGrayWight_Di[24]), .DI25(MemGrayWight_Di[25]), .DI26(MemGrayWight_Di[26]), .DI27(MemGrayWight_Di[27]), .DI28(MemGrayWight_Di[28]), .DI29(MemGrayWight_Di[29]), .DI30(MemGrayWight_Di[30]), .DI31(MemGrayWight_Di[31]),
                .CK(clk), .WEB(WEBGrayWight), .OE(1'd1), .CS(1'd1));
//==================================================================
// GrayAvg
//==================================================================



//==================================================================
// Max pooling
//==================================================================

//==================================================================
// Negative(x, y) = 255 – Grayscale(x, y
//==================================================================


//==================================================================
// Horizontal Flip
//==================================================================



//==================================================================
// Max pooling
//==================================================================






endmodule







module Med (
    input            clk  ,
    input            rst_n,
    input            st   ,
    input [7:0]      A    ,
    input [7:0]      B    ,
    input [7:0]      C    ,
    input [7:0]      D    ,
    input [7:0]      E    ,
    input [7:0]      F    ,
    input [7:0]      G    ,
    input [7:0]      H    ,
    input [7:0]      I    ,
    output reg [7:0] max  ,
    output reg [7:0] med  ,
    output reg [7:0] min
    );
    integer i,j,k,m,n,p,q;
    wire [7:0] max1[2:0], med1[2:0], min1[2:0];
    reg [7:0] max2[2:0], med2[2:0], min2[2:0];
    reg [7:0] Med_inA[2:0], Med_inB[2:0], Med_inC[2:0];
    reg st_delay, st_delay2;

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) st_delay <= 'd0;
        else st_delay <= st;
    end

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) st_delay2 <= 'd0;
        else st_delay2 <= st_delay;
    end

    always @(*) begin
        // if (st_delay) begin
        //     for (p=0 ; p<3 ; p=p+1) begin
        //     Med_inA [p] = max2[p];
        //     Med_inB [p] = med2[p];
        //     Med_inC [p] = min2[p];
        //     end
        // end
        // else if (st_delay2) begin
        //     for (n=0 ; n<3 ; n=n+1) begin
        //     Med_inA [n] = max2[2];
        //     Med_inB [n] = med2[1];
        //     Med_inC [n] = min2[0];
        //     end
        // end

        if (st_delay2) begin
            for (n=0 ; n<3 ; n=n+1) begin
            Med_inA [n] = max2[2];
            Med_inB [n] = med2[1];
            Med_inC [n] = min2[0];
            end
        end

        else if (st_delay) begin
            for (p=0 ; p<3 ; p=p+1) begin
            Med_inA [p] = max2[p];
            Med_inB [p] = med2[p];
            Med_inC [p] = min2[p];
            end
        end

        else begin
            Med_inA [0] = A;
            Med_inB [0] = B;
            Med_inC [0] = C;
            Med_inA [1] = D;
            Med_inB [1] = E;
            Med_inC [1] = F;
            Med_inA [2] = G;
            Med_inB [2] = H;
            Med_inC [2] = I;
        end
    end

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n)for (k= 0 ; k<3 ; k=k+1) max2[i] <= 'd0;
        else begin
            max2[0] <= max1[0];
            max2[1] <= med1[0];
            max2[2] <= min1[0];
        end
    end

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n)for (j = 0 ; j<3 ; j=j+1) med2[i] <= 'd0;
        else begin
            med2[0] <= max1[1];
            med2[1] <= med1[1];
            med2[2] <= min1[1];
        end
    end

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n)for (m = 0 ; m<3 ;m=m+1) min2[i] <= 'd0;
        else begin
            min2[0] <= max1[2];
            min2[1] <= med1[2];
            min2[2] <= min1[2];
        end
    end

    Med_PE Mid_PE1(
    .A  (Med_inA [0]),
    .B  (Med_inB [0]),
    .C  (Med_inC [0]),
    .max(max1[0][7:0]),
    .med(med1[0][7:0]),
    .min(min1[0][7:0])
    );

    Med_PE Mid_PE2(
    .A  (Med_inA [1]),
    .B  (Med_inB [1]),
    .C  (Med_inC [1]),
    .max(max1[1][7:0]),
    .med(med1[1][7:0]),
    .min(min1[1][7:0])
    );

    Med_PE Mid_PE3(
    .A  (Med_inA [2]),
    .B  (Med_inB [2]),
    .C  (Med_inC [2]),
    .max(max1[2][7:0]),
    .med(med1[2][7:0]),
    .min(min1[2][7:0])
    );

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            max <= 'd0;
            med <= 'd0;
            min <= 'd0;
        end
        // else if (st_delay2)begin
        //     max <= max1[0][7:0];
        //     med <= med1[0][7:0];
        //     min <= min1[0][7:0];
        // end
        else if (st_delay2)begin
            max <= max1[0][7:0];
            med <= med1[0][7:0];
            min <= min1[0][7:0];
        end
    end

endmodule


module Med_PE (
    input [7:0]      A  ,
    input [7:0]      B  ,
    input [7:0]      C  ,
    output reg [7:0] max,
    output reg [7:0] med,
    output reg [7:0] min
    );

    wire AbB, BbC, AbC;
    assign AbB = A > B;
    assign BbC = B > C;
    assign AbC = A > C;

    always @(*) begin
        casex ({ AbB, BbC, AbC})               // A B C
            'b100: {max,med, min} = {C, A, B}; // C>A>B C=A>B
            'b000: {max,med, min} = {C, B, A}; // C>B>A C=B=A C>B=A C=B>A C>A=B
            'b010: {max,med, min} = {B, C, A}; // B>C>A
            'b011: {max,med, min} = {B, A, C}; // B>A>C
            // 'b001: {max,med, min} = {B, A, C}; // NO CASE
            'b101: {max,med, min} = {A, C, B};
            // 'b110: {max,med, min} = {A, B, C}; // NO CASE
            'b111: {max,med, min} = {A, B, C}; // A>B>C
            default:   {max,med, min} = 'd0;
        endcase
    end

endmodule




//==================================================================
// Max pooling
//==================================================================

module MaxPooling_PE (
    input      [7:0] MP_i0,
    input      [7:0] MP_i1,
    input      [7:0] MP_i2,
    input      [7:0] MP_i3,
    output reg [7:0] MP_o
);

wire comp01,comp23,compbb;
wire [7:0] big0,big1;
assign comp01 = MP_i0 > MP_i1;
assign comp23 = MP_i2 > MP_i3;
assign big0 = (MP_i0 > MP_i1) ? MP_i0 : MP_i1;
assign big1 = (MP_i2 > MP_i3) ? MP_i2 : MP_i3;
assign MP_o = ( big0 > big1) ? big0 :  big1;

endmodule



//==================================================================
// Max pooling
//==================================================================