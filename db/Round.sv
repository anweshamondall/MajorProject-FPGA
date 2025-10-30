// Round_fixed.sv
// Computes h_out[i] = ROTL( (h_in[i+2] ^ s_box_out), floor(i/2) ) for i in 0..7
// Uses flat 32-bit h_in/h_out (8 nibbles concatenated {h7,...,h0})

module Round (
    input  [3:0]  s_box_out,
    input  [31:0] h_in,
    output reg [31:0] h_out
);

    // Internal split of nibbles (h_in_n[0] is lowest nibble H0)
    reg [3:0] h_in_n [0:7];
    reg [3:0] h_out_n [0:7];

    integer i;
    reg [3:0] temp;
    reg [1:0] rot; // 0..3

    // combinational logic: extract nibbles, compute each out nibble, then pack
    always @(*) begin
        // unpack h_in into h_in_n (be careful with concatenation order)
        // h_in is {H7, H6, H5, H4, H3, H2, H1, H0}
        h_in_n[7] = h_in[31:28];
        h_in_n[6] = h_in[27:24];
        h_in_n[5] = h_in[23:20];
        h_in_n[4] = h_in[19:16];
        h_in_n[3] = h_in[15:12];
        h_in_n[2] = h_in[11:8];
        h_in_n[1] = h_in[7:4];
        h_in_n[0] = h_in[3:0];

        // compute each output nibble
        for (i = 0; i < 8; i = i + 1) begin
            // source index (i+2) mod 8
            temp = h_in_n[(i + 2) % 8] ^ s_box_out;
            rot = (i/2); // floor(i/2): 0,0,1,1,2,2,3,3

            // rotate-left by rot over 4 bits
            if (rot == 0)
                h_out_n[i] = temp & 4'hF;
            else
                h_out_n[i] = ( ((temp << rot) | (temp >> (4 - rot))) & 4'hF );
        end

        // pack back into 32-bit h_out {H7,...,H0}
        h_out = {h_out_n[7], h_out_n[6], h_out_n[5], h_out_n[4],
                 h_out_n[3], h_out_n[2], h_out_n[1], h_out_n[0]};
    end

endmodule
