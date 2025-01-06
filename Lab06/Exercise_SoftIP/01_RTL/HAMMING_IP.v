//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2024/10
//		Version		: v1.0
//   	File Name   : HAMMING_IP.v
//   	Module Name : HAMMING_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module HAMMING_IP #(parameter IP_BIT = 5
) (
    // Input signals
    IN_code,
    // Output signals
    OUT_code
);

// ===============================================================
// Input & Output
// ===============================================================
input [IP_BIT+4-1:0]  IN_code;

output reg [IP_BIT-1:0] OUT_code;

// ===============================================================
// Design
// ===============================================================

genvar a,b,c,d,e;
integer i,j,k,l,m,n;

// IP_WIDTH, IP_BIT: avalible data width, 5~11
wire [3:0] end_xor_ord [ IP_BIT + 4 - 1 :0];
reg  [IP_BIT+4-1:0] CR_code; // Correcing IN_Code

generate
    for ( a = 0; a < IP_BIT + 4 ; a = a + 1) begin : decoder_xor
        wire [3:0] temp_xor;
        assign temp_xor = ( IN_code [(IP_BIT+4-1) - a]) ? a[3:0]+ 4'd1 : 'd0;
        if ( a == 0 ) begin
            assign end_xor_ord[0] [3:0] = temp_xor;
        end
        else begin
            assign end_xor_ord[a] [3:0] = end_xor_ord[a-1] ^ temp_xor;
            // end_xor_ord[IP_BIT + 4 - 1] range is 0 ~ 15
        end
    end
endgenerate

always @(*) begin
    CR_code = IN_code;
    CR_code [IP_BIT + 4 - end_xor_ord[IP_BIT + 4 - 1] ]=  ! IN_code [IP_BIT + 4 - end_xor_ord[IP_BIT + 4 - 1]];
end

always @(*) begin
    for ( i = IP_BIT -1 ; i>= 0 ; i = i - 1)begin
        if ( i == IP_BIT -1 )
            OUT_code[i] = CR_code [ (i - 2) + 4 ];
        else if (  i <= (IP_BIT -2)  & i >= (IP_BIT -4))
            OUT_code[i] = CR_code [ (i - 3) + 4 ];
        else
            OUT_code[i] = CR_code [ (i - 4) + 4 ];
    end
end


endmodule
