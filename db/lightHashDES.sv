// lightHashDES.v (universal version for all testbenches)
module lightHashDES(
    input              clk,
    input              M_valid,
    input              rst_n,
    input      [7:0]   M,
    input     [63:0]   input_length,
    output reg         hash_ready,
    output reg [31:0]  digest
);

    // Initial values (IV)
    localparam [3:0] Iv_h[7:0] = '{4'hF,4'h3,4'hC,4'h2,4'h9,4'hD,4'h4,4'hB};

    reg busy;
    reg [63:0] counter;
    reg [7:0] M_t;
    reg M_valid_t;
    reg [31:0] H;
    wire [31:0] H_fb;

    // Pack/unpack 32-bit internal state
    wire [7:0][3:0] H_array;
    wire [7:0][3:0] H_out_array;
    assign {H_array[7],H_array[6],H_array[5],H_array[4],
            H_array[3],H_array[2],H_array[1],H_array[0]} = H;
    assign H_fb = {H_out_array[7],H_out_array[6],H_out_array[5],H_out_array[4],
                   H_out_array[3],H_out_array[2],H_out_array[1],H_out_array[0]};

    // Instantiate the iteration core
    HashIteration main (
        .M(M_t),
        .h(H_array),
        .h_out(H_out_array)
    );

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_ready <= 0;
            busy <= 0;
            counter <= 0;
            M_t <= 0;
            M_valid_t <= 0;
            H <= {Iv_h[7],Iv_h[6],Iv_h[5],Iv_h[4],Iv_h[3],Iv_h[2],Iv_h[1],Iv_h[0]};
            digest <= 0;
        end else begin
            if (!busy && M_valid) begin
                // Start new hash
                busy <= 1;
                counter <= input_length;
                hash_ready <= 0;
                H <= {Iv_h[7],Iv_h[6],Iv_h[5],Iv_h[4],Iv_h[3],Iv_h[2],Iv_h[1],Iv_h[0]};
                M_t <= M;
                M_valid_t <= 1;
            end else if (busy) begin
                if (counter > 0) begin
                    H <= H_fb;
                    counter <= counter - 1;
                    M_t <= M;
                    M_valid_t <= M_valid;
                end

                if (counter == 1) begin
                    busy <= 0;
                    hash_ready <= 1;
                    digest <= H_fb;
                end
            end else begin
                M_valid_t <= 0;
                hash_ready <= 0;
            end
        end
    end
endmodule
