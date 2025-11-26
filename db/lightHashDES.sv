// lightHashDES.sv - streaming, M_valid-gated, 32-bit digest
module lightHashDES(
    input  logic        clk,
    input  logic        rst_n,          // active-low reset
    input  logic        M_valid,        // 1 when M has a valid byte
    input  logic [7:0]  M,              // input byte
    input  logic [63:0] input_length,   // number of bytes to process
    output logic        hash_ready,     // 1 when digest is ready
    output logic [31:0] digest          // 8 nibbles = 32-bit digest
);

    // Initial vector (8 nibbles)
    localparam logic [3:0] IV_H[7:0] = '{4'hF,4'h3,4'hC,4'h2,4'h9,4'hD,4'h4,4'hB};

    // Internal state
    logic        busy;
    logic [63:0] counter;
    logic [7:0]  M_t;
    logic        M_valid_t;
    logic [31:0] H;
    logic [31:0] H_fb;

    // 32-bit state as 8 × 4-bit nibbles
    logic [7:0][3:0] H_array;
    logic [7:0][3:0] H_out_array;

    assign {H_array[7],H_array[6],H_array[5],H_array[4],
            H_array[3],H_array[2],H_array[1],H_array[0]} = H;

    assign H_fb = {H_out_array[7],H_out_array[6],H_out_array[5],H_out_array[4],
                   H_out_array[3],H_out_array[2],H_out_array[1],H_out_array[0]};

    // Core hash iteration
    HashIteration core (
        .M    (M_t),
        .h    (H_array),
        .h_out(H_out_array)
    );

    // Sequential control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy       <= 1'b0;
            counter    <= 64'd0;
            M_t        <= 8'd0;
            M_valid_t  <= 1'b0;
            H          <= {IV_H[7],IV_H[6],IV_H[5],IV_H[4],
                           IV_H[3],IV_H[2],IV_H[1],IV_H[0]};
            digest     <= 32'd0;
            hash_ready <= 1'b0;
        end else begin
            // default: clear ready once seen
            if (hash_ready)
                hash_ready <= 1'b0;

            // start condition: first valid byte when not busy
            if (!busy && M_valid) begin
                busy       <= 1'b1;
                counter    <= input_length;
                H          <= {IV_H[7],IV_H[6],IV_H[5],IV_H[4],
                               IV_H[3],IV_H[2],IV_H[1],IV_H[0]};
                M_t        <= M;
                M_valid_t  <= 1'b1;
            end
            else if (busy) begin
                // sample input for next cycle
                M_t       <= M;
                M_valid_t <= M_valid;

                // consume a byte only when previous cycle had M_valid = 1
                if (M_valid_t && counter > 0) begin
                    H       <= H_fb;
                    counter <= counter - 1;
                end

                // just consumed the last byte
                if (M_valid_t && counter == 64'd1) begin
                    busy       <= 1'b0;
                    hash_ready <= 1'b1;
                    digest     <= H_fb;
                end
            end
        end
    end

endmodule
