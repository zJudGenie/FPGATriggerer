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


    output wire          trigger,
    output reg [5:0]     led
);

    `define EDGE_SENSITIVITY    0

    // [X X X X X X X E]
    // E = Edge Sensitivity
    //   \ 0 Low to High  
    //   \ 1 Low to High  

    `define LOW_TO_HIGH         0
    `define HIGH_TO_LOW         1

    reg triggered;
    reg signal_in_r;

    reg [7:0] reg_config;
    
    always @(posedge clk_usb) begin
        if (reg_write) begin
            case (reg_cmd)
                `DIGITAL_EDGE_DETECTOR_CFG: begin 
                    reg_config <= reg_data_in; // read only 1 byte
                    led <= ~reg_config[4:0];
                end
                default: ;
            endcase
        end
    end

    always @(*) begin
        if (reg_read) begin
            case (reg_cmd)
                `DIGITAL_EDGE_DETECTOR_CFG: reg_data_out <= reg_config; // read only 1 byte
                default: reg_data_out <= 8'd0;
            endcase
        end
        else
            reg_data_out <= 8'd0;
    end

    always @(posedge sampleclk) begin
        signal_in_r <= signal_in;
        
        case (reg_config[`EDGE_SENSITIVITY])
            `LOW_TO_HIGH : 
                triggered <= ~signal_in_r && signal_in; 

            `HIGH_TO_LOW : 
                triggered <= signal_in_r && ~signal_in;
        endcase
    end

    assign trigger = triggered;

endmodule
`default_nettype wire