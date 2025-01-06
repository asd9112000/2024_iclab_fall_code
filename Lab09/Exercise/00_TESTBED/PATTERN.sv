`define CYCLE  4.1
`define pat_num     1000000
`define SEED        54564789

// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_LATENCY=1000;
// parameter pat_num=10000;
// parameter `CYCLE = 5;
// integer SEED = 5487;


integer i, j, rand_0to3;

//================================================================
// wire & registers
//================================================================
logic [20:0] latency, total_latency;

logic [7:0] golden_DRAM [((65536+8*256)-1):(65536+0)];
Warn_Msg golden_warn;
logic golden_complete;


logic [1:0]  Act_T;
logic [2:0]  Formula_T;
logic [1:0]  Mode_T;
Month  Month_T;
Day    Day_T;
Data_No  Data_no_T;
Index IorV [0:3];  //0:TA 1:TB 2:TC 3:TD
logic signed [11:0] IorVs [0:3];  //0:TA 1:TB 2:TC 3:TD //signed

logic [19:0] d_Addr;
// logic [7:0] dram_data [0:7];
logic [7:0] d_Day;
logic [7:0] d_Month;
logic [11:0] d_IorV  [0:3]; //0:TA 1:TB 2:TC 3:TD
logic signed [12:0] d_IorVs [0:3]; //0:TA 1:TB 2:TC 3:TD //signed

logic [11:0] golden_Result;
logic [11:0] Threshold_AC, Threshold_BFGH, Threshold_DE;
logic [11:0] Threshold;
logic [11:0] GA;
logic [11:0] GB;
logic [11:0] GC;
logic [11:0] GD;


assign d_Addr = 'h10000 + Data_no_T*8;

assign d_Day =     golden_DRAM[d_Addr];
assign d_IorV[3] = {golden_DRAM[d_Addr+2][3:0],golden_DRAM[d_Addr+1]};  //D
assign d_IorV[2] = {golden_DRAM[d_Addr+3],golden_DRAM[d_Addr+2][7:4]};  //C
assign d_Month   =   golden_DRAM[d_Addr+4];
assign d_IorV[1] = {golden_DRAM[d_Addr+6][3:0],golden_DRAM[d_Addr+5]};  //B
assign d_IorV[0] = {golden_DRAM[d_Addr+7],golden_DRAM[d_Addr+6][7:4]};  //A

