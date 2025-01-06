
//=======================================================
//
//                  Beauiful Error, with problem but may be correct
//
//=======================================================
module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);

input sclk, dclk;
input rst_n;
input sready;           // Sending from Tx to handshaker, whether the Tx delivers data
input [WIDTH-1:0] din;
input dbusy;            // Sending from Rx to handshaker, whether the Rx will receive data.
output sidle;           // Sending from handshaker to Tx, whether the handshaker can deliver data
output reg dvalid;      // Sending from handshaker to Rx, whether the handshaker deliver data
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
output flag_handshake_to_clk1; // unused
input flag_clk1_to_handshake;  // unused

output flag_handshake_to_clk2; // unused
input flag_clk2_to_handshake;  // unused

// Remember:
//   Don't modify the signal name
reg  sreq;
wire dreq;
reg  dack;
wire sack;

reg [WIDTH-1:0] data;

reg sidle;
reg sCtrl, dCtrl;

always @( posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        data <= 0;
    end
    else  if (sCtrl) begin
            data <= din;
    end
    else begin
            data <= data;
    end
end

always @( posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dout <= 0;
    end
    else if (dCtrl) begin
            dout <= data;
    end
    else begin
            dout <= dout;
    end
end


always@(*)begin
    sCtrl = sidle & sready ;
end

always @(posedge sclk or negedge rst_n) begin
    if(~rst_n)begin
        sreq <= 0;
    end
    else begin
        if((~sreq) & sready & (~sack))begin
        // if(sCtrl)begin
            sreq <= 1;
        end
        else if(sreq & sack)begin
            sreq <= 0;
        end
    end
end


// Dst ctrl
always@(*) begin
    dCtrl = (~dbusy) & (~dack) & dreq ;
end

always@(posedge dclk or negedge rst_n)begin
    if(~rst_n)begin
        dack <= 0;
    end
    else if (dCtrl) begin// if((~dack) & dreq & (~dbusy))begin
        dack <= 1;
    end
    else if(dack & (~dreq))begin
        dack <= 0;
    end
end


// sidle: Sending from handshaker to Tx, whether the handshaker can deliver data
always@(*) begin
    sidle = (~sreq) & (~sack);
end


// dvalid: Sending from handshaker to Rx, whether the handshaker can deliver data
always@( posedge dclk or negedge rst_n) begin
    if (!rst_n) begin
        dvalid <= 0;
    end
    else if(~dbusy)begin
        dvalid <= dCtrl;
    end
    else begin
        dvalid <= 0;
    end
end


NDFF_syn S2D(.D(sreq), .Q(dreq), .clk(dclk), .rst_n(rst_n));
NDFF_syn D2S(.D(dack), .Q(sack), .clk(sclk), .rst_n(rst_n));


endmodule

