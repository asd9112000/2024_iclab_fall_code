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

parameter  IDLE           = 4'd13;
parameter  INPUT_DATA     = 4'd15;
parameter  INPUT_ACT      = 4'd14;
parameter  GRAY_CALL      = 4'd12;

parameter GRAY_MAX        = 4'd0 ;
parameter GRAY_AVG        = 4'd1 ;
parameter GRAY_WEIGHT     = 4'd2 ;
parameter MAX_POOLING     = 4'd3 ;
parameter NEGATIVE        = 4'd4 ;
parameter HORIZONTAL_FLIP = 4'd5 ;
parameter IMAGE_FILTER    = 4'd6 ;
parameter CROSS_COR       = 4'd7 ;

integer i,j,k,l, m,n,o,p,q, x,y,z;
genvar  a,b,c;
//==================================================================
// reg & wire
//==================================================================

reg set_end;      //one set includes 2~8 action
reg pattern_end;  //one  pattern inciude 8 set
reg input_data_end;
reg input_act_end;
reg input_act_end_delay;
reg input_act_end_delay2;
reg gray_end;
reg max_pooling_end;
reg negative_end;
reg horizontal_flip_end;
reg image_filter_end;
reg cross_cor_end;
reg cross_cor_end_delay;
reg in_valid2_has_come;

reg first_st;
reg [2:0] set_cnt;
reg [9:0] img_cnt;
reg [7:0] cnt256;
reg [7:0] cnt256_delay;
reg [1:0] img_size_reg;
reg [1:0] img_size_keep_reg;
reg [7:0] template_reg [8:0];
reg [2:0] act_num;// total num of act
reg [2:0] act_process;// process of doing action
reg [2:0] act_reg [7:0];
wire [3:0] nact ;
reg  [4:0] out_bit_cnt;
reg  [7:0] cross_out_cnt;
reg  WEBGray;
reg  [7:0]  MemGray_adr;
reg  [7:0] MemGrayMax_Di, MemGrayAvg_Di, MemGrayWeight_Di;
wire [7:0] MemGrayMax_Do, MemGrayAvg_Do, MemGrayWeight_Do;
reg  [3:0] cs, ns;
reg WSramA;



//==================================================================
// design
//==================================================================
reg [1:0] cnt_4;
reg [31:0]  Di_MP  , Di_Neg , Di_Hor , Di_Img , Di_Cro ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)  WSramA <= 'd0;
    else if (pattern_end | max_pooling_end |negative_end |horizontal_flip_end | image_filter_end | cross_cor_end) WSramA <= !WSramA;
end



//==================================================================
// cs ns
//==================================================================

//cs
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cs <= INPUT_DATA;
    else cs <= ns;
end

//ns
always @( *) begin
    case (cs)
        INPUT_DATA      : ns =  (input_data_end       ) ? INPUT_ACT : cs ;
        INPUT_ACT       : ns =  (input_act_end_delay2 ) ? nact : cs ;
        GRAY_CALL       : ns =  (gray_end             ) ? nact : cs ;
        MAX_POOLING     : ns =  (max_pooling_end      ) ? nact : cs ;
        NEGATIVE        : ns =  (negative_end         ) ? nact : cs ;
        HORIZONTAL_FLIP : ns =  (horizontal_flip_end  ) ? nact : cs ;
        IMAGE_FILTER    : ns =  (image_filter_end     ) ? nact : cs ;
        CROSS_COR       : ns =  (!cross_cor_end       ) ? cs :
                                ( pattern_end         ) ? INPUT_DATA : INPUT_ACT ;
    default:    ns = IDLE;
    endcase
end

