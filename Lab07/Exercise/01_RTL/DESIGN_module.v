module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
input clk;
input rst_n;
input in_valid;
input [17:0] in_row;
input [11:0] in_kernel;
input out_idle;
output reg handshake_sready;
output reg [29:0] handshake_din;
// You can use the the custom flag ports for your design
input  flag_handshake_to_clk1;
output flag_clk1_to_handshake;

input fifo_empty;
input [7:0] fifo_rdata;
output fifo_rinc;
output reg out_valid;
output reg [7:0] out_data;
// You can use the the custom flag ports for your design
output flag_clk1_to_fifo;
input flag_fifo_to_clk1;




// =========================
//
//       DESIGN DECALRE
//
// =========================
integer i, j, k, l, m, n;
genvar  a, b, c;
reg [2:0] cs ,ns;

reg [2:0] cnt8_input;
reg  [2:0] cnt_sready;

// =========================
//
//       End Signal
//
// =========================
reg  pat_end;
reg  set_end;
wire w_pat_end;

reg  n_out_valid;
reg  [7:0] n_out_data ;
// =========================
//
//         cs & ns
//
// =========================
parameter IDLE = 3'b000;
parameter READ = 3'b001;
parameter WAIT_OUT  = 3'b010;
parameter S_3  = 3'b011;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cs <= IDLE;
    else        cs <= ns;
end

always @(*) begin
    case (cs)
        IDLE: begin
            if (in_valid) ns = READ;
            else          ns = IDLE;
        end
        READ: begin
            ns = (cnt8_input == 'd5) ?  WAIT_OUT: READ;
        end
        WAIT_OUT: begin
            ns = (pat_end | set_end) ?  IDLE: WAIT_OUT;
        end
        default: ns = IDLE;
    endcase
end


reg  [7:0]cnt256_out;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cnt256_out <= 'd0;
    else if ( set_end | pat_end ) cnt256_out <= 'd0;
    else if ( out_valid ) cnt256_out <= cnt256_out + 'd1;
end
reg [7:0] out_data_test;
reg out_valid_test;
reg  [7:0]cnt256_out_test;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cnt256_out_test <= 'd0;
    else if ( set_end | pat_end ) cnt256_out_test <= 'd0;
    else if ( out_valid_test ) cnt256_out_test <= cnt256_out_test + 'd1;
end

always @(*) begin
    pat_end = cnt256_out == 'd149 & out_valid; //!!!!!
    set_end = cnt256_out == 'd149 & out_valid; //!!!!!
end
assign w_pat_end = 'b0;

// =========================
//
//         READ_INPUT
//
// =========================
reg [2:0] in_kernel_reg [5:0] [3:0];
reg [2:0] in_row_reg [5:0] [5:0]; // y, x
reg  out_idle_delay;
// in_kernel_reg shape
// 3 2
// 1 0


// in_row shape []
// in_row_reg shape
//   x =    5 4 3 2 1 0
//   y = 0
//   y = 1
//   y = 2
//   y = 3
//   y = 4
//   y = 5

always @(  posedge clk or negedge rst_n) begin
    if (!rst_n) cnt8_input <= 'd0;
    else if ( set_end | pat_end ) cnt8_input <= 'd0;
    else if ( in_valid ) cnt8_input <= cnt8_input + 'd1;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i < 6; i = i + 1) begin
            for ( j = 0; j < 4; j = j + 1) begin
                in_kernel_reg[i][j] <= 'd0;
            end
        end
    end
    else begin
        if (in_valid) begin
            in_kernel_reg[cnt8_input][0] <= in_kernel[2:0];
            in_kernel_reg[cnt8_input][1] <= in_kernel[5:3];
            in_kernel_reg[cnt8_input][2] <= in_kernel[8:6];
            in_kernel_reg[cnt8_input][3] <= in_kernel[11:9];
        end
    end
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i < 6; i = i + 1)
            for ( j = 0; j < 6; j = j + 1)
                in_row_reg[i][j] <= 'd0;
    end
    else begin
        if (in_valid) begin
            case (cnt8_input)
                0: begin
                    in_row_reg[0][0] <= in_row[2:0];
                    in_row_reg[0][1] <= in_row[5:3];
                    in_row_reg[0][2] <= in_row[8:6];
                    in_row_reg[0][3] <= in_row[11:9];
                    in_row_reg[0][4] <= in_row[14:12];
                    in_row_reg[0][5] <= in_row[17:15];
                end
                1:begin
                    in_row_reg[1][0] <= in_row[2:0];
                    in_row_reg[1][1] <= in_row[5:3];
                    in_row_reg[1][2] <= in_row[8:6];
                    in_row_reg[1][3] <= in_row[11:9];
                    in_row_reg[1][4] <= in_row[14:12];
                    in_row_reg[1][5] <= in_row[17:15];
                end
                2:begin
                    in_row_reg[2][0] <= in_row[2:0];
                    in_row_reg[2][1] <= in_row[5:3];
                    in_row_reg[2][2] <= in_row[8:6];
                    in_row_reg[2][3] <= in_row[11:9];
                    in_row_reg[2][4] <= in_row[14:12];
                    in_row_reg[2][5] <= in_row[17:15];
                end
                3:begin
                    in_row_reg[3][0] <= in_row[2:0];
                    in_row_reg[3][1] <= in_row[5:3];
                    in_row_reg[3][2] <= in_row[8:6];
                    in_row_reg[3][3] <= in_row[11:9];
                    in_row_reg[3][4] <= in_row[14:12];
                    in_row_reg[3][5] <= in_row[17:15];
                end
                4:begin
                    in_row_reg[4][0] <= in_row[2:0];
                    in_row_reg[4][1] <= in_row[5:3];
                    in_row_reg[4][2] <= in_row[8:6];
                    in_row_reg[4][3] <= in_row[11:9];
                    in_row_reg[4][4] <= in_row[14:12];
                    in_row_reg[4][5] <= in_row[17:15];
                end
                5:begin
                    in_row_reg[5][0] <= in_row[2:0];
                    in_row_reg[5][1] <= in_row[5:3];
                    in_row_reg[5][2] <= in_row[8:6];
                    in_row_reg[5][3] <= in_row[11:9];
                    in_row_reg[5][4] <= in_row[14:12];
                    in_row_reg[5][5] <= in_row[17:15];
                end
                default: ;
            endcase
            // in_row_reg[cnt8_input][0] <= in_row[2:0];
            // in_row_reg[cnt8_input][1] <= in_row[5:3];
            // in_row_reg[cnt8_input][2] <= in_row[8:6];
            // in_row_reg[cnt8_input][3] <= in_row[11:9];
            // in_row_reg[cnt8_input][4] <= in_row[14:12];
            // in_row_reg[cnt8_input][5] <= in_row[17:15];
        end
    end
