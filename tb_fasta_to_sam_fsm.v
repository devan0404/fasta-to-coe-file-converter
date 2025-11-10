`timescale 1ns/1ps

module tb_fasta_to_sam_fsm;

    reg clk;
    reg rst;

    // match DUT parameter ADDR_WIDTH = 15 => address width = 15 bits
    wire [14:0] rom_addr;
    wire [7:0]  rom_data;

    wire [14:0] ram_addr;
    wire [7:0]  ram_data_in;
    wire        ram_we;

    //----------------------------------------
    // Instantiate FSM DUT (explicit port connections)
    //----------------------------------------
    fasta_to_sam_fsm #(.ADDR_WIDTH(15)) dut (
        .clk(clk),
        .rst(rst),
        .rom_addr(rom_addr),
        .rom_data(rom_data),
        .ram_addr(ram_addr),
        .ram_data(ram_data_in),
        .ram_we(ram_we)
    );

    //----------------------------------------
    // Instantiate ROM (REAL IP)
    // Expect ROM IP to have matching address/data widths
    //----------------------------------------
    blk_mem_gen_1 rom_inst (
        .clka(clk),
        .ena(1'b1),       // enable ROM output
        .addra(rom_addr),
        .douta(rom_data)
    );

    //----------------------------------------
    // Instantiate RAM (REAL IP)
    //----------------------------------------
    blk_mem_gen_0 ram_inst (
        .clka(clk),
        .ena(1'b1),       // enable RAM (allow writes/reads)
        .wea(ram_we),
        .addra(ram_addr),
        .dina(ram_data_in),
        .douta()  // not reading back now
    );

    //----------------------------------------
    // Clock generator
    //----------------------------------------
    always #5 clk = ~clk;

    //----------------------------------------
    // Simulation control
    //----------------------------------------
    initial begin
        clk = 0;
        rst = 1;

        #20;
        rst = 0;  // release reset

        @(posedge clk); // allow synchronous ROM to present data for current address

        // Run simulation long enough for ROM->RAM transfer
        #20000;

        $display("SIMULATION COMPLETE.");
        $stop;
    end

    //----------------------------------------
    // OPTIONAL: Monitor RAM writes
    //----------------------------------------
    always @(posedge clk) begin
        if (ram_we) begin
            // display address, hex value and printable char if in printable range
            $write("WRITE -> RAM[%0d] = 0x%02h ", ram_addr, ram_data_in);
            if (ram_data_in >= 8'h20 && ram_data_in <= 8'h7E) begin
                $display("('%c')", ram_data_in);
            end else begin
                $display(" (non-print)");
            end
        end
    end

endmodule
