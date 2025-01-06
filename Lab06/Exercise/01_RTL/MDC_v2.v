//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/9
//		Version		: v1.0
//   	File Name   : MDC.v
//   	Module Name : MDC
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "HAMMING_IP.v"
//synopsys translate_on

module MDC(
    // Input signals
    clk,
	rst_n,
	in_valid,
    in_data,
	in_mode,
    // Output signals
    out_valid,
	out_data
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [8:0] in_mode;
input [14:0] in_data;

output reg out_valid;
output reg [206:0] out_data;



// ===============================================================
// Input & Output Declaration
// ===============================================================
parameter   IN_2CLK = 0,
            DET2    = 1,
            DET3    = 2,
            DET4    = 3;



// ===============================================================
// Input & Output Declaration
// ===============================================================
genvar a,b,c,d,e;
integer i,j,k,l,m,n;


reg  n_out_valid;
reg  [206:0] n_out_data;

reg  [1:0] cs, ns;
reg  det2_end, det3_end, det4_end,end_signal, end_signal_delay;



reg  [4:0]  cnt64;
reg  [8:0]  in_mode_reg;
reg  [14:0] in_data_reg;
wire [4:0]  deHAM_mode;
wire [10:0] CR_code;
reg signed [10:0] CR_code_reg [0:15];

reg  [206:0] out_data_bkg_reg;
// [206:0] out_data_bkg_reg = out_data_bkg_reg [0] [1] [2]....[8]
// [206:184] [183:161] [160:138] [137:115] [114:92] [91:69] [68:46] [45:23] [22:0]
// out_data_bkg_reg will also used to stored 2x2 det
reg  [206:0] det_out;



// ===============================================================
// DET3 Declaration
// ===============================================================
reg ctl;
reg add_ctl;
reg [10:0] A11;
reg [22:0] B22;
reg [10:0] C11;
reg [22:0] D22;
reg [35:0] B22_Temp_reg;
wire [35:0] sum;



// ===============================================================
// DET4 Declaration
// ===============================================================
wire signed [48:0] rod_down_ab_add_c;
reg  signed [10:0] rod_down_a ;
reg  signed [35:0] rod_down_b ;
reg  signed [48:0] rod_down_c ;
wire signed [48:0] rod_down_ab;
wire  ctl_ab_add_c;
assign  rod_down_ab = rod_down_a * rod_down_b;
// assign  rod_down_ab_add_c = rod_down_a * rod_down_b +rod_down_c;

assign ctl_ab_add_c = cnt64 == 'd13 | cnt64 =='d17;

add_sub_49 add_sub_49 (
    .in1(rod_down_c), .in2(rod_down_ab), .ctl(ctl_ab_add_c), .sum(rod_down_ab_add_c)
);

// ===============================================================
// CS, NS
// ===============================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= IN_2CLK;
    else
        cs <= ns;
end

always @(*) begin
    case (cs)
        IN_2CLK:if ( !in_valid) ns = IN_2CLK;
                else
                begin
                    case (deHAM_mode)
                        'b00100: ns = DET2;
                        'b00110: ns = DET3;
                        'b10110: ns = DET4;
                        default: ns = IN_2CLK;
                    endcase
                end
        DET2   : ns = ( det2_end )? IN_2CLK : DET2 ;
        DET3   : ns = ( det3_end )? IN_2CLK : DET3 ;
        DET4   : ns = ( det4_end )? IN_2CLK : DET4 ;
    endcase
end

HAMMING_IP  #( .IP_BIT(5)) in_mode_HAMMING(
    .IN_code(in_mode),
    .OUT_code(deHAM_mode)
);

// ===============================================================
// End Signal
// ===============================================================
always @(*) begin
    // det2_end = (cs == DET2) & cnt64 == 'd18 ;
    det2_end = (cs == DET2) & cnt64 == 'd16 ;
    det3_end = (cs == DET3) & cnt64 == 'd17 ;
    det4_end = (cs == DET4) & cnt64 == 'd19 ;  //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    end_signal = det2_end | det3_end | det4_end;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        end_signal_delay <= 'd0;
    else
        end_signal_delay <= end_signal;
end



