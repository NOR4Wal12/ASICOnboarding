/*
 * Copyright (c) 2024 Damir Gazizullin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module spi_peripheral (
    input  wire       rst_n,     // reset_n - low to reset
    input  wire       COPI,
    input  wire       nCS,
    input  wire       SCLK,       
    input  wire       clk, 
    output  reg [7:0] en_reg_out_7_0,
    output  reg [7:0] en_reg_out_15_8,
    output  reg [7:0] en_reg_pwm_7_0,
    output  reg [7:0] en_reg_pwm_15_8,
    output  reg [7:0] pwm_duty_cycle
);

    reg COPI1;
    reg COPI2;

    reg SCLK1;
    reg SCLK2;
    reg SCLK3;
    
    reg nCS1;
    reg nCS2;
    reg nCS3;

    reg [4:0] bits_done;
    reg [15:0] data;

    //update registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            COPI1 <= 0;
            COPI2 <= 0;
            SCLK1 <= 0;
            SCLK2 <= 0;
            SCLK3 <= 0;
            nCS1 <= 1; //active low
            nCS2 <= 1;
            nCS3 <= 1;
        end else begin
            COPI2 <= COPI1;
            COPI1 <= COPI;

            SCLK3 <= SCLK2;
            SCLK2 <= SCLK1;
            SCLK1 <= SCLK;

            nCS3 <= nCS2;
            nCS2 <= nCS1;
            nCS1 <= nCS;
        end
    end

    wire SCLK_rising = (SCLK2 && !SCLK3);
    wire nCS_rising = (nCS2 && !nCS3);
    wire nCS_falling = (!nCS2 && nCS3);

    //outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bits_done <= 5'b0;
            data <= 16'b0;
        end else if (nCS_falling) begin
            bits_done <= 5'b0;
        end else if (!nCS3 && SCLK_rising && bits_done < 5'd16) begin
            data <= {data[14:0], COPI2};
            bits_done <= bits_done + 1;
        end
    end

    //output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0 <= 8'b0;
            en_reg_out_15_8 <= 8'b0;
            en_reg_pwm_7_0 <= 8'b0;
            en_reg_pwm_15_8 <= 8'b0;
            pwm_duty_cycle <= 8'b0;
        end else if (bits_done == 5'd16 && nCS_rising) begin
            if (data[15]) begin
                case (data[14:8])
                    7'd0: en_reg_out_7_0 <= data[7:0];
                    7'd1: en_reg_out_15_8 <= data[7:0];
                    7'd2: en_reg_pwm_7_0 <= data[7:0];
                    7'd3: en_reg_pwm_15_8 <= data[7:0];
                    7'd4: pwm_duty_cycle <= data[7:0];
                    default: ;
                endcase
            end
        end
    end        

endmodule
