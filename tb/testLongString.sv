`timescale 1ns / 1ps
// Testbench: Long string stress test for lightHashDES
module testLongString;

    reg clk;
    reg rst_n;
    reg M_valid;
    reg [7:0] M;
    reg [63:0] input_length;

    wire hash_ready;
    wire [31:0] digest;

    // Instantiate DUT
    lightHashDES dut (
        .clk(clk),
        .M_valid(M_valid),
        .rst_n(rst_n),
        .M(M),
        .input_length(input_length),
        .hash_ready(hash_ready),
        .digest(digest)
    );

    // Clock generation (10 ns period)
    always #5 clk = ~clk;

    // Task to send one byte
    task send_byte(input [7:0] byte_val);
    begin
        @(posedge clk);
        M <= byte_val;
        M_valid <= 1;
        @(posedge clk);
        M_valid <= 0;
    end
    endtask

    integer i;
    reg [8*16-1:0] long_str;

    initial begin
        // Enable waveform dump
        $dumpfile("testLongString.vcd");
        $dumpvars(0, testLongString);

        $display("==== START LONG STRING TEST ====");

        // Initialize
        clk = 0;
        rst_n = 0;
        M_valid = 0;
        M = 0;

        // "LIGHTWEIGHTHASH" has 14 characters
        long_str = "LIGHTWEIGHTHASH";
        input_length = 14;

        // Apply reset
        #20;
        rst_n = 1;
        #20;

        $display("---- Sending String: 'LIGHTWEIGHTHASH' ----");

        // Feed characters MSB-first (most readable order)
        for (i = 0; i < 14; i = i + 1) begin
            send_byte(long_str[8*(13 - i) +: 8]);
            #10;  // brief delay between characters
        end

        // Wait for hash_ready
        @(posedge hash_ready);
        #10;

        $display("✅ Digest ('LIGHTWEIGHTHASH') = %h", digest);
        $display("==== END OF SIMULATION ====");

        #20;
        $finish;
    end

endmodule
