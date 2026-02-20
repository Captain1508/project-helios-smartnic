`timescale 1ns/1ps

module tb_stats_engine;

    localparam CLK_PERIOD = 10;

    logic        clk, rst_n;
    logic        packet_valid, packet_start;
    logic [7:0]  byte_count;
    logic [63:0] total_packets, total_bytes;

    stats_engine dut (  
        .clk(clk),
        .rst_n(rst_n),                
        .packet_valid(packet_valid),
        .packet_start(packet_start),
        .byte_count(byte_count),
        .total_packets(total_packets),
        .total_bytes(total_bytes)
    );

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
         $display("========================================");
        $display("Stats Engine Testbench");
        $display("========================================\n");
        packet_valid = 0;
        packet_start = 0;
        byte_count = 0;
        rst_n = 0;
        #(CLK_PERIOD*2);
        #1;
        rst_n = 1;
        @(posedge clk);
        #1;

        // TEST 1: Reset
        $display("[TEST 1] Reset Verification");
        if(total_packets == 0 && total_bytes == 0) begin
            $display("Pass: Both counter 0");
        end else begin
            $display("Fail: Expected both 0 got %0d , %0d",total_packets,total_bytes);
        end
        // TEST 2: Packet counting (3 packets)
        $display("[TEST 2] Packet Counter Verification");

        packet_start = 1;
        @(posedge clk); #1;
        packet_start = 0;
        @(posedge clk); #1;
        packet_start = 1; 
        @(posedge clk); #1;
        packet_start = 0;
        @(posedge clk); #1;
        packet_start = 1;
        @(posedge clk); #1;
        packet_start = 0;
        @(posedge clk); #1;
        if(total_packets == 3) begin
            $display("Pass: Packter counter increments to 3");
        end else begin
            $display("Fail: Expected 3 got %0d",total_packets);
        end
        // TEST 3: Byte accumulation
        $display("[TEST 3] Byte Counter Verification");
        packet_valid = 1;
        byte_count = 8;
        @(posedge clk); #1;
        packet_valid = 1;
        byte_count = 32;
        @(posedge clk); #1;
        packet_valid = 1;
        byte_count = 4;
        @(posedge clk); #1;
        if(total_bytes == 44) begin
            $display("Pass: Total bytes count increments to %0d",total_bytes);
        end else begin
            $display("Fail: Expected 44 got %0d",total_bytes);
        end

        packet_valid = 0;
        packet_start = 0;
        byte_count = 0;
        @(posedge clk); #1;
        // TEST 4: Same-cycle packet_start + packet_valid
        $display("[Test 4] Both Counter Simultaneous Verification");
        packet_start = 1;
        packet_valid = 1;
        byte_count = 64;
        @(posedge clk);
        #1;
        packet_start = 0;
        packet_valid = 0;
        @(posedge clk);
        #1;
        if(total_packets == 4 && total_bytes == 108) begin
            $display("Pass: Both counter works in same cycle");
        end else begin
            $display("Fail: Expected both 4 and 108 got total packets : %0d , total bytes : %0d",total_packets,total_bytes);
        end 
        $finish;
    end

endmodule