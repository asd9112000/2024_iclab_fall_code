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

reg  [1:0] cd, ns;
reg  det2_end, det3_end, det4_end;



reg  [4:0]  cnt64;
reg  [8:0]  in_mode_reg;
reg  [14:0] in_data_reg;
wire [4:0]  deHAM_mode;
wire [10:0] out_code;
reg signed [11:0] out_code_reg [0:15];



// ===============================================================
// CS, NS
// ===============================================================
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cs <= 'd0;
    else if (in_valid)
        cs <= ns;
end

always @( *) begin
    case (cs)
        IN_2CLK:if (cnt64 == 'd0) ns = IN_2CLK;
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

HAMMING_IP  #(parameter IP_BIT = 5) in_mode_HAMMING(
    .IN_code(in_mode_reg),
    .OUT_code(deHAM_mode)
);

in_mode
// ===============================================================
// Input Read
// ===============================================================
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        for (i=0;i<=15;i=i+1)
            out_code_reg[i] <= 'd0;
    else if (in_valid)
        out_code_reg[cnt64] <= out_code;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt64 <= 'd0;
    else if ( det2_end | det3_end |det4_end)
        cnt64 <= 'd0;
    else if (in_valid)
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

HAMMING_IP  #(parameter IP_BIT = 11) HAMMING_IP(
    .IN_code(in_data_reg),
    .OUT_code(out_code)
);














// ===============================================================
// Output
// ===============================================================
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_valid <= 'd0;
    else out_valid <= n_out_valid;
end
always @(*) begin
    n_out_valid = 'd0;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_data <= 'd0;
    else out_data <= n_out_data;
end
always @(*) begin
    n_out_data = (n_out_valid) ? 'd1 : 'd0; //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
end



endmodule


// module det2x2 (
//     input clk,
//     input rst_n,
//     input det2x2_st,
//     input [10:0] A,
//     input [10:0] B,
//     input [10:0] C,
//     input [10:0] D,
//     output[22:0] DetOut2x2
// );
// // | a b |
// // | c d |

// reg  det2x2_st_falg;
// reg  [3:0] det_cnt16;
// reg  [21:0] ad, bc;
// reg  [9:0] B_reg;

// wire det2x2_end;
// assign det2_end = det_cnt16 == 'd13 ; //!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// reg  [10:0] addin [3:0];


// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         B_reg <= 'd0;
//     else if ( st )
//         B_reg[9:0] <= B[10:1];
//     else
//         B_reg[9:0] <= B_reg <<1 ;
// end


// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n) det2x2_st_falg <= 'd0;
//     else if ( st ) det2x2_st_falg <= 'd1;
//     // else if ( det2x2_st_falg & det2x2_end) det2x2_st_falg <= 'd0;
//     else if ( det2x2_end) det2x2_st_falg <= 'd0;
// end

// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         det_cnt16 <= 'd0;
//     else if (st | det2x2_st_falg )
//         det_cnt16 <= det_cnt16 + 'd1;
//     else
//         det_cnt16 <= 'd0;
// end


// always @( *) begin
//     case (det_cnt16)
//         0: begin addin[0] = 'd0 ; addin [1] = (B[0]) ? A : 'd0; end
//         1: begin addin[0] = 'd0 ; addin [1] = (B[0]) ? A : 'd0; end
//         default:
//     endcase
// end



// reg  [21:0] ad, bc;
// always @( posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         ad <= 'd0;
//     else if (st | det2x2_st_falg )
//         case (det_cnt16)
//             0: ad []
//             default:
//         endcase
//         ad[12] <= ad[11] +addin
//     // else if (det_cnt16 == 'd0)
//     //     ad[12] <= 'd0;
// end




// endmodule