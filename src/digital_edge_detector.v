`timescale 1 ns / 1 ps
`default_nettype none
`include "commands.v"

module digital_edge_detector (
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


    output reg           triggered
);

    `define EDGE_SENSITIVITY    0

    // [X X X X X X X E]
    // E = Edge Sensitivity
    //      0 = Low to High  
    //      1 = High to Low  

    `define LOW_TO_HIGH         0
    `define HIGH_TO_LOW         1


    `define STATE_LISTENING     0   // Sampling input signals
    `define STATE_HOLDINGOFF    1   // Ignore the input

    reg [1:0] fsm_state = `STATE_LISTENING;

    reg signal_in_r;

    // 3 bytes: For how many clock cycles ignore the input
    reg [23:0] reg_holdoff_cycles = 24'd1000;
    reg [23:0] reg_counter = 24'd0;

    reg [7:0] reg_config;
    
    always @(posedge clk_usb) begin
        if (reg_write) begin
            case (reg_cmd)
                `DIGITAL_EDGE_DETECTOR_CFG: begin 
                    reg_config <= reg_data_in; // read only 1 byte
                end
                `DIGITAL_EDGE_DETECTOR_HOLDOFF: begin 
                    reg_holdoff_cycles[reg_bytecount*8 +: 8] <= reg_data_in; // read only 2 byte
                end
                default: ;
            endcase
        end
    end

    always @(*) begin
        if (reg_read) begin
            case (reg_cmd)
                `DIGITAL_EDGE_DETECTOR_CFG: reg_data_out <= reg_config; // read only 1 byte
                `DIGITAL_EDGE_DETECTOR_HOLDOFF: reg_data_out <= reg_holdoff_cycles[reg_bytecount*8 +: 8]; // read only 2 byte
                default: reg_data_out <= 8'd0;
            endcase
        end
        else
            reg_data_out <= 8'd0;
    end

    always @(posedge sampleclk) begin
        signal_in_r <= signal_in;

        case (fsm_state)

            `STATE_LISTENING: begin
                reg_counter <= 24'd0;

                case (reg_config[`EDGE_SENSITIVITY])
                    `LOW_TO_HIGH:
                        triggered = ~signal_in_r && signal_in; // blocking assign

                    `HIGH_TO_LOW:
                        triggered = signal_in_r && ~signal_in; // blocking assign
                endcase

                if (reg_holdoff_cycles != 0 && triggered)
                    fsm_state <= `STATE_HOLDINGOFF;
            end

            `STATE_HOLDINGOFF: begin
                triggered <= 0;

                if (reg_counter == reg_holdoff_cycles)
                    fsm_state <= `STATE_LISTENING;

                reg_counter <= reg_counter + 24'd1;
            end

            default: ;
        endcase
    end

    //assign trigger = triggered;

endmodule
`default_nettype wire