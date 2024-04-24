module led(
    input clkin,
    input signal_in,

    input uart_rx,
    output uart_tx,

    output wire [5:0] led,
    output trigger_out
);

wire reset = 0;

wire clkin_pll;

Gowin_rPLL pll(
    .clkout(clkin_pll), //output clkout
    .clkin(clkin) //input clkin
);

wire [7:0] reg_usb_data_in;
wire byte_ready;
wire uart_led;

uart u(
    clkin,
    uart_rx,
    uart_tx,
    uart_led,

    byte_ready,
    reg_usb_data_in
);

wire [7:0]  reg_cmd;
wire [15:0] reg_bytecount;
wire [7:0]  reg_data_in;
reg  [7:0]  reg_data_out;
wire        reg_read;
wire        reg_write;

wire [7:0]  data_read;
always @(posedge clkin) reg_data_out <= data_read;

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

wire [5:0] edge_detect_led;

digital_edge_detector sampler(
    reset,

    clkin_pll,
    signal_in,

    clkin,
    reg_cmd,
    reg_bytecount,
    reg_data_in,
    data_read,
    reg_read,
    reg_write,

    trigger_out,
    edge_detect_led
);

assign led = edge_detect_led;

endmodule