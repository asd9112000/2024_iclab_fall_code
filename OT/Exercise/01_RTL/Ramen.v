module Ramen(
    // Input Registers
    input clk,
    input rst_n,
    input in_valid,
    input selling,
    input portion,
    input [1:0] ramen_type,

    // Output Signals
    output reg out_valid_order,
    output reg success,

    output reg out_valid_tot,
    output reg [27:0] sold_num,
    output reg [14:0] total_gain
);


//==============================================//
//             Parameter and Integer            //
//==============================================//

// ramen_type
parameter TONKOTSU = 0;
parameter TONKOTSU_SOY = 1;
parameter MISO = 2;
parameter MISO_SOY = 3;

// initial ingredient
parameter NOODLE_INIT = 12000;
parameter BROTH_INIT = 41000;
parameter TONKOTSU_SOUP_INIT =  9000;
parameter MISO_INIT = 1000;
parameter SOY_SAUSE_INIT = 1500;


//==============================================//
//                 reg declaration              //
//==============================================//

reg  [6:0] sold_num_TONKOTSU, sold_num_TONKOTSU_SOY, sold_num_MISO, sold_num_MISO_SOY;

reg n_success;

reg selling_delay;
reg  [13:0] noodle, sub_noodle;
reg  [15:0] broth , sub_broth;
reg  [13:0] tonkotsu_soup, sub_tonkotsu_soup;
reg  [9 :0] miso, sub_miso;
reg  [10:0] soy_sause, sub_soy_sause;

reg  portion_reg;
reg  [1:0] ramen_type_reg;

reg  [3:0] cnt16;

reg [2:0] cs ,ns;

reg  selling_end;





//==============================================//
//                    input reg                 //
//==============================================//
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) ramen_type_reg <= 'd0;
    else if (in_valid & cnt16 == 'd0) ramen_type_reg <= ramen_type;
end
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) portion_reg <= 'd0;
    else if (in_valid & cnt16 == 'd1) portion_reg <= portion;
end



//==============================================//
//                    Design                    //
//==============================================//

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) selling_delay <= 'd0;
    else selling_delay <= selling;
end

