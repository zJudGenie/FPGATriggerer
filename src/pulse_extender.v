`timescale 1 ns / 1 ps
`default_nettype none
`include "commands.v"

module pulse_extender (
    input  wire          reset,


    input  wire          sampleclk,
    input  wire          signal_in,

    //Serial interface
    input  wire          clk_usb,
    input  wire  [7:0]   reg_cmd,       // Command to be executed
    input  wire  [15:0]  reg_bytecount, // Byte number to be read or written
    input  wire  [7:0]   reg_data_in,   // Data read from serial after header
    output reg   [7:0]   reg_data_out,  // Data to write to serial
    input  wire          reg_read,      // Read flag
    input  wire          reg_write,     // Write flag


    output reg          signal_out
);

    `define STATE_WAIT_PULSE    0   // Count until delay_cycles
    `define STATE_EXTENDING     1   // Delay expired, back to IDLE

    reg [1:0] fsm_state = `STATE_WAIT_PULSE;

    reg signal_in_r;

    // 2 bytes: By how many clock cycles extend the pulse
    reg [15:0] reg_extension_cycles;
    reg [15:0] reg_counter = 16'd1;
    
    always @(posedge clk_usb) begin
        if (reg_write) begin
            case (reg_cmd)
                `PULSE_EXTENDER_CYCLES: begin 
                    reg_extension_cycles[reg_bytecount*8 +: 8] <= reg_data_in; // read only 2 byte
                end
                default: ;
            endcase
        end
    end

    always @(*) begin
        if (reg_read) begin
            case (reg_cmd)
                `PULSE_EXTENDER_CYCLES: reg_data_out <= reg_extension_cycles[reg_bytecount*8 +: 8]; // read only 2 byte
                default: reg_data_out <= 8'd0;
            endcase
        end
        else
            reg_data_out <= 8'd0;
    end

    always @(posedge sampleclk) begin
        signal_in_r <= signal_in;

        case (fsm_state)

            `STATE_WAIT_PULSE: begin

                reg_counter <= 16'd0;
                signal_out  <= 0;

                if (~signal_in_r & signal_in)
                    fsm_state <= `STATE_EXTENDING;
            end

            `STATE_EXTENDING: begin
                signal_out  <= 1;

                if (reg_counter == reg_extension_cycles)
                    fsm_state <= `STATE_WAIT_PULSE;

                reg_counter <= reg_counter + 16'd1;
            end

            default: ;
        endcase
    end

endmodule
`default_nettype wire