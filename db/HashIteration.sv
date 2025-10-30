// HashIteration_fixed.sv
// Given byte M and 32-bit state h (8 x 4-bit nibbles),
// compute 4 rounds of Round(...) to produce h_out.

module HashIteration (
    input  [7:0]  M,
    input  [31:0] h,
    output [31:0] h_out
);

    // s-box output (4 bits)
    wire [3:0] s_box_out;

    // Compute M6 vector as in original: {M[5], M[7]^M[2], M[3], M[0], M[4]^M[1], M[6]}
    wire [5:0] M6;
    assign M6 = {M[5], (M[7] ^ M[2]), M[3], M[0], (M[4] ^ M[1]), M[6]};

    // Instantiate Sbox5 (combinational)
    Sbox5 sbox (
        .in(M6),
        .out(s_box_out)
    );

    // Wires for intermediate 32-bit outputs between rounds
    wire [31:0] h1_out;
    wire [31:0] h2_out;
    wire [31:0] h3_out;

    // Run 4 rounds
    Round round1 (
        .s_box_out(s_box_out),
        .h_in(h),
        .h_out(h1_out)
    );

    Round round2 (
        .s_box_out(s_box_out),
        .h_in(h1_out),
        .h_out(h2_out)
    );

    Round round3 (
        .s_box_out(s_box_out),
        .h_in(h2_out),
        .h_out(h3_out)
    );

    Round round4 (
        .s_box_out(s_box_out),
        .h_in(h3_out),
        .h_out(h_out)
    );

endmodule
