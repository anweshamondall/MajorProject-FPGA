// uart_rx.sv - simple UART receiver (8N1)
// Assumes clk = 100 MHz, baud = 115200

module uart_rx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD     = 115200
)(
    input       clk,
    input       rst_n,
    input       rx,          // UART RX pin from PC
    output reg  data_valid,  // 1 for one clk when data_byte is valid
    output reg [7:0] data_byte
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD;

    localparam [2:0]
        S_IDLE  = 3'd0,
        S_START = 3'd1,
        S_DATA  = 3'd2,
        S_STOP  = 3'd3,
        S_DONE  = 3'd4;

    reg [2:0] state = S_IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0]  bit_index = 0;
    reg [7:0]  rx_shift  = 8'd0;
    reg        rx_sync   = 1'b1;

    // Simple sync (optional)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_sync <= 1'b1;
        else
            rx_sync <= rx;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            clk_count  <= 0;
            bit_index  <= 0;
            rx_shift   <= 8'd0;
            data_byte  <= 8'd0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0; // default

            case (state)
                S_IDLE: begin
                    if (rx_sync == 1'b0) begin // start bit
                        state     <= S_START;
                        clk_count <= 0;
                    end
                end

                S_START: begin
                    if (clk_count == (CLKS_PER_BIT/2)) begin
                        // sample mid-start bit
                        if (rx_sync == 1'b0) begin
                            clk_count <= 0;
                            bit_index <= 0;
                            state     <= S_DATA;
                        end else begin
                            state <= S_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                S_DATA: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count          <= 0;
                        rx_shift[bit_index]<= rx_sync;
                        if (bit_index == 3'd7) begin
                            bit_index <= 0;
                            state     <= S_STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                S_STOP: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        state      <= S_DONE;
                        clk_count  <= 0;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                S_DONE: begin
                    data_byte  <= rx_shift;
                    data_valid <= 1'b1;
                    state      <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
