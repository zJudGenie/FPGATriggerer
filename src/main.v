module led(
    input clkin,
    input signal_in,

    input uart_rx,
    output uart_tx,

    output wire [5:0] led,
    output trigger_out,
    output target_reset
);

wire reset = 0;

wire clkin_pll;

Gowin_rPLL pll(
    .clkout(clkin_pll), //output clkout
    .clkin(clkin) //input clkin
);

wire [7:0] reg_usb_data_in;
wire byte_ready;

uart u(
    clkin,
    uart_rx,
    uart_tx,

    byte_ready,
    reg_usb_data_in
);

wire [7:0]  reg_cmd;
wire [15:0] reg_bytecount;
wire [7:0]  reg_data_in;
reg  [7:0]  reg_data_out;
wire        reg_read;
wire        reg_write;

// Temporary solution, reading from register is not implemented completely
wire [7:0]  data_read_1;
wire [7:0]  data_read_2;
wire [7:0]  data_read_3;
wire [7:0]  data_read_4;
always @(posedge clkin) begin
    reg_data_out <= data_read_1 | data_read_2 | data_read_3 | data_read_4;
end

cmd_handler cmd_reader(
    clkin,

    //UART inputs
    byte_ready,
    reg_usb_data_in,

    //Command handler outputs
    reg_cmd,
    reg_bytecount,
    reg_data_in,
    reg_data_out,
    reg_read,
    reg_write
);

wire trigger_in;

digital_edge_detector sampler(
    reset,

    // Inputs
    clkin_pll,
    signal_in,

    clkin,
    reg_cmd,
    reg_bytecount,
    reg_data_in,
    data_read_1,
    reg_read,
    reg_write,

    // Outputs
    trigger_in
);

wire delayer_out;

delay_module delayer(
    reset,

    // Inputs
    clkin_pll,
    trigger_in,

    clkin,
    reg_cmd,
    reg_bytecount,
    reg_data_in,
    data_read_2,
    reg_read,
    reg_write,

    // Outputs
    delayer_out
);

pulse_extender extender(
    reset,

    // Inputs
    clkin_pll,
    delayer_out,

    clkin,
    reg_cmd,
    reg_bytecount,
    reg_data_in,
    data_read_3,
    reg_read,
    reg_write,

    // Outputs
    trigger_out
);

target_resetter resetter(
    reset,

    clkin,
    reg_cmd,
    reg_bytecount,
    reg_data_in,
    data_read_4,
    reg_read,
    reg_write,

    // Outputs
    target_reset
);

assign led = ~(6'd0);

endmodule