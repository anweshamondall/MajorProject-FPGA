`timescale 1ns / 1ps
// Testbench for lightHashDES - Single input character: '0'

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

    // Generate 10 ns clock
    always #5 clk = ~clk;

    // Task to send one byte
    task send_byte(input [7:0] byte_val);
    begin
        @(posedge clk);
        M <= byte_val;
        M_valid <= 1;
        @(posedge clk);
        M_valid <= 0;
        #10;
    end
    endtask

    initial begin
        $dumpfile("wave_zero.vcd");
        $dumpvars(0, testBenchStrings);

        $display("==== START TESTBENCH (Input = '0') ====");

        clk = 0; rst_n = 0; M_valid = 0; M = 0; input_length = 0;

        // Reset
        #20;
        rst_n = 1;
        #10;

        // ---- TEST: Input '0' only ----
        $display("\n---- TEST: Sending '0' ----");
        input_length = 1; // Only one byte

        send_byte(8'h30); // '0'

        wait (hash_ready == 1);
        #10;
        $display("Digest for '0' = %h", digest);

        #50;
        $display("==== END OF SIMULATION ====");
        $finish;
    end

endmodule
