"""
Light Hash Algorithm v2 (DES S-box based) - Python reference implementation

This script implements exactly the same logic as the FPGA design:
- M6 compression
- Sbox5 LUT
- 4 Round() calls per input byte
- 32-bit internal state (8 x 4-bit nibbles)
- IV = 0xF3C29D4B

It is used to cross-verify FPGA results: for any given input message, we can
compute the expected hash in Python and compare it with the digest obtained
from the RTL implementation on the FPGA.
"""

# --------- Low-level helpers ---------

def rotl4(x, r):
    """Rotate a 4-bit value x left by r positions."""
    return ((x << r) | (x >> (4 - r))) & 0xF


def sbox5(in6):
    """
    DES S-box 5 implementation (same mapping as Sbox5_fixed.sv).

    in6: 6-bit integer (0..63)
    returns: 4-bit integer (0..15)
    """
    # Row is {MSB, LSB} = {in[5], in[0]}
    row = (((in6 >> 5) & 1) << 1) | (in6 & 1)
    # Column is in[4:1]
    col = (in6 >> 1) & 0xF

    # table[column][row]
    table = [
        [0x2, 0xE, 0x4, 0xB],  # col 0x0
        [0xC, 0xB, 0x2, 0x8],  # col 0x1
        [0x4, 0x2, 0x1, 0xC],  # col 0x2
        [0x1, 0xC, 0xB, 0x7],  # col 0x3
        [0x7, 0x4, 0xC, 0x1],  # col 0x4
        [0xA, 0x7, 0xD, 0xE],  # col 0x5
        [0xB, 0xD, 0x7, 0x2],  # col 0x6
        [0x6, 0x1, 0x8, 0xD],  # col 0x7
        [0x8, 0x5, 0xF, 0x6],  # col 0x8
        [0x5, 0x0, 0x9, 0xF],  # col 0x9
        [0x3, 0xF, 0xC, 0x0],  # col 0xA
        [0xF, 0xC, 0x5, 0x9],  # col 0xB
        [0xD, 0x3, 0x6, 0xC],  # col 0xC
        [0x0, 0x9, 0x3, 0x4],  # col 0xD
        [0xE, 0x8, 0x0, 0x5],  # col 0xE
        [0x9, 0x6, 0xE, 0x3],  # col 0xF
    ]

    return table[col][row]


def round_func(h, s):
    """
    Software equivalent of Round_fixed.sv

    h: 32-bit state (8 nibbles H0..H7, H0 = lowest nibble)
    s: 4-bit s_box_out
    returns: 32-bit updated state
    """
    # split into nibbles H[0]..H[7]
    H = [(h >> (4 * i)) & 0xF for i in range(8)]
    H_out = [0] * 8

    for i in range(8):
        temp = H[(i + 2) % 8] ^ s
        rot = i // 2  # floor(i/2): 0,0,1,1,2,2,3,3
        H_out[i] = rotl4(temp, rot)

    # pack back into 32-bit word
    out = 0
    for i in range(8):
        out |= (H_out[i] & 0xF) << (4 * i)
    return out


def hash_iteration(h, M):
    """
    One HashIteration over a single byte M (same as HashIteration_fixed.sv).

    h: current 32-bit state
    M: one byte (0..255)
    returns: updated 32-bit state
    """
    # M6 = {M[5], M[7]^M[2], M[3], M[0], M[4]^M[1], M[6]}
    M6 = (
        ((M >> 5) & 1) << 5 |
        (((M >> 7) & 1) ^ ((M >> 2) & 1)) << 4 |
        ((M >> 3) & 1) << 3 |
        ((M >> 0) & 1) << 2 |
        (((M >> 4) & 1) ^ ((M >> 1) & 1)) << 1 |
        ((M >> 6) & 1)
    )

    s = sbox5(M6)

    # 4 rounds, feeding output to input each time
    h1 = round_func(h, s)
    h2 = round_func(h1, s)
    h3 = round_func(h2, s)
    h4 = round_func(h3, s)

    return h4


def compute_hash(msg_bytes):
    """
    Compute the 32-bit hash of an arbitrary-length byte string.

    msg_bytes: Python bytes object (e.g. b"hello")
    returns: 32-bit integer digest
    """
    IV = 0xF3C29D4B
    h = IV
    for b in msg_bytes:
        h = hash_iteration(h, b)
    return h


# --------- Simple CLI for cross-verification ---------

def main():
    print("Light Hash Algorithm v2 - Python reference")
    print("This is for cross-verification with the FPGA implementation.\n")

    while True:
        user_in = input("Enter a message (ASCII) to hash (or just press Enter to quit): ")
        if user_in == "":
            print("Exiting.")
            break

        # Encode as ASCII bytes (same as feeding characters to the hardware)
        msg_bytes = user_in.encode("ascii", errors="strict")

        digest = compute_hash(msg_bytes)
        print(f"Input : {repr(user_in)}")
        print(f"Hash  : 0x{digest:08X}\n")


if __name__ == "__main__":
    main()
