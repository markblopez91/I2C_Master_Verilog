`timescale 1ns / 1ps

module i2c_master(
    input clk,
    input rst,
    input start,
    input [6:0] slave_addr,
    input [7:0] data_in,
    output reg scl,
    output reg sda,
    output reg busy,
    output reg done
);

parameter CLK_DIV = 250;

localparam IDLE  = 3'b000;
localparam START = 3'b001;
localparam ADDR  = 3'b010;
localparam DATA  = 3'b011;
localparam STOP  = 3'b100;
localparam DONE  = 3'b101;

reg [2:0] state;
reg [7:0] shift_reg;
reg [3:0] bit_count;
reg [15:0] clk_count;

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        scl <= 1'b1;
        sda <= 1'b1;
        busy <= 1'b0;
        done <= 1'b0;
        state <= IDLE;
        shift_reg <= 8'b0;
        bit_count <= 4'b0;
        clk_count <= 16'b0;
    end
    else
    begin
        case (state)

            IDLE:
            begin
                scl <= 1'b1;
                sda <= 1'b1;
                busy <= 1'b0;
                done <= 1'b0;
                clk_count <= 0;
                bit_count <= 0;

                if (start)
                begin
                    busy <= 1'b1;
                    shift_reg <= {slave_addr, 1'b0}; // write operation
                    state <= START;
                end
            end

            START:
            begin
                busy <= 1'b1;
                sda <= 1'b0; // start condition while SCL high

                if (clk_count < CLK_DIV)
                begin
                    clk_count <= clk_count + 1;
                end
                else
                begin
                    clk_count <= 0;
                    scl <= 1'b0;
                    bit_count <= 0;
                    state <= ADDR;
                end
            end

            ADDR:
            begin
                if (clk_count == 0)
                begin
                    sda <= shift_reg[7];
                    scl <= 1'b0;
                end
                else if (clk_count == CLK_DIV)
                begin
                    scl <= 1'b1;
                end
                else if (clk_count == CLK_DIV * 2)
                begin
                    scl <= 1'b0;
                    shift_reg <= {shift_reg[6:0], 1'b0};

                    if (bit_count < 7)
                    begin
                        bit_count <= bit_count + 1;
                    end
                    else
                    begin
                        bit_count <= 0;
                        shift_reg <= data_in;
                        state <= DATA;
                    end

                    clk_count <= 0;
                end

                clk_count <= clk_count + 1;
            end

            DATA:
            begin
                if (clk_count == 0)
                begin
                    sda <= shift_reg[7];
                    scl <= 1'b0;
                end
                else if (clk_count == CLK_DIV)
                begin
                    scl <= 1'b1;
                end
                else if (clk_count == CLK_DIV * 2)
                begin
                    scl <= 1'b0;
                    shift_reg <= {shift_reg[6:0], 1'b0};

                    if (bit_count < 7)
                    begin
                        bit_count <= bit_count + 1;
                    end
                    else
                    begin
                        bit_count <= 0;
                        state <= STOP;
                    end

                    clk_count <= 0;
                end

                clk_count <= clk_count + 1;
            end

            STOP:
            begin
                scl <= 1'b1;
                sda <= 1'b0;

                if (clk_count < CLK_DIV)
                begin
                    clk_count <= clk_count + 1;
                end
                else
                begin
                    sda <= 1'b1; // stop condition while SCL high
                    clk_count <= 0;
                    state <= DONE;
                end
            end

            DONE:
            begin
                busy <= 1'b0;
                done <= 1'b1;
                state <= IDLE;
            end

            default:
                state <= IDLE;

        endcase
    end
end

endmodule