`timescale 1ns / 1ps
// Testbench: Empty string and single-character test
module testBenchEmptyAndOneChar;

    // DUT inputs
    reg clk;
    reg rst_n;
    reg M_valid;
    reg [7:0] M;
    reg [63:0] input_length;

    // DUT outputs
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

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // Task to apply a byte
    task send_byte(input [7:0] byte_val);
    begin
        @(posedge clk);
        M <= byte_val;
        M_valid <= 1;
        @(posedge clk);
        M_valid <= 0;
    end
    endtask

    initial begin
        $display("---- TEST 1: Empty string ----");
        clk = 0; rst_n = 0; M_valid = 0; M = 0; input_length = 0;
        #20 rst_n = 1;

        // Empty input
        @(posedge clk);
        input_length = 0;
        M_valid = 0;
        #100;

        $display("Digest (Empty): %h", digest);

        $display("---- TEST 2: Single character 'A' ----");
        rst_n = 0; #20; rst_n = 1;
        input_length = 1;
        send_byte("A");
        wait (hash_ready);
        #10;
        $display("Digest ('A'): %h", digest);

        #50;
        $finish;
    end

endmodule
