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


    output wire          trigger
);

    `define STATE_IDLE          0   // Wait to be armed
    `define STATE_WAIT_TRIGIN   1   // Armed, wait an input trigger
    `define STATE_COUNTING      2   // Count until delay_cycles
    `define STATE_DELAY_EXP     3   // Delay expired, back to IDLE

    reg [2:0] fsm_state = `STATE_IDLE;

    reg triggered   = 0;
    reg armed       = 0;

    reg [23:0] reg_delay_cycles;
    reg [23:0] reg_counter = 24'd1;
    
    always @(posedge clk_usb) begin
        if (reg_write) begin
            case (reg_cmd)
                `DELAY_MODULE_DELAY: begin 
                    reg_delay_cycles[reg_bytecount*8 +: 8] <= reg_data_in; // read only 3 byte
                end
                `DELAY_MODULE_ARM: begin 
                    armed <= reg_data_in[0];
                end
                default: ;
            endcase
        end
    end

    always @(*) begin
        if (reg_read) begin
            case (reg_cmd)
                `DELAY_MODULE_DELAY: reg_data_out <= reg_delay_cycles[reg_bytecount*8 +: 8]; // write only 3 byte
                default: reg_data_out <= 8'd0;
            endcase
        end
        else
            reg_data_out <= 8'd0;
    end

    always @(posedge timerclk) begin

        case (fsm_state)

            `STATE_IDLE: begin
                triggered   <= 0;
                reg_counter <= 24'd1;

                if (armed)
                    fsm_state <= `STATE_WAIT_TRIGIN;
            end

            `STATE_WAIT_TRIGIN: begin
                if (trigger_in)
                    fsm_state <= `STATE_COUNTING;
            end

            `STATE_COUNTING: begin
                if (reg_counter == reg_delay_cycles) begin
                    fsm_state <= `STATE_DELAY_EXP;
                end

                reg_counter <= reg_counter + 24'd1;
            end

            `STATE_DELAY_EXP: begin
                triggered <= 1;

                fsm_state <= `STATE_IDLE;
            end

            default: ;
        endcase
    end

    assign trigger = triggered;

endmodule
`default_nettype wire