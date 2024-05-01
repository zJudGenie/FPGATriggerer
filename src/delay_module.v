`timescale 1 ns / 1 ps
`default_nettype none
`include "commands.v"

module delay_module (
    input  wire          reset,


    input  wire          timerclk,
    input  wire          trigger_in,

    //Serial interface
    input  wire          clk_usb,
    input  wire  [7:0]   reg_cmd,       // Command to be executed
    input  wire  [15:0]  reg_bytecount, // Byte number to be read or written
    input  wire  [7:0]   reg_data_in,   // Data read from serial after header
    output reg   [7:0]   reg_data_out,  // Data to write to serial
    input  wire          reg_read,      // Read flag
    input  wire          reg_write,     // Write flag


    output wire          trigger,
    output reg [5:0]     debug
);

    reg triggered;
    reg counting;

    reg [31:0] reg_delay_cycles;
    reg [31:0] reg_counter = 32'd1;
    
    always @(posedge clk_usb) begin
        if (reg_write) begin
            case (reg_cmd)
                `DELAY_MODULE_DELAY: begin 
                    reg_delay_cycles[reg_bytecount*8 +: 8] <= reg_data_in; // read only 4 byte
                    debug <= ~reg_data_in[5:0];
                end
                default: ;
            endcase
        end
    end

    always @(*) begin
        if (reg_read) begin
            case (reg_cmd)
                `DELAY_MODULE_DELAY: reg_data_out <= reg_delay_cycles[reg_bytecount*8 +: 8]; // write only 4 byte
                default: reg_data_out <= 8'd0;
            endcase
        end
        else
            reg_data_out <= 8'd0;
    end

    always @(posedge timerclk) begin
        triggered <= 0;

        if (counting) begin
            reg_counter <= reg_counter + 32'd1;

            if (reg_counter == reg_delay_cycles) begin
                triggered   <= 1;
                counting    <= 0;
                reg_counter <= 32'd0;
            end
        end
        else
            counting <= trigger_in;
    end

    assign trigger = triggered;

endmodule
`default_nettype wire