assign d_IorVs[0] = {1'b0, d_IorV[0]};
assign d_IorVs[1] = {1'b0, d_IorV[1]};
assign d_IorVs[2] = {1'b0, d_IorV[2]};
assign d_IorVs[3] = {1'b0, d_IorV[3]};

// assign Threshold_AC   = (Mode_T == Insensitive)? 'd2047 : (Mode_T == Normal) ? 'd1023 : 'd511;
// assign Threshold_BFGH = (Mode_T == Insensitive)? 'd800  : (Mode_T == Normal) ? 'd400  : 'd511;
// assign Threshold_DE   = (Mode_T == Insensitive)? '3     : (Mode_T == Normal) ? 'd2    : 'd1;
// assign Threshold = (Formula_T == Formula_A | Formula_T == Formula_C)? Threshold_AC : (Formula_T == Formula_D | Formula_T == Formula_E)? Threshold_DE : Threshold_BFGH;

//================================================================
// randomization
//================================================================
class random_act;
	rand Action act;

    function new (int seed);
        this.srandom(seed);
    endfunction

	constraint range{
		act inside{Index_Check,Update,Check_Valid_Date};
	}
endclass



class random_formula;
	rand Formula_Type formula;

    function new (int seed);
        this.srandom(seed);
    endfunction

	constraint range{
		formula inside{Formula_A,Formula_B,Formula_C,Formula_D,Formula_E,Formula_F,Formula_G,Formula_H};
	}
endclass


class random_mode;
	rand Mode mode;

    function new (int seed);
        this.srandom(seed);
    endfunction

	constraint range{
		mode inside{Insensitive,Normal,Sensitive};
	}
endclass


class random_date;
    rand Month month;
    rand Day day;

    function new (int seed);
        this.srandom(seed);
    endfunction


    constraint range1 {
        month inside {[1:12]};
    }

    constraint range2 {
        if (month inside {1, 3, 5, 7, 8, 10, 12}) {
            day inside {[1:31]};
        } else if (month inside {4, 6, 9, 11}) {
            day inside {[1:30]};
        } else if (month == 2) {
            day inside {[1:28]};
        }
    }
endclass


class random_data_no;
    rand Data_No data_no;

    function new (int seed);
        this.srandom(seed);
    endfunction

    constraint range {
        data_no inside {[0:255]};
    }
endclass


class random_index;
    rand Index index;

    function new (int seed);
        this.srandom(seed);
    endfunction

    constraint range {
        index inside {[0:4095]};
    }
endclass

// class random_variation;
//     rand reg signed [11:0] variation;

//     constraint range {
//         variation inside {[-2048:2047]};
//     }
// endclass

random_act       r_act     ;
random_formula   r_formula ;
random_mode      r_mode    ;
random_date      r_date    ;
random_data_no   r_data_no ;
random_index     r_index   ;


//random_variation r_var     = new();

//================================================================
// main
//================================================================

reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";
reg[10*8:1] txt_purple_prefix = "\033[1;35m";


reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";

initial begin

    r_act     = new(`SEED);
    r_formula = new(`SEED);
    r_mode    = new(`SEED);
    r_date    = new(`SEED);
    r_data_no = new(`SEED);
    r_index   = new(`SEED);

    $readmemh(DRAM_p_r, golden_DRAM);
	total_latency = 0;

    reset_task;
    for (i=0;i<`pat_num;i=i+1) begin
        choose_task;
		output_task;
		$display("                     PASS PATTERN NO. %d, latency = %d                   " ,i , latency);
    end




    $display("\033[40;1m                                              ");
    $display("\033[40;1m                                                                                                                                                      ");
    $display("\033[40;1m                                                                                                                                                      ");
    $display("\033[40;1m                                                                                                                                                      ");
    $display("\033[40;1m                                  \033[1;35m@@@                                                                                              ");
    $display("\033[40;1m                                  \033[1;35m@=+@#                                                                                            ");
    $display("\033[40;1m                                 \033[1;35m@*-==*@                                                                                           ");
    $display("\033[40;1m                                \033[1;35m@=-==-=@ @                                                                                         ");
    $display("\033[40;1m                                 \033[1;35m@========* @                                                                                      ");
    $display("\033[40;1m                                 \033[1;35m@-=======- =@\033[1;30m@              +\033[1;35m@@@@                                             ");
    $display("\033[40;1m                                \033[1;35m@-=========-=*@           \033[1;35m@@#*+*@                                               ");
    $display("\033[40;1m                                \033[1;35m@ ==========--=@     -\033[1;35m@@@#+=-=-#  *@@@                                          ");
    $display("\033[40;1m                      *         \033[1;35m@--===========--@@@@**=-====-@@#**+*@                                                              ");
    $display("\033[40;1m                   *\033[1;35m@@@@        \033[1;35m@=--==== = ===--  -=========* \033[1;30m-=- +                                                     ");
    $display("\033[40;1m                   \033[1;35m@+ -*@       \033[1;35m@+==--== = ================------@@@@@@@@@                                               ");
    $display("\033[40;1m                    \033[1;35m@ -=-+@@    \033[1;35m@*-=+== -   -====================-----  @          -\033[1;35m@=+#@@@@@@ @ @@   ");
    $display("\033[40;1m                  \033[1;35m@#-===-=+@    \033[1;35m@@+++--  \033[1;31m@ @\033[1;35m--=========================-@@@@@@@@###*****+==== = +@                       ");
    $display("\033[40;1m                  \033[1;35m@--=======@-  \033[1;35m@@----\033[1;31m=@   +@\033[1;35m--========================================-=* @                             ");
    $display("\033[40;1m                  \033[1;35m@ =======-=@+@=-----\033[1;31m@-=-=-=@-\033[1;35m-============================================== ==@@                                ");
    $display("\033[40;1m                  \033[1;35m@ ========--@--===-\033[1;31m##-===--=@ \033[1;35m-==========================================- =@\033[1;30m-。                                ");
    $display("\033[40;1m                 -\033[1;35m@-========= @+==== \033[1;31m@--=====  @-\033[1;35m-======================================-=*@                                       ");
    $display("\033[40;1m                 \033[1;35m@+==========--   -= \033[1;31m@=-====     @\033[1;35m-=================================-=+@@                                         ");
    $display("\033[40;1m                 *\033[1;35m@-===========-@@*=- \033[1;31m@*=-=      @@\033[1;35m=====----\033[1;31m==+**##@@@#@-@@@@@@@\033[1;35m-+@@                                            ");
    $display("\033[40;1m                 -\033[1;35m@--==========-@ =@@+-  \033[1;31m@ @@@@@@-\033[1;35m======\033[1;31m*@@@     =--=--=- @@@\033[1;35m====-=+*@                                              ");
    $display("\033[40;1m                  \033[1;35m@-==========-+#    +@# -=======-======-+\033[1;31m@=      =======-=@\033[1;35m------#@                                               ");
    $display("\033[40;1m                  \033[1;35m@-=-========-+@     @- # @@@*=- --====--*\033[1;31m@     ====@@@@\033[1;35m==-@@          -@ @                           ");
    $display("\033[40;1m                  \033[1;35m@#=-==========-@     @       +@@@#=-------+\033[1;31m@@====@@@\033[1;35m--==-  @=@@@@@@@@@@ +@ @                                 ");
    $display("\033[40;1m                   \033[1;35m@=-==========-@#   @-          @ @@@@@**-    **\033[1;31m+=-\033[1;35m---=*@@*-==--    - -  @@                                 ");
    $display("\033[40;1m                   \033[1;35m@@-============@   @           @      -*@@@@@@@@@@@@@@@+=*@-  --========= -- @                                  ");
    $display("\033[40;1m                   \033[1;35m@=--=========-=@#@           @+           @         @ -----============-= @                                     ");
    $display("\033[40;1m                   \033[1;35m@==-==========--=@           @           @        @@=-==================- @=                                    ");
    $display("\033[40;1m                   \033[1;35m@-==============--=*@ @       @          +@     *@@=--================--@ @\033[1;30m。                                  ");
    $display("\033[40;1m                  \033[1;35m@+=--============-==+# @@= @+         #    @@+=--=================--@#                                           ");
    $display("\033[40;1m              \033[1;35m@@@@#==+-===================*#@@@@@@#+++***@@@@#=--==================--*@                                       ");
    $display("\033[40;1m         \033[1;35m @@#+======+--=====================++*****=- ----====================@@                                              ");
    $display("\033[40;1m    \033[1;35m@@*@@*+=========+=-=====================================================---@@@                                            ");
    $display("\033[40;1m   \033[1;35m@@#+=@-==========++-================================================---+@@-                                                ");
    $display("\033[40;1m    \033[1;35m@@=--============++---=============================================----@@*                                                ");
    $display("\033[40;1m     -\033[1;35m@#+==============++=-=======================================-----==+=@                                                  ");
    $display("\033[40;1m        \033[1;35m@@+==============+=--=========================================++++=*@                                                 ");
    $display("\033[40;1m          \033[1;35m@@@*=--=====-==++=--==================================-======@            \033[1;35m Congratulations!!! \033[1;0m          ");
    $display("\033[40;1m              \033[1;35m@@@@@*++=@* -=++----================================= @@-==@-          \033[1;35m PASS This Lab........Maybe \033[1;0m ");
    $display("\033[40;1m                  =\033[1;35m@@@@@@@+==++-----==========================-- @+@+                 \033[1;35m Total Latency : %d\033[1;0m         ", total_latency);
    $display("\033[40;1m                           \033[1;35m@@*+==++=---============================- =@                                                       ");
    $display("\033[40;1m                              =\033[1;35m@@@#++==============================--#@                                                       ");
    $display("\033[40;1m                                  -\033[1;35m@@@*===---------======================+@                                                   ");
    $display("\033[40;1m                                       \033[1;35m@ @@ @@@#####@@#+- --==================-=@                                                  ");
    $display("\033[40;1m                                                   ***=   \033[1;35m@@@#*=--===============-@@@                                              ");
    $display("\033[40;1m                                                        =\033[1;35m@@@*==============-- @@@                                                  ");
    $display("\033[40;1m                                                                \033[1;35m@@@#**+-- --------  =@                                             ");
    $display("\033[40;1m                                                                    \033[1;35m=#@@@@@@@@@@@@@@                                               ");
    $display("\033[40;1m                                                                                                                                                      ");
    $display("\033[40;1m                                                                                                                                                      ");
    $display("\033[40;1m                                                                                                                                                      ");
    $display("\033[40;1m                                                                                                                                                      ");

    $display("\033[1;0m");

    //repeat (9) @(negedge clk);
	$finish;
end




task reset_task; begin
	inf.rst_n = 1'b1;
	inf.D = 72'bx;
	inf.sel_action_valid = 1'b0;
	inf.formula_valid = 1'b0;
	inf.mode_valid = 1'b0;
	inf.date_valid = 1'b0;
	inf.data_no_valid = 1'b0;
	inf.index_valid = 1'b0;

	force clk = 1'b0;

	#`CYCLE; inf.rst_n = 1'b0;
	#`CYCLE; inf.rst_n = 1'b1;

	if (inf.out_valid !== 1'b0 || inf.complete !== 1'b0 || inf.warn_msg !== 2'b00) begin
		$display("   RESET FAIL   ");
		repeat (3) #`CYCLE;
		$finish;
	end

	#`CYCLE; release clk;
end
endtask

task choose_task; begin
    rand_0to3 = $urandom_range(0,3);
    repeat (rand_0to3) @(negedge clk);

	if (!r_act.randomize()) begin  //random action
		$display("Randomization failed!");
		$finish;
	end

    inf.D = {60'bx,10'b0,r_act.act};
    Act_T = r_act.act;
    inf.sel_action_valid = 1;
    @(negedge clk);
    case (Act_T)
        Index_Check      : index_check_task;
        Update           : update_task;
        Check_Valid_Date : check_valid_date_task;
    endcase
end
endtask

//================================================================
// action : index check
//================================================================
task index_check_task; begin

    rand_0to3 = $urandom_range(0,3);  //random 1~4 `CYCLE
	begin
        inf.D = 72'bx; inf.sel_action_valid = 0;
         end
	repeat (rand_0to3) @(negedge clk);
	if (!r_formula.randomize()) begin  //random formula
		$display("Randomization failed!");
		$finish;
	end
    inf.D = {60'bx,9'b0,r_formula.formula};
    Formula_T = r_formula.formula;
    inf.formula_valid = 1;
	@(negedge clk);

	rand_0to3 = $urandom_range(0,3);  //random 1~4 `CYCLE
	begin
        inf.D = 72'bx; inf.formula_valid = 0;
    end
	repeat (rand_0to3) @(negedge clk);
	if (!r_mode.randomize()) begin  //random mode
		$display("Randomization failed!");
		$finish;
	end
    inf.D = {60'bx,10'b0,r_mode.mode};
    Mode_T = r_mode.mode;
    inf.mode_valid = 1;
	@(negedge clk);

	rand_0to3 = $urandom_range(0,3);  //random 1~4 `CYCLE
	begin
        inf.D = 72'bx; inf.mode_valid = 0;
    end
	repeat (rand_0to3) @(negedge clk);
	if (!r_date.randomize()) begin  //random date
		$display("Randomization failed!");
		$finish;
	end
    inf.D = {60'bx,3'b0, r_date.month, r_date.day};
    Month_T = r_date.month;
	Day_T = r_date.day;
    inf.date_valid = 1;
	@(negedge clk);

	rand_0to3 = $urandom_range(0,3);  //random 1~4 `CYCLE
	begin
        inf.D = 72'bx; inf.date_valid = 0;
    end
	repeat (rand_0to3) @(negedge clk);
	if (r_data_no.randomize()===256) begin  //random data number
		$display("Randomization failed!");
		$finish;
	end
    inf.D = {60'bx,4'b0,r_data_no.data_no};
    Data_no_T = r_data_no.data_no;
    inf.data_no_valid = 1;
	@(negedge clk);

    for (j=0;j<4;j=j+1) begin  //four index
        rand_0to3 = $urandom_range(0,3);  //random 1~4 `CYCLE
        begin
             inf.D = 72'bx; inf.data_no_valid = 0; inf.index_valid = 0;
        end
        repeat (rand_0to3) @(negedge clk);
        if (r_index.randomize()===4096) begin  //random data number
            $display("Randomization failed!");
            $finish;
        end
        inf.D = {60'bx,r_index.index};
        IorV[j] = r_index.index;
        inf.index_valid = 1;
        @(negedge clk);
    end
    inf.index_valid = 0;
    inf.D = 72'bx;
    index_check_result_task;
    @(negedge clk);
end
endtask



logic [11:0] sort_net [0:7];
logic [11:0] sort_maxI, sort_mid1I, sort_mid2I, sort_minI;
logic [11:0] sort_maxG, sort_mid1G, sort_mid2G, sort_minG;

task index_check_result_task; begin

    Threshold_AC   = (Mode_T == Insensitive)? 'd2047 : (Mode_T == Normal) ? 'd1023 : 'd511;
    Threshold_BFGH = (Mode_T == Insensitive)? 'd800  : (Mode_T == Normal) ? 'd400  : 'd200;
    Threshold_DE   = (Mode_T == Insensitive)? 'd3     : (Mode_T == Normal) ? 'd2    : 'd1;
    Threshold = (Formula_T == Formula_A | Formula_T == Formula_C)? Threshold_AC : (Formula_T == Formula_D | Formula_T == Formula_E)? Threshold_DE : Threshold_BFGH;

    GA = (d_IorV[0] > IorV[0]) ? (d_IorV[0] - IorV[0]) : (IorV[0] - d_IorV[0]);  //absolute index
    GB = (d_IorV[1] > IorV[1]) ? (d_IorV[1] - IorV[1]) : (IorV[1] - d_IorV[1]);
    GC = (d_IorV[2] > IorV[2]) ? (d_IorV[2] - IorV[2]) : (IorV[2] - d_IorV[2]);
    GD = (d_IorV[3] > IorV[3]) ? (d_IorV[3] - IorV[3]) : (IorV[3] - d_IorV[3]);

    sort_net[0] = (d_IorV[0] > d_IorV[1]) ? d_IorV[0] : d_IorV[1];  //sorting I
    sort_net[1] = (d_IorV[0] > d_IorV[1]) ? d_IorV[1] : d_IorV[0];
    sort_net[2] = (d_IorV[2] > d_IorV[3]) ? d_IorV[2] : d_IorV[3];
    sort_net[3] = (d_IorV[2] > d_IorV[3]) ? d_IorV[3] : d_IorV[2];

    sort_maxI   = (sort_net[0] > sort_net[2]) ? sort_net[0] : sort_net[2];
    sort_mid1I  = (sort_net[0] > sort_net[2]) ? sort_net[2] : sort_net[0];
    sort_mid2I  = (sort_net[1] > sort_net[3]) ? sort_net[1] : sort_net[3];
    sort_minI   = (sort_net[1] > sort_net[3]) ? sort_net[3] : sort_net[1];

    sort_net[4] = (GA > GB) ? GA : GB;  //sorting G
    sort_net[5] = (GA > GB) ? GB : GA;
    sort_net[6] = (GC > GD) ? GC : GD;
    sort_net[7] = (GC > GD) ? GD : GC;

    sort_maxG  = (sort_net[4] > sort_net[6]) ? sort_net[4] : sort_net[6];
    sort_mid1G = (sort_net[4] > sort_net[6]) ? sort_net[6] : sort_net[4];
    sort_mid2G = (sort_net[5] > sort_net[7]) ? sort_net[5] : sort_net[7];
    sort_minG =  (sort_net[5] > sort_net[7]) ? sort_net[7] : sort_net[5];

    case (Formula_T)
        Formula_A : golden_Result = (d_IorV[0]+d_IorV[1]+d_IorV[2]+d_IorV[3])/4;
        Formula_B : golden_Result = sort_maxI - sort_minI;
        Formula_C : golden_Result = sort_minI;
        Formula_D : golden_Result = (d_IorV[0] >= 2047) + (d_IorV[1] >= 2047) + (d_IorV[2] >= 2047) + (d_IorV[3] >= 2047);
        Formula_E : golden_Result = (d_IorV[0] >= IorV[0]) + (d_IorV[1] >= IorV[1]) + (d_IorV[2] >= IorV[2]) + (d_IorV[3] >= IorV[3]);
        Formula_F : golden_Result = (sort_mid1G + sort_mid2G + sort_minG)/3;
        Formula_G : golden_Result = sort_minG/2 + sort_mid1G/4 + sort_mid2G/4;
        Formula_H : golden_Result = (GA + GB + GC + GD)/4;
    endcase

    if ((d_Month > Month_T) | (d_Month === Month_T && d_Day > Day_T)) begin golden_complete = 0; golden_warn = Date_Warn; end   //date_warn
    else if (golden_Result >= Threshold)                              begin golden_complete = 0; golden_warn = Risk_Warn; end   //risk_warn
    else                                                              begin golden_complete = 1; golden_warn = No_Warn;   end   //no_warn

end
endtask

//================================================================
// action : update
//================================================================
task update_task; begin

    rand_0to3 = $urandom_range(0,3);    //random 1~4 `CYCLE
	begin
        inf.D = 72'bx; inf.sel_action_valid = 0;
    end
	repeat (rand_0to3) @(negedge clk);

	if (!r_date.randomize()) begin  //random date
		$display("Randomization failed!");
		$finish;
	end

    inf.D = {60'bx,3'b0,r_date.month,r_date.day};
    Month_T = r_date.month;
	Day_T   = r_date.day;
    inf.date_valid = 1;
	@(negedge clk);

	rand_0to3 = $urandom_range(0,3);    //random 1~4 `CYCLE
	begin
        inf.D = 72'bx; inf.date_valid = 0;
    end
	repeat (rand_0to3) @(negedge clk);
	if (r_data_no.randomize()===256) begin  //random data number
		$display("Randomization failed!");
		$finish;
	end
    inf.D = {60'bx,4'b0,r_data_no.data_no};
    Data_no_T = r_data_no.data_no;
    inf.data_no_valid = 1;
	@(negedge clk);

    for (j=0;j<4;j=j+1) begin  //four index
        rand_0to3 = $urandom_range(0,3);    //random 1~4 `CYCLE
        begin
            inf.D = 72'bx; inf.data_no_valid = 0; inf.index_valid = 0;
        end
        repeat (rand_0to3) @(negedge clk);
        if (r_index.randomize()===2048) begin  //random data number
            $display("Randomization failed!");
            $finish;
        end
        inf.D = {60'bx,r_index.index};
        IorVs[j] = {1'b0, r_index.index};

        inf.index_valid = 1;
        @(negedge clk);
    end
    inf.index_valid = 0;
    inf.D = 72'bx;
    update_result_task;
    @(negedge clk);
end
endtask

logic signed [13:0] plusA, plusB, plusC, plusD;
logic [11:0] WB_A, WB_B, WB_C, WB_D;

task update_result_task; begin

    plusA = d_IorVs[0] + IorVs[0];  //add variation
    plusB = d_IorVs[1] + IorVs[1];
    plusC = d_IorVs[2] + IorVs[2];
    plusD = d_IorVs[3] + IorVs[3];

    WB_A = (plusA >4095) ? 4095 : ((plusA <0) ? 0 : plusA[11:0]);  //saturation
    WB_B = (plusB >4095) ? 4095 : ((plusB <0) ? 0 : plusB[11:0]);
    WB_C = (plusC >4095) ? 4095 : ((plusC <0) ? 0 : plusC[11:0]);
    WB_D = (plusD >4095) ? 4095 : ((plusD <0) ? 0 : plusD[11:0]);

    if ((plusA <= 4095) & (plusA >= 0) &
        (plusB <= 4095) & (plusB >= 0) &
        (plusC <= 4095) & (plusC >= 0) &
        (plusD <= 4095) & (plusD >= 0)) begin
        golden_warn = No_Warn;   golden_complete = 1;
    end
    else begin
        golden_warn = Data_Warn; golden_complete = 0;
    end


    golden_DRAM[d_Addr]   = Day_T;
    golden_DRAM[d_Addr+1] = WB_D[7:0];
    golden_DRAM[d_Addr+2] = {WB_C[3:0], WB_D[11:8]};
    golden_DRAM[d_Addr+3] = WB_C[11:4];
    golden_DRAM[d_Addr+4] = Month_T;
    golden_DRAM[d_Addr+5] = WB_B[7:0];
    golden_DRAM[d_Addr+6] = {WB_A[3:0], WB_B[11:8]};
    golden_DRAM[d_Addr+7] = WB_A[11:4];

end
endtask

task check_valid_date_task; begin
    rand_0to3 = $urandom_range(0,3);    //random 1~4 `CYCLE
	begin
        inf.D = 72'bx; inf.sel_action_valid = 0;
    end
	repeat (rand_0to3) @(negedge clk);

	if (!r_date.randomize()) begin  //random date
		$display("Randomization failed!");
		$finish;
	end

    inf.D = {60'bx,3'b0,r_date.month,r_date.day};
    Month_T = r_date.month;
	Day_T = r_date.day;
    inf.date_valid = 1;
	@(negedge clk);

	rand_0to3 = $urandom_range(0,3);    //random 1~4 `CYCLE
	begin
        inf.D = 72'bx; inf.date_valid = 0;
    end
	repeat (rand_0to3) @(negedge clk);
	if (r_data_no.randomize()===256) begin  //random data number
		$display("Randomization failed!");
		$finish;
	end
    inf.D = {60'bx,4'b0,r_data_no.data_no};
    Data_no_T = r_data_no.data_no;
    inf.data_no_valid = 1;
	@(negedge clk);

    inf.data_no_valid = 0;
    inf.D = 72'bx;
	if ((d_Month > Month_T) | (d_Month === Month_T & d_Day > Day_T)) begin
        golden_complete = 0; golden_warn = Date_Warn;
    end //date_warn
	else  begin
        golden_complete = 1; golden_warn = No_Warn;
    end //no_warn
    @(negedge clk);
end
endtask


//================================================================
// wait output/warn/complete
//================================================================

task output_task; begin
    latency = 0;
	while (inf.out_valid !== 1'b1) begin
		latency = latency + 1;
		if (latency == MAX_LATENCY) begin
			$display(" Latency > %d ", MAX_LATENCY);
			repeat (2) @(negedge clk);
			$finish;
            break;
		end
		@(negedge clk);
	end
	total_latency = total_latency + latency;
    if ((inf.out_valid===1)&(inf.warn_msg !== golden_warn | inf.complete !== golden_complete)) begin
			$display("   WARNING MSG IS WRONG  ");
			$display("   CURRENT ACTION : %d   ", Act_T);
			$display("   CURRENT DATA NO : %d  ", Data_no_T);
            $display("   GOLDEN WARMING:  %d GOLDEN COMPLETE: %d ", golden_warn, golden_complete);
            $display("   YOUR : %d           YOUR : %d ", inf.warn_msg, inf.complete);
			repeat (2) @(negedge clk);
			$finish;
    end
    @(negedge clk);
end
endtask




endprogram


