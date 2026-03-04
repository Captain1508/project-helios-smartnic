`timescale 1ns/1ps

module tb_packet_timestamp_core;

    
    // Parameters
    
    localparam CLK_PERIOD = 10;

    // Signals
    logic        clk;
    logic        rst_n;
    logic        data_valid;
    logic [7:0]  byte_count;
    logic [63:0] current_timestamp;
    logic        packet_start;
    logic [63:0] packet_timestamp;
    logic [63:0] total_packets;
    logic [63:0] total_bytes;

    // DUT Instantiation
    
    packet_timestamp_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(data_valid),
        .byte_count(byte_count),
        .current_timestamp(current_timestamp),
        .packet_start(packet_start),
        .packet_timestamp(packet_timestamp),
        .total_packets(total_packets),
        .total_bytes(total_bytes)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test Stimulus
    initial begin
        $display("========================================");
        $display("Packet Timestamp Core - System Test");
        $display("========================================\n");

        // Initialize
        data_valid = 0;
        byte_count = 0;
        rst_n = 0;
        #(CLK_PERIOD * 2);
        rst_n = 1;
        @(posedge clk);
        #1;

        // TEST 1: Single Packet
        
        $display("[TEST 1] Single Packet");
        data_valid = 1;
        byte_count = 16;
        repeat (5) @(posedge clk);
        #1;
        if(packet_start == 1) begin
            $display(" - packet_start detected");
        end
        data_valid = 0;
        byte_count = 0;
        @(posedge clk);
        #1;
        if(total_packets ==1 && total_bytes == 80) begin
            $display("Pass: total_packets = 1 , total_bytes = 80");
        end else begin
            $display("Fail: Expected total_packets = 1 got %0d , total_bytes = 80 got %0d",total_packets,total_bytes);
        end
        if(packet_timestamp != 0) begin
            $display("Pass: packet_timestamp captured %0d",packet_timestamp);
        end else begin 
            $display("Fail: packet_timestamp not captured");
        end
        $display("  - Current time: %0d cycles\n", current_timestamp);
        // Send packet: data_valid=1 for 5 cycles, byte_count=16
        // Check: packet_start pulses once
        // Check: packet_timestamp captured
        // Check: total_packets = 1
        // Check: total_bytes = 80

        
        // TEST 2: Multiple Packets with Gap
        
        $display("\n[TEST 2] Multiple Packets with Gap");
        data_valid = 1;
        byte_count = 8;
        repeat (3) @(posedge clk);
        #1;
        if(packet_start == 1) begin
            $display(" - packet_start detected");
        end
    
        data_valid = 0;
        byte_count = 0;
        repeat (2) @(posedge clk);
        #1;
        data_valid = 1;
        byte_count = 16;
        repeat (4) @(posedge clk);
        #1;
        if(packet_start == 1) begin
            $display(" - packet_start detected");
        end
        
        data_valid = 0;
        byte_count = 0;
        @(posedge clk);
        #1;
        if(total_packets == 3 && total_bytes == 168) begin
            $display("Pass: total_packets = 3 , total_bytes = 168");
        end else begin
            $display("Fail: Expected total_packets = 3 got %0d , total_bytes = 168 got %0d",total_packets,total_bytes);
        end
        if(packet_timestamp > 0) begin
            $display("Pass: packet_timestamp captured %0d",packet_timestamp);
        end else begin 
            $display("Fail: packet_timestamp not captured");
        end
        $display("  - Current time: %0d cycles\n", current_timestamp);
        // Packet 1: 3 cycles, byte_count=8
        // Gap: 2 cycles
        // Packet 2: 4 cycles, byte_count=16
        // Check: total_packets = 2
        // Check: total_bytes = 88
        // Check: different packet_timestamp values

        
        // TEST 3: Back-to-Back Packets
        
        $display("\n[TEST 3] Back-to-Back Packets");
        data_valid = 1;
        byte_count = 8;
        repeat (3) @(posedge clk);
        #1;
        if(packet_start == 1) begin
            $display(" - Packet 1 detected");
        end
        
        data_valid = 0;
        byte_count = 0;
        @(posedge clk);  // 1 cycle gap
        #1;
        data_valid = 1;
        byte_count = 16;
        repeat (4) @(posedge clk);
        #1;
        if(packet_start == 1) begin
            $display(" - Packet 2 detected");
        end
        
        data_valid = 0;
        byte_count = 0;
        @(posedge clk);
        #1;
        if(total_packets == 5 && total_bytes == 256) begin
            $display("Pass: total_packets = 5 , total_bytes = 256");
        end else begin 
            $display("Fail: Expected total_packets = 5 got %0d , total_bytes = 256 got %0d",total_packets,total_bytes);
        end
        if(packet_timestamp > 1) begin
            $display("Pass: packet_timestamp captured %0d",packet_timestamp);
        end else begin 
            $display("Fail: packet_timestamp not captured");
        end
        $display("  - Current time: %0d cycles\n", current_timestamp);
        // Packet 1: 3 cycles, byte_count=8
        // Packet 1: 3 cycles
        // Packet 2: Immediate (no gap)
        // Check: counters continue accumulating

        
        // TEST 4: Long Packet
        
        $display("\n[TEST 4] Long Packet");
        data_valid = 1;
        byte_count = 4;
        repeat (20) @(posedge clk);
        #1;
        if(packet_start == 1) begin
            $display(" - Packet 1 detected");
        end
        
        data_valid = 0;
        byte_count = 0;
        @(posedge clk);  
        #1;
        if(total_packets == 6 && total_bytes == 336 ) begin 
            $display("Pass: total_packets = 6 ,total_bytes = 336");
        end else begin
            $display("Fail: Expected total_packets = 6 got %0d , total_bytes = 336 got %0d",total_packets,total_bytes);
        end
        if(packet_timestamp != 0) begin
            $display("Pass: packet_timestamp captured %0d", packet_timestamp);
        end else begin
            $display("Fail: packet_timestamp not captured");
        end 
        $display(" -Current time : %0d cycles\n",current_timestamp);

        // One packet: 20 cycles
        // Check: packet_start pulses ONLY once
        // Check: timestamp captured at start, not updated during packet

        $display("\n========================================");
        $display("All Tests Complete");
        $display("========================================");
        $finish;
    end

endmodule