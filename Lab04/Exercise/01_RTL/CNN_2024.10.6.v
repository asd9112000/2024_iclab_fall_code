//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Convolution Neural Network
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CNN.v
//   Module Name : CNN
//   Release version : V1.0 (Release Date: 2024-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################




module CNN(
// module CNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel_ch1,
    Kernel_ch2,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch_type = 0;
parameter inst_arch = 0;
parameter inst_faithful_round = 0;

// parameter IDLE = 3'd0;
// parameter IN = 3'd1;
// parameter CAL = 3'd2;
// parameter OUT = 3'd3;

`define  IDLE       3'd0;
`define  IN_PA_CV   3'd1;
`define  Act        3'd2;
`define  FC         3'd3;
`define  SM_OUT     3'd4;
`define  DEFAULT    3'd4;




input rst_n, clk, in_valid;
input [inst_sig_width+inst_exp_width:0] Img, Kernel_ch1, Kernel_ch2, Weight;
input Opt;

output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;


//---------------------------------------------------------------------
//   Reg & Wires
//---------------------------------------------------------------------
//
//  y = 0  * * * * *
//  y = 1  * * * * *           y = 0  * *
//  y = 2  * * * * *           y = 1  * *
//  y = 3  * * * * *           x =    0 1
//  y = 4  * * * * *
//  x =    0 1 2 3 4             Kernal
//
//      img
//

// reg [31:0] img1 [4:0] [4:0] ,img2 [4:0] [4:0],img3 [4:0] [4:0];  //32 bits, y axis, x axis
reg [31:0] img1 [4:0] [4:0] ;  //32 bits, y axis, x axis
reg [6:0]img_cnt;

genvar  a, b, c;
integer i,j,k;

//---------------------------------------------------------------------
// IPs
//---------------------------------------------------------------------


//---------------------------------------------------------------------
// Design
//---------------------------------------------------------------------


//---------------------------------------------------------------------
// Opt_reg
//---------------------------------------------------------------------
reg Opt_reg; // Opt_reg = 1/0, Replication /Zero padding
always @ (posedge clk or negedge rst_n)
    if (!rst_n) Opt_reg <= 1'd0;
    else Opt_reg <= (in_valid & img_cnt == 'd0) ? Opt :  Opt_reg;



//---------------------------------------------------------------------
// Image Read
//---------------------------------------------------------------------
wire RoundEnd;
assign RoundEnd = (img_cnt == 'd115);
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) img_cnt <= 'd0;
    else if (in_valid)  img_cnt <= img_cnt + 'd1;
    else if (img_cnt != 'd0 & !RoundEnd )  img_cnt <= img_cnt + 'd1;
    else img_cnt <= 'd0;



    // img_cnt <= (in_valid | ) ? img_cnt + 'd1 : 'd0;
end

always @( posedge clk or negedge rst_n) begin

    if (!rst_n) for (i=0; i<5 ; i= i+1)  for (j=0; j<5 ; j= j+1) img1[i][j] <= 'd0;
    else if (RoundEnd) for (i=0; i<5 ; i= i+1)  for (j=0; j<5 ; j= j+1) img1[i][j] <= 'd0;
    else if ( in_valid ) begin
        if ( img_cnt <= 'd4)       img1[0][img_cnt]        <= Img; //first pucture
        else if ( img_cnt <= 'd9)  img1[1][img_cnt -  'd5] <= Img;
        else if ( img_cnt <= 'd14) img1[2][img_cnt - 'd10] <= Img;
        else if ( img_cnt <= 'd19) img1[3][img_cnt - 'd15] <= Img;
        else if ( img_cnt <= 'd24) img1[4][img_cnt - 'd20] <= Img;

        else if ( img_cnt <= 'd29) img1[0][img_cnt - 'd25] <= Img; //second pucture
        else if ( img_cnt <= 'd34) img1[1][img_cnt - 'd30] <= Img;
        else if ( img_cnt <= 'd39) img1[2][img_cnt - 'd35] <= Img;
        else if ( img_cnt <= 'd44) img1[3][img_cnt - 'd40] <= Img;
        else if ( img_cnt <= 'd49) img1[4][img_cnt - 'd45] <= Img;

        else if ( img_cnt <= 'd54) img1[0][img_cnt - 'd50] <= Img; //third pucture
        else if ( img_cnt <= 'd59) img1[1][img_cnt - 'd55] <= Img;
        else if ( img_cnt <= 'd64) img1[2][img_cnt - 'd60] <= Img;
        else if ( img_cnt <= 'd69) img1[3][img_cnt - 'd65] <= Img;
        else if ( img_cnt <= 'd74) img1[4][img_cnt - 'd70] <= Img;
    end
    else begin
        for ( i = 0; i < 5; i=i+1) for ( j = 0; j < 5; j=j+1) img1[i][j] <= img1[i][j];
    end
    // else if ( in_valid ) begin
    // if (!rst_n) img2 <= 'd0;
    //     else if ( img_cnt <= 29) img2[0][img_cnt - 'd25] <= Img;
    //     else if ( img_cnt <= 34) img2[1][img_cnt - 'd29] <= Img;
    //     else if ( img_cnt <= 39) img2[2][img_cnt - 'd34] <= Img;
    //     else if ( img_cnt <= 44) img2[3][img_cnt - 'd39] <= Img;
    //     else if ( img_cnt <= 49) img2[4][img_cnt - 'd44] <= Img;
    // end
    // else for ( i = 0; i < 5; i=i+1) for ( j = 0; j < 5; j=j+1) img2[i][j] <= img2[i][j];

    // if (!rst_n) img3 <= 'd0;
    // else if ( in_valid ) begin
    //     else if ( img_cnt <= 54) img3[0][img_cnt - 'd49] <= Img;
    //     else if ( img_cnt <= 59) img3[1][img_cnt - 'd54] <= Img;
    //     else if ( img_cnt <= 64) img3[2][img_cnt - 'd59] <= Img;
    //     else if ( img_cnt <= 69) img3[3][img_cnt - 'd64] <= Img;
    //     else if ( img_cnt <= 74) img3[4][img_cnt - 'd69] <= Img;
    // end
    // else for ( i = 0; i < 5; i=i+1) for ( j = 0; j < 5; j=j+1) img3[i][j] <= img3[i][j];

end


//---------------------------------------------------------------------
// Image Padding
//---------------------------------------------------------------------
// reg [31:0]padding1[6:0] [6:0],padding2 [6:0] [6:0], padding3 [6:0] [6:0];
reg [31:0]padding1[6:0] [6:0];

wire [1567:0] padding1_flt;
always @(*) begin
    if (Opt_reg) begin

        padding1 [1][1] = img1 [0][0];
        padding1 [1][2] = img1 [0][1];
        padding1 [1][3] = img1 [0][2];
        padding1 [1][4] = img1 [0][3];
        padding1 [1][5] = img1 [0][4];

        padding1 [2][1] = img1 [1][0];
        padding1 [2][2] = img1 [1][1];
        padding1 [2][3] = img1 [1][2];
        padding1 [2][4] = img1 [1][3];
        padding1 [2][5] = img1 [1][4];

        padding1 [3][1] = img1 [2][0];
        padding1 [3][2] = img1 [2][1];
        padding1 [3][3] = img1 [2][2];
        padding1 [3][4] = img1 [2][3];
        padding1 [3][5] = img1 [2][4];

        padding1 [4][1] = img1 [3][0];
        padding1 [4][2] = img1 [3][1];
        padding1 [4][3] = img1 [3][2];
        padding1 [4][4] = img1 [3][3];
        padding1 [4][5] = img1 [3][4];

        padding1 [5][1] = img1 [4][0];
        padding1 [5][2] = img1 [4][1];
        padding1 [5][3] = img1 [4][2];
        padding1 [5][4] = img1 [4][3];
        padding1 [5][5] = img1 [4][4];

        // padding1 outside up round
        padding1 [0][0] = img1 [0][0];
        padding1 [0][1] = img1 [0][0];
        padding1 [0][2] = img1 [0][1];
        padding1 [0][3] = img1 [0][2];
        padding1 [0][4] = img1 [0][3];
        padding1 [0][5] = img1 [0][4];
        padding1 [0][6] = img1 [0][4];

        // padding1 outside down round
        padding1 [6][0] = img1 [4][0];
        padding1 [6][1] = img1 [4][0];
        padding1 [6][2] = img1 [4][1];
        padding1 [6][3] = img1 [4][2];
        padding1 [6][4] = img1 [4][3];
        padding1 [6][5] = img1 [4][4];
        padding1 [6][6] = img1 [4][4];

        // padding1 outside two side
        padding1 [1][0] = img1 [0][0];
        padding1 [1][6] = img1 [0][4];
        padding1 [2][0] = img1 [1][0];
        padding1 [2][6] = img1 [1][4];
        padding1 [3][0] = img1 [2][0];
        padding1 [3][6] = img1 [2][4];
        padding1 [4][0] = img1 [3][0];
        padding1 [4][6] = img1 [3][4];
        padding1 [5][0] = img1 [4][0];
        padding1 [5][6] = img1 [4][4];



    end
    else begin
        padding1 [1][1] = img1 [0][0];
        padding1 [1][2] = img1 [0][1];
        padding1 [1][3] = img1 [0][2];
        padding1 [1][4] = img1 [0][3];
        padding1 [1][5] = img1 [0][4];

        padding1 [2][1] = img1 [1][0];
        padding1 [2][2] = img1 [1][1];
        padding1 [2][3] = img1 [1][2];
        padding1 [2][4] = img1 [1][3];
        padding1 [2][5] = img1 [1][4];

        padding1 [3][1] = img1 [2][0];
        padding1 [3][2] = img1 [2][1];
        padding1 [3][3] = img1 [2][2];
        padding1 [3][4] = img1 [2][3];
        padding1 [3][5] = img1 [2][4];

        padding1 [4][1] = img1 [3][0];
        padding1 [4][2] = img1 [3][1];
        padding1 [4][3] = img1 [3][2];
        padding1 [4][4] = img1 [3][3];
        padding1 [4][5] = img1 [3][4];

        padding1 [5][1] = img1 [4][0];
        padding1 [5][2] = img1 [4][1];
        padding1 [5][3] = img1 [4][2];
        padding1 [5][4] = img1 [4][3];
        padding1 [5][5] = img1 [4][4];

        // padding1 outside up round
        padding1 [0][0] = 'd0;
        padding1 [0][1] = 'd0;
        padding1 [0][2] = 'd0;
        padding1 [0][3] = 'd0;
        padding1 [0][4] = 'd0;
        padding1 [0][5] = 'd0;
        padding1 [0][6] = 'd0;

        // padding1 outside down round
        padding1 [6][0] = 'd0;
        padding1 [6][1] = 'd0;
        padding1 [6][2] = 'd0;
        padding1 [6][3] = 'd0;
        padding1 [6][4] = 'd0;
        padding1 [6][5] = 'd0;
        padding1 [6][6] = 'd0;

        // padding1 outside two side
        padding1 [1][0] = 'd0;
        padding1 [1][6] = 'd0;
        padding1 [2][0] = 'd0;
        padding1 [2][6] = 'd0;
        padding1 [3][0] = 'd0;
        padding1 [3][6] = 'd0;
        padding1 [4][0] = 'd0;
        padding1 [4][6] = 'd0;
        padding1 [5][0] = 'd0;
        padding1 [5][6] = 'd0;
    end
end

assign padding1_flt = {
    padding1[0][0], padding1[0][1], padding1[0][2], padding1[0][3], padding1[0][4], padding1[0][5], padding1[0][6],
    padding1[1][0], padding1[1][1], padding1[1][2], padding1[1][3], padding1[1][4], padding1[1][5], padding1[1][6],
    padding1[2][0], padding1[2][1], padding1[2][2], padding1[2][3], padding1[2][4], padding1[2][5], padding1[2][6],
    padding1[3][0], padding1[3][1], padding1[3][2], padding1[3][3], padding1[3][4], padding1[3][5], padding1[3][6],
    padding1[4][0], padding1[4][1], padding1[4][2], padding1[4][3], padding1[4][4], padding1[4][5], padding1[4][6],
    padding1[5][0], padding1[5][1], padding1[5][2], padding1[5][3], padding1[5][4], padding1[5][5], padding1[5][6],
    padding1[6][0], padding1[6][1], padding1[6][2], padding1[6][3], padding1[6][4], padding1[6][5], padding1[6][6]
};

// assign padding2_flt = {
//     padding2[0][0], padding2[0][1], padding2[0][2], padding2[0][3], padding2[0][4], padding2[0][5], padding2[0][6],
//     padding2[1][0], padding2[1][1], padding2[1][2], padding2[1][3], padding2[1][4], padding2[1][5], padding2[1][6],
//     padding2[2][0], padding2[2][1], padding2[2][2], padding2[2][3], padding2[2][4], padding2[2][5], padding2[2][6],
//     padding2[3][0], padding2[3][1], padding2[3][2], padding2[3][3], padding2[3][4], padding2[3][5], padding2[3][6],
//     padding2[4][0], padding2[4][1], padding2[4][2], padding2[4][3], padding2[4][4], padding2[4][5], padding2[4][6],
//     padding2[5][0], padding2[5][1], padding2[5][2], padding2[5][3], padding2[5][4], padding2[5][5], padding2[5][6],
//     padding2[6][0], padding2[6][1], padding2[6][2], padding2[6][3], padding2[6][4], padding2[6][5], padding2[6][6],
// }


//---------------------------------------------------------------------
// Kernel Read
//---------------------------------------------------------------------


 // kernal
 // {ker[0][0], ker[0][1], ker[0][2], ker[0][3],
 //  ker[1][0], ker[1][1], ker[1][2], ker[1][3],
 //  ker[2][0], ker[2][1], ker[2][2], ker[2][3]
 // }


reg [31:0] Kernel1 [2:0] [3:0], Kernel2 [2:0] [3:0];
reg [383:0] Kernel1_flt, Kernel2_flt;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for (k=0; k<3 ; k= k+1)  for (j=0; j<4 ; j= j+1) Kernel1 [k][j] <= 'd0;
    // if (!rst_n)
    // {   Kernel1[0][0], Kernel1[0][1], Kernel1[0][2], Kernel1[0][3],
    //     Kernel1[1][0], Kernel1[1][1], Kernel1[1][2], Kernel1[1][3],
    //     Kernel1[2][0], Kernel1[2][1], Kernel1[2][2], Kernel1[2][3] } <='d0;

    else if ( in_valid & (img_cnt <= 'd11) ) begin
        if ( img_cnt <= 'd3  ) Kernel1[0][img_cnt      ]      <= Kernel_ch1;
        else if ( img_cnt <= 'd7  ) Kernel1[1][img_cnt - 'd4] <= Kernel_ch1;
        else if ( img_cnt <= 'd11 ) Kernel1[2][img_cnt - 'd8] <= Kernel_ch1;
    end
    else for ( i = 0; i < 3; i=i+1) for ( j = 0; j < 4; j=j+1) Kernel1[i][j] <= Kernel1[i][j];
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)for (i=0; i<3 ; i= i+1)  for (j=0; j<4 ; j= j+1) Kernel2 [i][j] <= 'd0;
    else if ( in_valid & img_cnt <= 11 ) begin
        if ( img_cnt <= 3  ) Kernel2[0][img_cnt      ] <= Kernel_ch2;
        else if ( img_cnt <= 7  ) Kernel2[1][img_cnt - 'd4] <= Kernel_ch2;
        else if ( img_cnt <= 11 ) Kernel2[2][img_cnt - 'd8] <= Kernel_ch2;
    end
    else for ( i = 0; i < 3; i=i+1) for ( j = 0; j < 4; j=j+1) Kernel2[i][j] <= Kernel2[i][j];
end
assign Kernel1_flt = {  Kernel1[0][0], Kernel1[0][1], Kernel1[0][2], Kernel1[0][3],
                        Kernel1[1][0], Kernel1[1][1], Kernel1[1][2], Kernel1[1][3],
                        Kernel1[2][0], Kernel1[2][1], Kernel1[2][2], Kernel1[2][3]
};
assign Kernel2_flt = {  Kernel2[0][0], Kernel2[0][1], Kernel2[0][2], Kernel2[0][3],
                        Kernel2[1][0], Kernel2[1][1], Kernel2[1][2], Kernel2[1][3],
                        Kernel2[2][0], Kernel2[2][1], Kernel2[2][2], Kernel2[2][3]
};

//---------------------------------------------------------------------
// FC Weight Read
//---------------------------------------------------------------------
reg [31:0] weight1 [7:0], weight2 [7:0], weight3 [7:0];
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {weight1[0],weight1[1],weight1[2],weight1[3],weight1[4],weight1[5] ,weight1[6],weight1[7]} <= 'd0;
        {weight2[0],weight2[1],weight2[2],weight2[3],weight2[4],weight2[5] ,weight2[6],weight2[7]} <= 'd0;
        {weight3[0],weight3[1],weight3[2],weight3[3],weight3[4],weight3[5] ,weight3[6],weight3[7]} <= 'd0;
        // for (i=0; i<6 ; i= i+1) weight1[i] <= 'd0;
        // for (i=0; i<6 ; i= i+1) weight2[i] <= 'd0;
        // for (i=0; i<6 ; i= i+1) weight3[i] <= 'd0;

        // for ( i = 0 ; i < 6 ; i = i + 1)  begin
        //     weight1[i] <= 32'd0;
        //     weight2[i] <= 32'd0;
        //     weight3[i] <= 32'd0;
        // end
    end
    else if ( in_valid & img_cnt < 'd8  )  weight1 [img_cnt       ] <= Weight;
    else if ( in_valid & img_cnt < 'd16 )  weight2 [img_cnt - 'd8 ] <= Weight;
    else if ( in_valid & img_cnt < 'd24 )  weight3 [img_cnt - 'd16] <= Weight;
    else begin
        for ( i = 0 ; i < 8 ; i = i + 1) begin
            weight1 [i] <=  weight1 [i];
            weight2 [i] <=  weight2 [i];
            weight3 [i] <=  weight3 [i];
        end
    end
end


//---------------------------------------------------------------------
// Convolution
//---------------------------------------------------------------------

// reg [31:0] CVout_temp1 [2:0] [35:0];
// reg [31:0] CVout_temp2 [2:0] [35:0];

wire en_CV_out_selA,en_CV_out_selB;
wire [31:0] PPLCV_PE_out_nA;
wire [31:0] PPLCV_PE_out_nB;
wire  [5:0] CV_out_selA;        //    [6]  [7]
wire  [5:0] CV_out_selB;         //    [6]  [7]
wire [1151:0] CV_reg;



PPLCV_CTRLA PPLCV_CTRLAL(
        .clk(clk),
        .rst_n(rst_n),
        .img_cnt(img_cnt),
        .Kernel_flt(Kernel1_flt),
        .Pad(padding1_flt), // 32*49 = 1568  { Pad [0]  [1]  [2]......}
        .CV_out_selA(CV_out_selA),          //    [6]  [7]
        .en_CV_out_selA(en_CV_out_selA),
        .PPLCV_PE_out_nA(PPLCV_PE_out_nA)

    );
PPLCV_CTRLB PPLCV_CTRLBL(
        .clk(clk),
        .rst_n(rst_n),
        .img_cnt(img_cnt),
        .Kernel_flt(Kernel1_flt),
        .Pad(padding1_flt), // 32*49 = 1568  { Pad [0]  [1]  [2]......}
        .CV_out_selB(CV_out_selB),          //    [6]  [7]
        .en_CV_out_selB(en_CV_out_selB),
        .PPLCV_PE_out_nB(PPLCV_PE_out_nB)
    );
CV_reg_ckt CV_reg_cktL (
        .clk(clk),
        .rst_n(rst_n),
        .img_cnt(img_cnt),
        .PPLCV_PE_out_nA(PPLCV_PE_out_nA),
        .PPLCV_PE_out_nB(PPLCV_PE_out_nB),
        .CV_out_selA(CV_out_selA),
        .CV_out_selB(CV_out_selB),          //    [6]  [7]
        .en_CV_out_selA(en_CV_out_selA),
        .en_CV_out_selB(en_CV_out_selB),          //    [6]  [7]
        .CV_reg(CV_reg)
    );



wire en_CV_out_selA_R,en_CV_out_selB_R;
wire [31:0] PPLCV_PE_out_nA_R;
wire [31:0] PPLCV_PE_out_nB_R;
wire  [5:0] CV_out_selA_R;          //    [6]  [7]
wire  [5:0] CV_out_selB_R;          //    [6]  [7]
wire [1151:0] CV_reg_R;

PPLCV_CTRLA PPLCV_CTRLAR(
        .clk(clk),
        .rst_n(rst_n),
        .img_cnt(img_cnt),
        .Kernel_flt(Kernel2_flt),
        .Pad(padding1_flt), // 32*49 = 1568  { Pad [0]  [1]  [2]......}
        .CV_out_selA(CV_out_selA_R),          //    [6]  [7]
        .en_CV_out_selA(en_CV_out_selA_R),
        .PPLCV_PE_out_nA(PPLCV_PE_out_nA_R)

    );
PPLCV_CTRLB PPLCV_CTRLBR(
        .clk(clk),
        .rst_n(rst_n),
        .img_cnt(img_cnt),
        .Kernel_flt(Kernel2_flt),
        .Pad(padding1_flt), // 32*49 = 1568  { Pad [0]  [1]  [2]......}
        .CV_out_selB(CV_out_selB_R),          //    [6]  [7]
        .en_CV_out_selB(en_CV_out_selB_R),
        .PPLCV_PE_out_nB(PPLCV_PE_out_nB_R)
    );
CV_reg_ckt CV_reg_cktR (
        .clk(clk),
        .rst_n(rst_n),
        .img_cnt(img_cnt),
        .PPLCV_PE_out_nA(PPLCV_PE_out_nA_R),
        .PPLCV_PE_out_nB(PPLCV_PE_out_nB_R),
        .CV_out_selA(CV_out_selA_R),          //    [6]  [7]
        .CV_out_selB(CV_out_selB_R),          //    [6]  [7]
        .en_CV_out_selA(en_CV_out_selA_R),         //    [6]  [7]
        .en_CV_out_selB(en_CV_out_selB_R),
        .CV_reg(CV_reg_R)
    );

//---------------------------------------------------------------------
// Max Pooling
//---------------------------------------------------------------------
 //when img_cnt =97 , comp has been finished. But Max[7] will be useable at cnt = 106 (105->106)
wire en_act;
wire [31:0] act_out;
wire [31:0] CVreg_arr [35:0], CV_reg_R_arr [35:0];
assign {CVreg_arr[0] [31:0], CVreg_arr[1] [31:0], CVreg_arr[2] [31:0], CVreg_arr[3] [31:0], CVreg_arr[4] [31:0], CVreg_arr[5] [31:0],
        CVreg_arr[6] [31:0], CVreg_arr[7] [31:0], CVreg_arr[8] [31:0], CVreg_arr[9] [31:0], CVreg_arr[10][31:0], CVreg_arr[11][31:0],
        CVreg_arr[12][31:0], CVreg_arr[13][31:0], CVreg_arr[14][31:0], CVreg_arr[15][31:0], CVreg_arr[16][31:0], CVreg_arr[17][31:0],
        CVreg_arr[18][31:0], CVreg_arr[19][31:0], CVreg_arr[20][31:0], CVreg_arr[21][31:0], CVreg_arr[22][31:0], CVreg_arr[23][31:0],
        CVreg_arr[24][31:0], CVreg_arr[25][31:0], CVreg_arr[26][31:0], CVreg_arr[27][31:0], CVreg_arr[28][31:0], CVreg_arr[29][31:0],
        CVreg_arr[30][31:0], CVreg_arr[31][31:0], CVreg_arr[32][31:0], CVreg_arr[33][31:0], CVreg_arr[34][31:0], CVreg_arr[35][31:0]} =CV_reg ;


assign {CV_reg_R_arr[0] [31:0] , CV_reg_R_arr[1] [31:0] , CV_reg_R_arr[2] [31:0] , CV_reg_R_arr[3] [31:0] , CV_reg_R_arr[4] [31:0] , CV_reg_R_arr[5] [31:0],
        CV_reg_R_arr[6] [31:0] , CV_reg_R_arr[7] [31:0] , CV_reg_R_arr[8] [31:0] , CV_reg_R_arr[9] [31:0] , CV_reg_R_arr[10][31:0] , CV_reg_R_arr[11][31:0],
        CV_reg_R_arr[12][31:0] , CV_reg_R_arr[13][31:0] , CV_reg_R_arr[14][31:0] , CV_reg_R_arr[15][31:0] , CV_reg_R_arr[16][31:0] , CV_reg_R_arr[17][31:0],
        CV_reg_R_arr[18][31:0] , CV_reg_R_arr[19][31:0] , CV_reg_R_arr[20][31:0] , CV_reg_R_arr[21][31:0] , CV_reg_R_arr[22][31:0] , CV_reg_R_arr[23][31:0],
        CV_reg_R_arr[24][31:0] , CV_reg_R_arr[25][31:0] , CV_reg_R_arr[26][31:0] , CV_reg_R_arr[27][31:0] , CV_reg_R_arr[28][31:0] , CV_reg_R_arr[29][31:0],
        CV_reg_R_arr[30][31:0] , CV_reg_R_arr[31][31:0] , CV_reg_R_arr[32][31:0] , CV_reg_R_arr[33][31:0] , CV_reg_R_arr[34][31:0] , CV_reg_R_arr[35][31:0]} = CV_reg_R ;

wire [31:0] act_up;


wire [7:0] agtb;
reg [31:0] compA[7:0],compB[7:0];
reg [31:0] Max[7:0];
// Max
// Chanel left      Chanel right
//    0  1             4   5
//    2  3             6   7
wire en_comp;
// reg [2:0]comp_cnt;
assign en_comp = img_cnt >= 'd89 & img_cnt <= 'd96 ;  //when img_cnt =97 , comp has been finished.

generate
    for (a=0 ; a<8 ; a = a+1)
        DW_fp_cmp_inst DW_fp_cmp_inst( .inst_a(compA[a]), .inst_b(compB[a]), .inst_zctr(1'd0), .agtb_inst(agtb[a]) );
endgenerate

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) for (i=0; i<8 ; i=i+1) Max[i] <='d0;
    else if ( RoundEnd ) for (i=0; i<8 ; i=i+1) Max[i] <= 'd0;
    else if (en_comp) begin
        for (i=0; i<8 ; i=i+1) begin
            Max[i] <= (agtb[i]) ? compA[i] : compB[i];
        end
    end
    else if ( en_act)
        case (img_cnt)
            'd97:  begin
                        Max[0] <= (Opt_reg) ? act_up : 32'b00111111100000000000000000000000 ;
                    end
            'd98:  begin
                        Max[1] <= (Opt_reg) ? act_up : 32'b00111111100000000000000000000000 ;
                        Max[0] <= act_out;
                    end
            'd99:  begin
                        Max[2] <= (Opt_reg) ? act_up : 32'b00111111100000000000000000000000 ;
                        Max[1] <= act_out;
                    end
            'd100: begin
                        Max[3] <= (Opt_reg) ? act_up : 32'b00111111100000000000000000000000 ;
                        Max[2] <= act_out;
                    end
            'd101: begin
                        Max[4] <= (Opt_reg) ? act_up : 32'b00111111100000000000000000000000 ;
                        Max[3] <= act_out;
                    end
            'd102: begin
                        Max[5] <= (Opt_reg) ? act_up : 32'b00111111100000000000000000000000 ;
                        Max[4] <= act_out;
                    end
            'd103: begin
                        Max[6] <= (Opt_reg) ? act_up : 32'b00111111100000000000000000000000 ;
                        Max[5] <= act_out;
                    end
            'd104: begin
                        Max[7] <= (Opt_reg) ? act_up : 32'b00111111100000000000000000000000 ;
                        Max[6] <= act_out;
                    end
            'd105: begin
                        Max[7] <= act_out;
                    end
        endcase

    else for (i=0; i<8 ; i=i+1) Max[i] <= Max[i];
end

always @(*) begin
    case (img_cnt)
        'd89:begin
            {compA [0] ,compB [0]} = {CVreg_arr[0] , CVreg_arr[1]      };
            {compA [1] ,compB [1]} = {CVreg_arr[3] , CVreg_arr[4]      };
            {compA [2] ,compB [2]} = {CVreg_arr[18], CVreg_arr[19]     };
            {compA [3] ,compB [3]} = {CVreg_arr[21], CVreg_arr[22]     };
            {compA [4] ,compB [4]} = {CV_reg_R_arr[0] , CV_reg_R_arr[1]};
            {compA [5] ,compB [5]} = {CV_reg_R_arr[3] , CV_reg_R_arr[4]};
            {compA [6] ,compB [6]} = {CV_reg_R_arr[18], CV_reg_R_arr[19]};
            {compA [7] ,compB [7]} = {CV_reg_R_arr[21], CV_reg_R_arr[22]};
        end
        'd90:begin
            {compA [0] ,compB [0]} = {CVreg_arr[2 ]   , Max[0]};
            {compA [1] ,compB [1]} = {CVreg_arr[5 ]   , Max[1]};
            {compA [2] ,compB [2]} = {CVreg_arr[20]   , Max[2]};
            {compA [3] ,compB [3]} = {CVreg_arr[23]   , Max[3]};
            {compA [4] ,compB [4]} = {CV_reg_R_arr[2 ], Max[4]};
            {compA [5] ,compB [5]} = {CV_reg_R_arr[5 ], Max[5]};
            {compA [6] ,compB [6]} = {CV_reg_R_arr[20], Max[6]};
            {compA [7] ,compB [7]} = {CV_reg_R_arr[23], Max[7]};
        end
        'd91:begin
            {compA [0] ,compB [0]} = {Max[0], CVreg_arr[6 ]};
            {compA [1] ,compB [1]} = {Max[1], CVreg_arr[9 ]};
            {compA [2] ,compB [2]} = {Max[2], CVreg_arr[24]};
            {compA [3] ,compB [3]} = {Max[3], CVreg_arr[27]};
            {compA [4] ,compB [4]} = {Max[4], CV_reg_R_arr[6 ]};
            {compA [5] ,compB [5]} = {Max[5], CV_reg_R_arr[9 ]};
            {compA [6] ,compB [6]} = {Max[6], CV_reg_R_arr[24]};
            {compA [7] ,compB [7]} = {Max[7], CV_reg_R_arr[27]};
        end
        'd92:begin
            {compA [0] ,compB [0]} = {CVreg_arr[7 ]   , Max[0]};
            {compA [1] ,compB [1]} = {CVreg_arr[10]   , Max[1]};
            {compA [2] ,compB [2]} = {CVreg_arr[25]   , Max[2]};
            {compA [3] ,compB [3]} = {CVreg_arr[28]   , Max[3]};
            {compA [4] ,compB [4]} = {CV_reg_R_arr[7 ], Max[4]};
            {compA [5] ,compB [5]} = {CV_reg_R_arr[10], Max[5]};
            {compA [6] ,compB [6]} = {CV_reg_R_arr[25], Max[6]};
            {compA [7] ,compB [7]} = {CV_reg_R_arr[28], Max[7]};
        end
        'd93:begin
            {compA [0] ,compB [0]} = {Max[0], CVreg_arr[8 ]};
            {compA [1] ,compB [1]} = {Max[1], CVreg_arr[11]};
            {compA [2] ,compB [2]} = {Max[2], CVreg_arr[26]};
            {compA [3] ,compB [3]} = {Max[3], CVreg_arr[29]};
            {compA [4] ,compB [4]} = {Max[4], CV_reg_R_arr[8 ]};
            {compA [5] ,compB [5]} = {Max[5], CV_reg_R_arr[11]};
            {compA [6] ,compB [6]} = {Max[6], CV_reg_R_arr[26]};
            {compA [7] ,compB [7]} = {Max[7], CV_reg_R_arr[29]};
        end
        'd94:begin
            {compA [0] ,compB [0]} = {  CVreg_arr[12]   , Max[0]};
            {compA [1] ,compB [1]} = {  CVreg_arr[15]   , Max[1]};
            {compA [2] ,compB [2]} = {  CVreg_arr[30]   , Max[2]};
            {compA [3] ,compB [3]} = {  CVreg_arr[33]   , Max[3]};
            {compA [4] ,compB [4]} = {  CV_reg_R_arr[12], Max[4]};
            {compA [5] ,compB [5]} = {  CV_reg_R_arr[15], Max[5]};
            {compA [6] ,compB [6]} = {  CV_reg_R_arr[30], Max[6]};
            {compA [7] ,compB [7]} = {  CV_reg_R_arr[33], Max[7]};
        end
        'd95:begin
            {compA [0] ,compB [0]} = {Max[0], CVreg_arr[13]   };
            {compA [1] ,compB [1]} = {Max[1], CVreg_arr[16]   };
            {compA [2] ,compB [2]} = {Max[2], CVreg_arr[31]   };
            {compA [3] ,compB [3]} = {Max[3], CVreg_arr[34]   };
            {compA [4] ,compB [4]} = {Max[4], CV_reg_R_arr[13]};
            {compA [5] ,compB [5]} = {Max[5], CV_reg_R_arr[16]};
            {compA [6] ,compB [6]} = {Max[6], CV_reg_R_arr[31]};
            {compA [7] ,compB [7]} = {Max[7], CV_reg_R_arr[34]};
        end
        'd96:begin
            {compA [0] ,compB [0]} = {  CVreg_arr[14]   , Max[0]};
            {compA [1] ,compB [1]} = {  CVreg_arr[17]   , Max[1]};
            {compA [2] ,compB [2]} = {  CVreg_arr[32]   , Max[2]};
            {compA [3] ,compB [3]} = {  CVreg_arr[35]   , Max[3]};
            {compA [4] ,compB [4]} = {  CV_reg_R_arr[14], Max[4]};
            {compA [5] ,compB [5]} = {  CV_reg_R_arr[17], Max[5]};
            {compA [6] ,compB [6]} = {  CV_reg_R_arr[32], Max[6]};
            {compA [7] ,compB [7]} = {  CV_reg_R_arr[35], Max[7]};
        end
        default: begin
            {compA [0] ,compB [0]} = 'd0;
            {compA [1] ,compB [1]} = 'd0;
            {compA [2] ,compB [2]} = 'd0;
            {compA [3] ,compB [3]} = 'd0;
            {compA [4] ,compB [4]} = 'd0;
            {compA [5] ,compB [5]} = 'd0;
            {compA [6] ,compB [6]} = 'd0;
            {compA [7] ,compB [7]} = 'd0;
        end
    endcase
end



//---------------------------------------------------------------------
// Activateion
//---------------------------------------------------------------------
// every act takes 2clk, first act , end at cnt 98=>99. (you can take it at cnt = 99)
// 8 act will start from cnt =97 and have been finished  106(105 =>106)
// opt = 0/1 => sigmoid / tanh

//  Act left        Act right
//    0  1             4   5
//    2  3             6   7
// You can easily take them from
//    99  100         103 104
//    101 102         105 106

reg [31:0] R1,R2,R3,R4;
reg  [31:0] fc_out1, fc_out2, fc_out3;



assign en_act = img_cnt >= 'd97 &  img_cnt <= 'd105;
wire [31:0] act_down,act_up_temp, act_down_temp;
reg  [31:0] exp_ord;

reg [31:0] act_temp ,Max_temp;
// we split result into act_up and act_down and store them in Max and act_down
// act_result will also stored in Max

always @(*) begin
    case (img_cnt)
        'd97 : Max_temp = Max [0];
        'd98 : Max_temp = Max [1];
        'd99 : Max_temp = Max [2];
        'd100: Max_temp = Max [3];
        'd101: Max_temp = Max [4];
        'd102: Max_temp = Max [5];
        'd103: Max_temp = Max [6];
        'd104: Max_temp = Max [7];
        // 'd105:
        // 'd106: Max_temp = Max [4];
        // 'd107:
        // 'd108: Max_temp = Max [5];
        // 'd109:
        // 'd110: Max_temp = Max [6];
        // 'd111:
        // 'd112: Max_temp = Max [7];
        default: Max_temp = 'd0;
    endcase
end

// act_down
// assign exp_ord = (Opt_reg) ? {Max_temp[31],{Max_temp[29:23]'1'd0},Max_tem[22:0]} :Max_temp;

always @( *) begin
    if ( img_cnt < 'd107)
        // exp_ord = (Opt_reg) ? {Max_temp[31],{Max_temp[29:23],1'd0},Max_temp[22:0]} :Max_temp;
        exp_ord = (Opt_reg) ? {Max_temp[31],{Max_temp[30:23]+8'd1},Max_temp[22:0]} :{!Max_temp[31],Max_temp[30:0]};
    else
        case (img_cnt)
        'd109: exp_ord = fc_out1;
        'd110: exp_ord = fc_out2;
        'd111: exp_ord = fc_out3;
        default : exp_ord = 'd0;
        endcase
end

reg [31:0] act_down_add_in1,act_down_add_in2;
always @( *) begin
    if ( img_cnt < 'd107) begin
        act_down_add_in1 = act_down_temp;
        act_down_add_in2 = 32'b00111111100000000000000000000000;
    end
    else
        case (img_cnt)
        'd110: begin act_down_add_in1 = R1; act_down_add_in2 = act_down_temp; end
        'd111: begin act_down_add_in1 = R4; act_down_add_in2 = act_down_temp; end
        default :  begin act_down_add_in1 = R1; act_down_add_in2 = act_down_temp; end
        endcase
end


//act_down
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) act_down_exp (
.a(exp_ord),
.z(act_down_temp));

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)act_down_add
( .a(act_down_add_in1), .b(act_down_add_in2), .rnd(3'd0), .z(act_down));

//act_up
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) act_up_exp (
.a( {Max_temp[31],{Max_temp[30:23] + 8'd1},Max_temp[22:0]} ),.z(act_up_temp));

DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)act_up_sub
( .a(act_up_temp), .b(32'b0111111100000000000000000000000), .rnd(3'd0), .z(act_up) );


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) act_temp <= 'd0;
    else if ( RoundEnd)  act_temp<='d0;
    else act_temp <= act_down;
end




// div

reg [31:0] act_div_up;
always @(*) begin
    if (Opt_reg)
        case (img_cnt)
            'd98 : act_div_up = Max [0];
            'd99 : act_div_up = Max [1];
            'd100: act_div_up = Max [2];
            'd101: act_div_up = Max [3];
            'd102: act_div_up = Max [4];
            'd103: act_div_up = Max [5];
            'd104: act_div_up = Max [6];
            'd105: act_div_up = Max [7];
            default: act_div_up = 'd0;
        endcase
    else act_div_up = 32'b0111111100000000000000000000000;
end

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) act_div
( .a(act_div_up), .b(act_temp), .rnd(3'd0), .z(act_out));




//---------------------------------------------------------------------
// Fully Connection
//---------------------------------------------------------------------

//  Act left        Act right
//    0  1             4   5
//    2  3             6   7
// You can easily take them from
//    100  101         104 105
//    102  103         106 107    **********  MAx[7]

// use act2 from cnt = 106 is ok
// compute act1 from 102 is good, this can connect act2
// act1 result outcome at cnt =104,  act2 result outcome at cnt =107
// for weight2 106~109
// for weight3 107~110

// fc_out1  store at cnt 107 =>108  108 can be used.
// fc_out2  store at cnt 108 =>109  109 can be used.
// fc_out3  store at cnt 109 =>110  110 can be used.

wire fc_st1;
reg fc_st2, fc_st3;
wire [31:0] fc_add_out;

wire [31:0] fc_ker1 [3:0], fc_ker2 [3:0], fc_ker3 [3:0];
wire [31:0] fc_pad1 [3:0], fc_pad2 [3:0], fc_pad3 [3:0];
wire [31:0] fc_PPLCV_PE_out_n1, fc_PPLCV_PE_out_n2, fc_PPLCV_PE_out_n3;
wire [31:0] fc_PPLCV_PE_out_1, fc_PPLCV_PE_out_2, fc_PPLCV_PE_out_3;
assign {fc_ker1[0],fc_ker1[1],fc_ker1[2],fc_ker1[3]} = (img_cnt > 'd105) ? {Max[4], Max[5], Max[6], Max[7]} : {Max[0], Max[1], Max[2], Max[3]};
assign {fc_ker2[0],fc_ker2[1],fc_ker2[2],fc_ker2[3]} = (img_cnt > 'd106) ? {Max[4], Max[5], Max[6], Max[7]} : {Max[0], Max[1], Max[2], Max[3]};
assign {fc_ker3[0],fc_ker3[1],fc_ker3[2],fc_ker3[3]} = (img_cnt > 'd107) ? {Max[4], Max[5], Max[6], Max[7]} : {Max[0], Max[1], Max[2], Max[3]};

assign {fc_pad1[0],fc_pad1[1],fc_pad1[2],fc_pad1[3]} = (img_cnt > 'd105) ? {weight1[4], weight1[5], weight1[6], weight1[7]} :{weight1[0], weight1[1], weight1[2], weight1[3]};
assign {fc_pad2[0],fc_pad2[1],fc_pad2[2],fc_pad2[3]} = (img_cnt > 'd106) ? {weight2[4], weight2[5], weight2[6], weight2[7]} :{weight2[0], weight2[1], weight2[2], weight2[3]};
assign {fc_pad3[0],fc_pad3[1],fc_pad3[2],fc_pad3[3]} = (img_cnt > 'd107) ? {weight3[4], weight3[5], weight3[6], weight3[7]} :{weight3[0], weight3[1], weight3[2], weight3[3]};
assign fc_st1 = img_cnt >= 'd103 & img_cnt <= 'd108;


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fc_st2 <= 'd0;
        fc_st3 <= 'd0;
    end
    else begin
        fc_st2 <= fc_st1;
        fc_st3 <= fc_st2;
    end
end

PPLCV_COMP FC1 (
        .clk(clk),
        .rst_n(rst_n),
        .st(fc_st1),
        .Ker1(fc_ker1[0][31:0]),  // Ker1 Ker2
        .Ker2(fc_ker1[1][31:0]),  // Ker3 Ker4
        .Ker3(fc_ker1[2][31:0]),
        .Ker4(fc_ker1[3][31:0]),
        .Pad1(fc_pad1[0][31:0]),  // Pad1 Pad2
        .Pad2(fc_pad1[1][31:0]),  // Pad3 Pad4
        .Pad3(fc_pad1[2][31:0]),
        .Pad4(fc_pad1[3][31:0]),
        .PPLCV_PE_out_n(fc_PPLCV_PE_out_n1),
        .PPLCV_PE_out(fc_PPLCV_PE_out_1)
    );
PPLCV_COMP FC2 (
        .clk(clk),
        .rst_n(rst_n),
        .st(fc_st2),
        .Ker1(fc_ker2[0][31:0]),  // Ker1 Ker2
        .Ker2(fc_ker2[1][31:0]),  // Ker3 Ker4
        .Ker3(fc_ker2[2][31:0]),
        .Ker4(fc_ker2[3][31:0]),
        .Pad1(fc_pad2[0][31:0]),  // Pad1 Pad2
        .Pad2(fc_pad2[1][31:0]),  // Pad3 Pad4
        .Pad3(fc_pad2[2][31:0]),
        .Pad4(fc_pad2[3][31:0]),
        .PPLCV_PE_out_n(fc_PPLCV_PE_out_n2),
        .PPLCV_PE_out(fc_PPLCV_PE_out_2)
    );
PPLCV_COMP FC3 (
        .clk(clk),
        .rst_n(rst_n),
        .st(fc_st3),
        .Ker1(fc_ker3[0][31:0]),  // Ker1 Ker2
        .Ker2(fc_ker3[1][31:0]),  // Ker3 Ker4
        .Ker3(fc_ker3[2][31:0]),
        .Ker4(fc_ker3[3][31:0]),
        .Pad1(fc_pad3[0][31:0]),  // Pad1 Pad2
        .Pad2(fc_pad3[1][31:0]),  // Pad3 Pad4
        .Pad3(fc_pad3[2][31:0]),
        .Pad4(fc_pad3[3][31:0]),
        .PPLCV_PE_out_n(fc_PPLCV_PE_out_n3),
        .PPLCV_PE_out(fc_PPLCV_PE_out_3)
    );

wire [31:0] PPLCV_PE_out, PPLCV_PE_out_n;
assign PPLCV_PE_out = (img_cnt == 'd108) ? fc_PPLCV_PE_out_1:
                      (img_cnt == 'd109) ? fc_PPLCV_PE_out_2:
                      (img_cnt == 'd110) ? fc_PPLCV_PE_out_3: 'd0;
assign PPLCV_PE_out_n = (img_cnt == 'd108) ? fc_PPLCV_PE_out_n1:
                        (img_cnt == 'd109) ? fc_PPLCV_PE_out_n2:
                        (img_cnt == 'd110) ? fc_PPLCV_PE_out_n3: 'd0;

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) fc_add
( .a(PPLCV_PE_out), .b(PPLCV_PE_out_n), .rnd(3'd0), .z(fc_add_out));


always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fc_out1 <= 'd0;
        fc_out2 <= 'd0;
        fc_out3 <= 'd0;
    end
    else if (RoundEnd)begin
        fc_out1 <= 'd0;   // fc_out1 can be used at cnt = 109
        fc_out2 <= 'd0;   // fc_out2 can be used at cnt = 110
        fc_out3 <= 'd0;   // fc_out3 can be used at cnt = 111
    end
    else begin
        fc_out1 <= (img_cnt == 'd108) ? fc_add_out :fc_out1;   // fc_out1 can be used at cnt = 109
        fc_out2 <= (img_cnt == 'd109) ? fc_add_out :fc_out2;   // fc_out2 can be used at cnt = 110
        fc_out3 <= (img_cnt == 'd110) ? fc_add_out :fc_out3;   // fc_out3 can be used at cnt = 111
    end
end

//---------------------------------------------------------------------
// Softmax   3 input & 3 output
//---------------------------------------------------------------------

reg [31:0] sm_div_up,sm_div_down;
wire [31:0] sm_div_out;



// fc_out1 can be used at cnt = 109
// fc_out2 can be used at cnt = 110
// fc_out3 can be used at cnt = 111
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
    R1 <= 'd0;
    R2 <= 'd0;
    R3 <= 'd0;
    R4 <= 'd0;
    end
    else if ( RoundEnd) begin
    R1 <= 'd0;
    R2 <= 'd0;
    R3 <= 'd0;
    R4 <= 'd0;
    end
    else if (img_cnt == 'd109) R1 <= act_down_temp;  //go to activate, about line 780
    else if (img_cnt == 'd110) begin                 // act_down is from adder, act_down_temp is from exp
        R2 <= act_down_temp;
        R4 <= act_down;
    end
    else if (img_cnt == 'd111) begin                 // cnt == 110, prapare is ok, R1,R2,R3,R4 can be uesd
        R3 <= act_down_temp;
        R4 <= act_down;
    end
    else if (img_cnt == 'd112) R1 <= sm_div_out;
    else if (img_cnt == 'd113) R2 <= sm_div_out;
    else if (img_cnt == 'd114) R3 <= sm_div_out;

end

always @(*) begin
    case (img_cnt)
        'd112: sm_div_up = R1;
        'd113: sm_div_up = R2;
        'd114: sm_div_up = R3;
        default: sm_div_up = 'd0;
    endcase
end

always @(*) begin
    sm_div_down = R4;
end

DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) SoftmaxDiv1
( .a(sm_div_up), .b(sm_div_down), .rnd(3'd0), .z(sm_div_out));

always @ ( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out <= 'd0;
        out_valid <= 'd0;
    end
    else if ( img_cnt == 'd113 | img_cnt == 'd114 | img_cnt == 'd115 ) begin
        out_valid <= 'd1;
        out <=  (img_cnt == 'd113) ? R1:
                (img_cnt == 'd114) ? R2:R3;
    end
    else begin
        out_valid <= 'd0;
        out <=  'd0;
    end
end

endmodule


//---------------------------------------------------------------------
// Activate function
//---------------------------------------------------------------------

// module Sigmoid (
//     in_si,out_si
//     );

//     input [31:0] in_si;
//     output[31:0] out_si;
//     wire [31:0] in_exp, in_plus1;

//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     parameter inst_arch = 0;
//     parameter inst_faithful_round = 0;

//     // 32'b  1.0 = 01111111 00000000000000000000000

//     DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) sig_exp (
//     .a({!in[31],in[30:0]}),
//     .z(in_exp),
//     .status() );

//     DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)sig_add
//     ( .a(32'b0111111100000000000000000000000), .b(in_exp), .rnd(3'd0), .z(in_plus1), .status() );

//     DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round) sig_div
//     ( .a(32'b0111111100000000000000000000000), .b(in_plus1), .rnd(3'd0), .z(out), .status()
//     );

// endmodule



// module Tanh (
//         in,out
//     );

//     input [31:0] in;
//     output[31:0] out;
//     wire [31:0] in_douple_exp;

//     parameter inst_sig_width = 23;
//     parameter inst_exp_width = 8;
//     parameter inst_ieee_compliance = 0;
//     parameter inst_arch_type = 0;
//     parameter inst_arch = 0;
//     parameter inst_faithful_round = 0;

//     // 32'b  1.0 = 01111111 00000000000000000000000

//     // wire [31:0]in_double, in_douple_exp_add, in_douple_exp_sub;
//     // assign in_double = {in[31], (in[29:23],1'd0), in[22:0]};

//     // use in_double
//     // DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) tanh_exp (
//     // .a(in_double),
//     // .z(in_douple_exp),
//     // .status() );

//     // DW_fp_add #(sig_width, exp_width, ieee_compliance)tanh_add
//     // ( .a(in_douple_exp), .b(32'b0111111100000000000000000000000), .rnd(3'd0), .z(in_douple_exp_add), .status() );

//     // DW_fp_sub #(sig_width, exp_width, ieee_compliance)tanh_sub
//     // ( .a(in_douple_exp), .b(32'b0111111100000000000000000000000), .rnd(3'd0), .z(in_douple_exp_sub), .status() );

//     // DW_fp_add #(sig_width, exp_width, ieee_compliance)tanh_add
//     // ( .a(in_douple_exp), .b(32'b0111111100000000000000000000000), .rnd(3'd0), .z(in_douple_exp_add), .status() );

//     // DW_fp_div #(sig_width, exp_width, ieee_compliance, inst_faithful_round) tanh_div
//     // ( .a(in_douple_exp_sub), .b(in_douple_exp_add), .rnd(3'd0), .z(out), .status()
//     // );


//     wire [31:0] in_exp_pos, in_exp_neg, in_exp_add. in_exp_sub;
//     //
//     DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) tanh_exp_pos (
//     .a(in),
//     .z(in_exp_pos) );


//     DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) tanh_exp_neg (
//     .a({!in[31],in[30:0]}),
//     .z(in_exp_neg) );

//     DW_fp_add #(sig_width, exp_width, ieee_compliance)tanh_add
//     ( .a(in_exp_pos), .b(in_exp_neg), .rnd(3'd0), .z(in_exp_add), .status() );

//     DW_fp_sub #(sig_width, exp_width, ieee_compliance)tanh_sub
//     ( .a(in_exp_pos), .b(in_exp_neg), .rnd(3'd0), .z(in_exp_sub), .status() );


//     DW_fp_div #(sig_width, exp_width, ieee_compliance, inst_faithful_round) tanh_div
//     ( .a(in_exp_neg), .b(in_exp_pos), .rnd(3'd0), .z(out), .status()
//     );

// endmodule



// //---------------------------------------------------------------------
// // Pipeline Convolution
// //---------------------------------------------------------------------

// module CNN(
module PPLCV_CTRLA(
        input clk,
        input rst_n,
        input [6:0]img_cnt,
        input [383:0] Kernel_flt,
        // input [383:0] Kernel2_flt,
        // input [31:0] Ker1,
        // input [31:0] Ker2,
        // input [31:0] Ker3,
        // input [31:0] Ker4,
        input [1567:0] Pad, // 32*49 = 1568  { Pad [0]  [1]  [2]......}
        output  [5:0] CV_out_selA,          //    [6]  [7]
        output en_CV_out_selA,
        output reg [31:0] PPLCV_PE_out_nA,
        // output reg [31:0] PPLCV_PE_out_A,
        output  [31:0] PPLCV_PE_out_nA1,
        output [31:0] PPLCV_PE_out_nA2,
        output [31:0] PPLCV_PE_out_nA3,
        output [31:0] PPLCV_PE_out_A1,
        output [31:0] PPLCV_PE_out_A2,
        output [31:0] PPLCV_PE_out_A3
    );


    // pad
    // { Pad [0]  [1]  [2]......}
    //       [6]  [7]  [8]

    // kernal
    // {ker[0][0], ker[0][1], ker[0][2], ker[0][3],
    //  ker[1][0], ker[1][1], ker[1][2], ker[1][3],
    //  ker[2][0], ker[2][1], ker[2][2], ker[2][3]
    // }

    integer i,j,k;
    reg [31:0] Pad_arr [48:0];  // 32*7 = 224
    reg  stA1, stA2, stA3;
    reg [5:0] PadA1_cnt, PadA2_cnt, PadA3_cnt ;
    reg  [31:0] Ker1;
    reg  [31:0] Ker2;
    reg  [31:0] Ker3;
    reg  [31:0] Ker4;
    reg  [31:0] PadA1 [3:0], PadA2 [3:0], PadA3 [3:0];
    reg  [31:0] n_PadA1 [3:0], n_PadA2 [3:0], n_PadA3 [3:0];
    // wire [31:0] PPLCV_PE_out_A1, PPLCV_PE_out_A2, PPLCV_PE_out_A3;
    // wire [31:0] PPLCV_PE_out_nA1, PPLCV_PE_out_nA2,  PPLCV_PE_out_nA3;

    //PPLCV_PE_out_nA
    always @(*) begin
        case (PadA3_cnt %3)
            'd0: PPLCV_PE_out_nA = PPLCV_PE_out_nA1 ;
            'd1: PPLCV_PE_out_nA = PPLCV_PE_out_nA2 ;
            'd2: PPLCV_PE_out_nA = PPLCV_PE_out_nA3 ;
            default: PPLCV_PE_out_nA = 'd0;
        endcase
    end

    //Pad_arr
    always @(*) begin
        for (i=0 ; i<49 ; i=i+1)
        Pad_arr[i] ={   Pad[1567-i*32], Pad[1567-i*32-1], Pad[1567-i*32-2], Pad[1567-i*32-3],
                        Pad[1567-i*32-4], Pad[1567-i*32-5], Pad[1567-i*32-6], Pad[1567-i*32-7],
                        Pad[1567 - i * 32 - 8 ], Pad[1567 - i * 32 - 9 ], Pad[1567 - i * 32 - 10], Pad[1567 - i * 32 - 11],
                        Pad[1567 - i * 32 - 12], Pad[1567 - i * 32 - 13], Pad[1567 - i * 32 - 14], Pad[1567 - i * 32 - 15],
                        Pad[1567 - i * 32 - 16], Pad[1567 - i * 32 - 17], Pad[1567 - i * 32 - 18], Pad[1567 - i * 32 - 19],
                        Pad[1567 - i * 32 - 20], Pad[1567 - i * 32 - 21], Pad[1567 - i * 32 - 22], Pad[1567 - i * 32 - 23],
                        Pad[1567 - i * 32 - 24], Pad[1567 - i * 32 - 25], Pad[1567 - i * 32 - 26], Pad[1567 - i * 32 - 27],
                        Pad[1567 - i * 32 - 28], Pad[1567 - i * 32 - 29], Pad[1567 - i * 32 - 30], Pad[1567 - i * 32 - 31]};
        // Pad_arr[i] ={   Pad[i*32+31], Pad[i*32+30], Pad[i*32+29], Pad[i*32+28],
        //                 Pad[i*32+27], Pad[i*32+26], Pad[i*32+25], Pad[i*32+24],
        //                 Pad[i*32+23], Pad[i*32+22], Pad[i*32+21], Pad[i*32+20],
        //                 Pad[i*32+19], Pad[i*32+18], Pad[i*32+17], Pad[i*32+16],
        //                 Pad[i*32+15], Pad[i*32+14], Pad[i*32+13], Pad[i*32+12],
        //                 Pad[i*32+11], Pad[i*32+10], Pad[i*32+9 ], Pad[i*32+8 ],
        //                 Pad[i*32+ 7], Pad[i*32+6 ], Pad[i*32+5 ], Pad[i*32+4 ],
        //                 Pad[i*32+ 3], Pad[i*32+2 ], Pad[i*32+1 ], Pad[i*32+0 ]  };

        end
        // input [1567:0] Pad, // 32*49 = 1568  { Pad [0]  [1]  [2]......}

    always @(*) begin
        if ( img_cnt < 'd52){Ker1, Ker2, Ker3, Ker4} = Kernel_flt [383:256];
        // else if  {Ker1, Ker2, Ker3, Ker4} = Kernel_flt [255:128];  //A will not join img2
        else {Ker1, Ker2, Ker3, Ker4} = Kernel_flt [127:0];
    end

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) stA1 <= 'd0;
        else if (  img_cnt == 'd2 | PadA1_cnt == 'd35 | img_cnt =='d51)  stA1 <= ~stA1; //PadA1_cnt =='d35 can auto cut off
        else stA1 <= stA1;
    end

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) stA2 <= 'd0;
        else stA2 <= stA1;
    end

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) stA3 <= 'd0;
        else stA3 <= stA2;
    end


    assign  CV_out_selA =PadA3_cnt; //when a1 finish adding( not reg yet), a3 is starting counting.
    assign  en_CV_out_selA = stA3;

    PPLCV_COMP PPLCV_COMPA1(
        .clk(clk),
        .rst_n(rst_n),
        .st(stA1),
        .Ker1(Ker1),
        .Ker2(Ker2),
        .Ker3(Ker3),
        .Ker4(Ker4),
        .Pad1(PadA1[0]),// Pad1 Pad2
        .Pad2(PadA1[1]),// Pad3 Pad4
        .Pad3(PadA1[2]),
        .Pad4(PadA1[3]),
        .PPLCV_PE_out(PPLCV_PE_out_A1),
        .PPLCV_PE_out_n(PPLCV_PE_out_nA1)
    );

    PPLCV_COMP PPLCV_COMPA2(
        .clk(clk),
        .rst_n(rst_n),
        .st(stA2),
        .Ker1(Ker1),
        .Ker2(Ker2),
        .Ker3(Ker3),
        .Ker4(Ker4),
        .Pad1(PadA2[0]),
        .Pad2(PadA2[1]),
        .Pad3(PadA2[2]),
        .Pad4(PadA2[3]),
        .PPLCV_PE_out(PPLCV_PE_out_A2),
        .PPLCV_PE_out_n(PPLCV_PE_out_nA2)
    );

    PPLCV_COMP PPLCV_COMPA3(
        .clk(clk),
        .rst_n(rst_n),
        .st(stA3),
        .Ker1(Ker1),
        .Ker2(Ker2),
        .Ker3(Ker3),
        .Ker4(Ker4),
        .Pad1(PadA3[0]),
        .Pad2(PadA3[1]),
        .Pad3(PadA3[2]),
        .Pad4(PadA3[3]),
        .PPLCV_PE_out(PPLCV_PE_out_A3),
        .PPLCV_PE_out_n(PPLCV_PE_out_nA3)
    );



    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) PadA1_cnt<='d0;
        else if (stA1) PadA1_cnt <= PadA1_cnt + 'd1;
        else PadA1_cnt<='d0;
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) PadA2_cnt<='d0;
        else if (stA2) PadA2_cnt <= PadA2_cnt + 'd1;
        else PadA2_cnt<='d0;
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) PadA3_cnt<='d0;
        else if (stA3) PadA3_cnt <= PadA3_cnt + 'd1;
        else PadA3_cnt<='d0;
    end


    //Padding table
    //PadA1
    always @(*) begin
        case (PadA1_cnt)
            'd0:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };
            'd1:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };
            'd2:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };

            'd3:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };
            'd4:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };
            'd5:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };

            'd6:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };
            'd7:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };
            'd8:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };

            'd9:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };
            'd10: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };
            'd11: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };

            'd12: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };
            'd13: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };
            'd14: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };

            'd15: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };
            'd16: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };
            'd17: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };

            'd18: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };
            'd19: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };
            'd20: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };

            'd21: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };
            'd22: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };
            'd23: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };

            'd24: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };
            'd25: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };
            'd26: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };

            'd27: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };
            'd28: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };
            'd29: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };

            'd30: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            'd31: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            'd32: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };

            'd33: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[46], Pad_arr[45], Pad_arr[39], Pad_arr[38] };
            'd34: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[46], Pad_arr[45], Pad_arr[39], Pad_arr[38] };
            'd35: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[46], Pad_arr[45], Pad_arr[39], Pad_arr[38] };
            default: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} ='d0;
        endcase
    end




    //Padding table
    //PadA2
    always @(*) begin
        case (PadA2_cnt)
            'd0:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };
            'd1:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };
            'd2:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };

            'd3:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };
            'd4:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };
            'd5:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };

            'd6:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };
            'd7:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };
            'd8:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };

            'd9:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };
            'd10: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };
            'd11: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };

            'd12: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };
            'd13: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };
            'd14: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };

            'd15: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };
            'd16: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };
            'd17: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };

            'd18: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[30], Pad_arr[29], Pad_arr[23], Pad_arr[22] };
            'd19: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[30], Pad_arr[29], Pad_arr[23], Pad_arr[22] };
            'd20: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[30], Pad_arr[29], Pad_arr[23], Pad_arr[22] };

            'd21: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };
            'd22: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };
            'd23: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };

            'd24: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[37], Pad_arr[36], Pad_arr[30], Pad_arr[29] };
            'd25: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[37], Pad_arr[36], Pad_arr[30], Pad_arr[29] };
            'd26: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[37], Pad_arr[36], Pad_arr[30], Pad_arr[29] };

            'd27: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };
            'd28: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };
            'd29: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };

            'd30: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };
            'd31: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };
            'd32: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };

            'd33: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            'd34: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            'd35: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            default:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} ='d0;
        endcase
    end

    //Padding table
    //PadA3
    always @(*) begin
        case (PadA3_cnt)
            'd0:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };
            'd1:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };
            'd2:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };

            'd3:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };
            'd4:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };
            'd5:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };

            'd6:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };
            'd7:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };
            'd8:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };

            'd9:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };
            'd10: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };
            'd11: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };

            'd12: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };
            'd13: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };
            'd14: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };

            'd15: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };
            'd16: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };
            'd17: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };

            'd18: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };
            'd19: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };
            'd20: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };

            'd21: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };
            'd22: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };
            'd23: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };

            'd24: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };
            'd25: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };
            'd26: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };

            'd27: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };
            'd28: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };
            'd29: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };

            'd30: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };
            'd31: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };
            'd32: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };

            'd33: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };
            'd34: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };
            'd35: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };

            default: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]} = 0;
        endcase
    end

endmodule


module PPLCV_CTRLB(
        input clk,
        input rst_n,
        input [6:0]img_cnt,
        input [383:0] Kernel_flt,
        input [1567:0] Pad, // 32*49 = 1568  { Pad [0]  [1]  [2]......}
        output  [5:0] CV_out_selB,          //    [6]  [7]
        output en_CV_out_selB,
        // output [31:0] PPLCV_PE_out_B,
        output reg [31:0] PPLCV_PE_out_nB,
        output [31:0] PPLCV_PE_out_nB1,
        output [31:0] PPLCV_PE_out_nB2,
        output [31:0] PPLCV_PE_out_nB3,
        output [31:0] PPLCV_PE_out_B1,
        output [31:0] PPLCV_PE_out_B2,
        output [31:0] PPLCV_PE_out_B3
    );


    // pad
    // { Pad [0]  [1]  [2]......}
    //       [6]  [7]  [8]

    // kernal
    // {ker[0][0], ker[0][1], ker[0][2], ker[0][3],
    //  ker[1][0], ker[1][1], ker[1][2], ker[1][3],
    //  ker[2][0], ker[2][1], ker[2][2], ker[2][3]
    // }

    integer i,j,k;
    reg [31:0] Pad_arr [48:0];  // 32*7 = 224
    reg  stA1, stA2, stA3;
    reg [5:0] PadA1_cnt, PadA2_cnt, PadA3_cnt ;
    reg  [31:0] Ker1;
    reg  [31:0] Ker2;
    reg  [31:0] Ker3;
    reg  [31:0] Ker4;
    reg  [31:0] PadA1 [3:0], PadA2 [3:0], PadA3 [3:0];
    reg  [31:0] n_PadA1 [3:0], n_PadA2 [3:0], n_PadA3 [3:0];
    // wire [31:0] PPLCV_PE_out_B1, PPLCV_PE_out_B2, PPLCV_PE_out_B3;
    // wire [31:0] PPLCV_PE_out_nB1, PPLCV_PE_out_nB2,  PPLCV_PE_out_nB3;

    //Pad_arr
    always @(*) begin
        for (i=0 ; i<49 ; i=i+1)
        Pad_arr[i] ={   Pad[1567-i*32], Pad[1567-i*32-1], Pad[1567-i*32-2], Pad[1567-i*32-3],
                        Pad[1567-i*32-4], Pad[1567-i*32-5], Pad[1567-i*32-6], Pad[1567-i*32-7],
                        Pad[1567 - i * 32 - 8 ], Pad[1567 - i * 32 - 9 ], Pad[1567 - i * 32 - 10], Pad[1567 - i * 32 - 11],
                        Pad[1567 - i * 32 - 12], Pad[1567 - i * 32 - 13], Pad[1567 - i * 32 - 14], Pad[1567 - i * 32 - 15],
                        Pad[1567 - i * 32 - 16], Pad[1567 - i * 32 - 17], Pad[1567 - i * 32 - 18], Pad[1567 - i * 32 - 19],
                        Pad[1567 - i * 32 - 20], Pad[1567 - i * 32 - 21], Pad[1567 - i * 32 - 22], Pad[1567 - i * 32 - 23],
                        Pad[1567 - i * 32 - 24], Pad[1567 - i * 32 - 25], Pad[1567 - i * 32 - 26], Pad[1567 - i * 32 - 27],
                        Pad[1567 - i * 32 - 28], Pad[1567 - i * 32 - 29], Pad[1567 - i * 32 - 30], Pad[1567 - i * 32 - 31]};
        // Pad_arr[i] ={   Pad[i*32+31], Pad[i*32+30], Pad[i*32+29], Pad[i*32+28],
        //                 Pad[i*32+27], Pad[i*32+26], Pad[i*32+25], Pad[i*32+24],
        //                 Pad[i*32+23], Pad[i*32+22], Pad[i*32+21], Pad[i*32+20],
        //                 Pad[i*32+19], Pad[i*32+18], Pad[i*32+17], Pad[i*32+16],
        //                 Pad[i*32+15], Pad[i*32+14], Pad[i*32+13], Pad[i*32+12],
        //                 Pad[i*32+11], Pad[i*32+10], Pad[i*32+9 ], Pad[i*32+8 ],
        //                 Pad[i*32+ 7], Pad[i*32+6 ], Pad[i*32+5 ], Pad[i*32+4 ],
        //                 Pad[i*32+ 3], Pad[i*32+2 ], Pad[i*32+1 ], Pad[i*32+0 ]  };

        end

    // always @(*) begin
    //     if ( img_cnt < 'd52){Ker1, Ker2, Ker3, Ker4} = Kernel_flt [383:256];
    //     // else if  {Ker1, Ker2, Ker3, Ker4} = Kernel_flt [255:128];  //A will not join img2
    //     else {Ker1, Ker2, Ker3, Ker4} = Kernel_flt [127:0];
    // end
    always @(*) begin
        {Ker1, Ker2, Ker3, Ker4} = Kernel_flt [255:128];
    end

    //stA1, stA2, stA3
    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) stA1 <= 'd0;
        else if (  img_cnt == 'd26 | PadA1_cnt == 'd35)  stA1 <= ~stA1; //PadA1_cnt =='d35 can auto cut off
        else stA1 <= stA1;
    end
    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) stA2 <= 'd0;
        else stA2 <= stA1;
    end
    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) stA3 <= 'd0;
        else stA3 <= stA2;
    end

    //PPLCV_PE_out_nB
    always @(*) begin
        case (PadA3_cnt %3)
            'd0: PPLCV_PE_out_nB = PPLCV_PE_out_nB1 ;
            'd1: PPLCV_PE_out_nB = PPLCV_PE_out_nB2 ;
            'd2: PPLCV_PE_out_nB = PPLCV_PE_out_nB3 ;
            default: PPLCV_PE_out_nB = 'd0;
        endcase
    end

    assign  CV_out_selB =PadA3_cnt; //when a1 finish adding( not reg yet), a3 is starting counting.
    assign  en_CV_out_selB = stA3;

    PPLCV_COMP PPLCV_COMPB1(
        .clk(clk),
        .rst_n(rst_n),
        .st(stA1),
        .Ker1(Ker1),
        .Ker2(Ker2),
        .Ker3(Ker3),
        .Ker4(Ker4),
        .Pad1(PadA1[0]),// Pad1 Pad2
        .Pad2(PadA1[1]),// Pad3 Pad4
        .Pad3(PadA1[2]),
        .Pad4(PadA1[3]),
        .PPLCV_PE_out(PPLCV_PE_out_B1),
        .PPLCV_PE_out_n(PPLCV_PE_out_nB1)
    );

    PPLCV_COMP PPLCV_COMPB2(
        .clk(clk),
        .rst_n(rst_n),
        .st(stA2),
        .Ker1(Ker1),
        .Ker2(Ker2),
        .Ker3(Ker3),
        .Ker4(Ker4),
        .Pad1(PadA2[0]),
        .Pad2(PadA2[1]),
        .Pad3(PadA2[2]),
        .Pad4(PadA2[3]),
        .PPLCV_PE_out(PPLCV_PE_out_B2),
        .PPLCV_PE_out_n(PPLCV_PE_out_nB2)
    );

    PPLCV_COMP PPLCV_COMPB3(
        .clk(clk),
        .rst_n(rst_n),
        .st(stA3),
        .Ker1(Ker1),
        .Ker2(Ker2),
        .Ker3(Ker3),
        .Ker4(Ker4),
        .Pad1(PadA3[0]),
        .Pad2(PadA3[1]),
        .Pad3(PadA3[2]),
        .Pad4(PadA3[3]),
        .PPLCV_PE_out(PPLCV_PE_out_B3),
        .PPLCV_PE_out_n(PPLCV_PE_out_nB3)
    );


    // saA1, saA2, saA3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) PadA1_cnt<='d0;
        else if (stA1) PadA1_cnt <= PadA1_cnt + 'd1;
        else PadA1_cnt<='d0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) PadA2_cnt<='d0;
        else if (stA2) PadA2_cnt <= PadA2_cnt + 'd1;
        else PadA2_cnt<='d0;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) PadA3_cnt<='d0;
        else if (stA3) PadA3_cnt <= PadA3_cnt + 'd1;
        else PadA3_cnt<='d0;
    end

    //Padding table
    //PadA1
    always @(*) begin
        case (PadA1_cnt)
            'd0:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };
            'd1:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };
            'd2:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };

            'd3:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };
            'd4:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };
            'd5:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };

            'd6:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };
            'd7:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };
            'd8:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };

            'd9:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };
            'd10: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };
            'd11: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };

            'd12: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };
            'd13: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };
            'd14: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };

            'd15: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };
            'd16: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };
            'd17: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };

            'd18: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };
            'd19: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };
            'd20: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };

            'd21: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };
            'd22: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };
            'd23: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };

            'd24: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };
            'd25: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };
            'd26: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };

            'd27: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };
            'd28: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };
            'd29: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };

            'd30: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            'd31: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            'd32: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };

            'd33: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[46], Pad_arr[45], Pad_arr[39], Pad_arr[38] };
            'd34: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[46], Pad_arr[45], Pad_arr[39], Pad_arr[38] };
            'd35: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[46], Pad_arr[45], Pad_arr[39], Pad_arr[38] };
            default: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} ='d0;
        endcase
    end




    //Padding table
    //PadA2
    always @(*) begin
        case (PadA2_cnt)
            'd0:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };
            'd1:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };
            'd2:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };

            'd3:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };
            'd4:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };
            'd5:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };

            'd6:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };
            'd7:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };
            'd8:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };

            'd9:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };
            'd10: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };
            'd11: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };

            'd12: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };
            'd13: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };
            'd14: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };

            'd15: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };
            'd16: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };
            'd17: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };

            'd18: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[30], Pad_arr[29], Pad_arr[23], Pad_arr[22] };
            'd19: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[30], Pad_arr[29], Pad_arr[23], Pad_arr[22] };
            'd20: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[30], Pad_arr[29], Pad_arr[23], Pad_arr[22] };

            'd21: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };
            'd22: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };
            'd23: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };

            'd24: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[37], Pad_arr[36], Pad_arr[30], Pad_arr[29] };
            'd25: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[37], Pad_arr[36], Pad_arr[30], Pad_arr[29] };
            'd26: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[37], Pad_arr[36], Pad_arr[30], Pad_arr[29] };

            'd27: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };
            'd28: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };
            'd29: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };

            'd30: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };
            'd31: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };
            'd32: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };

            'd33: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            'd34: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            'd35: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            default:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} ='d0;
        endcase
    end

    //Padding table
    //PadA3
    always @(*) begin
        case (PadA3_cnt)
            'd0:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };
            'd1:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };
            'd2:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };

            'd3:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };
            'd4:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };
            'd5:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };

            'd6:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };
            'd7:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };
            'd8:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };

            'd9:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };
            'd10: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };
            'd11: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };

            'd12: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };
            'd13: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };
            'd14: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };

            'd15: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };
            'd16: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };
            'd17: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };

            'd18: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };
            'd19: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };
            'd20: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };

            'd21: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };
            'd22: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };
            'd23: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };

            'd24: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };
            'd25: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };
            'd26: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };

            'd27: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };
            'd28: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };
            'd29: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };

            'd30: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };
            'd31: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };
            'd32: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };

            'd33: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };
            'd34: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };
            'd35: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };

            default: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]} = 0;
        endcase
    end




/*
    //Padding table
    //PadA1
    always @(*) begin
        case (PadA1_cnt)
            'd0:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };
            'd1:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };
            'd2:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[8], Pad_arr[7], Pad_arr[1], Pad_arr[0] };

            'd3:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };
            'd4:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };
            'd5:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[11], Pad_arr[10], Pad_arr[4], Pad_arr[3] };

            'd6:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };
            'd7:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };
            'd8:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[15], Pad_arr[14], Pad_arr[8], Pad_arr[7] };

            'd9:  {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };
            'd10: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };
            'd11: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[18], Pad_arr[17], Pad_arr[11], Pad_arr[10] };

            'd12: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };
            'd13: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };
            'd14: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[22], Pad_arr[21], Pad_arr[15], Pad_arr[14] };

            'd15: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };
            'd16: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };
            'd17: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[25], Pad_arr[24], Pad_arr[18], Pad_arr[17] };

            'd18: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };
            'd19: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };
            'd20: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };

            'd21: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };
            'd22: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };
            'd23: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[32], Pad_arr[31], Pad_arr[25], Pad_arr[24] };

            'd24: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };
            'd25: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };
            'd26: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };

            'd27: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };
            'd28: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };
            'd29: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[39], Pad_arr[38], Pad_arr[32], Pad_arr[31] };

            'd30: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            'd31: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            'd32: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };

            'd33: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            'd34: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            'd35: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} = { Pad_arr[43], Pad_arr[42], Pad_arr[36], Pad_arr[35] };
            default: {PadA1[3],PadA1[2],PadA1[1],PadA1[0]} ='d0;
        endcase
    end
    //Padding table
    //PadA2
    always @(*) begin
        case (PadA2_cnt)
            'd0:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };
            'd1:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };
            'd2:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[9], Pad_arr[8], Pad_arr[2], Pad_arr[1] };

            'd3:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };
            'd4:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };
            'd5:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[12], Pad_arr[11], Pad_arr[5], Pad_arr[4] };

            'd6:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };
            'd7:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };
            'd8:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[16], Pad_arr[15], Pad_arr[9], Pad_arr[8] };

            'd9:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };
            'd10: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };
            'd11: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[19], Pad_arr[18], Pad_arr[12], Pad_arr[11] };

            'd12: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };
            'd13: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };
            'd14: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[23], Pad_arr[22], Pad_arr[16], Pad_arr[15] };

            'd15: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };
            'd16: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };
            'd17: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[26], Pad_arr[25], Pad_arr[19], Pad_arr[18] };

            'd18: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };
            'd19: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };
            'd20: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[29], Pad_arr[28], Pad_arr[22], Pad_arr[21] };

            'd21: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };
            'd22: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };
            'd23: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[33], Pad_arr[32], Pad_arr[26], Pad_arr[25] };

            'd24: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };
            'd25: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };
            'd26: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[36], Pad_arr[35], Pad_arr[29], Pad_arr[28] };

            'd27: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };
            'd28: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };
            'd29: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[40], Pad_arr[39], Pad_arr[33], Pad_arr[32] };

            'd30: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };
            'd31: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };
            'd32: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[44], Pad_arr[43], Pad_arr[37], Pad_arr[36] };

            'd33: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            'd34: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            'd35: {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} = { Pad_arr[47], Pad_arr[46], Pad_arr[40], Pad_arr[39] };
            default:  {PadA2[3], PadA2[2], PadA2[1], PadA2[0]} ='d0;
        endcase
    end

    //Padding table
    //PadA3
    always @(*) begin
        case (PadA3_cnt)
            'd0:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };
            'd1:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };
            'd2:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[10], Pad_arr[9], Pad_arr[3], Pad_arr[2] };

            'd3:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };
            'd4:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };
            'd5:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[13], Pad_arr[12], Pad_arr[6], Pad_arr[5] };

            'd6:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };
            'd7:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };
            'd8:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[17], Pad_arr[16], Pad_arr[10], Pad_arr[9] };

            'd9:  {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };
            'd10: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };
            'd11: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[20], Pad_arr[19], Pad_arr[13], Pad_arr[12] };

            'd12: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };
            'd13: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };
            'd14: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[24], Pad_arr[23], Pad_arr[17], Pad_arr[16] };

            'd15: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };
            'd16: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };
            'd17: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[27], Pad_arr[26], Pad_arr[20], Pad_arr[19] };

            'd18: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };
            'd19: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };
            'd20: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[31], Pad_arr[30], Pad_arr[24], Pad_arr[23] };

            'd21: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };
            'd22: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };
            'd23: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[34], Pad_arr[33], Pad_arr[27], Pad_arr[26] };

            'd24: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };
            'd25: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };
            'd26: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[38], Pad_arr[37], Pad_arr[31], Pad_arr[30] };

            'd27: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };
            'd28: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };
            'd29: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[41], Pad_arr[40], Pad_arr[34], Pad_arr[33] };

            'd30: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };
            'd31: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };
            'd32: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[45], Pad_arr[44], Pad_arr[38], Pad_arr[37] };

            'd33: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };
            'd34: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };
            'd35: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]}  = { Pad_arr[48], Pad_arr[47], Pad_arr[41], Pad_arr[40] };

            default: {PadA3[3], PadA3[2], PadA3[1], PadA3[0]} = 0;
        endcase
    end
*/
endmodule

// module CNN (
module PPLCV_COMP (
        input clk,
        input rst_n,
        input st,
        // input  add_in_sel,
        // input [1:0] add_in_sel,
        input [31:0] Ker1,  // Ker1 Ker2
        input [31:0] Ker2,  // Ker3 Ker4
        input [31:0] Ker3,
        input [31:0] Ker4,
        input [31:0] Pad1,  // Pad1 Pad2
        input [31:0] Pad2,  // Pad3 Pad4
        input [31:0] Pad3,
        input [31:0] Pad4,
        output reg [31:0] PPLCV_PE_out,
        output [31:0] PPLCV_PE_out_n
    );

    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    parameter inst_arch = 0;
    parameter inst_faithful_round = 0;
    parameter inst_rnd = 3'd0;

    // wire [31:0] PPLCV_PE_out_n;
    reg [31:0] BP1,BP2;
    reg [1:0] PPLCV_COMP_cnt;

    wire [31:0] addin1,addin2;
    wire [31:0] mult_out1, mult_out2;
    wire add_in_sel;

    wire [31:0] Ker_in1 , Ker_in2;
    assign Ker_in1 = ( PPLCV_COMP_cnt == 'd0)?Ker1:Ker3;
    assign Ker_in2 = ( PPLCV_COMP_cnt == 'd0)?Ker2:Ker4;

    wire [31:0] Pad_in1, Pad_in2;
    assign Pad_in1 = ( PPLCV_COMP_cnt == 'd0)?Pad1:Pad3;
    assign Pad_in2 = ( PPLCV_COMP_cnt == 'd0)?Pad2:Pad4;


    // For test, fp => int
    // assign mult_out1 = Ker_in1 * Pad_in1;
    // assign mult_out2 = Ker_in2 * Pad_in2;
    // assign add_in_sel = (PPLCV_COMP_cnt == 'd2 ) ? 'd1: 'd0;
    // assign addin1 = (add_in_sel)? BP1 : mult_out1;
    // assign addin2 = (add_in_sel)? BP2 : mult_out2;
    // assign PPLCV_PE_out_n = addin1 + addin2;


    assign add_in_sel = (PPLCV_COMP_cnt == 'd2 ) ? 'd1: 'd0;
    assign addin1 = (add_in_sel)? BP1 : mult_out1;
    assign addin2 = (add_in_sel)? BP2 : mult_out2;

    DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1 ( .a(Ker_in1), .b(Pad_in1), .rnd(3'd0), .z(mult_out1) );
    DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U2 ( .a(Ker_in2), .b(Pad_in2), .rnd(3'd0), .z(mult_out2) );

    DW_fp_add_inst DW_fp_add_inst0( .inst_a(addin1), .inst_b(addin2), .inst_rnd(3'd0), .z_inst(PPLCV_PE_out_n)   );

    always @( posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            BP1 <='d0;
            BP2 <='d0;
            PPLCV_PE_out <='d0;
            PPLCV_COMP_cnt <='d0;
        end
        else if (st == 'd1)begin
            case (PPLCV_COMP_cnt)
                'd0:begin
                    BP1 <= PPLCV_PE_out_n;
                    PPLCV_COMP_cnt <= PPLCV_COMP_cnt +'d1;
                end
                'd1:begin
                    BP2 <= PPLCV_PE_out_n;
                    PPLCV_COMP_cnt <= PPLCV_COMP_cnt +'d1;
                end
                'd2:begin
                    PPLCV_PE_out <= PPLCV_PE_out_n;
                    PPLCV_COMP_cnt <= 'd0;
                end
                default:  begin
                    BP1 <= BP1;
                    BP2 <= BP2;
                    PPLCV_PE_out <= PPLCV_PE_out;
                    PPLCV_COMP_cnt <= PPLCV_COMP_cnt;
                end
            endcase
        end
        else begin
            // BP1 <= BP1;
            // BP2 <= BP2;
            BP1 <= 'd0;
            BP2 <= 'd0;
            PPLCV_PE_out <= 'd0;
            // PPLCV_PE_out <= PPLCV_PE_out;
            PPLCV_COMP_cnt <= 'd0;
        end
    end

endmodule


//---------------------------------------------------------------------
//  Convolution Reg
//---------------------------------------------------------------------
// module CNN (
module CV_reg_ckt (
        input clk,
        input rst_n,
        input [6:0] img_cnt,
        input [31:0] PPLCV_PE_out_nA,
        input [31:0] PPLCV_PE_out_nB,
        input  [5:0] CV_out_selA,          //    [6]  [7]
        input en_CV_out_selA,
        input  [5:0] CV_out_selB,          //    [6]  [7]
        input en_CV_out_selB,
        output [1151:0] CV_reg
    );

    integer i;
    // reg [31:0] CVreg_pt_add;
    // reg [31:0] CVreg_pt_old;
    wire [31:0] CVreg_pt_new;
    reg [31:0] CVreg_pt_oldA, CVreg_pt_oldB;
    // wire [31:0 ]CVreg_pt_addA, CVreg_pt_addB;
    wire [31:0] CVreg_pt_newA, CVreg_pt_newB;
    reg  [31:0] CVreg_arr [0:35];
    assign   CV_reg = {CVreg_arr[0] , CVreg_arr[1] , CVreg_arr[2] , CVreg_arr[3] ,
                    CVreg_arr[4] , CVreg_arr[5] , CVreg_arr[6] , CVreg_arr[7] ,
                    CVreg_arr[8] , CVreg_arr[9] , CVreg_arr[10], CVreg_arr[11],
                    CVreg_arr[12], CVreg_arr[13], CVreg_arr[14], CVreg_arr[15],
                    CVreg_arr[16], CVreg_arr[17], CVreg_arr[18], CVreg_arr[19],
                    CVreg_arr[20], CVreg_arr[21], CVreg_arr[22], CVreg_arr[23],
                    CVreg_arr[24], CVreg_arr[25], CVreg_arr[26], CVreg_arr[27],
                    CVreg_arr[28], CVreg_arr[29], CVreg_arr[30], CVreg_arr[31],
                    CVreg_arr[32], CVreg_arr[33], CVreg_arr[34], CVreg_arr[35]};


    always @( posedge clk or negedge rst_n) begin
        if (!rst_n){CVreg_arr[0] , CVreg_arr[1] , CVreg_arr[2] , CVreg_arr[3] ,
                    CVreg_arr[4] , CVreg_arr[5] , CVreg_arr[6] , CVreg_arr[7] ,
                    CVreg_arr[8] , CVreg_arr[9] , CVreg_arr[10], CVreg_arr[11],
                    CVreg_arr[12], CVreg_arr[13], CVreg_arr[14], CVreg_arr[15],
                    CVreg_arr[16], CVreg_arr[17], CVreg_arr[18], CVreg_arr[19],
                    CVreg_arr[20], CVreg_arr[21], CVreg_arr[22], CVreg_arr[23],
                    CVreg_arr[24], CVreg_arr[25], CVreg_arr[26], CVreg_arr[27],
                    CVreg_arr[28], CVreg_arr[29], CVreg_arr[30], CVreg_arr[31],
                    CVreg_arr[32], CVreg_arr[33], CVreg_arr[34], CVreg_arr[35]} <='d0;

        else if ( img_cnt == 'd115){ CVreg_arr[0] , CVreg_arr[1] , CVreg_arr[2] , CVreg_arr[3] ,
        // else if (RoundEnd){ CVreg_arr[0] , CVreg_arr[1] , CVreg_arr[2] , CVreg_arr[3] ,
                                CVreg_arr[4] , CVreg_arr[5] , CVreg_arr[6] , CVreg_arr[7] ,
                                CVreg_arr[8] , CVreg_arr[9] , CVreg_arr[10], CVreg_arr[11],
                                CVreg_arr[12], CVreg_arr[13], CVreg_arr[14], CVreg_arr[15],
                                CVreg_arr[16], CVreg_arr[17], CVreg_arr[18], CVreg_arr[19],
                                CVreg_arr[20], CVreg_arr[21], CVreg_arr[22], CVreg_arr[23],
                                CVreg_arr[24], CVreg_arr[25], CVreg_arr[26], CVreg_arr[27],
                                CVreg_arr[28], CVreg_arr[29], CVreg_arr[30], CVreg_arr[31],
                                CVreg_arr[32], CVreg_arr[33], CVreg_arr[34], CVreg_arr[35]} <='d0;

        else if  ( en_CV_out_selA | en_CV_out_selB)begin
            if (en_CV_out_selA) begin
                case (CV_out_selA)
                'd0 : CVreg_arr [0 ] <= CVreg_pt_newA ;
                'd1 : CVreg_arr [1 ] <= CVreg_pt_newA ;
                'd2 : CVreg_arr [2 ] <= CVreg_pt_newA ;
                'd3 : CVreg_arr [3 ] <= CVreg_pt_newA ;
                'd4 : CVreg_arr [4 ] <= CVreg_pt_newA ;
                'd5 : CVreg_arr [5 ] <= CVreg_pt_newA ;
                'd6 : CVreg_arr [6 ] <= CVreg_pt_newA ;
                'd7 : CVreg_arr [7 ] <= CVreg_pt_newA ;
                'd8 : CVreg_arr [8 ] <= CVreg_pt_newA ;
                'd9 : CVreg_arr [9 ] <= CVreg_pt_newA ;
                'd10: CVreg_arr [10] <= CVreg_pt_newA ;
                'd11: CVreg_arr [11] <= CVreg_pt_newA ;
                'd12: CVreg_arr [12] <= CVreg_pt_newA ;
                'd13: CVreg_arr [13] <= CVreg_pt_newA ;
                'd14: CVreg_arr [14] <= CVreg_pt_newA ;
                'd15: CVreg_arr [15] <= CVreg_pt_newA ;
                'd16: CVreg_arr [16] <= CVreg_pt_newA ;
                'd17: CVreg_arr [17] <= CVreg_pt_newA ;
                'd18: CVreg_arr [18] <= CVreg_pt_newA ;
                'd19: CVreg_arr [19] <= CVreg_pt_newA ;
                'd20: CVreg_arr [20] <= CVreg_pt_newA ;
                'd21: CVreg_arr [21] <= CVreg_pt_newA ;
                'd22: CVreg_arr [22] <= CVreg_pt_newA ;
                'd23: CVreg_arr [23] <= CVreg_pt_newA ;
                'd24: CVreg_arr [24] <= CVreg_pt_newA ;
                'd25: CVreg_arr [25] <= CVreg_pt_newA ;
                'd26: CVreg_arr [26] <= CVreg_pt_newA ;
                'd27: CVreg_arr [27] <= CVreg_pt_newA ;
                'd28: CVreg_arr [28] <= CVreg_pt_newA ;
                'd29: CVreg_arr [29] <= CVreg_pt_newA ;
                'd30: CVreg_arr [30] <= CVreg_pt_newA ;
                'd31: CVreg_arr [31] <= CVreg_pt_newA ;
                'd32: CVreg_arr [32] <= CVreg_pt_newA ;
                'd33: CVreg_arr [33] <= CVreg_pt_newA ;
                'd34: CVreg_arr [34] <= CVreg_pt_newA ;
                'd35: CVreg_arr [35] <= CVreg_pt_newA ;
                default:  for (i = 0 ;i<36;i=i+1) CVreg_arr[i] <= CVreg_arr[i];
            endcase
            end
            if (en_CV_out_selB) begin
                case (CV_out_selB)
                'd0 : CVreg_arr [0 ] <= CVreg_pt_newB ;
                'd1 : CVreg_arr [1 ] <= CVreg_pt_newB ;
                'd2 : CVreg_arr [2 ] <= CVreg_pt_newB ;
                'd3 : CVreg_arr [3 ] <= CVreg_pt_newB ;
                'd4 : CVreg_arr [4 ] <= CVreg_pt_newB ;
                'd5 : CVreg_arr [5 ] <= CVreg_pt_newB ;
                'd6 : CVreg_arr [6 ] <= CVreg_pt_newB ;
                'd7 : CVreg_arr [7 ] <= CVreg_pt_newB ;
                'd8 : CVreg_arr [8 ] <= CVreg_pt_newB ;
                'd9 : CVreg_arr [9 ] <= CVreg_pt_newB ;
                'd10: CVreg_arr [10] <= CVreg_pt_newB ;
                'd11: CVreg_arr [11] <= CVreg_pt_newB ;
                'd12: CVreg_arr [12] <= CVreg_pt_newB ;
                'd13: CVreg_arr [13] <= CVreg_pt_newB ;
                'd14: CVreg_arr [14] <= CVreg_pt_newB ;
                'd15: CVreg_arr [15] <= CVreg_pt_newB ;
                'd16: CVreg_arr [16] <= CVreg_pt_newB ;
                'd17: CVreg_arr [17] <= CVreg_pt_newB ;
                'd18: CVreg_arr [18] <= CVreg_pt_newB ;
                'd19: CVreg_arr [19] <= CVreg_pt_newB ;
                'd20: CVreg_arr [20] <= CVreg_pt_newB ;
                'd21: CVreg_arr [21] <= CVreg_pt_newB ;
                'd22: CVreg_arr [22] <= CVreg_pt_newB ;
                'd23: CVreg_arr [23] <= CVreg_pt_newB ;
                'd24: CVreg_arr [24] <= CVreg_pt_newB ;
                'd25: CVreg_arr [25] <= CVreg_pt_newB ;
                'd26: CVreg_arr [26] <= CVreg_pt_newB ;
                'd27: CVreg_arr [27] <= CVreg_pt_newB ;
                'd28: CVreg_arr [28] <= CVreg_pt_newB ;
                'd29: CVreg_arr [29] <= CVreg_pt_newB ;
                'd30: CVreg_arr [30] <= CVreg_pt_newB ;
                'd31: CVreg_arr [31] <= CVreg_pt_newB ;
                'd32: CVreg_arr [32] <= CVreg_pt_newB ;
                'd33: CVreg_arr [33] <= CVreg_pt_newB ;
                'd34: CVreg_arr [34] <= CVreg_pt_newB ;
                'd35: CVreg_arr [35] <= CVreg_pt_newB ;
                default:  for (i = 0 ;i<36;i=i+1) CVreg_arr[i] <= CVreg_arr[i];
                endcase

            end
        end
    end

    // assign CVreg_pt_addA = PPLCV_PE_out_nA1;

    always @(*) begin
        if (en_CV_out_selA) begin
            case (CV_out_selA)
                'd0:  CVreg_pt_oldA = CVreg_arr[0];
                'd1:  CVreg_pt_oldA = CVreg_arr[1];
                'd2:  CVreg_pt_oldA = CVreg_arr[2];
                'd3:  CVreg_pt_oldA = CVreg_arr[3];
                'd4:  CVreg_pt_oldA = CVreg_arr[4];
                'd5:  CVreg_pt_oldA = CVreg_arr[5];
                'd6:  CVreg_pt_oldA = CVreg_arr[6];
                'd7:  CVreg_pt_oldA = CVreg_arr[7];
                'd8:  CVreg_pt_oldA = CVreg_arr[8];
                'd9:  CVreg_pt_oldA = CVreg_arr[9];
                'd10: CVreg_pt_oldA = CVreg_arr[10];
                'd11: CVreg_pt_oldA = CVreg_arr[11];
                'd12: CVreg_pt_oldA = CVreg_arr[12];
                'd13: CVreg_pt_oldA = CVreg_arr[13];
                'd14: CVreg_pt_oldA = CVreg_arr[14];
                'd15: CVreg_pt_oldA = CVreg_arr[15];
                'd16: CVreg_pt_oldA = CVreg_arr[16];
                'd17: CVreg_pt_oldA = CVreg_arr[17];
                'd18: CVreg_pt_oldA = CVreg_arr[18];
                'd19: CVreg_pt_oldA = CVreg_arr[19];
                'd20: CVreg_pt_oldA = CVreg_arr[20];
                'd21: CVreg_pt_oldA = CVreg_arr[21];
                'd22: CVreg_pt_oldA = CVreg_arr[22];
                'd23: CVreg_pt_oldA = CVreg_arr[23];
                'd24: CVreg_pt_oldA = CVreg_arr[24];
                'd25: CVreg_pt_oldA = CVreg_arr[25];
                'd26: CVreg_pt_oldA = CVreg_arr[26];
                'd27: CVreg_pt_oldA = CVreg_arr[27];
                'd28: CVreg_pt_oldA = CVreg_arr[28];
                'd29: CVreg_pt_oldA = CVreg_arr[29];
                'd30: CVreg_pt_oldA = CVreg_arr[30];
                'd31: CVreg_pt_oldA = CVreg_arr[31];
                'd32: CVreg_pt_oldA = CVreg_arr[32];
                'd33: CVreg_pt_oldA = CVreg_arr[33];
                'd34: CVreg_pt_oldA = CVreg_arr[34];
                'd35: CVreg_pt_oldA = CVreg_arr[35];
                default: CVreg_pt_oldA = 'b0;
            endcase
        end
        else CVreg_pt_oldA = 'd0;

        if (en_CV_out_selB) begin
            case (CV_out_selB)
                'd0:  CVreg_pt_oldB = CVreg_arr[0];
                'd1:  CVreg_pt_oldB = CVreg_arr[1];
                'd2:  CVreg_pt_oldB = CVreg_arr[2];
                'd3:  CVreg_pt_oldB = CVreg_arr[3];
                'd4:  CVreg_pt_oldB = CVreg_arr[4];
                'd5:  CVreg_pt_oldB = CVreg_arr[5];
                'd6:  CVreg_pt_oldB = CVreg_arr[6];
                'd7:  CVreg_pt_oldB = CVreg_arr[7];
                'd8:  CVreg_pt_oldB = CVreg_arr[8];
                'd9:  CVreg_pt_oldB = CVreg_arr[9];
                'd10: CVreg_pt_oldB = CVreg_arr[10];
                'd11: CVreg_pt_oldB = CVreg_arr[11];
                'd12: CVreg_pt_oldB = CVreg_arr[12];
                'd13: CVreg_pt_oldB = CVreg_arr[13];
                'd14: CVreg_pt_oldB = CVreg_arr[14];
                'd15: CVreg_pt_oldB = CVreg_arr[15];
                'd16: CVreg_pt_oldB = CVreg_arr[16];
                'd17: CVreg_pt_oldB = CVreg_arr[17];
                'd18: CVreg_pt_oldB = CVreg_arr[18];
                'd19: CVreg_pt_oldB = CVreg_arr[19];
                'd20: CVreg_pt_oldB = CVreg_arr[20];
                'd21: CVreg_pt_oldB = CVreg_arr[21];
                'd22: CVreg_pt_oldB = CVreg_arr[22];
                'd23: CVreg_pt_oldB = CVreg_arr[23];
                'd24: CVreg_pt_oldB = CVreg_arr[24];
                'd25: CVreg_pt_oldB = CVreg_arr[25];
                'd26: CVreg_pt_oldB = CVreg_arr[26];
                'd27: CVreg_pt_oldB = CVreg_arr[27];
                'd28: CVreg_pt_oldB = CVreg_arr[28];
                'd29: CVreg_pt_oldB = CVreg_arr[29];
                'd30: CVreg_pt_oldB = CVreg_arr[30];
                'd31: CVreg_pt_oldB = CVreg_arr[31];
                'd32: CVreg_pt_oldB = CVreg_arr[32];
                'd33: CVreg_pt_oldB = CVreg_arr[33];
                'd34: CVreg_pt_oldB = CVreg_arr[34];
                'd35: CVreg_pt_oldB = CVreg_arr[35];
                default: CVreg_pt_oldB = 'b0;
            endcase
        end
        else CVreg_pt_oldB = 'd0;
    end



    // for test, fp => int
    // assign CVreg_pt_newA = PPLCV_PE_out_nA+ CVreg_pt_oldA;
    // assign CVreg_pt_newB = PPLCV_PE_out_nB+ CVreg_pt_oldB;

    DW_fp_add_inst DW_fp_add_instA( .inst_a(PPLCV_PE_out_nA), .inst_b(CVreg_pt_oldA), .inst_rnd(3'd0), .z_inst(CVreg_pt_newA) );
    DW_fp_add_inst DW_fp_add_instB( .inst_a(PPLCV_PE_out_nB), .inst_b(CVreg_pt_oldB), .inst_rnd(3'd0), .z_inst(CVreg_pt_newB) );


    endmodule


//---------------------------------------------------------------------
// DsignWare   Tool
//---------------------------------------------------------------------


module fp_mult_add( inst_a, inst_b, inst_c, inst_rnd, z_inst); //ab+c
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    parameter inst_arch = 0;
    parameter inst_faithful_round = 0;

    input [inst_sig_width+inst_exp_width : 0] inst_a;
    input [inst_sig_width+inst_exp_width : 0] inst_b;
    input [inst_sig_width+inst_exp_width : 0] inst_c;
    input [2 : 0] inst_rnd;
    output [inst_sig_width+inst_exp_width : 0] z_inst;
    wire [7 : 0] status_inst;

    // assign inst_rnd = 3'd0;
    DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U1 (
    .a(inst_a),
    .b(inst_b),
    .c(inst_c),
    .rnd(inst_rnd),
    .z(z_inst),
    .status(status_inst) );

endmodule



module DW_fp_sub_inst( inst_a, inst_b, inst_rnd, z_inst );
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    parameter inst_arch = 0;
    parameter inst_faithful_round = 0;

    input [inst_sig_width+inst_exp_width : 0] inst_a;
    input [inst_sig_width+inst_exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [inst_sig_width+inst_exp_width : 0] z_inst;
    wire [7 : 0] status_inst;

    // assign inst_rnd =3'd0;
    // Instance of DW_fp_sub
    DW_fp_sub #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule


module DW_fp_add_inst( inst_a, inst_b, inst_rnd, z_inst );
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    parameter inst_arch = 0;
    parameter inst_faithful_round = 0;

    input [inst_sig_width+inst_exp_width : 0] inst_a;
    input [inst_sig_width+inst_exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [inst_sig_width+inst_exp_width : 0] z_inst;
    wire [7 : 0] status_inst;
    // Instance of DW_fp_add
    DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule


module DW_fp_mult_inst( inst_a, inst_b, inst_rnd, z_inst );
    parameter inst_sig_width = 23;
    parameter inst_exp_width = 8;
    parameter inst_ieee_compliance = 0;
    parameter inst_arch_type = 0;
    parameter inst_arch = 0;
    parameter inst_faithful_round = 0;

    input [inst_sig_width+inst_exp_width : 0] inst_a;
    input [inst_sig_width+inst_exp_width : 0] inst_b;
    input [2 : 0] inst_rnd;
    output [inst_sig_width+inst_exp_width : 0] z_inst;
    wire  [7 : 0] status_inst;

    // Instance of DW_fp_mult
    DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
    U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule



module DW_fp_cmp_inst( inst_a, inst_b, inst_zctr, aeqb_inst, altb_inst,
    agtb_inst, unordered_inst, z0_inst, z1_inst, status0_inst,
    status1_inst );
    parameter sig_width = 23;
    parameter exp_width = 8;
    parameter ieee_compliance = 0;
    input [sig_width+exp_width : 0] inst_a;
    input [sig_width+exp_width : 0] inst_b;
    input inst_zctr;
    output aeqb_inst;
    output altb_inst;
    output agtb_inst;
    output unordered_inst;
    output [sig_width+exp_width : 0] z0_inst;
    output [sig_width+exp_width : 0] z1_inst;
    output [7 : 0] status0_inst;
    output [7 : 0] status1_inst;
    // Instance of DW_fp_cmp
    DW_fp_cmp #(sig_width, exp_width, ieee_compliance)
    U1 ( .a(inst_a), .b(inst_b), .zctr(inst_zctr), .aeqb(aeqb_inst),     // when zctr('d0) Z1 is the bigger one
    .altb(altb_inst), .agtb(agtb_inst), .unordered(unordered_inst),
    .z0(z0_inst), .z1(z1_inst), .status0(status0_inst),
    .status1(status1_inst) );
endmodule

//---------------------------------------------------------------------
// systolic Convolution
//---------------------------------------------------------------------

// module systolic_arr (
    //     input clk,
    //     input rst_n,
    //     input [15:0] stp,
    //     input [15:0] clr,
    //     input [127:0] Ker,
    //     input [127:0] Pa,
    //     output [31:0] CVout1,
    //     output [31:0] CVput2
    // );

    //     wire [15:0] o_r, o_b;
    //     output [31:0] sum [15:0];
    //     SystolicPE sa0 (.clk(clk), .rst_n(rst_n), .clr(clr[0] ), .stp(stp[0] ),.i_u(Pa[31:0 ] ), .i_l(Ker[31:0]  ), .o_r(o_r[0] ), .o_b(o_b[0] ), .sum(sum[0] ));
    //     SystolicPE sa1 (.clk(clk), .rst_n(rst_n), .clr(clr[1] ), .stp(stp[1] ),.i_u(Pa[63:32] ), .i_l(o_r[0]     ), .o_r(o_r[1] ), .o_b(o_b[1] ), .sum(sum[1] ));
    //     SystolicPE sa2 (.clk(clk), .rst_n(rst_n), .clr(clr[2] ), .stp(stp[2] ),.i_u(Pa[95:64] ), .i_l(o_r[1]     ), .o_r(o_r[2] ), .o_b(o_b[2] ), .sum(sum[2] ));
    //     SystolicPE sa3 (.clk(clk), .rst_n(rst_n), .clr(clr[3] ), .stp(stp[3] ),.i_u(Pa[127:96]), .i_l(o_r[2]     ), .o_r(o_r[3] ), .o_b(o_b[3] ), .sum(sum[3] ));

    //     SystolicPE sa4 (.clk(clk), .rst_n(rst_n), .clr(clr[4] ), .stp(stp[4] ),.i_u(o_b[0]    ), .i_l(Ker[63:32] ), .o_r(o_r[4] ), .o_b(o_b[4] ), .sum(sum[4] ));
    //     SystolicPE sa5 (.clk(clk), .rst_n(rst_n), .clr(clr[5] ), .stp(stp[5] ),.i_u(o_b[1]    ), .i_l(o_r[4])     , .o_r(o_r[5] ), .o_b(o_b[5] ), .sum(sum[5] ));
    //     SystolicPE sa6 (.clk(clk), .rst_n(rst_n), .clr(clr[6] ), .stp(stp[6] ),.i_u(o_b[2]    ), .i_l(o_r[5])     , .o_r(o_r[6] ), .o_b(o_b[6] ), .sum(sum[6] ));
    //     SystolicPE sa7 (.clk(clk), .rst_n(rst_n), .clr(clr[7] ), .stp(stp[7] ),.i_u(o_b[3]    ), .i_l(o_r[6])     , .o_r(o_r[7] ), .o_b(o_b[7] ), .sum(sum[7] ));

    //     SystolicPE sa8 (.clk(clk), .rst_n(rst_n), .clr(clr[8] ), .stp(stp[8] ), .i_u(o_b[4]   ), .i_l(Ker[95:64] ), .o_r(o_r[8] ), .o_b(o_b[8] ), .sum(sum[8] ));
    //     SystolicPE sa9 (.clk(clk), .rst_n(rst_n), .clr(clr[9] ), .stp(stp[9] ), .i_u(o_b[5]   ), .i_l(o_r[8]     ), .o_r(o_r[9] ), .o_b(o_b[9] ), .sum(sum[9] ));
    //     SystolicPE sa10(.clk(clk), .rst_n(rst_n), .clr(clr[10]), .stp(stp[10]), .i_u(o_b[6]   ), .i_l(o_r[9]     ), .o_r(o_r[10]), .o_b(o_b[10]), .sum(sum[10]));
    //     SystolicPE sa11(.clk(clk), .rst_n(rst_n), .clr(clr[11]), .stp(stp[11]), .i_u(o_b[7]   ), .i_l(o_r[10]    ), .o_r(o_r[11]), .o_b(o_b[11]), .sum(sum[11]));

    //     SystolicPE sa12(.clk(clk), .rst_n(rst_n), .clr(clr[12]), .stp(stp[12]), .i_u(o_b[8]   ), .i_l(Ker[127:96]), .o_r(o_r[12]), .o_b(o_b[12]), .sum(sum[12]));
    //     SystolicPE sa13(.clk(clk), .rst_n(rst_n), .clr(clr[13]), .stp(stp[13]), .i_u(o_b[9]   ), .i_l(o_r[12]    ), .o_r(o_r[13]), .o_b(o_b[13]), .sum(sum[13]));
    //     SystolicPE sa14(.clk(clk), .rst_n(rst_n), .clr(clr[14]), .stp(stp[14]), .i_u(o_b[10]  ), .i_l(o_r[13]    ), .o_r(o_r[14]), .o_b(o_b[14]), .sum(sum[14]));
    //     SystolicPE sa15(.clk(clk), .rst_n(rst_n), .clr(clr[15]), .stp(stp[15]), .i_u(o_b[11]  ), .i_l(o_r[14]    ), .o_r(o_r[15]), .o_b(o_b[15]), .sum(sum[15]));
// endmodule

// module SystolicPE (
    //     input clk,
    //     input rst_n,
    //     input clr,
    //     input stp,   //stop
    //     input [31:0] i_u,
    //     input [31:0] i_l,
    //     output reg [31:0] o_r,
    //     output reg [31:0] o_b,
    //     output reg [31:0] sum
    // );

    // parameter inst_sig_width = 23;
    // parameter inst_exp_width = 8;
    // parameter inst_ieee_compliance = 0;
    // parameter inst_arch_type = 0;
    // parameter inst_arch = 0;
    // parameter inst_faithful_round = 0;

    // wire [31:0] n_sum;
    // fp_mult_add fp_mult_add( .inst_a(i_l), .inst_b(i_u), .inst_c(sum), .inst_rnd(3'd0), .z_inst(n_sum)); //ab+c

    // always @( posedge clk or negedge rst_n) begin
    //     if (! rst_n) begin
    //         o_r  <= 'd0;
    //         o_b <= 'd0;
    //         sum        <= 'd0;
    //     end
    //     else if (clr) begin
    //         o_r  <= 'd0;
    //         o_b <= 'd0;
    //         sum        <= 'd0;
    //     end
    //     else if (stp) begin
    //         o_r  <= o_r  ;
    //         o_b <= o_b ;
    //         sum        <= sum        ;
    //     end
    //     else begin
    //         o_r  <= i_l  ;
    //         o_b <= i_u ;
    //         sum        <= n_sum ;
    //     end
    // end


// endmodule





// evince /usr/cad/synopsys/synthesis/cur/dw/doc/manuals/dwbb_userguide.pdf &