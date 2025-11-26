// top_fpga_lighthash_uart.sv
// User types a word over UART; digest shown on 7-seg.

module top_fpga_lighthash_uart(
    input        CLK100MHZ,
    input        btnC,      // reset (active-high)
    input        uart_rx,   // from Nexys USB-UART RX pin
    output [6:0] seg,
    output       dp,
    output [7:0] an
);

    wire rst_n = ~btnC;

    // ---------- UART receiver ----------
    wire        rx_valid;
    wire [7:0]  rx_byte;

    uart_rx #(
        .CLK_FREQ(100_000_000),
        .BAUD(115200)
    ) u_rx (
        .clk       (CLK100MHZ),
        .rst_n     (rst_n),
        .rx        (uart_rx),
        .data_valid(rx_valid),
        .data_byte (rx_byte)
    );

    // ---------- Message buffer ----------
    localparam integer MAX_LEN = 32;
    reg [7:0] msg_mem [0:MAX_LEN-1];
    reg [5:0] msg_len;      // 0..32

    // ---------- Hash core signals ----------
    reg         M_valid;
    reg  [7:0]  M;
    reg  [63:0] input_length;
    wire        hash_ready;
    wire [31:0] digest;

    lightHashDES hash_core (
        .clk          (CLK100MHZ),
        .M_valid      (M_valid),
        .rst_n        (rst_n),
        .M            (M),
        .input_length (input_length),
        .hash_ready   (hash_ready),
        .digest       (digest)
    );

    // ---------- Control FSM ----------
    reg [1:0] state;
    reg [5:0] send_index;

    localparam S_COLLECT = 2'd0;
    localparam S_SEND    = 2'd1;
    localparam S_WAIT    = 2'd2;
    localparam S_DONE    = 2'd3;

    // simple slow enable so M_valid is visible to core
    reg [19:0] slow_cnt;
    wire slow_en = (slow_cnt == 20'd0);

    always @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n)
            slow_cnt <= 20'd0;
        else
            slow_cnt <= slow_cnt + 1;
    end

    integer i;

    always @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_COLLECT;
            msg_len      <= 0;
            send_index   <= 0;
            M_valid      <= 1'b0;
            M            <= 8'd0;
            input_length <= 64'd0;
        end else begin
            M_valid <= 1'b0; // default

            case (state)
                // Collect chars from UART until Enter
                S_COLLECT: begin
                    if (rx_valid) begin
                        if (rx_byte == 8'h0D || rx_byte == 8'h0A) begin
                            // Enter pressed, finalize message
                            input_length <= msg_len;
                            send_index   <= 0;
                            state        <= S_SEND;
                        end else if (msg_len < MAX_LEN) begin
                            msg_mem[msg_len] <= rx_byte;
                            msg_len          <= msg_len + 1;
                        end
                    end
                end

                // Send stored bytes to hash core
                S_SEND: begin
                    if (slow_en) begin
                        if (send_index < msg_len) begin
                            M       <= msg_mem[send_index];
                            M_valid <= 1'b1;   // one slow_en pulse per byte
                            send_index <= send_index + 1;
                        end else begin
                            state <= S_WAIT;
                        end
                    end
                end

                // Wait for hash_ready
                S_WAIT: begin
                    if (hash_ready)
                        state <= S_DONE;
                end

                // Stay here; digest is stable on display.
                S_DONE: begin
                    // Optional: reset logic to allow new word without reset button
                    // For now, user can press btnC to type a new word.
                end

                default: state <= S_COLLECT;
            endcase
        end
    end

    // ---------- 7-seg display ----------
    sevenseg_driver u_disp (
        .clk   (CLK100MHZ),
        .value (digest),
        .an    (an),
        .seg   (seg),
        .dp    (dp)
    );

endmodule
