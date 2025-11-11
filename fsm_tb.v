`timescale 1ns/1ps

module tb_fasta_to_sam_fsm();

    parameter ADDR_WIDTH = 16;

    reg clk, rst;
    
    reg enable;
    // --- FSM interface signals ---
    wire [ADDR_WIDTH-1:0] rom_addr;
    wire [7:0]            rom_data;

    wire [ADDR_WIDTH-1:0] ram_addr;
    wire [7:0]            ram_data;
    wire                  ram_we;

    // --- Clock ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Reset ---
    initial begin
        rst = 1;
        #20 rst = 0;
        #20 enable = 0;
    end

    // --- DUT: FSM ---
    fasta_to_sam_fsm #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) DUT (
        .clk(clk),
        .rst(rst),

        .rom_addr(rom_addr),
        .rom_data(rom_data),

        .ram_addr(ram_addr),
        .ram_data(ram_data),
        .ram_we(ram_we)
    );

    // --- ROM (generated from .coe) ---
    // Single-port ROM
    blk_mem_gen_rom ROM (
        .clka(clk),
        .addra(rom_addr),
        .ena(enable),
        .douta(rom_data)
    );

    // --- RAM (write only from FSM) ---
    blk_mem_gen_ram RAM (
        .clka(clk),
        .wea(ram_we),
        .ena(enable),
        .addra(ram_addr),
        .dina(ram_data)
    );

    // --- Monitor writes to RAM ---
    always @(posedge clk) begin
        if (ram_we) begin
            $display("RAM_WRITE: addr=%0d data=%c (0x%h)", 
                ram_addr, ram_data, ram_data);
        end
    end

    // --- Stop after some time ---
    initial begin
        #20000;
        $stop;
    end

endmodule