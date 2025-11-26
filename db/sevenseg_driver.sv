// sevenseg_driver.sv
// Shows 32-bit value as 8 hex digits on Nexys-4 DDR 7-seg display

module sevenseg_driver(
    input        clk,         // 100 MHz clock
    input [31:0] value,       // digest to display
    output reg [7:0] an,      // anode lines (active-low)
    output [6:0] seg,         // segment lines (active-low)
    output       dp           // decimal point (off)
);

    reg  [2:0]  digit_sel = 3'b000;
    reg  [15:0] refresh_counter = 16'd0;
    reg  [3:0]  current_nibble;

    assign dp = 1'b1; // active-low, so 1 = off

    // refresh / multiplex counter
    always @(posedge clk) begin
        refresh_counter <= refresh_counter + 1;
        digit_sel       <= refresh_counter[15:13];
    end

    // select which nibble of "value" to show
    always @* begin
        case (digit_sel)
            3'd0: current_nibble = value[3:0];     // rightmost
            3'd1: current_nibble = value[7:4];
            3'd2: current_nibble = value[11:8];
            3'd3: current_nibble = value[15:12];
            3'd4: current_nibble = value[19:16];
            3'd5: current_nibble = value[23:20];
            3'd6: current_nibble = value[27:24];
            3'd7: current_nibble = value[31:28];   // leftmost
            default: current_nibble = 4'h0;
        endcase
    end

    // one-hot anode enable (active-low)
    always @* begin
        an = 8'b1111_1111;
        an[digit_sel] = 1'b0;
    end

    // nibble → segments
    hex_to_7seg u_hex (
        .hex(current_nibble),
        .seg(seg)
    );

endmodule
