`timescale 1ns / 1ps
// Testbench for lightHashDES - String input test

module testBenchStrings;

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

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // Task to send 1 byte with proper timing
    task send_byte(input [7:0] byte_val);
    begin
        @(posedge clk);
        M <= byte_val;
        M_valid <= 1;
        @(posedge clk);
        M_valid <= 0;
        #10; // small delay between bytes
    end
    endtask

    initial begin
        // Enable waveform dump
        $dumpfile("testBenchStrings.vcd");
        $dumpvars(0, testBenchStrings);

        $display("==== START TESTBENCH ====");

        // Initial values
        clk = 0; rst_n = 0; M_valid = 0; M = 0; input_length = 0;

        // Reset phase
        #20;
        rst_n = 1;
        #10;

        // ---- TEST 1: 'ABCD' ----
        $display("\n---- TEST 1: String 'ABCD' ----");
        input_length = 4;
        send_byte("A");
        send_byte("B");
        send_byte("C");
        send_byte("D");

        wait (hash_ready == 1);
        #10;
        $display("Digest ('ABCD') = %h", digest);

        // ---- TEST 2: 'HELLO' ----
        $display("\n---- TEST 2: String 'HELLO' ----");
        rst_n = 0; #20; rst_n = 1;
        input_length = 5;
        #10;
        send_byte("H");
        send_byte("E");
        send_byte("L");
        send_byte("L");
        send_byte("O");

        wait (hash_ready == 1);
        #10;
        $display("Digest ('HELLO') = %h", digest);

        #100;
        $display("==== END OF SIMULATION ====");
        $finish;
    end

endmodule
