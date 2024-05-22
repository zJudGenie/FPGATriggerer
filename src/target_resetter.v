`timescale 1 ns / 1 ps
`default_nettype none
`include "commands.v"

module target_resetter (
    input  wire          reset,

    //Serial interface
    input  wire          clk_usb,
    input  wire  [7:0]   reg_cmd,       // Command to be executed
    input  wire  [15:0]  reg_bytecount, // Byte number to be read or written
    input  wire  [7:0]   reg_data_in,   // Data read from serial after header
    output reg   [7:0]   reg_data_out,  // Data to write to serial
    input  wire          reg_read,      // Read flag
    input  wire          reg_write,     // Write flag


    output reg           target_reset
);
    
    reg reg_reset    = 0;

    always @(posedge clk_usb) begin
        if (reg_write) begin
            case (reg_cmd)
                `TARGET_RESETTER_RESET: begin 
                    reg_reset <= reg_data_in[0]; // read only 2 byte
                end
                default: ;
            endcase
        end
    end

    always @(*) begin
        if (reg_read) begin
            case (reg_cmd)
                `TARGET_RESETTER_RESET: reg_data_out <= reg_reset;
                default: reg_data_out <= 8'd0;
            endcase
        end
        else
            reg_data_out <= 8'd0;
    end

    always @(posedge clk_usb) begin
        // Just copy the reset register content to the output pin
        target_reset <= reg_reset;
    end

endmodule
`default_nettype wire