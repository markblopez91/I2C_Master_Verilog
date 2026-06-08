`timescale 1ns / 1ps

module i2c_master_tb;

reg clk;
reg rst;
reg start;
reg [6:0] slave_addr;
reg [7:0] data_in;

wire scl;
wire sda;
wire busy;
wire done;

i2c_master uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .slave_addr(slave_addr),
    .data_in(data_in),
    .scl(scl),
    .sda(sda),
    .busy(busy),
    .done(done)
);

// 100 MHz clock
always #5 clk = ~clk;

initial
begin
    clk = 0;
    rst = 1;
    start = 0;
    slave_addr = 7'h50;
    data_in = 8'hA5;

    #100;
    rst = 0;

    #100;
    start = 1;

    #10;
    start = 0;

    #200000;

    $stop;
end

endmodule