end



always @( posedge clk or negedge rst_n) begin
    if (!rst_n) handshake_sready <= 'd0;
    else if (( !handshake_sready && cnt_sready == 'd6) ||  set_end || pat_end) handshake_sready <= 'd0;
    else if ( cs == WAIT_OUT ) handshake_sready <= out_idle;
    else handshake_sready <= 'd0;
end

// handshake_din <= {in_kernel, in_row}, total six times
always @( posedge clk or negedge rst_n) begin
    if (!rst_n)  handshake_din <= 'd0;
    else if (cs == WAIT_OUT &&  out_idle) begin
        case (cnt_sready)
            0: handshake_din <={in_kernel_reg[0][3], in_kernel_reg[0][2],
                                in_kernel_reg[0][1], in_kernel_reg[0][0],
                                in_row_reg   [0][5], in_row_reg   [0][4],
                                in_row_reg   [0][3], in_row_reg   [0][2],
                                in_row_reg   [0][1], in_row_reg   [0][0]};
            1: handshake_din <={in_kernel_reg[1][3], in_kernel_reg[1][2],
                                in_kernel_reg[1][1], in_kernel_reg[1][0],
                                in_row_reg   [1][5], in_row_reg   [1][4],
                                in_row_reg   [1][3], in_row_reg   [1][2],
                                in_row_reg   [1][1], in_row_reg   [1][0]};
            2: handshake_din <={in_kernel_reg[2][3], in_kernel_reg[2][2],
                                in_kernel_reg[2][1], in_kernel_reg[2][0],
                                in_row_reg   [2][5], in_row_reg   [2][4],
                                in_row_reg   [2][3], in_row_reg   [2][2],
                                in_row_reg   [2][1], in_row_reg   [2][0]};
            3: handshake_din <={in_kernel_reg[3][3], in_kernel_reg[3][2],
                                in_kernel_reg[3][1], in_kernel_reg[3][0],
                                in_row_reg   [3][5], in_row_reg   [3][4],
                                in_row_reg   [3][3], in_row_reg   [3][2],
                                in_row_reg   [3][1], in_row_reg   [3][0]};
            4: handshake_din <={in_kernel_reg[4][3], in_kernel_reg[4][2],
                                in_kernel_reg[4][1], in_kernel_reg[4][0],
                                in_row_reg   [4][5], in_row_reg   [4][4],
                                in_row_reg   [4][3], in_row_reg   [4][2],
                                in_row_reg   [4][1], in_row_reg   [4][0]};
            5: handshake_din <={in_kernel_reg[5][3], in_kernel_reg[5][2],
                                in_kernel_reg[5][1], in_kernel_reg[5][0],
                                in_row_reg   [5][5], in_row_reg   [5][4],
                                in_row_reg   [5][3], in_row_reg   [5][2],
                                in_row_reg   [5][1], in_row_reg   [5][0]};
            default: ;
        endcase
    end
end


reg  handshake_sready_delay;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) handshake_sready_delay <= 'd0;
    else handshake_sready_delay <= handshake_sready;
end
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) out_idle_delay <= 'd0;
    else out_idle_delay <= out_idle;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cnt_sready <= 'd0;
    else if ( set_end | pat_end ) cnt_sready <= 'd0;
    else if ( (cs == WAIT_OUT & !handshake_sready_delay & handshake_sready & cnt_sready != 'd6)) cnt_sready <= cnt_sready + 'd1;
end



reg first_fifo_empty, first_fifo_empty_delay, first_fifo_empty_delay2;
reg  fifo_empty_delay, fifo_empty_delay2, fifo_empty_delay3;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) first_fifo_empty <= 'd0;
    else if ( set_end | pat_end ) first_fifo_empty <= 'd0;
    else if ( first_fifo_empty )  first_fifo_empty <= 'd1;
    else if ( !first_fifo_empty ) first_fifo_empty <= !fifo_empty_delay2;
end


assign fifo_rinc = first_fifo_empty & !fifo_empty;



always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fifo_empty_delay <= 'd1;
        fifo_empty_delay2 <= 'd1;
        fifo_empty_delay3 <= 'd1;
        first_fifo_empty_delay <= 'd0;
        first_fifo_empty_delay2 <= 'd0;

    end
    else begin
        fifo_empty_delay <= fifo_empty;
        fifo_empty_delay2 <= fifo_empty_delay;
        fifo_empty_delay3 <= fifo_empty_delay2;
        first_fifo_empty_delay <= first_fifo_empty;
        first_fifo_empty_delay2 <= first_fifo_empty_delay;
    end
end


always @(*) begin
        out_valid = out_valid_test;
        out_data = out_data_test;
end

always @( *) begin
    if ((cs != WAIT_OUT) || fifo_empty_delay2 || !first_fifo_empty ) begin
        out_valid_test = 'd0;
        out_data_test = 'd0;
    end
    else if (first_fifo_empty_delay2)begin
        out_valid_test = 'd1;
        out_data_test = fifo_rdata;
    end
    else begin
        out_valid_test = 'd0;
        out_data_test = 'd0;
    end
end


endmodule
















//////////////////////////////////////////////
//                                          //
//      ██████╗██╗     ██╗  ██╗██████╗      //
//     ██╔════╝██║     ██║ ██╔╝╚════██╗     //
//     ██║     ██║     █████╔╝  █████╔╝     //
//     ██║     ██║     ██╔═██╗ ██╔═══╝      //
//     ╚██████╗███████╗██║  ██╗███████╗     //
//      ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝     //
//                                          //
//////////////////////////////////////////////

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

input clk;
input rst_n;
input in_valid;
input fifo_full;
input [29:0] in_data;
output reg out_valid;
output reg [7:0] out_data;
output reg busy;

// You can use the the custom flag ports for your design
input  flag_handshake_to_clk2;
output flag_clk2_to_handshake;

input  flag_fifo_to_clk2;
output flag_clk2_to_fifo;






// =========================
//
//       DESIGN DECALRE
//
// =========================
integer i, j, k, l, m, n;
genvar  a, b, c;
reg [2:0] cs ,ns;


// =========================
//
//       End Signal
//
// =========================
reg  pat_end;
reg  set_end;
wire w_pat_end;

reg  n_out_valid;
reg  [7:0] n_out_data ;

reg [2:0] cnt8_input;
reg [4:0] cnt32_row;
reg [9:0] cnt1024_row_test;
reg [2:0] cnt8_new_kernal;

// =========================
//
//         cs & ns
//
// =========================
parameter WAIT_INPUT = 3'b000;
parameter CAL = 3'b001;
parameter S_2  = 3'b010;
parameter S_3  = 3'b011;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cs <= WAIT_INPUT;
    else        cs <= ns;
end

always @(*) begin
    case (cs)
        WAIT_INPUT: begin
            if (cnt8_input == 'd5 & in_valid)
                ns = CAL;
            else
                ns = WAIT_INPUT;
        end
        CAL: begin
            ns = (pat_end | set_end ) ? WAIT_INPUT :CAL;
        end
        default: ns = WAIT_INPUT;
    endcase
end


reg  n_pat_end, n_set_end;
always @(*) begin
    n_pat_end = cnt8_new_kernal == 'd5 & cnt32_row == 'd24 & !fifo_full; //!!!!!
    n_set_end = cnt8_new_kernal == 'd5 & cnt32_row == 'd24 & !fifo_full; //!!!!!
end
always @(  posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        set_end <= 'd0;
        pat_end <= 'd0;
    end
    else begin
        set_end <= n_set_end;
        pat_end <= n_pat_end;
    end
end


// =========================
//
//         READ_INPUT
//
// =========================
reg [2:0] in_kernel_reg [5:0] [3:0];
reg [2:0] in_row_reg [5:0] [5:0]; // y, x
reg  [2:0] cnt_sready;
reg  out_idle_delay;
// in_kernel_reg shape
// 3 2
// 1 0

// in_row_reg shape
//   x =    5 4 3 2 1 0
//   y = 0
//   y = 1
//   y = 2
//   y = 3
//   y = 4
//   y = 5


always @(  posedge clk or negedge rst_n) begin
    if (!rst_n) cnt8_input <= 'd0;
    else if ( set_end | pat_end ) cnt8_input <= 'd0;
    else if ( cs == WAIT_INPUT & in_valid ) cnt8_input <= cnt8_input + 'd1;
end


always @(  posedge clk or negedge rst_n) begin
    if (!rst_n) cnt32_row <= 'd0;
    else if ( set_end | pat_end | (cnt32_row == 'd24 & !fifo_full ) ) cnt32_row <= 'd0;
    else if ( cs == CAL & (!fifo_full) ) cnt32_row <= cnt32_row + 'd1;
end
always @(  posedge clk or negedge rst_n) begin
    if (!rst_n) cnt1024_row_test <= 'd0;
    else if ( set_end | pat_end  ) cnt1024_row_test <= 'd0;
    else if ( cs == CAL & (!fifo_full) ) cnt1024_row_test <= cnt1024_row_test + 'd1;
end


always @(posedge clk or negedge rst_n )begin
    if (!rst_n) cnt8_new_kernal <= 'd0;
    else if ( set_end | pat_end ) cnt8_new_kernal <= 'd0;
    else if (cs ==CAL  & !fifo_full & cnt32_row == 'd24) cnt8_new_kernal <= cnt8_new_kernal + 'd1;

end


// 1: handshake_din <={in_kernel_reg[1][3], in_kernel_reg[1][2],
//                     in_kernel_reg[1][1], in_kernel_reg[1][0],
//                     in_row_reg   [1][5], in_row_reg   [1][4],
//                     in_row_reg   [1][3], in_row_reg   [1][2],
//                     in_row_reg   [1][1], in_row_reg   [1][0]};
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i < 6; i = i + 1) begin
            for ( j = 0; j < 4; j = j + 1) begin
                in_kernel_reg[i][j] <= 'd0;
            end
        end
    end
    else if (in_valid & cs == WAIT_INPUT) begin
        in_kernel_reg[cnt8_input][3] <= in_data[20:18];
        in_kernel_reg[cnt8_input][2] <= in_data[23:21];
        in_kernel_reg[cnt8_input][1] <= in_data[26:24];
        in_kernel_reg[cnt8_input][0] <= in_data[29:27];

    end
    else if (cs == CAL & !fifo_full & cnt32_row == 'd24 & !(pat_end | set_end)) begin
        for ( i=0 ; i<=4 ; i = i + 1) begin
            for ( j=0 ; j<=3 ; j = j + 1) begin
                in_kernel_reg[i][j] <= in_kernel_reg[i+1][j];
            end
        end
        for ( i=5 ; i<=5 ; i = i + 1) begin
            for ( j=0 ; j<=3 ; j = j + 1) begin
                in_kernel_reg[i][j] <= 'd0;
            end
        end
    end
end


// in_row_reg, clk2
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for ( i = 0; i < 6; i = i + 1)
            for ( j = 0; j < 6; j = j + 1)
                in_row_reg[i][j] <= 'd0;
    end
    else if ( in_valid & cs == WAIT_INPUT )begin
            in_row_reg[cnt8_input][5] <= in_data[2:0];
            in_row_reg[cnt8_input][4] <= in_data[5:3];
            in_row_reg[cnt8_input][3] <= in_data[8:6];
            in_row_reg[cnt8_input][2] <= in_data[11:9];
            in_row_reg[cnt8_input][1] <= in_data[14:12];
            in_row_reg[cnt8_input][0] <= in_data[17:15];
    end



    else if (cs ==CAL  & !fifo_full & !(pat_end | set_end)) begin
        if (cnt32_row == 'd4 | cnt32_row == 'd9 | cnt32_row == 'd14 | cnt32_row == 'd19) begin // jump
            for ( i = 0 ; i<=5 ; i = i + 1) begin
                if ( i == 5) begin
                    for ( j = 5 ; j>=2 ; j = j - 1) begin
                        in_row_reg[i][j] <= in_row_reg[i][j-2];
                    end
                        in_row_reg[i][1] <= in_row_reg[0][5];
                        in_row_reg[i][0] <= in_row_reg[0][4];
                end
                else begin
                    for ( j = 5 ; j>=2 ; j = j - 1) begin
                        in_row_reg[i][j] <= in_row_reg[i][j-2];
                    end
                        in_row_reg[i][1] <= in_row_reg[i+1][5];
                        in_row_reg[i][0] <= in_row_reg[i+1][4];
                end
            end
        end
        else if ( cnt32_row == 'd24 ) begin // New kernal
            // x= 5,4,3,2
            for ( i = 2 ; i<=5 ; i = i + 1) begin
                for ( j = 0 ; j<=4 ; j = j + 1) begin // y= 0,1,2,3,4
                    in_row_reg[j][i] <= in_row_reg[j+1][i-2];
                end
                    in_row_reg[5][i] <= in_row_reg[0][i-2]; // y= 5
            end
            // x= 1, 0
            for ( i = 0 ; i<=1 ; i = i + 1) begin
                for ( j = 0 ; j<=3 ; j = j + 1) begin // y= 0,1,2,3
                    in_row_reg[j][i] <= in_row_reg[j+2][i+4];
                end
                    in_row_reg[4][i] <= in_row_reg[0][i+4]; // y= 4
                    in_row_reg[5][i] <= in_row_reg[1][i+4]; // y= 5
            end
        end
        else begin
            for ( i = 0 ; i<=5 ; i = i + 1) begin
                if ( i == 5) begin
                    for ( j = 5 ; j>=1 ; j = j - 1) begin
                        in_row_reg[i][j] <= in_row_reg[i][j-1];
                    end
                        in_row_reg[i][0] <= in_row_reg[0][5];
                end
                else begin
                    for ( j = 5 ; j>=1 ; j = j - 1) begin
                        in_row_reg[i][j] <= in_row_reg[i][j-1];
                    end
                        in_row_reg[i][0] <= in_row_reg[i+1][5];
                end
            end
        end
    end
end


wire [7:0] conv_out;
assign conv_out = in_kernel_reg[0][3] * in_row_reg[0][5] + in_kernel_reg[0][2] * in_row_reg[0][4]
                + in_kernel_reg[0][1] * in_row_reg[1][5] + in_kernel_reg[0][0] * in_row_reg[1][4];


wire n_busy;
assign n_busy = 'd0;
always @(*) busy = n_busy;



reg  [8:0] cnt256_out_valid;
always @(*) begin
    if ( cs == CAL & !fifo_full & cnt256_out_valid != 'd150 )
        out_valid = 'd1;
    else
        out_valid = 'd0;
end

always @(*) begin
    out_data = conv_out;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cnt256_out_valid <= 'd0;
    else if ( set_end | pat_end ) cnt256_out_valid <= 'd0;
    else if ( cs ==CAL  & !fifo_full & !(pat_end | set_end)) cnt256_out_valid <= cnt256_out_valid + 'd1;
end
endmodule