// end signal
always @ (*) begin
    input_data_end      = (cs == INPUT_DATA      ) & (|img_cnt) & !in_valid;
    input_act_end       = (cs == INPUT_ACT       ) & (|cnt256 ) & gray_end ;
    negative_end        = (cs == NEGATIVE        ) & cnt256 == 'd1 ;
    horizontal_flip_end = (cs == HORIZONTAL_FLIP ) & cnt256 == 'd1 ;
    image_filter_end    = (cs == IMAGE_FILTER    ) & ((img_size_reg == 'd0 & cnt256 == 'd1) | (img_size_reg == 'd1 & cnt256 == 'd9) | (img_size_reg == 'd2 & cnt256 == 'd18)) ;
    max_pooling_end     = (cs == MAX_POOLING     ) & ((img_size_reg == 'd0 & cnt256 == 'd0) | (img_size_reg == 'd1 & cnt256 == 'd4) | (img_size_reg == 'd2 & cnt256 == 'd8));
    cross_cor_end       = (cs == CROSS_COR       ) & (  ( img_size_reg == 'd0 & out_bit_cnt == 'd19 & cross_out_cnt == 'd15) |
                                                        ( img_size_reg == 'd1 & out_bit_cnt == 'd19 & cross_out_cnt == 'd63) |
                                                        ( img_size_reg == 'd2 & out_bit_cnt == 'd19 & cross_out_cnt == 'd255)   );

    gray_end            = (img_size_reg == 'd0 & cnt256 == 'd15) | ( img_size_reg == 'd1 & cnt256 == 'd63) | ( img_size_reg == 'd2 & cnt256 == 'd255);
    set_end             = cross_cor_end;
    pattern_end         = set_end & (set_cnt == 'd7);
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cross_cor_end_delay <= 'd0;
        input_act_end_delay <= 'd0;
        input_act_end_delay2 <= 'd0;
    end
    else begin
        cross_cor_end_delay <= cross_cor_end;
        input_act_end_delay <= input_act_end;
        input_act_end_delay2 <= input_act_end_delay;
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) in_valid2_has_come <= 'd0;
    else if (in_valid2) in_valid2_has_come <= 'd1;
    else if (cs == CROSS_COR ) in_valid2_has_come<='d0;
    else in_valid2_has_come <= in_valid2_has_come;
end


//==================================================================
// img_cnt, img_size_reg, template_reg, cnt256, cnt256_delay, set_cnt
//==================================================================

// img_cnt
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) img_cnt <= 'd0;
    else if (max_pooling_end | negative_end | horizontal_flip_end | image_filter_end | cross_cor_end_delay | pattern_end | set_end |input_data_end |input_act_end_delay2) img_cnt <= 'd0;
    else if (in_valid | cs == INPUT_ACT & in_valid2_has_come | cs == MAX_POOLING | cs == NEGATIVE | cs == HORIZONTAL_FLIP | cs == IMAGE_FILTER | cs == CROSS_COR ) img_cnt <= img_cnt + 'd1;
    else img_cnt <= img_cnt;
end

// cnt256
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cnt256 <= 'd0;
    else if (max_pooling_end | negative_end | horizontal_flip_end | image_filter_end | cross_cor_end_delay | pattern_end | set_end |input_data_end |input_act_end_delay2) cnt256 <= 'd0;
    else if (in_valid | cs == INPUT_ACT & (in_valid2_has_come ) | cs == MAX_POOLING | cs == NEGATIVE | cs == HORIZONTAL_FLIP | cs == IMAGE_FILTER | cs == CROSS_COR ) cnt256 <= cnt256 + 'd1;
    else cnt256 <= cnt256;
end

// cnt256_delay
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cnt256_delay <= 'd0;
    else cnt256_delay <= cnt256;
end

//set_cnt
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) set_cnt <= 'd0;
    else if (set_end) set_cnt <= set_cnt + 'd1;
    else set_cnt <= set_cnt;
end

// img_size_reg
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) img_size_reg <= 'd0;
    else if ( cs == INPUT_DATA & img_cnt == 'd0) img_size_reg <= image_size ;
    else if (cross_cor_end_delay) img_size_reg <= img_size_keep_reg;
    else if (max_pooling_end) begin
        case (img_size_reg)
            0:img_size_reg <= 'd0;
            1:img_size_reg <= 'd0;
            2:img_size_reg <= 'd13;
            default: ;
        endcase
    end
    else img_size_reg <= img_size_reg;
end

// img_size_keep_reg
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) img_size_keep_reg <= 'd0;
    else if ( cs == INPUT_DATA & img_cnt == 'd0) img_size_keep_reg <= image_size ;
    else img_size_keep_reg <= img_size_keep_reg;
end

//template_reg
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for ( i=0 ; i<9 ; i=i+1) template_reg[i]  <= 'd0;
    else if ( cs == INPUT_DATA )
        // template_reg [img_cnt] <= template;
        case (img_cnt)
            0: template_reg [0] <= template;
            1: template_reg [1] <= template;
            2: template_reg [2] <= template;
            3: template_reg [3] <= template;
            4: template_reg [4] <= template;
            5: template_reg [5] <= template;
            6: template_reg [6] <= template;
            7: template_reg [7] <= template;
            8: template_reg [8] <= template;
            default: for ( i=0 ; i<9 ; i=i+1) template_reg[i]  <= template_reg[i];
        endcase
end



//==================================================================
// act_reg
//==================================================================

assign nact = {1'd0,act_reg[1]};
//act_num
always @( posedge clk or negedge rst_n) begin   // if act_reg = 5, it means there are 5 actions should be done.
    if (!rst_n) act_num <= 'd0;
    else if (set_end | pattern_end ) act_num <= 'd0;
    else if (in_valid2) act_num <= act_num + 'd1;
    else act_num <= act_num;
end

// process of doing action
always @( posedge clk or negedge rst_n) begin   // act_process = n, it means there are n action have been done
    if (!rst_n) act_process <= 'd0;
    else if ( pattern_end | set_end ) act_process <= 'd0;
    else if ( max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end_delay | input_act_end_delay2 )
        act_process <= act_process + 'd1;
    else act_process <= act_process;
end

//act_reg
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for ( i=0 ; i<8 ; i=i+1) act_reg[i]  <= 'd0;
    // else if (set_end | pattern_end ) act_reg <= 'd0;
    else if ( cs == INPUT_ACT & in_valid2 )
        case (act_num)
            0: act_reg [0] <= action;
            1: act_reg [1] <= action;
            2: act_reg [2] <= action;
            3: act_reg [3] <= action;
            4: act_reg [4] <= action;
            5: act_reg [5] <= action;
            6: act_reg [6] <= action;
            7: act_reg [7] <= action;
            default: ;
        endcase
    else if ( max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end_delay | input_act_end_delay2 ) begin
            act_reg [0] <= act_reg [1] ;
            act_reg [1] <= act_reg [2] ;
            act_reg [2] <= act_reg [3] ;
            act_reg [3] <= act_reg [4] ;
            act_reg [4] <= act_reg [5] ;
            act_reg [5] <= act_reg [6] ;
            act_reg [6] <= act_reg [7] ;
            act_reg [7] <= 'd0         ;
    end
end



//==================================================================
// work_reg
//==================================================================
wire [7:0] Gray_out_port;
reg  [7:0] work_reg [0:17] [0:17];

reg  [7:0] MPi [7:0] [3:0];
wire [7:0] MPo [7:0];

reg  [7:0] Med_in[15:0][8:0];
wire [7:0] Med_out[15:0];

// reg  [7:0] padding [0:17] [0:17];
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for (i=0 ;i<18;i=i+1)for(j=0;j<18;j=j+1) work_reg[i][j] <= 'd0;
    else if ( cs == INPUT_DATA & in_valid) begin
        case (img_cnt%3)
            0: work_reg [0][0] <=  image;
            1: work_reg [0][1] <=  image;
            2: work_reg [0][2] <=  image;
            default:   for (i=1 ;i<17;i=i+1)for(j=1;j<17;j=j+1)work_reg[i][j] <= work_reg[i][j];
        endcase
    end
    else if ( cs == INPUT_ACT & cs == cs) begin
        case ( img_size_reg )
            0: begin
                case (cnt256_delay)
                    0 : work_reg [1][1] <= Gray_out_port;
                    1 : work_reg [1][2] <= Gray_out_port;
                    2 : work_reg [1][3] <= Gray_out_port;
                    3 : work_reg [1][4] <= Gray_out_port;

                    4 : work_reg [2][1] <= Gray_out_port;
                    5 : work_reg [2][2] <= Gray_out_port;
                    6 : work_reg [2][3] <= Gray_out_port;
                    7 : work_reg [2][4] <= Gray_out_port;

                    8 : work_reg [3][1] <= Gray_out_port;
                    9 : work_reg [3][2] <= Gray_out_port;
                    10: work_reg [3][3] <= Gray_out_port;
                    11: work_reg [3][4] <= Gray_out_port;

                    12: work_reg [4][1] <= Gray_out_port;
                    13: work_reg [4][2] <= Gray_out_port;
                    14: work_reg [4][3] <= Gray_out_port;
                    15: work_reg [4][4] <= Gray_out_port;
                    default: for (i=0 ;i<18;i=i+1)for(j=0;j<18;j=j+1)work_reg[i][j] <= work_reg[i][j];
                endcase
            end
            1: begin
                case (cnt256_delay)
                    0  : work_reg[1][1] <= Gray_out_port;
                    1  : work_reg[1][2] <= Gray_out_port;
                    2  : work_reg[1][3] <= Gray_out_port;
                    3  : work_reg[1][4] <= Gray_out_port;
                    4  : work_reg[1][5] <= Gray_out_port;
                    5  : work_reg[1][6] <= Gray_out_port;
                    6  : work_reg[1][7] <= Gray_out_port;
                    7  : work_reg[1][8] <= Gray_out_port;

                    8  : work_reg[2][1] <= Gray_out_port;
                    9  : work_reg[2][2] <= Gray_out_port;
                    10 : work_reg[2][3] <= Gray_out_port;
                    11 : work_reg[2][4] <= Gray_out_port;
                    12 : work_reg[2][5] <= Gray_out_port;
                    13 : work_reg[2][6] <= Gray_out_port;
                    14 : work_reg[2][7] <= Gray_out_port;
                    15 : work_reg[2][8] <= Gray_out_port;

                    16 : work_reg[3][1] <= Gray_out_port;
                    17 : work_reg[3][2] <= Gray_out_port;
                    18 : work_reg[3][3] <= Gray_out_port;
                    19 : work_reg[3][4] <= Gray_out_port;
                    20 : work_reg[3][5] <= Gray_out_port;
                    21 : work_reg[3][6] <= Gray_out_port;
                    22 : work_reg[3][7] <= Gray_out_port;
                    23 : work_reg[3][8] <= Gray_out_port;

                    24 : work_reg[4][1] <= Gray_out_port;
                    25 : work_reg[4][2] <= Gray_out_port;
                    26 : work_reg[4][3] <= Gray_out_port;
                    27 : work_reg[4][4] <= Gray_out_port;
                    28 : work_reg[4][5] <= Gray_out_port;
                    29 : work_reg[4][6] <= Gray_out_port;
                    30 : work_reg[4][7] <= Gray_out_port;
                    31 : work_reg[4][8] <= Gray_out_port;

                    32 : work_reg[5][1] <= Gray_out_port;
                    33 : work_reg[5][2] <= Gray_out_port;
                    34 : work_reg[5][3] <= Gray_out_port;
                    35 : work_reg[5][4] <= Gray_out_port;
                    36 : work_reg[5][5] <= Gray_out_port;
                    37 : work_reg[5][6] <= Gray_out_port;
                    38 : work_reg[5][7] <= Gray_out_port;
                    39 : work_reg[5][8] <= Gray_out_port;

                    40 : work_reg[6][1] <= Gray_out_port;
                    41 : work_reg[6][2] <= Gray_out_port;
                    42 : work_reg[6][3] <= Gray_out_port;
                    43 : work_reg[6][4] <= Gray_out_port;
                    44 : work_reg[6][5] <= Gray_out_port;
                    45 : work_reg[6][6] <= Gray_out_port;
                    46 : work_reg[6][7] <= Gray_out_port;
                    47 : work_reg[6][8] <= Gray_out_port;

                    48 : work_reg[7][1] <= Gray_out_port;
                    49 : work_reg[7][2] <= Gray_out_port;
                    50 : work_reg[7][3] <= Gray_out_port;
                    51 : work_reg[7][4] <= Gray_out_port;
                    52 : work_reg[7][5] <= Gray_out_port;
                    53 : work_reg[7][6] <= Gray_out_port;
                    54 : work_reg[7][7] <= Gray_out_port;
                    55 : work_reg[7][8] <= Gray_out_port;

                    56 : work_reg[8][1] <= Gray_out_port;
                    57 : work_reg[8][2] <= Gray_out_port;
                    58 : work_reg[8][3] <= Gray_out_port;
                    59 : work_reg[8][4] <= Gray_out_port;
                    60 : work_reg[8][5] <= Gray_out_port;
                    61 : work_reg[8][6] <= Gray_out_port;
                    62 : work_reg[8][7] <= Gray_out_port;
                    63 : work_reg[8][8] <= Gray_out_port;

                    default: for (i=0 ;i<18;i=i+1)for(j=0;j<18;j=j+1)work_reg[i][j] <= work_reg[i][j];
                endcase
            end
            2:begin
                work_reg [(cnt256_delay / 'd16) +'d1][ cnt256_delay % 'd16 + 'd1] <= Gray_out_port;
            end
            default:for (i=1 ;i<17;i=i+1)for(j=1;j<17;j=j+1)work_reg[i][j] <= work_reg[i][j];
        endcase

        if ( nact == IMAGE_FILTER & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][4];

                // work_reg outside down round
                work_reg [5][0] <= work_reg [4][1];
                work_reg [5][1] <= work_reg [4][1];
                work_reg [5][2] <= work_reg [4][2];
                work_reg [5][3] <= work_reg [4][3];
                work_reg [5][4] <= work_reg [4][4];
                work_reg [5][5] <= work_reg [4][4];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][5] <= work_reg [1][4];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][5] <= work_reg [2][4];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][5] <= work_reg [3][4];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][5] <= work_reg [4][4];
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][5];
                work_reg [0][6] <= work_reg [1][6];
                work_reg [0][7] <= work_reg [1][7];
                work_reg [0][8] <= work_reg [1][8];
                work_reg [0][9] <= work_reg [1][8];

                // work_reg outside down round
                work_reg [9][0] <= work_reg [8][1];
                work_reg [9][1] <= work_reg [8][1];
                work_reg [9][2] <= work_reg [8][2];
                work_reg [9][3] <= work_reg [8][3];
                work_reg [9][4] <= work_reg [8][4];
                work_reg [9][5] <= work_reg [8][5];
                work_reg [9][6] <= work_reg [8][6];
                work_reg [9][7] <= work_reg [8][7];
                work_reg [9][8] <= work_reg [8][8];
                work_reg [9][9] <= work_reg [8][8];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][9] <= work_reg [1][8];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][9] <= work_reg [2][8];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][9] <= work_reg [3][8];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][9] <= work_reg [4][8];
                work_reg [5][0] <= work_reg [5][1];
                work_reg [5][9] <= work_reg [5][8];
                work_reg [6][0] <= work_reg [6][1];
                work_reg [6][9] <= work_reg [6][8];
                work_reg [7][0] <= work_reg [7][1];
                work_reg [7][9] <= work_reg [7][8];
                work_reg [8][0] <= work_reg [8][1];
                work_reg [8][9] <= work_reg [8][8];
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0 ] <= work_reg [1][1 ];
                work_reg [0][1 ] <= work_reg [1][1 ];
                work_reg [0][2 ] <= work_reg [1][2 ];
                work_reg [0][3 ] <= work_reg [1][3 ];
                work_reg [0][4 ] <= work_reg [1][4 ];
                work_reg [0][5 ] <= work_reg [1][5 ];
                work_reg [0][6 ] <= work_reg [1][6 ];
                work_reg [0][7 ] <= work_reg [1][7 ];
                work_reg [0][8 ] <= work_reg [1][8 ];
                work_reg [0][9 ] <= work_reg [1][9 ];
                work_reg [0][10] <= work_reg [1][10];
                work_reg [0][11] <= work_reg [1][11];
                work_reg [0][12] <= work_reg [1][12];
                work_reg [0][13] <= work_reg [1][13];
                work_reg [0][14] <= work_reg [1][14];
                work_reg [0][15] <= work_reg [1][15];
                work_reg [0][16] <= work_reg [1][16];
                work_reg [0][17] <= work_reg [1][16];

                // work_reg outside down round
                work_reg [17][0 ] <= work_reg [16][1 ];
                work_reg [17][1 ] <= work_reg [16][1 ];
                work_reg [17][2 ] <= work_reg [16][2 ];
                work_reg [17][3 ] <= work_reg [16][3 ];
                work_reg [17][4 ] <= work_reg [16][4 ];
                work_reg [17][5 ] <= work_reg [16][5 ];
                work_reg [17][6 ] <= work_reg [16][6 ];
                work_reg [17][7 ] <= work_reg [16][7 ];
                work_reg [17][8 ] <= work_reg [16][8 ];
                work_reg [17][9 ] <= work_reg [16][9 ];
                work_reg [17][10] <= work_reg [16][10];
                work_reg [17][11] <= work_reg [16][11];
                work_reg [17][12] <= work_reg [16][12];
                work_reg [17][13] <= work_reg [16][13];
                work_reg [17][14] <= work_reg [16][14];
                work_reg [17][15] <= work_reg [16][15];
                work_reg [17][16] <= work_reg [16][16];
                work_reg [17][17] <= work_reg [16][16];

                // work_reg outside two side
                work_reg [1 ][0 ] <= work_reg [1 ][1 ];
                work_reg [1 ][17] <= work_reg [1 ][16];
                work_reg [2 ][0 ] <= work_reg [2 ][1 ];
                work_reg [2 ][17] <= work_reg [2 ][16];
                work_reg [3 ][0 ] <= work_reg [3 ][1 ];
                work_reg [3 ][17] <= work_reg [3 ][16];
                work_reg [4 ][0 ] <= work_reg [4 ][1 ];
                work_reg [4 ][17] <= work_reg [4 ][16];
                work_reg [5 ][0 ] <= work_reg [5 ][1 ];
                work_reg [5 ][17] <= work_reg [5 ][16];
                work_reg [6 ][0 ] <= work_reg [6 ][1 ];
                work_reg [6 ][17] <= work_reg [6 ][16];
                work_reg [7 ][0 ] <= work_reg [7 ][1 ];
                work_reg [7 ][17] <= work_reg [7 ][16];
                work_reg [8 ][0 ] <= work_reg [8 ][1 ];
                work_reg [8 ][17] <= work_reg [8 ][16];
                work_reg [9 ][0 ] <= work_reg [9 ][1 ];
                work_reg [9 ][17] <= work_reg [9 ][16];
                work_reg [10][0 ] <= work_reg [10][1 ];
                work_reg [10][17] <= work_reg [10][16];
                work_reg [11][0 ] <= work_reg [11][1 ];
                work_reg [11][17] <= work_reg [11][16];
                work_reg [12][0 ] <= work_reg [12][1 ];
                work_reg [12][17] <= work_reg [12][16];
                work_reg [13][0 ] <= work_reg [13][1 ];
                work_reg [13][17] <= work_reg [13][16];
                work_reg [14][0 ] <= work_reg [14][1 ];
                work_reg [14][17] <= work_reg [14][16];
                work_reg [15][0 ] <= work_reg [15][1 ];
                work_reg [15][17] <= work_reg [15][16];
                work_reg [16][0 ] <= work_reg [16][1 ];
                work_reg [16][17] <= work_reg [16][16];
            end
        end
        else if ( nact == CROSS_COR & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin

                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;

                // work_reg outside down round
                work_reg [5][0] <= 'd0;
                work_reg [5][1] <= 'd0;
                work_reg [5][2] <= 'd0;
                work_reg [5][3] <= 'd0;
                work_reg [5][4] <= 'd0;
                work_reg [5][5] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][5] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][5] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][5] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][5] <= 'd0;
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;
                work_reg [0][6] <= 'd0;
                work_reg [0][7] <= 'd0;
                work_reg [0][8] <= 'd0;
                work_reg [0][9] <= 'd0;

                // work_reg [0][0] <= 'd8;
                // work_reg [0][1] <= 'd8;
                // work_reg [0][2] <= 'd8;
                // work_reg [0][3] <= 'd8;
                // work_reg [0][4] <= 'd8;
                // work_reg [0][5] <= 'd8;
                // work_reg [0][6] <= 'd8;
                // work_reg [0][7] <= 'd8;
                // work_reg [0][8] <= 'd8;
                // work_reg [0][9] <= 'd8;

                // work_reg outside down round
                work_reg [9][0] <= 'd0;
                work_reg [9][1] <= 'd0;
                work_reg [9][2] <= 'd0;
                work_reg [9][3] <= 'd0;
                work_reg [9][4] <= 'd0;
                work_reg [9][5] <= 'd0;
                work_reg [9][6] <= 'd0;
                work_reg [9][7] <= 'd0;
                work_reg [9][8] <= 'd0;
                work_reg [9][9] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][9] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][9] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][9] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][9] <= 'd0;
                work_reg [5][0] <= 'd0;
                work_reg [5][9] <= 'd0;
                work_reg [6][0] <= 'd0;
                work_reg [6][9] <= 'd0;
                work_reg [7][0] <= 'd0;
                work_reg [7][9] <= 'd0;
                work_reg [8][0] <= 'd0;
                work_reg [8][9] <= 'd0;
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0 ] <= 'd0;
                work_reg [0][1 ] <= 'd0;
                work_reg [0][2 ] <= 'd0;
                work_reg [0][3 ] <= 'd0;
                work_reg [0][4 ] <= 'd0;
                work_reg [0][5 ] <= 'd0;
                work_reg [0][6 ] <= 'd0;
                work_reg [0][7 ] <= 'd0;
                work_reg [0][8 ] <= 'd0;
                work_reg [0][9 ] <= 'd0;
                work_reg [0][10] <= 'd0;
                work_reg [0][11] <= 'd0;
                work_reg [0][12] <= 'd0;
                work_reg [0][13] <= 'd0;
                work_reg [0][14] <= 'd0;
                work_reg [0][15] <= 'd0;
                work_reg [0][16] <= 'd0;
                work_reg [0][17] <= 'd0;

                // work_reg outside down round
                work_reg [17][0 ] <= 'd0;
                work_reg [17][1 ] <= 'd0;
                work_reg [17][2 ] <= 'd0;
                work_reg [17][3 ] <= 'd0;
                work_reg [17][4 ] <= 'd0;
                work_reg [17][5 ] <= 'd0;
                work_reg [17][6 ] <= 'd0;
                work_reg [17][7 ] <= 'd0;
                work_reg [17][8 ] <= 'd0;
                work_reg [17][9 ] <= 'd0;
                work_reg [17][10] <= 'd0;
                work_reg [17][11] <= 'd0;
                work_reg [17][12] <= 'd0;
                work_reg [17][13] <= 'd0;
                work_reg [17][14] <= 'd0;
                work_reg [17][15] <= 'd0;
                work_reg [17][16] <= 'd0;
                work_reg [17][17] <= 'd0;

                // work_reg outside two side
                work_reg [1 ][0 ] <= 'd0;
                work_reg [1 ][17] <= 'd0;
                work_reg [2 ][0 ] <= 'd0;
                work_reg [2 ][17] <= 'd0;
                work_reg [3 ][0 ] <= 'd0;
                work_reg [3 ][17] <= 'd0;
                work_reg [4 ][0 ] <= 'd0;
                work_reg [4 ][17] <= 'd0;
                work_reg [5 ][0 ] <= 'd0;
                work_reg [5 ][17] <= 'd0;
                work_reg [6 ][0 ] <= 'd0;
                work_reg [6 ][17] <= 'd0;
                work_reg [7 ][0 ] <= 'd0;
                work_reg [7 ][17] <= 'd0;
                work_reg [8 ][0 ] <= 'd0;
                work_reg [8 ][17] <= 'd0;
                work_reg [9 ][0 ] <= 'd0;
                work_reg [9 ][17] <= 'd0;
                work_reg [10][0 ] <= 'd0;
                work_reg [10][17] <= 'd0;
                work_reg [11][0 ] <= 'd0;
                work_reg [11][17] <= 'd0;
                work_reg [12][0 ] <= 'd0;
                work_reg [12][17] <= 'd0;
                work_reg [13][0 ] <= 'd0;
                work_reg [13][17] <= 'd0;
                work_reg [14][0 ] <= 'd0;
                work_reg [14][17] <= 'd0;
                work_reg [15][0 ] <= 'd0;
                work_reg [15][17] <= 'd0;
                work_reg [16][0 ] <= 'd0;
                work_reg [16][17] <= 'd0;
            end
        end
    end

    else if ( cs == IMAGE_FILTER ) begin
        if (!image_filter_end) begin
            if (cnt256 != 'd9) begin
                case ( img_size_reg )
                    0: begin  // only need to do once
                        for ( i=0 ;i<4;i=i+1)  for ( j=0 ;j<4;j=j+1) work_reg[i+1][j+1] <= Med_out[i+4*j ];
                    end
                    1: begin // only need to do 4 times, exactly 16 fxxx   !!!!!!
                        work_reg[0 ][9] <= 'd0;
                        work_reg[9 ][9] <= 'd0;
                        for ( l=1 ;l<=8;l=l+1) begin
                            // work_reg[l][4] <= Med_out[l-1];
                            work_reg[l][9] <= Med_out[l-1];
                        end
                        for ( i=0 ; i <= 9 ; i=i+1) begin
                            for ( j=0 ; j<=8 ; j=j+1) begin
                                work_reg[i][j] <= work_reg[i][j+1];
                            end
                        end
                    end
                    2: begin // only need to do 16 times
                        work_reg[0 ][17] <= 'd0;
                        work_reg[17][17] <= 'd0;
                        for ( i=1 ;i<=16;i=i+1) begin
                            work_reg[i][17] <= Med_out[i-1];
                        end
                        for ( i=0 ; i <= 17 ; i=i+1) begin
                            for ( j=0 ; j<=16 ; j=j+1) begin
                                work_reg[i][j] <= work_reg[i][j+1];
                            end
                        end
                    end
                    default:for (i=1 ;i<17;i=i+1)for(j=1;j<17;j=j+1)work_reg[i][j] <= work_reg[i][j];
                endcase
            end
        end

        if ( nact == IMAGE_FILTER & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][4];

                // work_reg outside down round
                work_reg [5][0] <= work_reg [4][1];
                work_reg [5][1] <= work_reg [4][1];
                work_reg [5][2] <= work_reg [4][2];
                work_reg [5][3] <= work_reg [4][3];
                work_reg [5][4] <= work_reg [4][4];
                work_reg [5][5] <= work_reg [4][4];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][5] <= work_reg [1][4];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][5] <= work_reg [2][4];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][5] <= work_reg [3][4];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][5] <= work_reg [4][4];
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][5];
                work_reg [0][6] <= work_reg [1][6];
                work_reg [0][7] <= work_reg [1][7];
                work_reg [0][8] <= work_reg [1][8];
                work_reg [0][9] <= work_reg [1][8];

                // work_reg outside down round
                work_reg [9][0] <= work_reg [8][1];
                work_reg [9][1] <= work_reg [8][1];
                work_reg [9][2] <= work_reg [8][2];
                work_reg [9][3] <= work_reg [8][3];
                work_reg [9][4] <= work_reg [8][4];
                work_reg [9][5] <= work_reg [8][5];
                work_reg [9][6] <= work_reg [8][6];
                work_reg [9][7] <= work_reg [8][7];
                work_reg [9][8] <= work_reg [8][8];
                work_reg [9][9] <= work_reg [8][8];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][9] <= work_reg [1][8];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][9] <= work_reg [2][8];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][9] <= work_reg [3][8];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][9] <= work_reg [4][8];
                work_reg [5][0] <= work_reg [5][1];
                work_reg [5][9] <= work_reg [5][8];
                work_reg [6][0] <= work_reg [6][1];
                work_reg [6][9] <= work_reg [6][8];
                work_reg [7][0] <= work_reg [7][1];
                work_reg [7][9] <= work_reg [7][8];
                work_reg [8][0] <= work_reg [8][1];
                work_reg [8][9] <= work_reg [8][8];
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0 ] <= work_reg [1][1 ];
                work_reg [0][1 ] <= work_reg [1][1 ];
                work_reg [0][2 ] <= work_reg [1][2 ];
                work_reg [0][3 ] <= work_reg [1][3 ];
                work_reg [0][4 ] <= work_reg [1][4 ];
                work_reg [0][5 ] <= work_reg [1][5 ];
                work_reg [0][6 ] <= work_reg [1][6 ];
                work_reg [0][7 ] <= work_reg [1][7 ];
                work_reg [0][8 ] <= work_reg [1][8 ];
                work_reg [0][9 ] <= work_reg [1][9 ];
                work_reg [0][10] <= work_reg [1][10];
                work_reg [0][11] <= work_reg [1][11];
                work_reg [0][12] <= work_reg [1][12];
                work_reg [0][13] <= work_reg [1][13];
                work_reg [0][14] <= work_reg [1][14];
                work_reg [0][15] <= work_reg [1][15];
                work_reg [0][16] <= work_reg [1][16];
                work_reg [0][17] <= work_reg [1][16];

                // work_reg outside down round
                work_reg [17][0 ] <= work_reg [16][1 ];
                work_reg [17][1 ] <= work_reg [16][1 ];
                work_reg [17][2 ] <= work_reg [16][2 ];
                work_reg [17][3 ] <= work_reg [16][3 ];
                work_reg [17][4 ] <= work_reg [16][4 ];
                work_reg [17][5 ] <= work_reg [16][5 ];
                work_reg [17][6 ] <= work_reg [16][6 ];
                work_reg [17][7 ] <= work_reg [16][7 ];
                work_reg [17][8 ] <= work_reg [16][8 ];
                work_reg [17][9 ] <= work_reg [16][9 ];
                work_reg [17][10] <= work_reg [16][10];
                work_reg [17][11] <= work_reg [16][11];
                work_reg [17][12] <= work_reg [16][12];
                work_reg [17][13] <= work_reg [16][13];
                work_reg [17][14] <= work_reg [16][14];
                work_reg [17][15] <= work_reg [16][15];
                work_reg [17][16] <= work_reg [16][16];
                work_reg [17][17] <= work_reg [16][16];

                // work_reg outside two side
                work_reg [1 ][0 ] <= work_reg [1 ][1 ];
                work_reg [1 ][17] <= work_reg [1 ][16];
                work_reg [2 ][0 ] <= work_reg [2 ][1 ];
                work_reg [2 ][17] <= work_reg [2 ][16];
                work_reg [3 ][0 ] <= work_reg [3 ][1 ];
                work_reg [3 ][17] <= work_reg [3 ][16];
                work_reg [4 ][0 ] <= work_reg [4 ][1 ];
                work_reg [4 ][17] <= work_reg [4 ][16];
                work_reg [5 ][0 ] <= work_reg [5 ][1 ];
                work_reg [5 ][17] <= work_reg [5 ][16];
                work_reg [6 ][0 ] <= work_reg [6 ][1 ];
                work_reg [6 ][17] <= work_reg [6 ][16];
                work_reg [7 ][0 ] <= work_reg [7 ][1 ];
                work_reg [7 ][17] <= work_reg [7 ][16];
                work_reg [8 ][0 ] <= work_reg [8 ][1 ];
                work_reg [8 ][17] <= work_reg [8 ][16];
                work_reg [9 ][0 ] <= work_reg [9 ][1 ];
                work_reg [9 ][17] <= work_reg [9 ][16];
                work_reg [10][0 ] <= work_reg [10][1 ];
                work_reg [10][17] <= work_reg [10][16];
                work_reg [11][0 ] <= work_reg [11][1 ];
                work_reg [11][17] <= work_reg [11][16];
                work_reg [12][0 ] <= work_reg [12][1 ];
                work_reg [12][17] <= work_reg [12][16];
                work_reg [13][0 ] <= work_reg [13][1 ];
                work_reg [13][17] <= work_reg [13][16];
                work_reg [14][0 ] <= work_reg [14][1 ];
                work_reg [14][17] <= work_reg [14][16];
                work_reg [15][0 ] <= work_reg [15][1 ];
                work_reg [15][17] <= work_reg [15][16];
                work_reg [16][0 ] <= work_reg [16][1 ];
                work_reg [16][17] <= work_reg [16][16];
            end
        end
        else if ( nact == CROSS_COR & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin

                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;

                // work_reg outside down round
                work_reg [5][0] <= 'd0;
                work_reg [5][1] <= 'd0;
                work_reg [5][2] <= 'd0;
                work_reg [5][3] <= 'd0;
                work_reg [5][4] <= 'd0;
                work_reg [5][5] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][5] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][5] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][5] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][5] <= 'd0;
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;
                work_reg [0][6] <= 'd0;
                work_reg [0][7] <= 'd0;
                work_reg [0][8] <= 'd0;
                work_reg [0][9] <= 'd0;

                // work_reg [0][0] <= 'd8;
                // work_reg [0][1] <= 'd8;
                // work_reg [0][2] <= 'd8;
                // work_reg [0][3] <= 'd8;
                // work_reg [0][4] <= 'd8;
                // work_reg [0][5] <= 'd8;
                // work_reg [0][6] <= 'd8;
                // work_reg [0][7] <= 'd8;
                // work_reg [0][8] <= 'd8;
                // work_reg [0][9] <= 'd8;

                // work_reg outside down round
                work_reg [9][0] <= 'd0;
                work_reg [9][1] <= 'd0;
                work_reg [9][2] <= 'd0;
                work_reg [9][3] <= 'd0;
                work_reg [9][4] <= 'd0;
                work_reg [9][5] <= 'd0;
                work_reg [9][6] <= 'd0;
                work_reg [9][7] <= 'd0;
                work_reg [9][8] <= 'd0;
                work_reg [9][9] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][9] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][9] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][9] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][9] <= 'd0;
                work_reg [5][0] <= 'd0;
                work_reg [5][9] <= 'd0;
                work_reg [6][0] <= 'd0;
                work_reg [6][9] <= 'd0;
                work_reg [7][0] <= 'd0;
                work_reg [7][9] <= 'd0;
                work_reg [8][0] <= 'd0;
                work_reg [8][9] <= 'd0;
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0 ] <= 'd0;
                work_reg [0][1 ] <= 'd0;
                work_reg [0][2 ] <= 'd0;
                work_reg [0][3 ] <= 'd0;
                work_reg [0][4 ] <= 'd0;
                work_reg [0][5 ] <= 'd0;
                work_reg [0][6 ] <= 'd0;
                work_reg [0][7 ] <= 'd0;
                work_reg [0][8 ] <= 'd0;
                work_reg [0][9 ] <= 'd0;
                work_reg [0][10] <= 'd0;
                work_reg [0][11] <= 'd0;
                work_reg [0][12] <= 'd0;
                work_reg [0][13] <= 'd0;
                work_reg [0][14] <= 'd0;
                work_reg [0][15] <= 'd0;
                work_reg [0][16] <= 'd0;
                work_reg [0][17] <= 'd0;

                // work_reg outside down round
                work_reg [17][0 ] <= 'd0;
                work_reg [17][1 ] <= 'd0;
                work_reg [17][2 ] <= 'd0;
                work_reg [17][3 ] <= 'd0;
                work_reg [17][4 ] <= 'd0;
                work_reg [17][5 ] <= 'd0;
                work_reg [17][6 ] <= 'd0;
                work_reg [17][7 ] <= 'd0;
                work_reg [17][8 ] <= 'd0;
                work_reg [17][9 ] <= 'd0;
                work_reg [17][10] <= 'd0;
                work_reg [17][11] <= 'd0;
                work_reg [17][12] <= 'd0;
                work_reg [17][13] <= 'd0;
                work_reg [17][14] <= 'd0;
                work_reg [17][15] <= 'd0;
                work_reg [17][16] <= 'd0;
                work_reg [17][17] <= 'd0;

                // work_reg outside two side
                work_reg [1 ][0 ] <= 'd0;
                work_reg [1 ][17] <= 'd0;
                work_reg [2 ][0 ] <= 'd0;
                work_reg [2 ][17] <= 'd0;
                work_reg [3 ][0 ] <= 'd0;
                work_reg [3 ][17] <= 'd0;
                work_reg [4 ][0 ] <= 'd0;
                work_reg [4 ][17] <= 'd0;
                work_reg [5 ][0 ] <= 'd0;
                work_reg [5 ][17] <= 'd0;
                work_reg [6 ][0 ] <= 'd0;
                work_reg [6 ][17] <= 'd0;
                work_reg [7 ][0 ] <= 'd0;
                work_reg [7 ][17] <= 'd0;
                work_reg [8 ][0 ] <= 'd0;
                work_reg [8 ][17] <= 'd0;
                work_reg [9 ][0 ] <= 'd0;
                work_reg [9 ][17] <= 'd0;
                work_reg [10][0 ] <= 'd0;
                work_reg [10][17] <= 'd0;
                work_reg [11][0 ] <= 'd0;
                work_reg [11][17] <= 'd0;
                work_reg [12][0 ] <= 'd0;
                work_reg [12][17] <= 'd0;
                work_reg [13][0 ] <= 'd0;
                work_reg [13][17] <= 'd0;
                work_reg [14][0 ] <= 'd0;
                work_reg [14][17] <= 'd0;
                work_reg [15][0 ] <= 'd0;
                work_reg [15][17] <= 'd0;
                work_reg [16][0 ] <= 'd0;
                work_reg [16][17] <= 'd0;
            end
        end
    end

    else if ( cs == NEGATIVE ) begin
        if ( !negative_end) begin
            for (i=1 ;i<17;i=i+1) for(j=1;j<17;j=j+1) work_reg[i][j] <= ~ work_reg[i][j];
        end
        if ( nact == IMAGE_FILTER & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][4];

                // work_reg outside down round
                work_reg [5][0] <= work_reg [4][1];
                work_reg [5][1] <= work_reg [4][1];
                work_reg [5][2] <= work_reg [4][2];
                work_reg [5][3] <= work_reg [4][3];
                work_reg [5][4] <= work_reg [4][4];
                work_reg [5][5] <= work_reg [4][4];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][5] <= work_reg [1][4];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][5] <= work_reg [2][4];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][5] <= work_reg [3][4];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][5] <= work_reg [4][4];
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][5];
                work_reg [0][6] <= work_reg [1][6];
                work_reg [0][7] <= work_reg [1][7];
                work_reg [0][8] <= work_reg [1][8];
                work_reg [0][9] <= work_reg [1][8];

                // work_reg outside down round
                work_reg [9][0] <= work_reg [8][1];
                work_reg [9][1] <= work_reg [8][1];
                work_reg [9][2] <= work_reg [8][2];
                work_reg [9][3] <= work_reg [8][3];
                work_reg [9][4] <= work_reg [8][4];
                work_reg [9][5] <= work_reg [8][5];
                work_reg [9][6] <= work_reg [8][6];
                work_reg [9][7] <= work_reg [8][7];
                work_reg [9][8] <= work_reg [8][8];
                work_reg [9][9] <= work_reg [8][8];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][9] <= work_reg [1][8];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][9] <= work_reg [2][8];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][9] <= work_reg [3][8];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][9] <= work_reg [4][8];
                work_reg [5][0] <= work_reg [5][1];
                work_reg [5][9] <= work_reg [5][8];
                work_reg [6][0] <= work_reg [6][1];
                work_reg [6][9] <= work_reg [6][8];
                work_reg [7][0] <= work_reg [7][1];
                work_reg [7][9] <= work_reg [7][8];
                work_reg [8][0] <= work_reg [8][1];
                work_reg [8][9] <= work_reg [8][8];
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0 ] <= work_reg [1][1 ];
                work_reg [0][1 ] <= work_reg [1][1 ];
                work_reg [0][2 ] <= work_reg [1][2 ];
                work_reg [0][3 ] <= work_reg [1][3 ];
                work_reg [0][4 ] <= work_reg [1][4 ];
                work_reg [0][5 ] <= work_reg [1][5 ];
                work_reg [0][6 ] <= work_reg [1][6 ];
                work_reg [0][7 ] <= work_reg [1][7 ];
                work_reg [0][8 ] <= work_reg [1][8 ];
                work_reg [0][9 ] <= work_reg [1][9 ];
                work_reg [0][10] <= work_reg [1][10];
                work_reg [0][11] <= work_reg [1][11];
                work_reg [0][12] <= work_reg [1][12];
                work_reg [0][13] <= work_reg [1][13];
                work_reg [0][14] <= work_reg [1][14];
                work_reg [0][15] <= work_reg [1][15];
                work_reg [0][16] <= work_reg [1][16];
                work_reg [0][17] <= work_reg [1][16];

                // work_reg outside down round
                work_reg [17][0 ] <= work_reg [16][1 ];
                work_reg [17][1 ] <= work_reg [16][1 ];
                work_reg [17][2 ] <= work_reg [16][2 ];
                work_reg [17][3 ] <= work_reg [16][3 ];
                work_reg [17][4 ] <= work_reg [16][4 ];
                work_reg [17][5 ] <= work_reg [16][5 ];
                work_reg [17][6 ] <= work_reg [16][6 ];
                work_reg [17][7 ] <= work_reg [16][7 ];
                work_reg [17][8 ] <= work_reg [16][8 ];
                work_reg [17][9 ] <= work_reg [16][9 ];
                work_reg [17][10] <= work_reg [16][10];
                work_reg [17][11] <= work_reg [16][11];
                work_reg [17][12] <= work_reg [16][12];
                work_reg [17][13] <= work_reg [16][13];
                work_reg [17][14] <= work_reg [16][14];
                work_reg [17][15] <= work_reg [16][15];
                work_reg [17][16] <= work_reg [16][16];
                work_reg [17][17] <= work_reg [16][16];

                // work_reg outside two side
                work_reg [1 ][0 ] <= work_reg [1 ][1 ];
                work_reg [1 ][17] <= work_reg [1 ][16];
                work_reg [2 ][0 ] <= work_reg [2 ][1 ];
                work_reg [2 ][17] <= work_reg [2 ][16];
                work_reg [3 ][0 ] <= work_reg [3 ][1 ];
                work_reg [3 ][17] <= work_reg [3 ][16];
                work_reg [4 ][0 ] <= work_reg [4 ][1 ];
                work_reg [4 ][17] <= work_reg [4 ][16];
                work_reg [5 ][0 ] <= work_reg [5 ][1 ];
                work_reg [5 ][17] <= work_reg [5 ][16];
                work_reg [6 ][0 ] <= work_reg [6 ][1 ];
                work_reg [6 ][17] <= work_reg [6 ][16];
                work_reg [7 ][0 ] <= work_reg [7 ][1 ];
                work_reg [7 ][17] <= work_reg [7 ][16];
                work_reg [8 ][0 ] <= work_reg [8 ][1 ];
                work_reg [8 ][17] <= work_reg [8 ][16];
                work_reg [9 ][0 ] <= work_reg [9 ][1 ];
                work_reg [9 ][17] <= work_reg [9 ][16];
                work_reg [10][0 ] <= work_reg [10][1 ];
                work_reg [10][17] <= work_reg [10][16];
                work_reg [11][0 ] <= work_reg [11][1 ];
                work_reg [11][17] <= work_reg [11][16];
                work_reg [12][0 ] <= work_reg [12][1 ];
                work_reg [12][17] <= work_reg [12][16];
                work_reg [13][0 ] <= work_reg [13][1 ];
                work_reg [13][17] <= work_reg [13][16];
                work_reg [14][0 ] <= work_reg [14][1 ];
                work_reg [14][17] <= work_reg [14][16];
                work_reg [15][0 ] <= work_reg [15][1 ];
                work_reg [15][17] <= work_reg [15][16];
                work_reg [16][0 ] <= work_reg [16][1 ];
                work_reg [16][17] <= work_reg [16][16];
            end
        end
        else if ( nact == CROSS_COR & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin

                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;

                // work_reg outside down round
                work_reg [5][0] <= 'd0;
                work_reg [5][1] <= 'd0;
                work_reg [5][2] <= 'd0;
                work_reg [5][3] <= 'd0;
                work_reg [5][4] <= 'd0;
                work_reg [5][5] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][5] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][5] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][5] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][5] <= 'd0;
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;
                work_reg [0][6] <= 'd0;
                work_reg [0][7] <= 'd0;
                work_reg [0][8] <= 'd0;
                work_reg [0][9] <= 'd0;

                // work_reg [0][0] <= 'd8;
                // work_reg [0][1] <= 'd8;
                // work_reg [0][2] <= 'd8;
                // work_reg [0][3] <= 'd8;
                // work_reg [0][4] <= 'd8;
                // work_reg [0][5] <= 'd8;
                // work_reg [0][6] <= 'd8;
                // work_reg [0][7] <= 'd8;
                // work_reg [0][8] <= 'd8;
                // work_reg [0][9] <= 'd8;

                // work_reg outside down round
                work_reg [9][0] <= 'd0;
                work_reg [9][1] <= 'd0;
                work_reg [9][2] <= 'd0;
                work_reg [9][3] <= 'd0;
                work_reg [9][4] <= 'd0;
                work_reg [9][5] <= 'd0;
                work_reg [9][6] <= 'd0;
                work_reg [9][7] <= 'd0;
                work_reg [9][8] <= 'd0;
                work_reg [9][9] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][9] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][9] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][9] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][9] <= 'd0;
                work_reg [5][0] <= 'd0;
                work_reg [5][9] <= 'd0;
                work_reg [6][0] <= 'd0;
                work_reg [6][9] <= 'd0;
                work_reg [7][0] <= 'd0;
                work_reg [7][9] <= 'd0;
                work_reg [8][0] <= 'd0;
                work_reg [8][9] <= 'd0;
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0 ] <= 'd0;
                work_reg [0][1 ] <= 'd0;
                work_reg [0][2 ] <= 'd0;
                work_reg [0][3 ] <= 'd0;
                work_reg [0][4 ] <= 'd0;
                work_reg [0][5 ] <= 'd0;
                work_reg [0][6 ] <= 'd0;
                work_reg [0][7 ] <= 'd0;
                work_reg [0][8 ] <= 'd0;
                work_reg [0][9 ] <= 'd0;
                work_reg [0][10] <= 'd0;
                work_reg [0][11] <= 'd0;
                work_reg [0][12] <= 'd0;
                work_reg [0][13] <= 'd0;
                work_reg [0][14] <= 'd0;
                work_reg [0][15] <= 'd0;
                work_reg [0][16] <= 'd0;
                work_reg [0][17] <= 'd0;

                // work_reg outside down round
                work_reg [17][0 ] <= 'd0;
                work_reg [17][1 ] <= 'd0;
                work_reg [17][2 ] <= 'd0;
                work_reg [17][3 ] <= 'd0;
                work_reg [17][4 ] <= 'd0;
                work_reg [17][5 ] <= 'd0;
                work_reg [17][6 ] <= 'd0;
                work_reg [17][7 ] <= 'd0;
                work_reg [17][8 ] <= 'd0;
                work_reg [17][9 ] <= 'd0;
                work_reg [17][10] <= 'd0;
                work_reg [17][11] <= 'd0;
                work_reg [17][12] <= 'd0;
                work_reg [17][13] <= 'd0;
                work_reg [17][14] <= 'd0;
                work_reg [17][15] <= 'd0;
                work_reg [17][16] <= 'd0;
                work_reg [17][17] <= 'd0;

                // work_reg outside two side
                work_reg [1 ][0 ] <= 'd0;
                work_reg [1 ][17] <= 'd0;
                work_reg [2 ][0 ] <= 'd0;
                work_reg [2 ][17] <= 'd0;
                work_reg [3 ][0 ] <= 'd0;
                work_reg [3 ][17] <= 'd0;
                work_reg [4 ][0 ] <= 'd0;
                work_reg [4 ][17] <= 'd0;
                work_reg [5 ][0 ] <= 'd0;
                work_reg [5 ][17] <= 'd0;
                work_reg [6 ][0 ] <= 'd0;
                work_reg [6 ][17] <= 'd0;
                work_reg [7 ][0 ] <= 'd0;
                work_reg [7 ][17] <= 'd0;
                work_reg [8 ][0 ] <= 'd0;
                work_reg [8 ][17] <= 'd0;
                work_reg [9 ][0 ] <= 'd0;
                work_reg [9 ][17] <= 'd0;
                work_reg [10][0 ] <= 'd0;
                work_reg [10][17] <= 'd0;
                work_reg [11][0 ] <= 'd0;
                work_reg [11][17] <= 'd0;
                work_reg [12][0 ] <= 'd0;
                work_reg [12][17] <= 'd0;
                work_reg [13][0 ] <= 'd0;
                work_reg [13][17] <= 'd0;
                work_reg [14][0 ] <= 'd0;
                work_reg [14][17] <= 'd0;
                work_reg [15][0 ] <= 'd0;
                work_reg [15][17] <= 'd0;
                work_reg [16][0 ] <= 'd0;
                work_reg [16][17] <= 'd0;
            end
        end
    end

    else if ( cs == HORIZONTAL_FLIP ) begin
        if (!horizontal_flip_end )begin
            case (img_size_reg)
                0: for (i=1 ;i<=4 ;i=i+1) for(j=1;j<=4 ;j=j+1) work_reg[i][j] <= work_reg[i][5-j];
                1: for (i=1 ;i<=8 ;i=i+1) for(j=1;j<=8 ;j=j+1) work_reg[i][j] <= work_reg[i][9-j];
                2: for (i=1 ;i<=16;i=i+1) for(j=1;j<=16;j=j+1) work_reg[i][j] <= work_reg[i][17-j];
                default:  for (i=0 ;i<=17;i=i+1) for(j=0;j<=17;j=j+1) work_reg[i][j] <= work_reg[i][j];
            endcase
        end
        if ( nact == IMAGE_FILTER & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][4];

                // work_reg outside down round
                work_reg [5][0] <= work_reg [4][1];
                work_reg [5][1] <= work_reg [4][1];
                work_reg [5][2] <= work_reg [4][2];
                work_reg [5][3] <= work_reg [4][3];
                work_reg [5][4] <= work_reg [4][4];
                work_reg [5][5] <= work_reg [4][4];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][5] <= work_reg [1][4];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][5] <= work_reg [2][4];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][5] <= work_reg [3][4];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][5] <= work_reg [4][4];
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][5];
                work_reg [0][6] <= work_reg [1][6];
                work_reg [0][7] <= work_reg [1][7];
                work_reg [0][8] <= work_reg [1][8];
                work_reg [0][9] <= work_reg [1][8];

                // work_reg outside down round
                work_reg [9][0] <= work_reg [8][1];
                work_reg [9][1] <= work_reg [8][1];
                work_reg [9][2] <= work_reg [8][2];
                work_reg [9][3] <= work_reg [8][3];
                work_reg [9][4] <= work_reg [8][4];
                work_reg [9][5] <= work_reg [8][5];
                work_reg [9][6] <= work_reg [8][6];
                work_reg [9][7] <= work_reg [8][7];
                work_reg [9][8] <= work_reg [8][8];
                work_reg [9][9] <= work_reg [8][8];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][9] <= work_reg [1][8];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][9] <= work_reg [2][8];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][9] <= work_reg [3][8];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][9] <= work_reg [4][8];
                work_reg [5][0] <= work_reg [5][1];
                work_reg [5][9] <= work_reg [5][8];
                work_reg [6][0] <= work_reg [6][1];
                work_reg [6][9] <= work_reg [6][8];
                work_reg [7][0] <= work_reg [7][1];
                work_reg [7][9] <= work_reg [7][8];
                work_reg [8][0] <= work_reg [8][1];
                work_reg [8][9] <= work_reg [8][8];
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0 ] <= work_reg [1][1 ];
                work_reg [0][1 ] <= work_reg [1][1 ];
                work_reg [0][2 ] <= work_reg [1][2 ];
                work_reg [0][3 ] <= work_reg [1][3 ];
                work_reg [0][4 ] <= work_reg [1][4 ];
                work_reg [0][5 ] <= work_reg [1][5 ];
                work_reg [0][6 ] <= work_reg [1][6 ];
                work_reg [0][7 ] <= work_reg [1][7 ];
                work_reg [0][8 ] <= work_reg [1][8 ];
                work_reg [0][9 ] <= work_reg [1][9 ];
                work_reg [0][10] <= work_reg [1][10];
                work_reg [0][11] <= work_reg [1][11];
                work_reg [0][12] <= work_reg [1][12];
                work_reg [0][13] <= work_reg [1][13];
                work_reg [0][14] <= work_reg [1][14];
                work_reg [0][15] <= work_reg [1][15];
                work_reg [0][16] <= work_reg [1][16];
                work_reg [0][17] <= work_reg [1][16];

                // work_reg outside down round
                work_reg [17][0 ] <= work_reg [16][1 ];
                work_reg [17][1 ] <= work_reg [16][1 ];
                work_reg [17][2 ] <= work_reg [16][2 ];
                work_reg [17][3 ] <= work_reg [16][3 ];
                work_reg [17][4 ] <= work_reg [16][4 ];
                work_reg [17][5 ] <= work_reg [16][5 ];
                work_reg [17][6 ] <= work_reg [16][6 ];
                work_reg [17][7 ] <= work_reg [16][7 ];
                work_reg [17][8 ] <= work_reg [16][8 ];
                work_reg [17][9 ] <= work_reg [16][9 ];
                work_reg [17][10] <= work_reg [16][10];
                work_reg [17][11] <= work_reg [16][11];
                work_reg [17][12] <= work_reg [16][12];
                work_reg [17][13] <= work_reg [16][13];
                work_reg [17][14] <= work_reg [16][14];
                work_reg [17][15] <= work_reg [16][15];
                work_reg [17][16] <= work_reg [16][16];
                work_reg [17][17] <= work_reg [16][16];

                // work_reg outside two side
                work_reg [1 ][0 ] <= work_reg [1 ][1 ];
                work_reg [1 ][17] <= work_reg [1 ][16];
                work_reg [2 ][0 ] <= work_reg [2 ][1 ];
                work_reg [2 ][17] <= work_reg [2 ][16];
                work_reg [3 ][0 ] <= work_reg [3 ][1 ];
                work_reg [3 ][17] <= work_reg [3 ][16];
                work_reg [4 ][0 ] <= work_reg [4 ][1 ];
                work_reg [4 ][17] <= work_reg [4 ][16];
                work_reg [5 ][0 ] <= work_reg [5 ][1 ];
                work_reg [5 ][17] <= work_reg [5 ][16];
                work_reg [6 ][0 ] <= work_reg [6 ][1 ];
                work_reg [6 ][17] <= work_reg [6 ][16];
                work_reg [7 ][0 ] <= work_reg [7 ][1 ];
                work_reg [7 ][17] <= work_reg [7 ][16];
                work_reg [8 ][0 ] <= work_reg [8 ][1 ];
                work_reg [8 ][17] <= work_reg [8 ][16];
                work_reg [9 ][0 ] <= work_reg [9 ][1 ];
                work_reg [9 ][17] <= work_reg [9 ][16];
                work_reg [10][0 ] <= work_reg [10][1 ];
                work_reg [10][17] <= work_reg [10][16];
                work_reg [11][0 ] <= work_reg [11][1 ];
                work_reg [11][17] <= work_reg [11][16];
                work_reg [12][0 ] <= work_reg [12][1 ];
                work_reg [12][17] <= work_reg [12][16];
                work_reg [13][0 ] <= work_reg [13][1 ];
                work_reg [13][17] <= work_reg [13][16];
                work_reg [14][0 ] <= work_reg [14][1 ];
                work_reg [14][17] <= work_reg [14][16];
                work_reg [15][0 ] <= work_reg [15][1 ];
                work_reg [15][17] <= work_reg [15][16];
                work_reg [16][0 ] <= work_reg [16][1 ];
                work_reg [16][17] <= work_reg [16][16];
            end
        end
        else if ( nact == CROSS_COR & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin

                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;

                // work_reg outside down round
                work_reg [5][0] <= 'd0;
                work_reg [5][1] <= 'd0;
                work_reg [5][2] <= 'd0;
                work_reg [5][3] <= 'd0;
                work_reg [5][4] <= 'd0;
                work_reg [5][5] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][5] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][5] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][5] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][5] <= 'd0;
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;
                work_reg [0][6] <= 'd0;
                work_reg [0][7] <= 'd0;
                work_reg [0][8] <= 'd0;
                work_reg [0][9] <= 'd0;

                // work_reg [0][0] <= 'd8;
                // work_reg [0][1] <= 'd8;
                // work_reg [0][2] <= 'd8;
                // work_reg [0][3] <= 'd8;
                // work_reg [0][4] <= 'd8;
                // work_reg [0][5] <= 'd8;
                // work_reg [0][6] <= 'd8;
                // work_reg [0][7] <= 'd8;
                // work_reg [0][8] <= 'd8;
                // work_reg [0][9] <= 'd8;

                // work_reg outside down round
                work_reg [9][0] <= 'd0;
                work_reg [9][1] <= 'd0;
                work_reg [9][2] <= 'd0;
                work_reg [9][3] <= 'd0;
                work_reg [9][4] <= 'd0;
                work_reg [9][5] <= 'd0;
                work_reg [9][6] <= 'd0;
                work_reg [9][7] <= 'd0;
                work_reg [9][8] <= 'd0;
                work_reg [9][9] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][9] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][9] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][9] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][9] <= 'd0;
                work_reg [5][0] <= 'd0;
                work_reg [5][9] <= 'd0;
                work_reg [6][0] <= 'd0;
                work_reg [6][9] <= 'd0;
                work_reg [7][0] <= 'd0;
                work_reg [7][9] <= 'd0;
                work_reg [8][0] <= 'd0;
                work_reg [8][9] <= 'd0;
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0 ] <= 'd0;
                work_reg [0][1 ] <= 'd0;
                work_reg [0][2 ] <= 'd0;
                work_reg [0][3 ] <= 'd0;
                work_reg [0][4 ] <= 'd0;
                work_reg [0][5 ] <= 'd0;
                work_reg [0][6 ] <= 'd0;
                work_reg [0][7 ] <= 'd0;
                work_reg [0][8 ] <= 'd0;
                work_reg [0][9 ] <= 'd0;
                work_reg [0][10] <= 'd0;
                work_reg [0][11] <= 'd0;
                work_reg [0][12] <= 'd0;
                work_reg [0][13] <= 'd0;
                work_reg [0][14] <= 'd0;
                work_reg [0][15] <= 'd0;
                work_reg [0][16] <= 'd0;
                work_reg [0][17] <= 'd0;

                // work_reg outside down round
                work_reg [17][0 ] <= 'd0;
                work_reg [17][1 ] <= 'd0;
                work_reg [17][2 ] <= 'd0;
                work_reg [17][3 ] <= 'd0;
                work_reg [17][4 ] <= 'd0;
                work_reg [17][5 ] <= 'd0;
                work_reg [17][6 ] <= 'd0;
                work_reg [17][7 ] <= 'd0;
                work_reg [17][8 ] <= 'd0;
                work_reg [17][9 ] <= 'd0;
                work_reg [17][10] <= 'd0;
                work_reg [17][11] <= 'd0;
                work_reg [17][12] <= 'd0;
                work_reg [17][13] <= 'd0;
                work_reg [17][14] <= 'd0;
                work_reg [17][15] <= 'd0;
                work_reg [17][16] <= 'd0;
                work_reg [17][17] <= 'd0;

                // work_reg outside two side
                work_reg [1 ][0 ] <= 'd0;
                work_reg [1 ][17] <= 'd0;
                work_reg [2 ][0 ] <= 'd0;
                work_reg [2 ][17] <= 'd0;
                work_reg [3 ][0 ] <= 'd0;
                work_reg [3 ][17] <= 'd0;
                work_reg [4 ][0 ] <= 'd0;
                work_reg [4 ][17] <= 'd0;
                work_reg [5 ][0 ] <= 'd0;
                work_reg [5 ][17] <= 'd0;
                work_reg [6 ][0 ] <= 'd0;
                work_reg [6 ][17] <= 'd0;
                work_reg [7 ][0 ] <= 'd0;
                work_reg [7 ][17] <= 'd0;
                work_reg [8 ][0 ] <= 'd0;
                work_reg [8 ][17] <= 'd0;
                work_reg [9 ][0 ] <= 'd0;
                work_reg [9 ][17] <= 'd0;
                work_reg [10][0 ] <= 'd0;
                work_reg [10][17] <= 'd0;
                work_reg [11][0 ] <= 'd0;
                work_reg [11][17] <= 'd0;
                work_reg [12][0 ] <= 'd0;
                work_reg [12][17] <= 'd0;
                work_reg [13][0 ] <= 'd0;
                work_reg [13][17] <= 'd0;
                work_reg [14][0 ] <= 'd0;
                work_reg [14][17] <= 'd0;
                work_reg [15][0 ] <= 'd0;
                work_reg [15][17] <= 'd0;
                work_reg [16][0 ] <= 'd0;
                work_reg [16][17] <= 'd0;
            end
        end
    end

    else if ( cs  == MAX_POOLING) begin
        case (img_size_reg)
            1 : begin
                case (img_cnt)
                    0:begin
                        for (i=1 ;i<=8;i=i+1) for(j=0;j<=6;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=4;i=i+1)  work_reg[i][7] <= MPo[i-1 ];
                    end
                    1:begin
                        for (i=1 ;i<=8;i=i+1) for(j=0 ;j<=5;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        // for (i=1 ;i<=16;i=i+1) for(j=15;j<=15;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=4;i=i+1)  work_reg[i][6] <= MPo[i-1 ];
                    end
                    2:begin
                        for (i=1 ;i<=8;i=i+1) for(j=0 ;j<=4;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1) for(j=6 ;j<=6;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=4;i=i+1)  work_reg[i][5] <= MPo[i-1 ];
                    end
                    3:begin
                        for (i=1 ;i<=8;i=i+1) for(j=0 ;j<=3;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1) for(j=5 ;j<=6;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=4;i=i+1)  work_reg[i][4] <= MPo[i-1 ];
                    end

                    default:  ;
                endcase
            end
            2 : begin
                case (img_cnt)
                    0:begin
                        for (i=1 ;i<=16;i=i+1) for(j=0;j<=14;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1)  work_reg[i][15] <= MPo[i-1 ];
                    end
                    1:begin
                        for (i=1 ;i<=16;i=i+1) for(j=0 ;j<=13;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        // for (i=1 ;i<=16;i=i+1) for(j=15;j<=15;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1)  work_reg[i][14] <= MPo[i-1 ];
                    end
                    2:begin
                        for (i=1 ;i<=16;i=i+1) for(j=0 ;j<=12;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=16;i=i+1) for(j=14;j<=14;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1)  work_reg[i][13] <= MPo[i-1 ];
                    end
                    3:begin
                        for (i=1 ;i<=16;i=i+1) for(j=0 ;j<=11;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=16;i=i+1) for(j=13;j<=14;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1)  work_reg[i][12] <= MPo[i-1 ];
                    end
                    4:begin
                        for (i=1 ;i<=16;i=i+1) for(j=0 ;j<=10;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=16;i=i+1) for(j=12;j<=14;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1)  work_reg[i][11] <= MPo[i-1 ];
                        end
                    5:begin
                        for (i=1 ;i<=16;i=i+1) for(j=0 ;j<=9;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=16;i=i+1) for(j=11;j<=14;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1)  work_reg[i][10] <= MPo[i-1 ];
                    end
                    6:begin
                        for (i=1 ;i<=16;i=i+1) for(j=0 ;j<=8;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=16;i=i+1) for(j=10;j<=14;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1)  work_reg[i][9] <= MPo[i-1 ];
                    end
                    7:begin
                        for (i=1 ;i<=16;i=i+1) for(j=0 ;j<=7;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=16;i=i+1) for(j=9;j<=14;j=j+1) work_reg[i][j] <= work_reg[i][j+2];
                        for (i=1 ;i<=8;i=i+1)  work_reg[i][8] <= MPo[i-1 ];
                    end
                    default:  ;
                endcase
            end
            default: for (i=0 ;i<=17;i=i+1) for(j=0;j<=17;j=j+1) work_reg[i][j] <= work_reg[i][j];
        endcase
        if ( nact == IMAGE_FILTER & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][4];


                // work_reg outside down round
                work_reg [5][0] <= work_reg [4][1];
                work_reg [5][1] <= work_reg [4][1];
                work_reg [5][2] <= work_reg [4][2];
                work_reg [5][3] <= work_reg [4][3];
                work_reg [5][4] <= work_reg [4][4];
                work_reg [5][5] <= work_reg [4][4];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][5] <= work_reg [1][4];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][5] <= work_reg [2][4];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][5] <= work_reg [3][4];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][5] <= work_reg [4][4];
            end
            else if (img_size_reg == 'd1) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][4];


                // work_reg outside down round
                work_reg [5][0] <= work_reg [4][1];
                work_reg [5][1] <= work_reg [4][1];
                work_reg [5][2] <= work_reg [4][2];
                work_reg [5][3] <= work_reg [4][3];
                work_reg [5][4] <= work_reg [4][4];
                work_reg [5][5] <= work_reg [4][4];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][5] <= work_reg [1][4];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][5] <= work_reg [2][4];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][5] <= work_reg [3][4];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][5] <= work_reg [4][4];
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0] <= work_reg [1][1];
                work_reg [0][1] <= work_reg [1][1];
                work_reg [0][2] <= work_reg [1][2];
                work_reg [0][3] <= work_reg [1][3];
                work_reg [0][4] <= work_reg [1][4];
                work_reg [0][5] <= work_reg [1][5];
                work_reg [0][6] <= work_reg [1][6];
                work_reg [0][7] <= work_reg [1][7];
                work_reg [0][8] <= work_reg [1][8];
                work_reg [0][9] <= work_reg [1][8];

                // work_reg [0][0] <= 'd0;
                // work_reg [0][1] <= 'd0;
                // work_reg [0][2] <= 'd0;
                // work_reg [0][3] <= 'd0;
                // work_reg [0][4] <= 'd0;
                // work_reg [0][5] <= 'd0;
                // work_reg [0][6] <= 'd0;
                // work_reg [0][7] <= 'd0;
                // work_reg [0][8] <= 'd0;
                // work_reg [0][9] <= 'd0;

                // work_reg outside down round
                work_reg [9][0] <= work_reg [8][1];
                work_reg [9][1] <= work_reg [8][1];
                work_reg [9][2] <= work_reg [8][2];
                work_reg [9][3] <= work_reg [8][3];
                work_reg [9][4] <= work_reg [8][4];
                work_reg [9][5] <= work_reg [8][5];
                work_reg [9][6] <= work_reg [8][6];
                work_reg [9][7] <= work_reg [8][7];
                work_reg [9][8] <= work_reg [8][8];
                work_reg [9][9] <= work_reg [8][8];

                // work_reg outside two side
                work_reg [1][0] <= work_reg [1][1];
                work_reg [1][9] <= work_reg [1][8];
                work_reg [2][0] <= work_reg [2][1];
                work_reg [2][9] <= work_reg [2][8];
                work_reg [3][0] <= work_reg [3][1];
                work_reg [3][9] <= work_reg [3][8];
                work_reg [4][0] <= work_reg [4][1];
                work_reg [4][9] <= work_reg [4][8];
                work_reg [5][0] <= work_reg [5][1];
                work_reg [5][9] <= work_reg [5][8];
                work_reg [6][0] <= work_reg [6][1];
                work_reg [6][9] <= work_reg [6][8];
                work_reg [7][0] <= work_reg [7][1];
                work_reg [7][9] <= work_reg [7][8];
                work_reg [8][0] <= work_reg [8][1];
                work_reg [8][9] <= work_reg [8][8];
            end
        end
        else if ( nact == CROSS_COR & (max_pooling_end | negative_end | horizontal_flip_end |image_filter_end |cross_cor_end | input_act_end_delay2) ) begin
            if ( img_size_reg == 'd0) begin

                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;

                // work_reg outside down round
                work_reg [5][0] <= 'd0;
                work_reg [5][1] <= 'd0;
                work_reg [5][2] <= 'd0;
                work_reg [5][3] <= 'd0;
                work_reg [5][4] <= 'd0;
                work_reg [5][5] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][5] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][5] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][5] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][5] <= 'd0;
            end
            else if (img_size_reg == 'd1) begin

                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;

                // work_reg outside down round
                work_reg [5][0] <= 'd0;
                work_reg [5][1] <= 'd0;
                work_reg [5][2] <= 'd0;
                work_reg [5][3] <= 'd0;
                work_reg [5][4] <= 'd0;
                work_reg [5][5] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][5] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][5] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][5] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][5] <= 'd0;
            end
            else if (img_size_reg == 'd2) begin
                // work_reg outside up round
                work_reg [0][0] <= 'd0;
                work_reg [0][1] <= 'd0;
                work_reg [0][2] <= 'd0;
                work_reg [0][3] <= 'd0;
                work_reg [0][4] <= 'd0;
                work_reg [0][5] <= 'd0;
                work_reg [0][6] <= 'd0;
                work_reg [0][7] <= 'd0;
                work_reg [0][8] <= 'd0;
                work_reg [0][9] <= 'd0;

                // work_reg outside down round
                work_reg [9][0] <= 'd0;
                work_reg [9][1] <= 'd0;
                work_reg [9][2] <= 'd0;
                work_reg [9][3] <= 'd0;
                work_reg [9][4] <= 'd0;
                work_reg [9][5] <= 'd0;
                work_reg [9][6] <= 'd0;
                work_reg [9][7] <= 'd0;
                work_reg [9][8] <= 'd0;
                work_reg [9][9] <= 'd0;

                // work_reg outside two side
                work_reg [1][0] <= 'd0;
                work_reg [1][9] <= 'd0;
                work_reg [2][0] <= 'd0;
                work_reg [2][9] <= 'd0;
                work_reg [3][0] <= 'd0;
                work_reg [3][9] <= 'd0;
                work_reg [4][0] <= 'd0;
                work_reg [4][9] <= 'd0;
                work_reg [5][0] <= 'd0;
                work_reg [5][9] <= 'd0;
                work_reg [6][0] <= 'd0;
                work_reg [6][9] <= 'd0;
                work_reg [7][0] <= 'd0;
                work_reg [7][9] <= 'd0;
                work_reg [8][0] <= 'd0;
                work_reg [8][9] <= 'd0;
            end
        end
    end
    else if ( cs  == CROSS_COR) begin
        case (img_size_reg)
            0 :begin
                if ( (( !first_st & out_bit_cnt == 'd9) | ( first_st & out_bit_cnt == 'd19)) )begin
                    // if (((cross_out_cnt - 'd6)% 'd8) =='d0) begin
                    if (((cross_out_cnt - 'd2)% 'd4) =='d0) begin
                        for ( i=0 ; i<=5 ;i=i+1) for ( j=0 ; j<=2 ;j=j+1) work_reg [i][j] <= work_reg [i][j+3];
                        for ( i=0 ; i<=4 ;i=i+1)  begin
                            work_reg [i][3] <= work_reg [i+1][0];
                            work_reg [i][4] <= work_reg [i+1][1];
                            work_reg [i][5] <= work_reg [i+1][2];
                        end
                    end
                    else begin
                        for ( i=0 ; i<=5 ;i=i+1) for ( j=0 ; j<=4 ;j=j+1) work_reg [i][j] <= work_reg [i][j+1];
                        for ( i=0 ; i<=4 ;i=i+1)  work_reg [i][5] <= work_reg [i+1][0];
                    end
                end
            end
            1 : begin
                if ( (( !first_st & out_bit_cnt == 'd9) | ( first_st & out_bit_cnt == 'd19)) )begin
                    if (((cross_out_cnt - 'd6)% 'd8) =='d0) begin
                        for ( i=0 ; i<=9 ;i=i+1) for ( j=0 ; j<=6 ;j=j+1) work_reg [i][j] <= work_reg [i][j+3];
                        for ( i=0 ; i<=8 ;i=i+1)  begin
                            work_reg [i][7] <= work_reg [i+1][0];
                            work_reg [i][8] <= work_reg [i+1][1];
                            work_reg [i][9] <= work_reg [i+1][2];
                        end
                    end
                    else begin
                        for ( i=0 ; i<=9 ;i=i+1) for ( j=0 ; j<=8 ;j=j+1) work_reg [i][j] <= work_reg [i][j+1];
                        for ( i=0 ; i<=8 ;i=i+1)  work_reg [i][9] <= work_reg [i+1][0];
                    end
                end
            end
            2 : begin
                if ( (( !first_st & out_bit_cnt == 'd9) | ( first_st & out_bit_cnt == 'd19)) )begin
                    if (((cross_out_cnt - 'd14) % 'd16 )=='d0) begin
                        for ( i=0 ; i<=17 ;i=i+1) for ( j=0 ; j<=14 ;j=j+1) work_reg [i][j] <= work_reg [i][j+3];
                        for ( i=0 ; i<=16 ;i=i+1)  begin
                            work_reg [i][15] <= work_reg [i+1][0];
                            work_reg [i][16] <= work_reg [i+1][1];
                            work_reg [i][17] <= work_reg [i+1][2];
                        end
                    end
                    else begin
                        for ( i=0 ; i<=17 ;i=i+1) for ( j=0 ; j<=16 ;j=j+1) work_reg [i][j] <= work_reg [i][j+1];
                        for ( i=0 ; i<=16 ;i=i+1)  work_reg [i][17] <= work_reg [i+1][0];
                    end
                end
            end
            default: for (i=0 ;i<=17;i=i+1) for(j=0;j<=17;j=j+1) work_reg[i][j] <= work_reg[i][j];
        endcase
    end
end



//==================================================================
// GrayMax, GrayAvg, GrayWeight
//==================================================================


wire [7:0] gray_max_med_pe, gray_avg, gray_weight;
Med_PE Gray_Max_Med_PE ( .A  (work_reg[0][0]), .B  (work_reg[0][1]), .C  (work_reg[0][2]), .max(gray_max_med_pe) );

assign gray_avg = (work_reg[0][0][7:0] + work_reg[0][1][7:0] + work_reg[0][2][7:0]) / 'd3;
assign gray_weight = (work_reg[0][0][7:0] >> 2) + (work_reg[0][1][7:0] >> 1 ) + ( work_reg[0][2][7:0] >> 2);

always @( * ) begin
    if( cs ==INPUT_DATA)
        WEBGray = !((img_cnt % 'd3) == 'd0 & img_cnt != 'd0) |(img_cnt == 'd16 & img_size_reg == 'd0) | (img_cnt == 'd64 & img_size_reg == 'd1) | (img_cnt == 'd256 & img_size_reg == 'd2);
    else WEBGray ='d1;
end

//MemGray_adr
always @( * ) begin
    case (cs)
        INPUT_DATA: MemGray_adr = img_cnt / 'd3 - 'd1;
        INPUT_ACT : MemGray_adr = cnt256;
        default: MemGray_adr = cnt256;
    endcase
end

//MemGray_Di
always @( * ) begin
    case (cs)
        INPUT_DATA: begin
            MemGrayMax_Di     = gray_max_med_pe ;
            MemGrayAvg_Di     = gray_avg        ;
            MemGrayWeight_Di  = gray_weight     ;
        end
        default :begin
            MemGrayMax_Di     = 'd0 ;
            MemGrayAvg_Di     = 'd0 ;
            MemGrayWeight_Di  = 'd0 ;
        end
    endcase
end


// GRAY_MAX = 4'd0, GRAY_AVG = 4'd1,  GRAY_WEIGHT = 4'd2
assign Gray_out_port =  ( act_reg[0] == 4'd0 ) ? MemGrayMax_Do :
                        ( act_reg[0] == 4'd1 ) ? MemGrayAvg_Do : MemGrayWeight_Do;

TEST_MEM8X16X16S MemGrayMax (   .A0  (MemGray_adr     [0 ]) , .A1  (MemGray_adr     [1 ]), .A2  (MemGray_adr     [2 ]), .A3  (MemGray_adr     [3 ]), .A4  (MemGray_adr     [4 ]), .A5  (MemGray_adr     [5 ]), .A6  (MemGray_adr     [6 ]), .A7  (MemGray_adr     [7 ]),
                                .DO0 (MemGrayMax_Do   [0 ]) , .DO1 (MemGrayMax_Do   [1 ]), .DO2 (MemGrayMax_Do   [2 ]), .DO3 (MemGrayMax_Do   [3 ]), .DO4 (MemGrayMax_Do   [4 ]), .DO5 (MemGrayMax_Do   [5 ]), .DO6 (MemGrayMax_Do   [6 ]), .DO7 (MemGrayMax_Do   [7 ]),
                                .DI0 (MemGrayMax_Di   [0 ]) , .DI1 (MemGrayMax_Di   [1 ]), .DI2 (MemGrayMax_Di   [2 ]), .DI3 (MemGrayMax_Di   [3 ]), .DI4 (MemGrayMax_Di   [4 ]), .DI5 (MemGrayMax_Di   [5 ]), .DI6 (MemGrayMax_Di   [6 ]), .DI7 (MemGrayMax_Di   [7 ]),
                                .CK(clk), .WEB(WEBGray), .OE(1'd1), .CS(1'd1));

TEST_MEM8X16X16S MemGrayAvg (   .A0  (MemGray_adr     [0 ]) , .A1  (MemGray_adr     [1 ]), .A2  (MemGray_adr     [2 ]), .A3  (MemGray_adr     [3 ]), .A4  (MemGray_adr     [4 ]), .A5  (MemGray_adr     [5 ]), .A6  (MemGray_adr     [6 ]), .A7  (MemGray_adr     [7 ]),
                                .DO0 (MemGrayAvg_Do   [0 ]) , .DO1 (MemGrayAvg_Do   [1 ]), .DO2 (MemGrayAvg_Do   [2 ]), .DO3 (MemGrayAvg_Do   [3 ]), .DO4 (MemGrayAvg_Do   [4 ]), .DO5 (MemGrayAvg_Do   [5 ]), .DO6 (MemGrayAvg_Do   [6 ]), .DO7 (MemGrayAvg_Do   [7 ]),
                                .DI0 (MemGrayAvg_Di   [0 ]) , .DI1 (MemGrayAvg_Di   [1 ]), .DI2 (MemGrayAvg_Di   [2 ]), .DI3 (MemGrayAvg_Di   [3 ]), .DI4 (MemGrayAvg_Di   [4 ]), .DI5 (MemGrayAvg_Di   [5 ]), .DI6 (MemGrayAvg_Di   [6 ]), .DI7 (MemGrayAvg_Di   [7 ]),
                                .CK(clk), .WEB(WEBGray), .OE(1'd1), .CS(1'd1));

TEST_MEM8X16X16S MemGrayWeight (.A0  (MemGray_adr     [0 ]) , .A1  (MemGray_adr     [1 ]), .A2  (MemGray_adr     [2 ]), .A3  (MemGray_adr     [3 ]), .A4  (MemGray_adr     [4 ]), .A5  (MemGray_adr     [5 ]), .A6  (MemGray_adr     [6 ]), .A7  (MemGray_adr     [7 ]),
                                .DO0 (MemGrayWeight_Do[0 ]) , .DO1 (MemGrayWeight_Do[1 ]), .DO2 (MemGrayWeight_Do[2 ]), .DO3 (MemGrayWeight_Do[3 ]), .DO4 (MemGrayWeight_Do[4 ]), .DO5 (MemGrayWeight_Do[5 ]), .DO6 (MemGrayWeight_Do[6 ]), .DO7 (MemGrayWeight_Do[7 ]),
                                .DI0 (MemGrayWeight_Di[0 ]) , .DI1 (MemGrayWeight_Di[1 ]), .DI2 (MemGrayWeight_Di[2 ]), .DI3 (MemGrayWeight_Di[3 ]), .DI4 (MemGrayWeight_Di[4 ]), .DI5 (MemGrayWeight_Di[5 ]), .DI6 (MemGrayWeight_Di[6 ]), .DI7 (MemGrayWeight_Di[7 ]),
                                .CK(clk), .WEB(WEBGray), .OE(1'd1), .CS(1'd1));



//==================================================================
// MAX_POOLING
//==================================================================
generate
    for ( a=0 ; a<8 ; a=a+1) begin :MP
        MaxPooling_PE MP ( .MP_i0(MPi[a ][0]), .MP_i1(MPi[a ][1]), .MP_i2(MPi[a ][2]), .MP_i3(MPi[a ][3]), .MP_o (MPo[a ]) );
    end
endgenerate

// MPi[0~7]
always @(*) begin
    for ( i=0 ; i<=7 ; i=i+1 ) begin
        for ( j=0 ; j<=1 ;j=j+1 ) begin MPi[i][j] = work_reg[i*2+1][1+j]  ; end
        for ( j=2 ; j<=3 ;j=j+1 ) begin MPi[i][j] = work_reg[i*2+2][1+j%2]; end
    end
end

//==================================================================
// IMAGE_FILTER
//==================================================================

// Medin
always @(*) begin
    if ( img_size_reg == 'd0 )begin
        for (i=0 ; i<4 ; i=i+1) begin
            Med_in[i ][0] = work_reg [i  ][0];
            Med_in[i ][1] = work_reg [i  ][1];
            Med_in[i ][2] = work_reg [i  ][2];
            Med_in[i ][3] = work_reg [i+1][0];
            Med_in[i ][4] = work_reg [i+1][1];
            Med_in[i ][5] = work_reg [i+1][2];
            Med_in[i ][6] = work_reg [i+2][0];
            Med_in[i ][7] = work_reg [i+2][1];
            Med_in[i ][8] = work_reg [i+2][2];
        end

        for (i=4 ; i<8 ; i=i+1) begin
            Med_in[i ][0] = work_reg [i-4][1];
            Med_in[i ][1] = work_reg [i-4][2];
            Med_in[i ][2] = work_reg [i-4][3];
            Med_in[i ][3] = work_reg [i-3][1];
            Med_in[i ][4] = work_reg [i-3][2];
            Med_in[i ][5] = work_reg [i-3][3];
            Med_in[i ][6] = work_reg [i-2][1];
            Med_in[i ][7] = work_reg [i-2][2];
            Med_in[i ][8] = work_reg [i-2][3];
        end

        for (i=8 ; i<12 ; i=i+1) begin
            Med_in[i ][0] = work_reg [i-8][2];
            Med_in[i ][1] = work_reg [i-8][3];
            Med_in[i ][2] = work_reg [i-8][4];
            Med_in[i ][3] = work_reg [i-7][2];
            Med_in[i ][4] = work_reg [i-7][3];
            Med_in[i ][5] = work_reg [i-7][4];
            Med_in[i ][6] = work_reg [i-6][2];
            Med_in[i ][7] = work_reg [i-6][3];
            Med_in[i ][8] = work_reg [i-6][4];
        end

        for (i=12 ; i<16 ; i=i+1) begin
            Med_in[i ][0] = work_reg [i-12][3];
            Med_in[i ][1] = work_reg [i-12][4];
            Med_in[i ][2] = work_reg [i-12][5];
            Med_in[i ][3] = work_reg [i-11][3];
            Med_in[i ][4] = work_reg [i-11][4];
            Med_in[i ][5] = work_reg [i-11][5];
            Med_in[i ][6] = work_reg [i-10][3];
            Med_in[i ][7] = work_reg [i-10][4];
            Med_in[i ][8] = work_reg [i-10][5];
        end

    end
    else if (img_size_reg == 'd1) begin
        for (i=0 ; i<8 ; i=i+1) begin
            Med_in[i ][0] = work_reg [i  ][0];
            Med_in[i ][1] = work_reg [i  ][1];
            Med_in[i ][2] = work_reg [i  ][2];
            Med_in[i ][3] = work_reg [i+1][0];
            Med_in[i ][4] = work_reg [i+1][1];
            Med_in[i ][5] = work_reg [i+1][2];
            Med_in[i ][6] = work_reg [i+2][0];
            Med_in[i ][7] = work_reg [i+2][1];
            Med_in[i ][8] = work_reg [i+2][2];
        end
        for (i=8 ; i<16 ; i=i+1) begin
            Med_in[i ][0] = work_reg [i-8][4];
            Med_in[i ][1] = work_reg [i-8][5];
            Med_in[i ][2] = work_reg [i-8][6];
            Med_in[i ][3] = work_reg [i-7][4];
            Med_in[i ][4] = work_reg [i-7][5];
            Med_in[i ][5] = work_reg [i-7][6];
            Med_in[i ][6] = work_reg [i-6][4];
            Med_in[i ][7] = work_reg [i-6][5];
            Med_in[i ][8] = work_reg [i-6][6];
        end
    end
    else  if (img_size_reg == 'd2) begin
        for (i=0 ; i<16 ; i=i+1) begin
            Med_in[i ][0] = work_reg [i  ][0];
            Med_in[i ][1] = work_reg [i  ][1];
            Med_in[i ][2] = work_reg [i  ][2];
            Med_in[i ][3] = work_reg [i+1][0];
            Med_in[i ][4] = work_reg [i+1][1];
            Med_in[i ][5] = work_reg [i+1][2];
            Med_in[i ][6] = work_reg [i+2][0];
            Med_in[i ][7] = work_reg [i+2][1];
            Med_in[i ][8] = work_reg [i+2][2];
        end
    end
    else for (i=0 ; i<16 ; i=i+1) for (j=0 ; j<9 ; j=j+1) Med_in[i ][j] = 'd0;
end

generate
    for (a = 0 ; a <= 15 ; a = a+1) begin :Med
        Med Med00 ( .A (Med_in[a ][0][7:0]), .B (Med_in[a ][1][7:0]), .C (Med_in[a ][2][7:0]), .D (Med_in[a ][3][7:0]), .E (Med_in[a ][4][7:0]), .F (Med_in[a ][5][7:0]), .G (Med_in[a ][6][7:0]), .H (Med_in[a ][7][7:0]), .I (Med_in[a ][8][7:0]), .med (Med_out[a ]) );
    end
endgenerate



//==================================================================
// CROSS_COR & OUTPUT
//==================================================================

wire  st;
reg  [19:0]out_reg;
wire [19:0] PPLCV_PE_out;
wire [19:0] PPLCV_PE_out_n;
wire  [3:0] PPLCV_COMP_cnt;

ConV_PE ConV_PE (
        .clk           (clk)  ,
        .rst_n         (rst_n)  ,
        .st            (st)  ,
        .Ker1          (template_reg[0][7:0])  ,
        .Ker2          (template_reg[1][7:0])  ,
        .Ker3          (template_reg[2][7:0])  ,
        .Ker4          (template_reg[3][7:0])  ,
        .Ker5          (template_reg[4][7:0])  ,
        .Ker6          (template_reg[5][7:0])  ,
        .Ker7          (template_reg[6][7:0])  ,
        .Ker8          (template_reg[7][7:0])  ,
        .Ker9          (template_reg[8][7:0])  ,
        .Pad1          (work_reg[0][0])  ,
        .Pad2          (work_reg[0][1])  ,
        .Pad3          (work_reg[0][2])  ,
        .Pad4          (work_reg[1][0])  ,
        .Pad5          (work_reg[1][1])  ,
        .Pad6          (work_reg[1][2])  ,
        .Pad7          (work_reg[2][0])  ,
        .Pad8          (work_reg[2][1])  ,
        .Pad9          (work_reg[2][2])  ,
		.BP1           (PPLCV_PE_out)    ,
        .PPLCV_PE_out_n(PPLCV_PE_out_n)  ,
		.PPLCV_COMP_cnt(PPLCV_COMP_cnt)
    );


// first_st
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) first_st <= 'd0;
    else if ( cs == CROSS_COR & out_bit_cnt == 'd9 & cross_out_cnt == 'd0) first_st <= 'd1;
    else if ( cross_cor_end_delay ) first_st <= 'd0;
    else first_st <= first_st;
end

assign st = cs == CROSS_COR & (!first_st & ( (out_bit_cnt == 'd0) & (cross_out_cnt == 'd0)) | first_st & (out_bit_cnt == 'd0) );

// out_bit_cnt
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_bit_cnt <= 'd0;
    else if ( !first_st & out_bit_cnt =='d9) out_bit_cnt <= 'd0;
    else if ( out_bit_cnt == 'd19) out_bit_cnt <= 'd0;
    else if ( cs == CROSS_COR ) out_bit_cnt <= out_bit_cnt + 'd1;
    else  out_bit_cnt <= out_bit_cnt;
end
// cross_out_cnt
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cross_out_cnt <= 'd0;
        else if ( cross_cor_end_delay ) cross_out_cnt <= 'd0;
    else if ( cs == CROSS_COR & out_bit_cnt == 'd19 ) cross_out_cnt <= cross_out_cnt +'d1;

end


reg n_out_valid ;
reg [19:0]n_out_value ;

//out_valid & n_out_valid
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_valid <= 'd0;
    else out_valid <= n_out_valid;
end

always @(*) begin
    // if ( ! out_valid ) n_out_valid = (cs == CROSS_COR) & (out_bit_cnt == 'd8) ;
    if ( ! out_valid ) n_out_valid = (cs == CROSS_COR) & (first_st) ;
    else    n_out_valid = (cross_cor_end_delay) ? 'd0 : 'd1;
end

//out_value & n_out_value
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_value <= 'd0;
    else out_value <= n_out_value;
end

always @( *) begin
    n_out_value =  (n_out_valid) ? out_reg[19] : 'd0;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_reg <= 'd0;
    else if ( cs == CROSS_COR & (  ( !first_st & out_bit_cnt == 'd9) | ( first_st & (out_bit_cnt == 'd19)))) out_reg <= PPLCV_PE_out;
    else out_reg <= out_reg <<1;
end

endmodule











//==================================================================
//
//
//                          SUB MODULE
//
//
//==================================================================



//==================================================================
// IMAGE_FILTER :  Med
//==================================================================

module Med (
    input [7:0]      A    ,
    input [7:0]      B    ,
    input [7:0]      C    ,
    input [7:0]      D    ,
    input [7:0]      E    ,
    input [7:0]      F    ,
    input [7:0]      G    ,
    input [7:0]      H    ,
    input [7:0]      I    ,
    output [7:0] med
    );
    integer i,j,k,m,n,p,q;
    wire [7:0] max1[2:0], med1[2:0], min1[2:0];
    wire [7:0] max2[2:0], med2[2:0], min2[2:0];

    Med_PE Mid_PE01(
    .A  (A),
    .B  (B),
    .C  (C),
    .max(max1[0][7:0]),
    .med(med1[0][7:0]),
    .min(min1[0][7:0])
    );

    Med_PE Mid_PE02(
    .A  (D),
    .B  (E),
    .C  (F),
    .max(max1[1][7:0]),
    .med(med1[1][7:0]),
    .min(min1[1][7:0])
    );

    Med_PE Mid_PE03(
    .A  (G),
    .B  (H),
    .C  (I),
    .max(max1[2][7:0]),
    .med(med1[2][7:0]),
    .min(min1[2][7:0])
    );


    Med_PE Mid_PE11(
    .A  (max1[0][7:0]),
    .B  (max1[1][7:0]),
    .C  (max1[2][7:0]),
    .max(max2[0][7:0]),
    .med(med2[0][7:0]),
    .min(min2[0][7:0])
    );

    Med_PE Mid_PE12(
    .A  (med1[0][7:0]),
    .B  (med1[1][7:0]),
    .C  (med1[2][7:0]),
    .max(max2[1][7:0]),
    .med(med2[1][7:0]),
    .min(min2[1][7:0])
    );

    Med_PE Mid_PE13(
    .A  (min1[0][7:0]),
    .B  (min1[1][7:0]),
    .C  (min1[2][7:0]),
    .max(max2[2][7:0]),
    .med(med2[2][7:0]),
    .min(min2[2][7:0])
    );

    Med_PE Mid_PE21(
    .A  (min2[0][7:0]),
    .B  (med2[1][7:0]),
    .C  (max2[2][7:0]),
    // .max(max2[2][7:0]),
    .med(med)
    // .min(min2[2][7:0])
    );

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
//CROSS_COR
//==================================================================
// if st rise is the first cycle,
// comb output can be used at the 8th cycle
// reg output can be used at the 9th cycle

// st isn't needed to be kept , and reg output will keep until next st rise.
// Ker, Pad should be kept.


module ConV_PE (
        input               clk             ,
        input               rst_n           ,
        input               st              ,
        input [7:0]         Ker1            ,
        input [7:0]         Ker2            ,
        input [7:0]         Ker3            ,
        input [7:0]         Ker4            ,
        input [7:0]         Ker5            ,
        input [7:0]         Ker6            ,
        input [7:0]         Ker7            ,
        input [7:0]         Ker8            ,
        input [7:0]         Ker9            ,
        input [7:0]         Pad1            ,
        input [7:0]         Pad2            ,
        input [7:0]         Pad3            ,
        input [7:0]         Pad4            ,
        input [7:0]         Pad5            ,
        input [7:0]         Pad6            ,
        input [7:0]         Pad7            ,
        input [7:0]         Pad8            ,
        input [7:0]         Pad9            ,
		output reg [19:0]   BP1             ,
        output [19:0]       PPLCV_PE_out_n  ,
		output reg  [3:0]   PPLCV_COMP_cnt
    );

    // Ker1 Ker2 Ker3   Pad1 Pad2 Pad3
    // Ker4 Ker5 Ker6   Pad4 Pad5 Pad6
    // Ker7 Ker8 Ker9   Pad7 Pad8 Pad9

    //reg  [2:0] PPLCV_COMP_cnt;
    reg   [7:0] Ker_in1 ;
    reg   [7:0] Pad_in1 ;

    wire  [19:0] addin1,addin2;
    wire  [15:0] mult_out;
    wire add_in_sel;

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) PPLCV_COMP_cnt <= 'd0;
        else if (PPLCV_COMP_cnt == 'd8) PPLCV_COMP_cnt <= 'd0 ;
        else if  (st | PPLCV_COMP_cnt != 'd0) PPLCV_COMP_cnt <= PPLCV_COMP_cnt +'d1;
        else  PPLCV_COMP_cnt <= PPLCV_COMP_cnt;
    end

    //mult_out
    always @(*) begin
        case (PPLCV_COMP_cnt)
            0: begin Ker_in1 = Ker1; Pad_in1 = Pad1; end
            1: begin Ker_in1 = Ker2; Pad_in1 = Pad2; end
            2: begin Ker_in1 = Ker3; Pad_in1 = Pad3; end
            3: begin Ker_in1 = Ker4; Pad_in1 = Pad4; end
            4: begin Ker_in1 = Ker5; Pad_in1 = Pad5; end
            5: begin Ker_in1 = Ker6; Pad_in1 = Pad6; end
            6: begin Ker_in1 = Ker7; Pad_in1 = Pad7; end
            7: begin Ker_in1 = Ker8; Pad_in1 = Pad8; end
            8: begin Ker_in1 = Ker9; Pad_in1 = Pad9; end
            9: begin Ker_in1 = 'd10; Pad_in1 = 'd10; end
            default: begin Ker_in1 = Ker1; Pad_in1 = Pad1; end
        endcase
    end

    assign mult_out = Ker_in1 * Pad_in1;
    assign addin1 = {4'd0, mult_out};
    assign addin2 = (PPLCV_COMP_cnt == 'd0) ? 20'd0 : BP1;
    assign PPLCV_PE_out_n = addin1 + addin2;


    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) BP1 <='d0;
        else if (st | PPLCV_COMP_cnt != 'd0 ) BP1 <= PPLCV_PE_out_n;
        else BP1 <= BP1;
    end
endmodule
