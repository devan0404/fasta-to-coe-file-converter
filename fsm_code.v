`timescale 1ns / 1ps
module fasta_to_sam_fsm #(
    parameter ADDR_WIDTH = 15,
    parameter MAX_ID_DIGITS = 6
)(
    input  wire                  clk,
    input  wire                  rst,

    // ROM (FASTA input)
    output reg  [ADDR_WIDTH-1:0] rom_addr,
    input  wire [7:0]            rom_data,

    // RAM (SAM output)
    output reg  [ADDR_WIDTH-1:0] ram_addr,
    output reg  [7:0]            ram_data,
    output reg                   ram_we
);

    // ---- 4 States ----
    localparam S0_HEADER = 2'd0;   // write SAM header once
    localparam S1_READLN = 2'd1;   // write "read<ID> 4 * 0 0 * * "
    localparam S2_SEQ    = 2'd2;   // write sequence from ROM until newline
    localparam S3_NEXT   = 2'd3;   // increment ID, go to next read or stop

    reg [1:0] state;

    // --- Header text ---
    localparam HDR_LEN = 23;
    reg [7:0] hdr [0:HDR_LEN-1];
    reg [5:0] hdr_idx;

    // --- Constant SAM middle ---
    localparam C_LEN = 12;
    reg [7:0] ctext [0:C_LEN-1];
    reg [3:0] c_idx;

    // prefix "read"
    reg [2:0] p_idx;

    // Read ID counter and buffer
    reg [31:0] read_id;
    reg [7:0]  id_buf [0:MAX_ID_DIGITS-1];
    reg [2:0]  id_len;
    reg [2:0]  id_idx;

    integer i, v, k;

    // init ROM text arrays
    initial begin
        hdr[0]  = "@"; hdr[1]  = "H"; hdr[2]  = "D"; hdr[3]  = " ";
        hdr[4]  = "V"; hdr[5]  = "N"; hdr[6]  = ":"; hdr[7]  = "1";
        hdr[8]  = "."; hdr[9]  = "0"; hdr[10] = " "; hdr[11] = "S";
        hdr[12] = "O"; hdr[13] = ":"; hdr[14] = "u"; hdr[15] = "n";
        hdr[16] = "s"; hdr[17] = "o"; hdr[18] = "r"; hdr[19] = "t";
        hdr[20] = "e"; hdr[21] = "d"; hdr[22] = "\n";

        ctext[0]  = " "; ctext[1]  = "4"; ctext[2]  = " ";
        ctext[3]  = "*"; ctext[4]  = " "; ctext[5]  = "0";
        ctext[6]  = " "; ctext[7]  = "0"; ctext[8]  = " ";
        ctext[9]  = "*"; ctext[10] = " "; ctext[11] = "*";
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state    <= S0_HEADER;
            rom_addr <= 0;
            ram_addr <= 0;
            ram_we   <= 0;
            hdr_idx  <= 0;
            p_idx    <= 0;
            c_idx    <= 0;
            id_idx   <= 0;
            id_len   <= 0;
            read_id  <= 1;
        end else begin
            ram_we <= 0;

            case(state)

                // ---- S0: Write header ----
                S0_HEADER: begin
                    if (hdr_idx < HDR_LEN) begin
                        ram_we   <= 1;
                        ram_data <= hdr[hdr_idx];
                        ram_addr <= ram_addr + 1;
                        hdr_idx  <= hdr_idx + 1;
                    end else begin
                        state <= S1_READLN;
                    end
                end

                // ---- S1: "read<ID> 4 * 0 0 * * " ----
                S1_READLN: begin
                    // First write "read"
                    if (p_idx < 4) begin
                        ram_we <= 1;
                        ram_addr <= ram_addr + 1;
                        case(p_idx)
                            0: ram_data <= "r";
                            1: ram_data <= "e";
                            2: ram_data <= "a";
                            3: ram_data <= "d";
                        endcase
                        p_idx <= p_idx + 1;
                    end
                    
                    // Convert ID once p_idx==4
                    else if (id_len == 0) begin
                        v = read_id;
                        k = 0;
                        if (v == 0) begin
                            id_buf[0] = "0";
                            id_len = 1;
                        end else begin
                            while (v != 0 && k < MAX_ID_DIGITS) begin
                                id_buf[k] = "0" + (v % 10);
                                v = v / 10;
                                k = k + 1;
                            end
                            id_len = k;
                            for (i = 0; i < id_len/2; i=i+1) begin
                                {id_buf[i], id_buf[id_len-1-i]} = {id_buf[id_len-1-i], id_buf[i]};
                            end
                        end
                    end

                    // Write ID
                    else if (id_idx < id_len) begin
                        ram_we   <= 1;
                        ram_data <= id_buf[id_idx];
                        ram_addr <= ram_addr + 1;
                        id_idx   <= id_idx + 1;
                    end

                    // Write constant tail
                    else if (c_idx < C_LEN) begin
                        ram_we <= 1;
                        ram_data <= ctext[c_idx];
                        ram_addr <= ram_addr + 1;
                        c_idx <= c_idx + 1;
                    end

                    // go copy sequence
                    else begin
                        state <= S2_SEQ;
                    end
                end

                // ---- S2: Copy sequence until newline ----
                S2_SEQ: begin
                    ram_we   <= 1;
                    ram_data <= rom_data;
                    ram_addr <= ram_addr + 1;
                    rom_addr <= rom_addr + 1;

                    if (rom_data == 8'h0A)
                        state <= S3_NEXT;
                end

                // ---- S3: Next read or restart ----
                S3_NEXT: begin
                    // reset counters
                    p_idx  <= 0;
                    id_idx <= 0;
                    id_len <= 0;
                    c_idx  <= 0;
                    read_id <= read_id + 1;
                    state <= S1_READLN;
                end

            endcase
        end
    end

//If rom_data sees 8'h0A, end of sam file reached, stop reading further
    always @(posedge clk) begin
        if (rom_data == 8'h0A && state == S2_SEQ) begin
            // Stop further processing by staying in current state
            state <= S3_NEXT; // Move to next read state
        end
    end 

endmodule
