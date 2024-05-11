module cmd_handler (
    input  wire          clk_usb,

    input  wire          byte_ready,
    input  wire [7:0]    reg_usb_data_in,

    // Serial Interface registers
    output reg  [7:0]    reg_cmd,  // Command to be executed
    output reg  [15:0]   reg_bytecount, // Byte number to be read or written
    output reg  [7:0]    reg_data_in,   // Data read from serial after header
    input  wire [7:0]    reg_data_out,  // Data to write to serial
    output reg           reg_read,      // Read flag
    output reg           reg_write     // Write flag
);

    `define CMD_MODE_MASK   8'b11_000000
    `define CMD_MASK        8'b00_111111

    `define MODE_READ       2'b10
    `define MODE_WRITE      2'b11


    `define STATE_WAIT_HEADER   0
    `define STATE_READ_DATA_LEN 1
    `define STATE_READ_BYTES    2 // In MODE_WRITE we read bytes from serial to write it in registers
    `define STATE_WRITE_BYTES   3 // in MODE_READ we read from register and we write to serial

    reg [2:0] handler_state = `STATE_WAIT_HEADER;

    reg [1:0]   cmd_mode;
    reg [15:0]  data_len;
    reg         curr_data_len_byte;

    always @(posedge clk_usb) begin
        case (handler_state)

            // Disables the reg_write flag at the end of the clock cycle after reading reg_data_in from modules
            `STATE_READ_BYTES: begin
                if (reg_write == 1) begin //delay by 1 clock cycle the bytecount increment to avoid starting to write to byte 1
                    reg_bytecount <= reg_bytecount + 16'd1;
                end

                reg_write       <= 0;
            end

            // TODO implementation to be completed
            `STATE_WRITE_BYTES: begin
                //reg_usb_data_out <= reg_data_out;
                reg_read <= 1; // I want to read data from registers
                
                // I've read all the bytes I requested
                if (reg_bytecount == data_len)
                    handler_state <= `STATE_WAIT_HEADER;
                
                reg_bytecount <= reg_bytecount + 16'd1;
            end
            default: ;
        endcase

        // Serial reader FSM that evolve on each byte received
        if (byte_ready) begin
            case (handler_state)
                `STATE_WAIT_HEADER: begin
                    reg_cmd    <= reg_usb_data_in & `CMD_MASK;
                    cmd_mode   <= reg_usb_data_in[7:6];

                    data_len            <= 16'd0;
                    curr_data_len_byte  <= 2'd0;

                    reg_bytecount   <= 0;
                    
                    handler_state   <= `STATE_READ_DATA_LEN;
                end
                `STATE_READ_DATA_LEN: begin
                    data_len[curr_data_len_byte*8 +: 8] <= reg_usb_data_in;

                    // After reading two bytes of data_len we process the command
                    if (curr_data_len_byte == 1) begin
                        case (cmd_mode)
                            `MODE_READ:     handler_state <= `STATE_WRITE_BYTES;
                            `MODE_WRITE:    handler_state <= `STATE_READ_BYTES;
                            default:        handler_state <= `STATE_WAIT_HEADER;
                        endcase

                         // data_len has been fully read, decrement by 1 as reg_bytecount starts from 0
                        data_len <= data_len - 16'd1;
                    end

                    curr_data_len_byte <= curr_data_len_byte + 1'd1;
                end
                `STATE_READ_BYTES: begin
                    reg_data_in <= reg_usb_data_in;
                    reg_write <= 1; // Data can now be written to the registers
                    
                    if (reg_bytecount == data_len) begin
                        handler_state <= `STATE_WAIT_HEADER;
                    end
                end
                default: ;
            endcase
        end
    end


endmodule