// ===============================================================
// Input Read
// ===============================================================
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for (i=0;i<=15;i=i+1)
            CR_code_reg[i] <= 'd0;
    else if (  (cs == DET4) & in_valid)
        // if (in_valid)
        begin
            CR_code_reg[7] <= CR_code;
            for ( j=0 ; j<7 ; j=j+1)
                CR_code_reg [j] <=  CR_code_reg [j+1];
        end
    else if ((in_valid | ( cnt64 == 'd16 | cnt64 =='d17 )) & cs != DET4 ) begin
        CR_code_reg[7] <= CR_code;
        for ( j=0 ; j<7 ; j=j+1)
            CR_code_reg [j] <=  CR_code_reg [j+1];
    end
    // else if ( cs == DET3 & ( cnt64 == 'd16 | cnt64 =='d17 | cnt64 == 'd18))
    //     CR_code_reg[7] <= CR_code;
    //     for ( j=0 ; j<7 ; j=j+1)
    //         CR_code_reg [j] <=  CR_code_reg [j+1];
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt64 <= 'd0;
    else if ( det2_end | det3_end |det4_end)
        cnt64 <= 'd0;
    else if (in_valid | cnt64 != 'd0 )
        cnt64 <= cnt64 + 'd1;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        in_mode_reg <= 'd0;
    else if (in_valid & cnt64 == 'd0)
        in_mode_reg <= in_mode;
end


always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        in_data_reg <= 'd0;
    else if (in_valid )
        in_data_reg <= in_data;
end

// HAMMING_IP  #(parameter IP_BIT = 11) HAMMING_IP(
//     .IN_code(in_data_reg),
//     .CR_code(CR_code)
// );

HAMMING_IP  #( .IP_BIT(11)) HAMMING_IP(
    .IN_code (in_data),
    .OUT_code(CR_code)
);



wire [22:0] det2x2_c_outA, det2x2_c_outB, det2x2_c_outC, det2x2_c_outA_plus;
det2x2_A det2x2_c_A (.in_A(CR_code_reg[0]),.in_B(CR_code_reg[1]),.in_C(CR_code_reg[4]),.in_D(CR_code_reg[5]),.DetOut2x2(det2x2_c_outA) );
det2x2_A det2x2_c_B (.in_A(CR_code_reg[0]),.in_B(CR_code_reg[2]),.in_C(CR_code_reg[4]),.in_D(CR_code_reg[6]),.DetOut2x2(det2x2_c_outB) );
det2x2_A det2x2_c_C (.in_A(CR_code_reg[0]),.in_B(CR_code_reg[3]),.in_C(CR_code_reg[4]),.in_D(CR_code_reg[7]),.DetOut2x2(det2x2_c_outC) );
det2x2_A det2x2_c_A_plus (.in_A(CR_code_reg[2]),.in_B(CR_code_reg[3]),.in_C(CR_code_reg[6]),.in_D(CR_code_reg[7]),.DetOut2x2(det2x2_c_outA_plus) );


// ===============================================================
// DET2 & out_data_bkg_reg
// ===============================================================


// [206:0] out_data_bkg_reg = out_data_bkg_reg [0] [1] [2]....[8]
// [206:184] [183:161] [160:138] [137:115] [114:92] [91:69] [68:46] [45:23] [22:0]
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_data_bkg_reg <= 'd0;
    else begin
        case (cs)
            IN_2CLK :;
            DET2    :
                        // if (cnt64 >= 'd8 & cnt64 <= 'd18 & cnt64 != 'd11 & cnt64 != 'd15) begin
                        //     out_data_bkg_reg [22:0   ] <= det2x2_c_outA             ;
                        //     out_data_bkg_reg [45:23  ] <= out_data_bkg_reg [22:0   ];
                        //     out_data_bkg_reg [68:46  ] <= out_data_bkg_reg [45:23  ];
                        //     out_data_bkg_reg [91:69  ] <= out_data_bkg_reg [68:46  ];
                        //     out_data_bkg_reg [114:92 ] <= out_data_bkg_reg [91:69  ];
                        //     out_data_bkg_reg [137:115] <= out_data_bkg_reg [114:92 ];
                        //     out_data_bkg_reg [160:138] <= out_data_bkg_reg [137:115];
                        //     out_data_bkg_reg [183:161] <= out_data_bkg_reg [160:138];
                        //     out_data_bkg_reg [206:184] <= out_data_bkg_reg [183:161];
                        // end

                        if (cnt64 >= 'd6 & cnt64 <= 'd116 & cnt64 != 'd9 & cnt64 != 'd13) begin
                            out_data_bkg_reg [22:0   ] <= det2x2_c_outA_plus        ;
                            out_data_bkg_reg [45:23  ] <= out_data_bkg_reg [22:0   ];
                            out_data_bkg_reg [68:46  ] <= out_data_bkg_reg [45:23  ];
                            out_data_bkg_reg [91:69  ] <= out_data_bkg_reg [68:46  ];
                            out_data_bkg_reg [114:92 ] <= out_data_bkg_reg [91:69  ];
                            out_data_bkg_reg [137:115] <= out_data_bkg_reg [114:92 ];
                            out_data_bkg_reg [160:138] <= out_data_bkg_reg [137:115];
                            out_data_bkg_reg [183:161] <= out_data_bkg_reg [160:138];
                            out_data_bkg_reg [206:184] <= out_data_bkg_reg [183:161];
                        end
            DET3    :   begin
                        if (cnt64 >= 'd8 & cnt64 <= 'd14 & cnt64 != 'd11 ) begin  // first data(1256) will only be used at cnt64 = 11, and has been removed at cnt64 = 15
                            out_data_bkg_reg [114:92 ] <= det2x2_c_outA             ;
                            out_data_bkg_reg [137:115] <= out_data_bkg_reg [114:92 ];
                            out_data_bkg_reg [160:138] <= out_data_bkg_reg [137:115];
                            out_data_bkg_reg [183:161] <= out_data_bkg_reg [160:138];
                            out_data_bkg_reg [206:184] <= out_data_bkg_reg [183:161];
                        end

                        if (cnt64 >= 'd8 & cnt64 <= 'd13 & cnt64 != 'd10 & cnt64 != 'd11) begin
                            out_data_bkg_reg [22:0   ] <= det2x2_c_outB             ;
                            out_data_bkg_reg [45:23  ] <= out_data_bkg_reg [22:0   ];
                            out_data_bkg_reg [68:46  ] <= out_data_bkg_reg [45:23  ];
                            out_data_bkg_reg [91:69  ] <= out_data_bkg_reg [68:46  ];
                        end
                        end
            DET4    :begin
                        if (cnt64 >= 'd8 & cnt64 <= 'd10) begin  // first data(1256) will only be used at cnt64 = 11, and has been removed at cnt64 = 15
                            out_data_bkg_reg [114:92 ] <= det2x2_c_outA             ;
                            out_data_bkg_reg [137:115] <= out_data_bkg_reg [114:92 ];
                            out_data_bkg_reg [160:138] <= out_data_bkg_reg [137:115];
                        end

                        if (cnt64 >= 'd8 & cnt64 <= 'd13 & cnt64 != 'd10 & cnt64 != 'd11) begin
                            out_data_bkg_reg [22:0   ] <= det2x2_c_outB             ;
                            out_data_bkg_reg [45:23  ] <= out_data_bkg_reg [22:0   ];
                            out_data_bkg_reg [68:46  ] <= out_data_bkg_reg [45:23  ];
                            out_data_bkg_reg [91:69  ] <= out_data_bkg_reg [68:46  ];
                        end

                        if (cnt64 == 'd8)
                            out_data_bkg_reg [183:161] <= det2x2_c_outC;
                    end
            default:;
        endcase
    end
end



//det_out
// [206:0] out_data_bkg_reg = out_data_bkg_reg [0] [1] [2]....[8]
// 23 b each set :[206:184] [183:161] [160:138] [137:115] [114:92] [91:69] [68:46] [45:23] [22:0]
// 51 b each set :[206:204],    [203:153] [152:102] [101:51] [50:0]
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) det_out <= 'd0;
    else if ( end_signal_delay) det_out <= 'd0;
    else begin
        case (cs)
            IN_2CLK :;
            DET2    :
                        // if (cnt64 >= 'd8 & cnt64 <= 'd18 & cnt64 != 'd11 & cnt64 != 'd15) begin
                        //     det_out [22:0   ] <= det2x2_c_outA    ;
                        //     det_out [45:23  ] <= det_out [22:0   ];
                        //     det_out [68:46  ] <= det_out [45:23  ];
                        //     det_out [91:69  ] <= det_out [68:46  ];
                        //     det_out [114:92 ] <= det_out [91:69  ];
                        //     det_out [137:115] <= det_out [114:92 ];
                        //     det_out [160:138] <= det_out [137:115];
                        //     det_out [183:161] <= det_out [160:138];
                        //     det_out [206:184] <= det_out [183:161];
                        // end

                        if (cnt64 >= 'd6 & cnt64 <= 'd116 & cnt64 != 'd9 & cnt64 != 'd13) begin
                            det_out [22:0   ] <= det2x2_c_outA_plus    ;
                            det_out [45:23  ] <= det_out [22:0   ];
                            det_out [68:46  ] <= det_out [45:23  ];
                            det_out [91:69  ] <= det_out [68:46  ];
                            det_out [114:92 ] <= det_out [91:69  ];
                            det_out [137:115] <= det_out [114:92 ];
                            det_out [160:138] <= det_out [137:115];
                            det_out [183:161] <= det_out [160:138];
                            det_out [206:184] <= det_out [183:161];
                        end

            DET3    :   begin
                            if (cnt64 == 'd11 | cnt64 == 'd13 | cnt64 == 'd15 | cnt64 == 'd17) begin
                                det_out [50:0   ] <= {{15{sum[35]}},sum}   ;
                                det_out [101:51 ] <= det_out [50:0   ];
                                det_out [152:102] <= det_out [101:51 ];
                                det_out [203:153] <= det_out [152:102];
                            end
                        end
            DET4    :   begin
                            if ( cnt64 == 'd13 | cnt64 == 'd15 | cnt64 == 'd17 ) begin
                                det_out [48:0   ] <= rod_down_ab_add_c ;
                            end
                            if ( cnt64 == 'd19) begin
                                det_out  <= {{158{rod_down_ab_add_c[48]}},rod_down_ab_add_c} ;
                            end
                        end
            default:;
        endcase
    end
end


// ===============================================================
// DET3 & DET4 for det_ord_down
// ===============================================================
det_ord_down det_ord_down (
    .ctl,  // 0 is +, 1 is -
    .add_ctl,// cnt = 10/11 => A11*B22 + C11*D22 / A11*B22 + B22_Temp_reg
    .A11(A11),
    .B22(B22),
    .C11(C11),
    .D22(D22),
    .Temp(B22_Temp_reg),
    .sum(sum)
);

//ctl add_ctl
always @(*) begin
    // cs == DET3
    // cnt = 10/11 => -/+
    // cnt = 10/11 => A11*B22 + C11*D22 / A11*B22 + B22_Temp_reg
    if (cs == DET3) begin
        ctl = !cnt64[0];
        add_ctl = cnt64[0];
    end
    else begin
        ctl = cnt64[0];
        add_ctl = !cnt64[0];
    end
end

//A11
always @(*) begin
    case (cs)
        DET3:begin
            case (cnt64)
                10: A11 = CR_code_reg[6];
                11: A11 = CR_code_reg[7];

                12: A11 = CR_code_reg[5];
                13: A11 = CR_code_reg[6];

                14: A11 = CR_code_reg[6];
                15: A11 = CR_code_reg[7];

                16: A11 = CR_code_reg[5];
                17: A11 = CR_code_reg[6];
                // default:A11 = CR_code_reg[6];
                default:A11 = 'd0;
            endcase
        end
        DET4: begin
            case (cnt64)
                11: A11 = CR_code_reg[6];
                12: A11 = CR_code_reg[7];

                13: A11 = CR_code_reg[3];
                14: A11 = CR_code_reg[5];

                15: A11 = CR_code_reg[1];
                16: A11 = CR_code_reg[3];

                17: A11 = CR_code_reg[0];
                18: A11 = CR_code_reg[2];
                // default:A11 = CR_code_reg[6];
                default:A11 = 'd0;
            endcase
        end
        default: A11 = 'd0;
    endcase
end

//C11
always @(*) begin
    case (cs)
        DET3:begin
            case (cnt64)
                10: C11 = CR_code_reg[7];
                11: C11 = CR_code_reg[7];

                12: C11 = CR_code_reg[6];
                13: C11 = CR_code_reg[6];

                14: C11 = CR_code_reg[7];
                15: C11 = CR_code_reg[7];

                16: C11 = CR_code_reg[6];
                17: C11 = CR_code_reg[7];
                // default:C11 = CR_code_reg[7];
                default:C11 = 'd0;
            endcase
        end
        DET4: begin
            case (cnt64)
                11: C11 = CR_code_reg[7];
                12: C11 = CR_code_reg[7];

                13: C11 = CR_code_reg[5];
                14: C11 = CR_code_reg[5];

                15: C11 = CR_code_reg[2];
                16: C11 = CR_code_reg[3];

                17: C11 = CR_code_reg[1];
                18: C11 = CR_code_reg[1];
                // default:C11 = CR_code_reg[2];
                default:C11 = 'd0;
            endcase
        end
        default: C11 = 'd0;
    endcase
end

//B22
always @(*) begin
    case (cs)
        DET3:begin
            case (cnt64)
                10: B22 = out_data_bkg_reg [114:92 ];
                11: B22 = out_data_bkg_reg [160:138];//

                12: B22 = out_data_bkg_reg [114:92 ];
                13: B22 = out_data_bkg_reg [160:138];

                14: B22 = out_data_bkg_reg [114:92 ];
                15: B22 = out_data_bkg_reg [160:138];

                16: B22 = out_data_bkg_reg [114:92 ];
                17: B22 = out_data_bkg_reg [137:115];

                // default:B22 = out_data_bkg_reg [114:92 ];
                default:B22 = 'd0;
            endcase
        end
        DET4: begin
            case (cnt64)
                11: B22 = out_data_bkg_reg [114:92 ];
                // 12: B22 = out_data_bkg_reg [160:138];//
                12: B22 = out_data_bkg_reg [137:115];//

                13: B22 = out_data_bkg_reg [114:92 ];
                14: B22 = out_data_bkg_reg [91:69  ];

                15: B22 = out_data_bkg_reg [68:46  ];
                16: B22 = out_data_bkg_reg [160:138];

                17: B22 = out_data_bkg_reg [137:115];
                18: B22 = out_data_bkg_reg [160:138];

                // default:B22 = out_data_bkg_reg [114:92 ];
                default:B22 = 'd0;
            endcase
        end
        default :B22 = 'd0;
    endcase
end

//D22
always @(*) begin
    case (cs)
        DET3:begin
            case (cnt64)
                10: D22 = out_data_bkg_reg [45:23  ];
                11: D22 = out_data_bkg_reg [45:23  ];//

                12: D22 = out_data_bkg_reg [22:0   ];
                13: D22 = out_data_bkg_reg [22:0   ];

                14: D22 = out_data_bkg_reg [45:23  ];
                15: D22 = out_data_bkg_reg [45:23  ];

                16: D22 = out_data_bkg_reg [22:0   ];
                17: D22 = out_data_bkg_reg [22:0   ];
                default:D22 = 'd0;
                // default:D22 = out_data_bkg_reg [22:0   ];
            endcase
        end
        DET4: begin
            case (cnt64)
                11: D22 = out_data_bkg_reg [22:0   ];
                12: D22 = out_data_bkg_reg [22:0   ];

                13: D22 = out_data_bkg_reg [183:161];
                14: D22 = out_data_bkg_reg [183:161];

                15: D22 = out_data_bkg_reg [183:161];
                16: D22 = out_data_bkg_reg [183:161];

                17: D22 = out_data_bkg_reg [91:69  ];
                18: D22 = out_data_bkg_reg [91:69  ];

                // default:B22 = out_data_bkg_reg [45:23  ];
                default:D22 = 'd0;
            endcase
        end
        default: D22 = 'd0;
    endcase
end


//B22_Temp_reg
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) B22_Temp_reg <= 'd0;
    else B22_Temp_reg <= sum;
end

//det4

//rod_down_a
always @(*) begin
    case (cnt64)
        13:rod_down_a =CR_code_reg[7];
        15:rod_down_a =CR_code_reg[6];
        17:rod_down_a =CR_code_reg[6];
        19:rod_down_a =CR_code_reg[7];
        default: rod_down_a = 'd0;
    endcase
end

//rod_down_b
always @(*) begin
        rod_down_b =B22_Temp_reg;
end

//rod_down_c
always @(*) begin
    case (cnt64)
        13:rod_down_c = 'd0;
        15:rod_down_c =det_out[48:0];
        17:rod_down_c =det_out[48:0];  ///  simplify!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        19:rod_down_c =det_out[48:0];
        default: rod_down_c = 'd0;
    endcase
end


// ===============================================================
// Output
// ===============================================================
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_valid <= 'd0;
    else out_valid <= n_out_valid;
end
always @(*) begin
    n_out_valid = end_signal;
end

// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n) out_data <= 'd0;
//     else out_data <= n_out_data;
// end
// always @(*) begin
//     // n_out_data = (n_out_valid) ? out_data_bkg_reg : 'd0; //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//     n_out_data = out_data_bkg_reg & {207{n_out_valid}}; //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// end

always @(*) begin
    out_data = det_out & {207{out_valid}};
end

endmodule




// ================================================================================ //
//  ____    _   _   ____      __  __    ___    ____    _   _   _       _____        //
// / ___|  | | | | | __ )    |  \/  |  / _ \  |  _ \  | | | | | |     | ____|       //
// \___ \  | | | | |  _ \    | |\/| | | | | | | | | | | | | | | |     |  _|         //
//  ___) | | |_| | | |_) |   | |  | | | |_| | | |_| | | |_| | | |___  | |___        //
// |____/   \___/  |____/    |_|  |_|  \___/  |____/   \___/  |_____| |_____|       //
//                                                                                  //
// ================================================================================ //



module add_sub_36 (
    in1,in2,ctl,sum
);
parameter wordlength = 36;
input [wordlength-1:0] in1,in2;
input ctl;
output [wordlength-1:0] sum;
reg [wordlength-1:0] sum;
always @(in1 or in2 or ctl)begin
    if (ctl == 0)
        sum = in1 + in2;
    else
        sum = in1 - in2;
end
endmodule

module add_sub_49 (
    in1,in2,ctl,sum
);
parameter wordlength = 49;
input [wordlength-1:0] in1,in2;
input ctl;
output [wordlength-1:0] sum;
reg [wordlength-1:0] sum;
always @(in1 or in2 or ctl)begin
    if (ctl == 0)
        sum = in1 + in2;
    else
        sum = in1 - in2;
end
endmodule

module det2x2_A (
    input signed [10:0] in_A,
    input signed [10:0] in_B,
    input signed [10:0] in_C,
    input signed [10:0] in_D,
    output signed [22:0] DetOut2x2
);
    // | a b |
    // | c d |
    // wire signed  [10:0] A, B, C, D ;
    // wire signed  [22:0] DetOut2x2 ;
    // 11+11+1=23 [22:0]
    wire signed [22:0] A,B;
    assign A = in_A*in_D;
    assign B = in_B*in_C;
    assign DetOut2x2 = in_A*in_D-in_B*in_C;

endmodule

// 11+11+11+1=34
// 11+11+11+11+1=45
module det_ord_down (
    input  signed ctl,  // 0 is +, 1 is -
    input  signed add_ctl,
    input  signed [10:0] A11,
    input  signed [22:0] B22,
    input  signed [10:0] C11,
    input  signed [22:0] D22,
    input  signed [35:0] Temp,
    output signed [35:0] sum
);
    //add_ctl = 0, A11*B22 + C11*D22
    //add_ctl = 1, A11*B22 + Temp
    // wire signed  [10:0] A11, C11 ;
    // wire signed  [21:0] C22, D22 ;
    // wire signed  [35:0] DetOut2x2 ;

    // wire []
    wire signed [35:0] in1, in2;
    wire signed [35:0] C11D22;
    assign C11D22 = C11*D22;
    // assign in1_ = A11*B22
    assign in1 = A11*B22;
    assign in2 = (add_ctl) ? Temp : C11D22 ;
    add_sub_36 add_sub_36(.in1(in1), .in2(in2), .ctl(ctl), .sum(sum));

endmodule