always @( posedge clk or negedge rst_n) begin
    if (!rst_n) cnt16 <= 'd0;
    // else if (selling_delay == 'd0 & selling == 'd1) cnt16 <= 'd0;
    else if ( (cnt16 == 'd3 & selling ) | (cnt16 == 'd4 & !selling )) cnt16 <= 'd0;
    else if ( in_valid | cnt16 != 'd0) cnt16 <= cnt16 + 'd1;

end

//out_valid_order,
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid_order <= 'd0;
    end
    else if (out_valid_order) out_valid_order <= 'd0;
    else if (cnt16 == 'd2)    out_valid_order <= 'd1;
end

// sucess & n_sucess
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        success <= 'd0;
    end
    else if (success) success <= 'd0;
    else if (cnt16 == 'd2) success <= n_success;
end
always @(*) begin
    n_success = (sub_noodle <= noodle) & (sub_broth <= broth) & (sub_tonkotsu_soup <= tonkotsu_soup) & (sub_soy_sause <= soy_sause) & (sub_miso <= miso);
end


//noodle broth tonkotsu_soup miso soy_sause
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        noodle          <= NOODLE_INIT;
        broth           <= BROTH_INIT;
        tonkotsu_soup   <= TONKOTSU_SOUP_INIT;
        miso            <= MISO_INIT;
        soy_sause       <= SOY_SAUSE_INIT;
    end
    else if (selling_delay == 'd0 & selling == 'd1) begin
        noodle          <= NOODLE_INIT;
        broth           <= BROTH_INIT;
        tonkotsu_soup   <= TONKOTSU_SOUP_INIT;
        miso            <= MISO_INIT;
        soy_sause       <= SOY_SAUSE_INIT;
    end
    else if ( cnt16 == 'd2)begin
        noodle          <= n_success ? sub_noodle        : noodle          ;
        broth           <= n_success ? sub_broth         : broth           ;
        tonkotsu_soup   <= n_success ? sub_tonkotsu_soup : tonkotsu_soup   ;
        soy_sause       <= n_success ? sub_soy_sause     : soy_sause       ;
        miso            <= n_success ? sub_miso          : miso            ;
    end
end

//n_noodle, n_broth, n_tonkotsu_soup, n_miso, n_soy_sause
always @(*) begin
    //{small/big(0/1),....}
    // ramen_type
    // parameter TONKOTSU = 0;
    // parameter TONKOTSU_SOY = 1;
    // parameter MISO = 2;
    // parameter MISO_SOY = 3;
    case ({portion_reg,ramen_type_reg})
        3'b000: begin  // small, TONKOTSU}
            sub_noodle        = noodle           - 'd100;
            sub_broth         = broth            - 'd300;
            sub_tonkotsu_soup = tonkotsu_soup    - 'd150;
            sub_soy_sause     = soy_sause               ;
            sub_miso          = miso                    ;
        end
        3'b001: begin  // small, TONKOTSU_SOY}
            sub_noodle        = noodle           - 'd100;
            sub_broth         = broth            - 'd300;
            sub_tonkotsu_soup = tonkotsu_soup    - 'd100;
            sub_soy_sause     = soy_sause        - 'd30 ;
            sub_miso          = miso ;
        end
        3'b010: begin  // small, MISO}
            sub_noodle        = noodle           - 'd100;
            sub_broth         = broth            - 'd400;
            sub_tonkotsu_soup = tonkotsu_soup           ;
            sub_soy_sause     = soy_sause               ;
            sub_miso          = miso             - 'd30 ;
        end
        3'b011: begin  // small, MISO_SOY}
            sub_noodle        = noodle           - 'd100;
            sub_broth         = broth            - 'd300;
            sub_tonkotsu_soup = tonkotsu_soup    - 'd70 ;
            sub_soy_sause     = soy_sause        - 'd15 ;
            sub_miso          = miso             - 'd15 ;
        end

        3'b100: begin  // big, TONKOTSU}
            sub_noodle        = noodle           - 'd150;
            sub_broth         = broth            - 'd500;
            sub_tonkotsu_soup = tonkotsu_soup    - 'd200;
            sub_soy_sause     = soy_sause               ;
            sub_miso          = miso                    ;
        end
        3'b101: begin  // big, TONKOTSU_SOY}
            sub_noodle        = noodle           - 'd150;
            sub_broth         = broth            - 'd500;
            sub_tonkotsu_soup = tonkotsu_soup    - 'd150;
            sub_soy_sause     = soy_sause        - 'd50 ;
            sub_miso          = miso                    ;
        end
        3'b110: begin  // big, MISO}
            sub_noodle        = noodle           - 'd150;
            sub_broth         = broth            - 'd650;
            sub_tonkotsu_soup = tonkotsu_soup           ;
            sub_soy_sause     = soy_sause               ;
            sub_miso          = miso             - 'd50 ;
        end
        3'b111: begin  // big, MISO_SOY}
            sub_noodle        = noodle           - 'd150;
            sub_broth         = broth            - 'd500;
            sub_tonkotsu_soup = tonkotsu_soup    - 'd100;
            sub_soy_sause     = soy_sause        - 'd25 ;
            sub_miso          = miso             - 'd25 ;
        end
        default: ;
    endcase
end


//sold_num_TONKOTSU, sold_num_TONKOTSU_SOY, sold_num_MISO, sold_num_MISO_SOY;
// reg  [6:0] sold_num_TONKOTSU, sold_num_TONKOTSU_SOY, sold_num_MISO, sold_num_MISO_SOY;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sold_num_TONKOTSU       <= 'd0;
        sold_num_TONKOTSU_SOY   <= 'd0;
        sold_num_MISO           <= 'd0;
        sold_num_MISO_SOY       <= 'd0;
    end
    else if (cnt16 == 'd4) begin
        sold_num_TONKOTSU       <= 'd0;
        sold_num_TONKOTSU_SOY   <= 'd0;
        sold_num_MISO           <= 'd0;
        sold_num_MISO_SOY       <= 'd0;
    end
    else if ( cnt16 == 'd2) begin
        case (ramen_type_reg)
            TONKOTSU:       sold_num_TONKOTSU       <= sold_num_TONKOTSU     + {6'd0, n_success};
            TONKOTSU_SOY:   sold_num_TONKOTSU_SOY   <= sold_num_TONKOTSU_SOY + {6'd0, n_success};
            MISO:           sold_num_MISO           <= sold_num_MISO         + {6'd0, n_success};
            MISO_SOY:       sold_num_MISO_SOY       <= sold_num_MISO_SOY     + {6'd0, n_success};
            default: ;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid_tot <= 'd0;
    end
    else if (out_valid_tot) out_valid_tot <= 'd0;
    else if (cnt16 == 'd3& !selling )  out_valid_tot <= 'd1;
end

//sold_num
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sold_num <= 'd0;
    end
    else if (cnt16 == 'd3 & !selling) sold_num <= {sold_num_TONKOTSU, sold_num_TONKOTSU_SOY, sold_num_MISO, sold_num_MISO_SOY};
    else sold_num<= 'd0;
end

//total_gain
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        total_gain <= 'd0;
    end
    else if (cnt16 == 'd3 & !selling) total_gain <= sold_num_TONKOTSU * 'd200 + sold_num_TONKOTSU_SOY * 'd250
                                        +sold_num_MISO     * 'd200 + sold_num_MISO_SOY * 'd250;
    else total_gain<= 'd0;
end

// For debugging
reg [9:0]sell_cnt ;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) sell_cnt <= 'd0;
    else if (cnt16 == 'd4) sell_cnt <= sell_cnt + 'd1;
end
reg [9:0]ord_cnt ;
always @( posedge clk or negedge rst_n) begin
    if (!rst_n) ord_cnt <= 'd0;
    else if (cnt16 == 'd2) ord_cnt <= ord_cnt + 'd1;
end








endmodule

